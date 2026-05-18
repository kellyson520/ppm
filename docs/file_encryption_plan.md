# 文件加密 / 解密功能方案

> 状态: 设计阶段 | 版本: v0.1 | 日期: 2026-05-18

---

## 1. 目标

在 ZTD Password Manager 中增加对**任意类型文件**的加密与解密能力，使其成为真正的「零信任数据保险箱」——不仅保护密码文本，也能保护照片、文档、密钥文件等敏感数据。

---

## 2. 核心设计原则

| 原则 | 说明 |
|------|------|
| **复用现有加密栈** | 使用已有的 AES-256-GCM、Argon2id KDF、KEK/DEK 双层信封加密封装 |
| **流式处理** | 大文件不分块加载到内存，使用分块加密，避免 OOM |
| **元数据保护** | 文件名、MIME 类型等元数据一并加密，防止侧信道泄露 |
| **平台原生集成** | iOS: Files App / Share Sheet，Android: SAF / Share Intent |
| **与密码库统一** | 文件加密密钥从 Vault DEK 派生，与管理密码同生命周期 |

---

## 3. 加密方案

### 3.1 文件加密信封格式 (`.ztdenc`)

```
┌──────────────────────────────────────┐
│  Header (明文)                        │
│  ├─ magic:   "ZTDF" (4 bytes)        │
│  ├─ version: uint8  (1 byte = 1)     │
│  ├─ kdfSalt: [32]byte                │
│  ├─ dekNonce: [12]byte               │
│  └─ fileNameLen: uint16              │
├──────────────────────────────────────┤
│  Encrypted Metadata (AES-256-GCM)    │
│  ├─ originalFileName: UTF-8 string   │
│  ├─ mimeType: UTF-8 string           │
│  ├─ originalSize: uint64              │
│  └─ chunkSize: uint32                 │
├──────────────────────────────────────┤
│  Encrypted Chunks (每个 chunk)        │
│  ├─ chunkNonce: [12]byte             │
│  ├─ chunkLen: uint32                  │
│  └─ ciphertext: [chunkLen]byte       │
└──────────────────────────────────────┘
```

### 3.2 密钥派生

```
fileKey = HKDF-SHA256(
    ikm: VaultSessionDEK,
    salt: randomFileSalt,
    info: "ztd-file-encryption-v1"
)
```

每个文件一个随机 salt，确保同一 DEK 加密的不同文件有独立密钥。

### 3.3 分块策略

| 文件大小 | 块大小 | 内存占用 |
|----------|--------|----------|
| ≤ 1 MB | 64 KB | ~128 KB (双缓冲) |
| 1 MB – 100 MB | 512 KB | ~1 MB |
| > 100 MB | 2 MB | ~4 MB |

---

## 4. 解密方案

1. 读取 Header，验证 magic `ZTDF`
2. 用 Vault DEK + Header.kdfSalt 派生 fileKey
3. 解密 Metadata block → 获取文件名、MIME、原始大小
4. 逐块解密 content chunks
5. 写入输出流，完成后校验总大小

---

## 5. UI / UX 流程

### 5.1 主入口
- **底部导航新增第四 tab**: `文件` (Files) — 图标: `folder_lock`
- 或: 在密码库页面顶部添加 `SegmentedControl`: [密码 | 文件]

### 5.2 文件列表视图
- 加密文件列表（显示加密后的文件名预览、加密日期、大小）
- 长按 → Context Menu: 解密 / 导出 / 删除
- 空状态: `EmptyState(icon: Icons.folder_off, title: "暂无加密文件")`

### 5.3 加密新文件
```
[+ 添加] → 系统文件选择器
         → 显示文件预览（名称、大小、类型图标）
         → 可选: 重命名
         → [加密并保存] 按钮
         → 进度条（大文件）
         → 完成后自动清理原始文件（可选开关）
```

### 5.4 解密文件
```
点击文件 → 解密到临时目录 / 用户选择的位置
         → 打开（调用系统关联应用）
         → 关闭后可选: 重新加密 / 保留明文 / 安全擦除
```

### 5.5 安全擦除
解密后的临时文件在以下时机自动安全擦除（3-pass overwrite + unlink）：
- 用户关闭查看器
- App 进入后台超过 30 秒
- Vault 锁定

---

## 6. 集成点

### 6.1 共享/分享扩展 (iOS Share Extension / Android Intent Filter)
- 从其他 App 接收文件直接加密保存
- URL Scheme: `ztdpm://encrypt?uri=file://...`

### 6.2 WebDAV 同步
- 加密后的 `.ztdenc` 文件作为二进制 blob 同步到 WebDAV
- 使用现有的 `WebDavSyncManager` 增量同步逻辑

---

## 7. 安全考量

| 威胁 | 对策 |
|------|------|
| 文件名泄露 | 文件名加密在 metadata block 中 |
| 部分已知明文攻击 | 每个 chunk 独立 nonce (AES-GCM) |
| 文件完整性 | GCM 认证标签自动校验，篡改立即检测 |
| 临时文件残留 | 3-pass overwrite + 刷新 fsync |
| 内存 dump | 密钥使用 `SecureBuffer`，用完立即 `SecByteChannel.zero` |

---

## 8. 技术实现路径

| 阶段 | 内容 | 预计工时 |
|------|------|----------|
| Phase 1 | `FileCryptoService`: 核心加密/解密流，信封格式实现 | 3 天 |
| Phase 2 | `FileVaultService`: 文件索引管理，元数据 CRUD | 2 天 |
| Phase 3 | UI: 文件列表页、加密/解密流程 | 3 天 |
| Phase 4 | 平台集成: SAF / Share Sheet / 文件选择器 | 2 天 |
| Phase 5 | WebDAV 同步、测试、安全审计 | 2 天 |

---

## 9. 依赖

- 现有: `CryptoService`, `KeyManager`, `DatabaseService`, `SecureBuffer`
- 需新增: `FileCryptoService`, `FileVaultService`, `FileBloc`, 文件相关 UI screens

---

## 10. 与密码管理的差异

| 维度 | 密码管理 | 文件加密 |
|------|---------|---------|
| 数据大小 | < 1 KB | 1 KB – 500 MB |
| 加密模式 | 一次性 AES-GCM | 流式分块 AES-GCM |
| 存储 | SQLCipher 内嵌 | 文件系统 + 索引在 DB |
| 搜索 | 明文盲索引 | 仅元数据搜索 |
| 同步 | 事件流 CRDT | 二进制 blob 增量 |

---

*此方案为设计文档，待评审通过后进入实现阶段。*
