# ZTD Password Manager - 项目规范标准

本文档定义了 ZTD Password Manager 项目的所有技术标准和开发规范，确保代码一致性、可维护性和安全性。

---

## 目录

1. [编码规范](#1-编码规范)
2. [Dart/Flutter 规范](#2-dartflutter-规范)
3. [架构规范](#3-架构规范)
4. [安全规范](#4-安全规范)
5. [Git 工作流](#5-git-工作流)
6. [CI/CD 规范](#6-cicd-规范)
7. [测试规范](#7-测试规范)
8. [文档规范](#8-文档规范)
9. [命名规范](#9-命名规范)

---

## 1. 编码规范

### 1.1 基本原则

| 原则 | 说明 |
|------|------|
| **可读性优先** | 代码应自解释，避免过度注释 |
| **一致性** | 全项目保持统一的代码风格 |
| **简洁性** | 避免重复代码，使用 DRY 原则 |
| **安全性** | 安全相关的代码必须经过审计 |

### 1.2 代码格式化

```bash
# 使用 flutter format 格式化代码
flutter format .

# 格式化并检查
dart format --set-exit-if-changed .
```

**规则：**
- 缩进：2 空格（不使用 Tab）
- 行长度：建议不超过 80 字符，强制不超过 120 字符
- 运算符前后空格：`a + b` 而非 `a+b`
- 花括号：K&R 风格（Opening brace on same line）

### 1.3 Lint 规则

项目使用 `analysis_options.yaml` 中定义的规则，核心规则：

```yaml
linter:
  rules:
    # 安全
    avoid_print: true          # 生产代码禁止 print
    avoid_slow_async_io: true  # 避免慢速异步 IO

    # 代码质量
    prefer_single_quotes: true        # 使用单引号
    prefer_const_constructors: true    # 优先使用 const 构造器
    prefer_const_declarations: true   # 优先使用 const 声明
    prefer_final_fields: true         # 优先使用 final 字段
    prefer_final_locals: true         # 优先使用 final 局部变量
    unnecessary_this: true            # 避免不必要的 this

    # 错误处理
    avoid_catches_without_on_clauses: true  # catch 必须有 on 子句
    avoid_catching_errors: true              # 避免捕获 Error
    use_rethrow_when_possible: true          # 尽可能使用 rethrow

    # 性能
    avoid_unnecessary_containers: true  # 避免不必要的容器

analyzer:
  language:
    strict-casts: true      # 启用严格类型转换检查
    strict-raw-types: true  # 禁止 raw 类型
```

### 1.4 禁止的做法

```dart
// ❌ 禁止：使用 var 而不指定类型推断的明显场景
var x = someFunction();  // 当类型明确时

// ✅ 推荐：显式声明类型
String x = someFunction();

// ❌ 禁止：print 语句在生产代码
print('Debug info: $data');

// ✅ 推荐：使用日志框架或移除
// Logger.d('Debug info: $data');

// ❌ 禁止：裸 catch
try {
  doSomething();
} catch (e) {  // 缺少 on 子句
  handle(e);
}

// ✅ 推荐：捕获特定异常
try {
  doSomething();
} on SpecificException catch (e) {
  handle(e);
}
```

---

## 2. Dart/Flutter 规范

### 2.1 文件组织

```
lib/
├── main.dart                    # 应用入口
├── core/                        # 核心模块（不依赖 UI）
│   ├── crypto/                  # 密码学模块
│   │   ├── providers/            # 算法实现
│   │   ├── crypto_core.dart     # 核心类型定义
│   │   ├── crypto_facade.dart   # 业务层 API
│   │   └── crypto_policy.dart   # 策略配置
│   ├── crdt/                    # CRDT 合并逻辑
│   ├── events/                  # 事件溯源
│   ├── models/                  # 数据模型
│   ├── security/                # 安全工具
│   ├── storage/                 # 数据库层
│   └── sync/                    # 同步模块
├── services/                    # 业务服务层
├── blocs/                       # 状态管理
│   ├── auth/
│   ├── password/
│   ├── sync/
│   └── vault/
├── ui/                          # 表现层
│   ├── screens/                # 页面
│   └── widgets/                 # 组件
└── l10n/                        # 本地化
```

### 2.2 导入顺序

```dart
import 'dart:xxx';           // Dart SDK
import 'package:xxx/xxx.dart'; // 第三方包
import '../xxx/xxx.dart';     // 相对导入（项目内部）
```

### 2.3 类和接口设计

```dart
// ✅ 推荐：使用 mixin 而非继承实现复用
class MyWidget extends StatelessWidget with CustomMixin {
  // ...
}

// ✅ 推荐：使用 extension 扩展现有类
extension StringExtension on String {
  String get capitalized => this[0].toUpperCase() + substring(1);
}

// ✅ 推荐：私有类使用 _ 前缀
class _PrivateImplementation {
  // ...
}
```

### 2.4 异步编程

```dart
// ✅ 推荐：使用 async/await
Future<void> fetchData() async {
  try {
    final result = await api.getData();
    process(result);
  } on NetworkException catch (e) {
    handleError(e);
  }
}

// ❌ 避免：.then() 链式调用（复杂场景除外）
api.getData()
    .then((r) => process(r))
    .catchError((e) => handleError(e));
```

### 2.5 状态管理 (BLoC)

```dart
// ✅ 推荐：使用 freezed 生成不可变状态
@freezed
class PasswordState with _$PasswordState {
  const factory PasswordState.initial() = PasswordInitial;
  const factory PasswordState.loading() = PasswordLoading;
  const factory PasswordState.loaded(List<PasswordCard> cards) = PasswordLoaded;
  const factory PasswordState.error(String message) = PasswordError;
}

// ✅ 推荐：事件使用 sealed class
@freezed
class PasswordEvent with _$PasswordEvent {
  const factory PasswordEvent.load() = PasswordLoadRequested;
  const factory PasswordEvent.search(String query) = PasswordSearchRequested;
  const factory PasswordEvent.add(PasswordPayload payload) = PasswordAddRequested;
}
```

---

## 3. 架构规范

### 3.1 分层架构

```
┌─────────────────────────────────────────────┐
│           Presentation Layer                │
│         (UI Screens, Widgets)              │
├─────────────────────────────────────────────┤
│           Application Layer                 │
│           (BLoCs, Services)                 │
├─────────────────────────────────────────────┤
│             Domain Layer                    │
│    (Crypto, CRDT, Events, Models)          │
├─────────────────────────────────────────────┤
│          Infrastructure Layer               │
│     (Database, WebDAV, Secure Storage)       │
└─────────────────────────────────────────────┘
```

**依赖规则：**
- 上层可以依赖下层
- 下层不得依赖上层
- 同层之间通过接口依赖

### 3.2 模块边界

| 模块 | 依赖 | 说明 |
|------|------|------|
| `core/crypto` | 无 | 独立于其他模块 |
| `core/models` | 无 | 纯数据定义 |
| `core/security` | `core/crypto` | 安全工具 |
| `core/events` | `core/models`, `core/crypto` | 事件管理 |
| `core/crdt` | `core/models` | 合并逻辑 |
| `services` | `core/*` | 业务逻辑 |
| `blocs` | `services` | 状态管理 |
| `ui` | `blocs`, `services` | 表现层 |

### 3.3 加密模块设计

```dart
// ✅ 核心原则：业务层只依赖 Facade
class VaultService {
  final CryptoFacade _crypto;  // 不直接依赖具体算法

  Future<void> encryptData(...) {
    // 使用 Facade API，不关心具体算法
    final envelope = _crypto.encrypt(plaintext, key);
  }
}
```

详见 [docs/crypto_modularization/architecture.md](docs/crypto_modularization/architecture.md)

---

## 4. 安全规范

### 4.1 密钥管理

| 密钥类型 | 存储方式 | 说明 |
|----------|----------|------|
| KEK | TEE/Secure Enclave | 主密码派生，永不离开安全区域 |
| DEK | 加密后存数据库 | 每次会话重新解密 |
| Search Key | 加密后存数据库 | 用于盲索引 |

### 4.2 内存安全

```dart
// ✅ 必须：敏感数据使用后清除
void processPassword(String password) {
  final buffer = Uint8List.fromList(utf8.encode(password));
  try {
    // 处理逻辑
  } finally {
    // 清除内存
    buffer.fillRange(0, buffer.length, 0);
  }
}

// ✅ 必须：使用 SecureBuffer
class SecureBuffer {
  final Uint8List _data;

  void clear() {
    _data.fillRange(0, _data.length, 0);
  }
}
```

### 4.3 时序安全

```dart
// ✅ 必须：使用常量时间比较
bool secureCompare(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  int result = 0;
  for (int i = 0; i < a.length; i++) {
    result |= a[i] ^ b[i];
  }
  return result == 0;
}
```

### 4.4 禁止的做法

```dart
// ❌ 禁止：密码日志
logger.d('Password: $password');

// ❌ 禁止：密码硬编码
const password = 'hardcoded123';

// ❌ 禁止：不安全的随机数
final random = Random();  // 非密码学安全

// ✅ 推荐：使用 SecureRandom
final secureRandom = SecureRandom('Fortuna');
```

---

## 5. Git 工作流

### 5.1 分支命名

| 分支类型 | 命名格式 | 示例 |
|----------|----------|------|
| 功能分支 | `feature/<功能名>` | `feature/biometric-auth` |
| 修复分支 | `fix/<问题描述>` | `fix/login-crash` |
| 发布分支 | `release/v<版本号>` | `release/v0.2.18` |
| 热修复分支 | `hotfix/<问题描述>` | `hotfix/security-patch` |

### 5.2 提交规范

```
<类型>(<范围>): <简短描述>

[可选的正文]

[可选的脚注]
```

**类型：**

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | 错误修复 |
| `docs` | 文档变更 |
| `style` | 代码格式（不影响功能） |
| `refactor` | 重构（不影响功能） |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/工具变更 |

**示例：**

```bash
feat(crypto): 添加 Argon2id 密钥派生支持

- 实现 PBKDF2 到 Argon2id 的迁移
- 添加设备参数校准逻辑
- 更新测试覆盖率

Closes #123
```

### 5.3 PR 流程

```
1. 从 main 创建功能分支
2. 开发并提交代码
3. 确保 flutter analyze 通过
4. 确保所有测试通过
5. 创建 Pull Request
6. 至少 1 人 Review
7. 合并到 main
```

### 5.4 保护规则

- `main` 分支禁止直接推送
- 必须通过 PR 合并
- CI 必须通过才能合并
- 需要至少 1 个 Approve

---

## 6. CI/CD 规范

### 6.1 CI 流程

```yaml
# .github/workflows/ci.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4 with: java-version: '17'
      - uses: subosito/flutter-action@v2 with:
          flutter-version: '3.41.2'
      - uses: nttld/setup-ndk@v1 with:
          ndk-version: r27

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze code          # Step 1: 静态分析
        run: flutter analyze

      - name: Run tests              # Step 2: 单元测试
        run: flutter test

      - name: Build Android APK      # Step 3: 构建
        run: flutter build apk --release

      - name: Build Android AppBundle
        run: flutter build appbundle --release

      - name: Build Web
        run: flutter build web --release
```

### 6.2 CI 失败处理

| 阶段 | 失败原因 | 处理方式 |
|------|----------|----------|
| `flutter analyze` | Lint 错误 | 修复代码后重试 |
| `flutter test` | 测试失败 | 修复测试或代码 |
| `flutter build` | 编译错误 | 检查依赖和代码 |

### 6.3 本地验证

```bash
# 在推送代码前始终运行
flutter analyze
flutter test
```

### 6.4 发布流程

```bash
# 1. 更新版本号
# pubspec.yaml: version: 0.2.19+19

# 2. 创建 tag
git tag v0.2.19
git push origin v0.2.19

# 3. CI 自动构建并发布
```

---

## 7. 测试规范

### 7.1 测试类型

| 类型 | 位置 | 说明 |
|------|------|------|
| 单元测试 | `test/unit/` | 独立模块测试 |
| 集成测试 | `test/integration/` | 多模块协作测试 |
| Widget 测试 | `test/widget/` | UI 组件测试 |
| 端到端测试 | `test/e2e/` | 完整流程测试 |

### 7.2 测试命名

```dart
// ✅ 测试文件命名
password_bloc_test.dart      // 测试 password_bloc
crypto_facade_test.dart      // 测试 crypto_facade

// ✅ 测试函数命名
void main() {
  group('PasswordBloc', () {
    test('emits [PasswordLoading, PasswordLoaded] when load is requested', () {
      // ...
    });

    group('search', () {
      test('returns empty list when query is empty', () {
        // ...
      });

      test('filters cards by query', () {
        // ...
      });
    });
  });
}
```

### 7.3 测试原则

- **AAA 模式**: Arrange (准备) → Act (执行) → Assert (断言)
- **每个测试一个断言**: 便于定位问题
- **测试隔离**: 测试之间无依赖
- **可重复**: 每次运行结果一致

### 7.4 代码覆盖率

- 核心模块 (crypto, crdt): ≥ 90%
- 业务逻辑 (services): ≥ 80%
- UI 组件: ≥ 60%

---

## 8. 文档规范

### 8.1 代码注释

```dart
/// 密码学门面（Facade）
///
/// 供业务层（Vault/Sync/Event）调用的稳定 API。
/// 业务代码**只依赖此类**，不直接依赖具体算法实现。
///
/// 功能：
/// - 对称加密/解密（通过 CiphertextEnvelope 自描述格式）
/// - 密钥派生（KDF）
/// - ...
class CryptoFacade {
  /// 生成密码学安全随机字节
  ///
  /// [length] 需要的字节长度
  /// 返回 [Uint8List] 随机字节数组
  Uint8List generateRandomBytes(int length) {
    // ...
  }
}
```

### 8.2 API 文档

所有公开 API 必须包含：
- 功能描述
- 参数说明（含类型）
- 返回值说明（含类型）
- 异常说明
- 使用示例

### 8.3 变更日志

使用 [Keep a Changelog](https://keepachangelog.com/) 格式：

```markdown
## [0.2.19] - 2026-05-10

### Added
- Biometric authentication support

### Changed
- Upgraded to Flutter 3.41.2
- Improved search performance

### Fixed
- Resolved crash on vault unlock
```

---

## 9. 命名规范

### 9.1 文件命名

| 类型 | 命名方式 | 示例 |
|------|----------|------|
| Dart 文件 | snake_case | `password_card.dart` |
| 测试文件 | `<name>_test.dart` | `password_bloc_test.dart` |
| Mock 文件 | `<name>.mocks.dart` | `password_bloc_test.mocks.dart` |
| 生成文件 | `<name>.g.dart` | `app_localizations.g.dart` |

### 9.2 类命名

| 类型 | 命名方式 | 示例 |
|------|----------|------|
| 类 | PascalCase | `PasswordCard`, `CryptoFacade` |
| Mixin | PascalCase | `CustomScrollBehavior` |
| Extension | PascalCase | `StringExtension` |
| Enum | PascalCase | `SyncStatus` |
| Enum 值 | camelCase | `SyncStatus.idle` |

### 9.3 变量/函数命名

| 类型 | 命名方式 | 示例 |
|------|----------|------|
| 变量 | camelCase | `passwordCard`, `isValid` |
| 函数 | camelCase | `getPassword()`, `validateInput()` |
| 私有变量 | _camelCase | `_vaultService`, `_encryptionKey` |
| 常量 | camelCase 或 SCREAMING_SNAKE | `maxRetries`, `MAX_RETRY_COUNT` |
| 布尔值 | is/has/can 开头 | `isValid`, `hasPermission` |

### 9.4 状态/事件命名

```dart
// ✅ BLoC 状态使用以 State 类型名结尾的类
class PasswordState {}
class PasswordInitial extends PasswordState {}
class PasswordLoading extends PasswordState {}
class PasswordLoaded extends PasswordLoaded {}

// ✅ BLoC 事件使用以 Event 类型名结尾的类
class PasswordEvent {}
class PasswordLoadRequested extends PasswordEvent {}
class PasswordSearchRequested extends PasswordEvent {}
```

---

## 快速检查清单

在提交代码前，确认以下各项：

- [ ] `flutter analyze` 无错误和警告
- [ ] `flutter test` 全部通过
- [ ] 代码符合命名规范
- [ ] 无硬编码的敏感数据
- [ ] 公共 API 有文档注释
- [ ] 提交信息符合规范
- [ ] 已在本地测试功能正常

---

## 参考资料

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart)
- [Flutter Widget Guide](https://flutter.dev/docs/development/ui/widgets)
- [BLoC Pattern](https://bloclibrary.dev/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

*本文档由项目维护者维护，最后更新：2026-05-10*
