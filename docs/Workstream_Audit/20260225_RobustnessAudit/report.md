# ZTD Password Manager — 鲁棒性 & 架构审计报告

> **审计日期**: 2026-02-25  
> **审计员**: Architecture Auditor (PSB System)  
> **覆盖版本**: v0.2.4  
> **审计范围**: `lib/` 全量代码（main.dart、services/、core/、ui/）

---

## 📊 执行摘要 (Executive Summary)

| 维度          | 评分 | 状态           |
|:-------------|:----:|:-------------|
| 架构分层      | 7/10 | ⚠️ 有可优化空间 |
| 安全鲁棒性    | 8/10 | ✅ 整体良好     |
| 代码壮硕性    | 6/10 | ⚠️ 存在技术债   |
| 测试覆盖率    | 3/10 | 🔴 严重不足     |
| 静态分析      | 9/10 | ✅ 仅1个 lint  |
| 功能完整性    | 5/10 | ⚠️ 多处 TODO  |

**总体结论**：项目核心加密架构设计非常专业（双信封加密、CRDT/事件溯源、盲索引搜索），但存在明确的**架构耦合问题**、**测试缺失**、**功能骨架未完成**等技术债。下面按优先级分类逐一说明。

---

## 🔴 P0 — 架构红线 (立即修复)

### P0-1: `VaultService` 解密逻辑存在严重 Bug

**文件**: `lib/services/vault_service.dart` · 第 280-306 行  
**问题**: `decryptCard()` 方法构造了假的 `EncryptedData`，`iv` 和 `authTag` 被硬编码为空的零字节，这意味着**解密会在实际场景中报错或返回错误数据**。

```dart
// ❌ 错误：IV 和 authTag 为零字节，与加密时存储的真实值不匹配
final encryptedData = EncryptedData(
  ciphertext: base64Decode(card.encryptedPayload),
  iv: Uint8List(12),      // ← 绝对错误！IV 应从密文中提取
  authTag: Uint8List(16), // ← 绝对错误！
);
```

**根因分析**: `_encryptPayload()` 调用 `CryptoService.encryptString()` 后，只将 `encryptedPayload.ciphertext` 的 base64 存入 `card.encryptedPayload`，但 **IV、authTag 没有被序列化**进去。加密侧的 `EncryptedPayload` 模型存的是分开的三段（`ciphertext/iv/authTag`），而 `createCard()` 只存了 `ciphertext` 部分到 card 里。解密侧根本无法重建正确的 IV。

**修复方向**: 
1. `_encryptPayload()` 后应将完整的三段（ciphertext + iv + authTag）序列化（如用 `EncryptedData.serialize()`）存入 `card.encryptedPayload`。
2. `decryptCard()` 应反序列化三段后再解密：`EncryptedData.deserialize(card.encryptedPayload)`。

**影响**: 🩸 **所有密码卡的解密均会失败**，这是核心功能级 Bug。

---

### P0-2: `DatabaseService._db` 使用 `static` — 跨实例污染

**文件**: `lib/core/storage/database_service.dart` · 第 20 行  
**问题**:

```dart
static Database? _db;  // ← 危险：静态变量
```

`DatabaseService` 不是单例，但 `_db` 是静态的。若在测试或未来多 vault 场景下创建多个 `DatabaseService` 实例，它们会**共享同一个数据库连接**，且先 `close()` 会影响其他实例。

**修复方向**: 改为实例变量，或将 `DatabaseService` 改为真正的单例模式（添加 `factory` 构造函数 + 私有构造函数）。

---

### P0-3: `exportDatabase()` 调用了未实现的 `_getEncryptionKey()`

**文件**: `lib/core/storage/database_service.dart` · 第 370 行  
**问题**:

```dart
Future<String> _getEncryptionKey() async {
  // This should be implemented based on your key management strategy
  throw UnimplementedError('Encryption key retrieval not implemented');
}
```

`exportDatabase()` 在 close 数据库后调用此方法重新初始化，**会直接抛出 UnimplementedError**，导致应用崩溃且数据库被关闭后无法重新打开。

**修复方向**: 应让 `DatabaseService` 持有或通过回调获取加密 key，在初始化时缓存。

---

## 🟡 P1 — 技术债 (本迭代内修复)

### P1-1: 架构耦合 — UI 层直接持有 `VaultService`

**文件**: `lib/ui/screens/add_password_screen.dart`，`lib/ui/screens/vault_screen.dart`  
**问题**: UI Widget 的 `build` 方法内不应直接调用 `VaultService` 方法。当前 `add_password_screen.dart`（第7行）将 `VaultService` 作为 Widget 属性注入，Widget 调用 `widget.vaultService.decryptCard(...)` 等 IO 操作。

```
当前：Widget → VaultService → DatabaseService（跨层直调）
规范：Widget → BLoC/Provider → VaultService → DatabaseService
```

**影响**: UI 与业务逻辑严重耦合，难以单元测试，状态管理混乱（无统一 loading/error state）。

---

### P1-2: 未实现的功能在 UI 中"假装可用"

**文件**: `lib/ui/screens/settings_screen.dart`  
**问题**: 多处功能按钮调用为 `// TODO`，包括：
- 生物识别 (`Biometric Authentication`) Switch 被硬编码为 `value: false`，点击 `onChanged` 空实现
- WebDAV 设置、手动同步、导入/导出备份 均为空 `onTap`
- Documentation、Source Code 外链均为空实现

用户点击后**毫无反馈**（仅"Sync started"这样的假Toast），构成用户体验欺骗。

**修复方向**: 功能未实现时，应禁用按钮（`onTap: null`）或添加 `_showComingSoon()` 提示。

---

### P1-3: `main.dart` 的 `_initializeApp` 吞掉异常但不上报

**文件**: `lib/main.dart` · 第 185-188 行  
**问题**:

```dart
} on Object catch (_) {   // ← _ 表示忽略异常对象！
  setState(() {
    _appState = AppState.error;
  });
}
```

捕获了异常但没有任何日志记录（`_` 忽略），也没有调用 `CrashReportService`。`AppState.error` 状态展示的错误 UI 也没有显示具体错误原因（只显示 "Failed to initialize vault"）。

**flutter analyze 已将其标记为 lint**: `avoid_catches_without_on_clauses`（行185）。

**修复方向**:
```dart
} on Object catch (e, stack) {
  CrashReportService.instance.reportZoneError(e, stack);
  setState(() { _appState = AppState.error; });
}
```

---

### P1-4: `KeyManager.unlock()` 吞掉解密失败的异常栈

**文件**: `lib/core/crypto/key_manager.dart` · 第 147-148 行  
**问题**:

```dart
} on Exception {   // ← 没有变量名，栈丢失
  return false;
}
```

同样情况出现于 `changeMasterPassword`（236行）、`rotateDEK`（294行）、`exportEmergencyKit`（353行）、`importEmergencyKit`（382行）。
  
当解密 DEK 失败（可能是硬件 TEE 异常、Storage 损坏等），这些异常被静默吞掉，返回 `false`，让上层认为是"密码错误"。实际上可能是更严重的问题。

**修复方向**: 至少打日志，区分"密码错误"与"系统错误"。

---

### P1-5: `rotateDEK` 实现不完整 — 只换了 Key 未重加密数据

**文件**: `lib/services/vault_service.dart` · 第 416-427 行  
**问题**:

```dart
// Re-encrypt all cards with new DEK
// This is a complex operation that should be done carefully
// For now, we'll just update the session
_sessionDek = newDek;
```

开启了 DEK 轮换功能但实际上**只更新了内存中的 DEK，没有重新加密数据库里的卡片**。调用者以为旋转成功，但旧的加密数据仍用旧 DEK 加密，新 DEK 无法解密旧数据，导致数据不可读。

---

### P1-6: `add_auth_screen.dart` 调用 `authService.createCard/updateCard` 未 await

**文件**: `lib/ui/screens/add_auth_screen.dart` · 第 188-201 行  
**问题**:

```dart
if (widget.editCard != null) {
  widget.authService.updateCard(...);  // ← 没有 await！
} else {
  widget.authService.createCard(...);  // ← 没有 await！
}
if (mounted) {
  Navigator.pop(context, true);  // ← 立即返回，可能操作未持久化
}
```

如果 `createCard/updateCard` 是异步操作，界面在操作完成前就关闭了，导致**数据可能丢失**或用户列表未刷新。

---

## 🟢 P2 — 优化建议 (下一迭代)

### P2-1: 超级文件警告 — UI 层多个 Screen 超过 600 行

| 文件 | 行数 |
|:---|:---:|
| `add_auth_screen.dart` | **759** |
| `auth_detail_screen.dart` | 612 |
| `authenticator_screen.dart` | 577 |

**建议**: 将大型 Screen 拆分为子 Widget（如 `_AuthDetailHeader`、`_TotpCodeDisplay` 等），遵循 Widget 单一职责原则。

---

### P2-2: Settings Screen 版本号硬编码

**文件**: `lib/ui/screens/settings_screen.dart` · 第 336 行  
**问题**: `subtitle: Text('1.0.0')` 硬编码，与 `pubspec.yaml` 中的实际版本（`0.2.4`）不一致。

**建议**: 使用 `package_info_plus` 动态读取版本号。

---

### P2-3: `debugPrint` 在 Release 构建中仍保留

**文件**: `lib/core/diagnostics/crash_report_service.dart` · 第 110-115 行  
**问题**: 崩溃日志通过 `debugPrint` 输出，在 Release 构建中 `debugPrint` 会被移除，但日志的格式化逻辑仍会执行（浪费性能）。

**建议**: 用 `logger` 包或条件编译 (`kReleaseMode`) 控制输出。

---

### P2-4: `DatabaseService.clearAllData()` 无事务保护

**文件**: `lib/core/storage/database_service.dart` · 第 391-397 行  
**问题**: 删除5张表的操作分5个独立语句执行，没有包裹在 `transaction` 中。若中途失败会导致**部分数据被删、部分未删**的不一致状态。

---

### P2-5: `EventStore` 未验证事件链的哈希完整性

**文件**: `lib/core/events/event_store.dart`  
**问题**: 模型中存在 `prev_event_hash` 字段（用于事件链验证），但 `appendEvent` 时没有校验 `event.prev_event_hash == previousEvent.eventId` 是否一致。链式校验形同虚设。

---

## 🔬 架构全景评估

### 架构层级现状

```
lib/
├── main.dart          [应用入口 + AppNavigator 状态机] ✅ 概念清晰
├── services/
│   ├── vault_service.dart   [业务协调层: 506行] ⚠️ 过重, 需拆分
│   └── auth_service.dart    [2FA 协调层]
├── core/
│   ├── crypto/              [密码学层] ✅ 架构卓越
│   │   ├── crypto_facade.dart   [稳定 API 门面]
│   │   ├── crypto_registry.dart [可插拔算法注册表]
│   │   ├── crypto_policy.dart   [算法策略引擎]
│   │   ├── crypto_core.dart     [数据模型]
│   │   ├── key_manager.dart     [密钥生命周期管理]
│   │   └── providers/           [具体算法实现]
│   ├── storage/
│   │   └── database_service.dart [SQLCipher 数据访问层] ⚠️ 静态变量Bug
│   ├── events/
│   │   └── event_store.dart      [事件溯源存储] ✅ 设计良好
│   ├── crdt/                     [CRDT 合并逻辑] ✅
│   ├── models/                   [领域模型] ✅ 纯 Dart
│   ├── sync/                     [WebDAV 同步]
│   └── diagnostics/              [崩溃报告系统] ✅
└── ui/
    ├── screens/                  [12个页面] ⚠️ 过重、部分功能骨架
    └── widgets/                  [1个组件]  ⚠️ 组件严重不足
```

### 优势亮点 ✅
1. **双信封加密 (Double Envelope)**: KEK → DEK 设计非常专业，支持密码更换而无需重新加密数据
2. **密码算法模块化**: `CryptoFacade + Registry + Policy` 三层结构，可插拔设计，支持算法升级而不破坏向后兼容
3. **盲索引搜索**: HMAC-SHA256 盲索引防止明文数据泄露给数据库
4. **CRDT + HLC 事件溯源**: 多设备同步的正确性设计
5. **CrashReportService**: 带 `runZonedGuarded` 的多层崩溃捕获

### 核心问题 ⚠️
1. **没有 BLoC/Provider 状态管理层**: 业务状态由 Widget 的 `setState` 直接管理，VaultService 直接作为 Widget 属性传递，无法统一处理 loading/error 状态
2. **测试严重不足**: 项目只有 3 个测试文件（`crypto_test.dart`、`hlc_test.dart`、`widget_test.dart`），对已识别的 P0 Bug 均无测试覆盖

---

## 📋 待修复清单 (Fix Backlog)

```markdown
## P0 — 立即修复（阻断功能）
- [ ] [P0-1] vault_service.dart: 修复 decryptCard() 的 IV/authTag 硬编码 Bug
- [ ] [P0-2] database_service.dart: _db 由 static 改为实例变量或单例
- [ ] [P0-3] database_service.dart: 实现 _getEncryptionKey() 或注入密钥

## P1 — 本迭代修复（技术债）
- [ ] [P1-1] 引入 BLoC/Provider，解耦 UI 与 VaultService 的直接依赖
- [ ] [P1-2] settings_screen.dart: 未实现功能改为禁用/提示"即将推出"
- [ ] [P1-3] main.dart L185: catch (_) → catch (e, stack) + CrashReportService
- [ ] [P1-4] key_manager.dart: unlock/changeMasterPassword/etc 的 catch(Exception) 加日志
- [ ] [P1-5] vault_service.dart: rotateDEK() 必须重加密所有 card
- [ ] [P1-6] add_auth_screen.dart: createCard/updateCard 调用加 await

## P2 — 下迭代优化
- [ ] [P2-1] add_auth_screen.dart (759行) 拆分为子Widget
- [ ] [P2-2] settings_screen.dart: 版本号改为 package_info_plus 动态读取
- [ ] [P2-3] crash_report_service.dart: debugPrint 改用 kReleaseMode 控制
- [ ] [P2-4] database_service.dart: clearAllData() 包裹 transaction
- [ ] [P2-5] event_store.dart: appendEvent() 增加 prev_event_hash 校验
```

---

## 🚧 测试覆盖率评估

| 模块             | 测试文件 | 关键路径覆盖 |
|:----------------|:------:|:-----------:|
| `CryptoService`  | ✅ 有  | 约 60%      |
| `HLC`            | ✅ 有  | 约 70%      |
| `VaultService`   | ❌ 无  | 0%          |
| `KeyManager`     | ❌ 无  | 0%          |
| `DatabaseService`| ❌ 无  | 0%          |
| `EventStore`     | ❌ 无  | 0%          |
| `CrdtMerger`     | ❌ 无  | 0%          |
| UI Screens       | ❌ 无  | 0%          |

**结论**: 最关键的业务逻辑层（VaultService、KeyManager）均无测试，P0 Bug 也正好发生在无测试覆盖的代码路径上。

---

## 🔐 安全审计

| 检查项 | 状态 | 备注 |
|:------|:----:|:-----|
| AES-256-GCM 加密 | ✅ | 正确实现 |
| Argon2id KDF | ✅ | 有设备自适应参数校准 |
| 常量时间比较 | ✅ | `constantTimeEquals` 实现正确 |
| 内存安全清除 | ✅ | 三次覆写（00/FF/00）|
| TOTP 密钥内存保护 | ⚠️ | SecretKey 未使用 SecureBuffer |
| 紧急套件明文导出 DEK | 🔴 | `exportEmergencyKit` 返回明文 DEK JSON，无二次加密 |
| 会话 key 内存暴露 | ⚠️ | `_sessionDek` 在 Dart heap，GC 不保证立即清除 |

**最严重安全问题**: `exportEmergencyKit` 将 DEK 以明文 base64 编码导出为 JSON 字符串（无密码保护）。任何能读取此字符串的人即可解密全部密码。建议使用用户设置的导出密码对紧急套件进行二次加密（如使用 AEAD 包装）。

---

*报告生成时间: 2026-02-25T21:44:00+08:00*
