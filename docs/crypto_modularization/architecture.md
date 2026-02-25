# 密码学模块化重构 - 架构文档

## 📅 完成日期
2026-02-25

## 📌 改动背景
将原 `CryptoService` 单体类重构为模块化、算法可插拔的加密架构，
实现加密算法与业务逻辑的完全解耦。

## 🏗️ 架构总览

```
lib/core/crypto/
├── crypto.dart                    # barrel export
├── crypto_core.dart               # 接口 + CiphertextEnvelope + 算法套件
├── crypto_registry.dart           # Provider 注册表
├── crypto_policy.dart             # 策略引擎（防降级）
├── crypto_facade.dart             # 门面 (对外稳定 API)
├── crypto_service.dart            # 兼容层 (包装 CryptoFacade)
├── key_manager.dart               # 密钥管理
└── providers/
    ├── aes_gcm_provider.dart      # AES-256-GCM AEAD
    ├── pbkdf2_provider.dart       # PBKDF2-HMAC-SHA256 KDF
    └── hkdf_provider.dart         # HKDF-SHA256
```

## 📐 分层架构

| 层级 | 模块 | 职责 |
|:---|:---|:---|
| **接口层** | `crypto_core.dart` | 定义 Kdf / AeadCipher / KeyWrap / Signer / Rng 抽象接口 + CiphertextEnvelope 数据格式 + CryptoSuite 套件 |
| **实现层** | `providers/` | 具体算法实现，可独立替换/新增 |
| **注册层** | `crypto_registry.dart` | Provider 注册表，管理多算法并存 |
| **策略层** | `crypto_policy.dart` | 默认套件选择、防降级校验、安全等级管理 |
| **门面层** | `crypto_facade.dart` | 业务层唯一入口，封装所有加密操作 |
| **兼容层** | `crypto_service.dart` | 旧 API 的薄包装，保持 KeyManager/VaultService/EventStore 等不变 |

## 🔑 核心设计

### 1. 算法可插拔
新增算法只需：
1. 实现 `AeadCipher` 或 `Kdf` 接口
2. 在 `CryptoRegistry` 中注册
3. 在 `CryptoSuite` 中定义套件

```dart
// 例：新增 XChaCha20-Poly1305
class XChaCha20Provider implements AeadCipher { ... }

CryptoRegistry().registerAead(XChaCha20Provider());
CryptoRegistry().registerSuite(CryptoSuite(
  id: 'ZTDPM_SUITE_2026_02',
  aeadId: 'xchacha20-poly1305',
  kdfId: 'argon2id',
  ...
));
```

### 2. 自描述密文 (CiphertextEnvelope)
所有加密产物使用统一的自描述格式：
- `schemaVersion`: 格式版本
- `suiteId`: 算法套件标识
- `aeadId`: AEAD 算法
- `kdfParams`: KDF 参数
- `keyInfo`: 密钥版本
- `nonce` + `ciphertext` + `authTag`
- `aadMeta`: AAD 绑定元数据（防剪切/重放）

### 3. 防降级策略
- `AllowedSuites` 集合控制可解密的算法
- `suiteId` 不在允许集合 → 拒绝解密并告警
- `SecurityLevel` 最低安全等级门槛

### 4. 向后兼容
- `CryptoService` 保留所有旧方法签名
- `EncryptedData` ↔ `CiphertextEnvelope` 互转
- 现有代码（KeyManager, VaultService, EventStore, DatabaseService）无需任何改动

## 📋 受影响文件
| 文件 | 变更类型 | 说明 |
|:---|:---|:---|
| `crypto_core.dart` | **新增** | 接口 + 数据格式 |
| `providers/aes_gcm_provider.dart` | **新增** | AES-GCM 实现 |
| `providers/pbkdf2_provider.dart` | **新增** | PBKDF2 KDF 实现 |
| `providers/hkdf_provider.dart` | **新增** | HKDF 实现 |
| `crypto_registry.dart` | **新增** | Provider 注册表 |
| `crypto_policy.dart` | **新增** | 策略引擎 |
| `crypto_facade.dart` | **新增** | 门面 API |
| `crypto_service.dart` | **重写** | 改为 CryptoFacade 的薄包装层 |
| `crypto.dart` | **更新** | barrel export |
| `key_manager.dart` | 无改动 | 通过兼容层保持不变 |
| `vault_service.dart` | 无改动 | 通过兼容层保持不变 |
| `event_store.dart` | 无改动 | 通过兼容层保持不变 |
| `database_service.dart` | 无改动 | 通过兼容层保持不变 |

## 🔮 后续路线图
1. **Phase 1**: ✅ 完成 - 接口抽象 + 默认 Provider + CiphertextEnvelope + 防降级
2. **Phase 2**: 新增 Argon2id Provider（通过 FFI/原生库）
3. **Phase 3**: 新增 XChaCha20-Poly1305 Provider（可选）
4. **Phase 4**: 实现渐进式重加密（idle 时迁移旧数据到新套件）
5. **Phase 5**: 策略文件签名校验（防止攻击者篡改 AllowedSuites）
