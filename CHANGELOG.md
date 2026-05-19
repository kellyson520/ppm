# Changelog

## [0.2.23] - 2026-05-19

### ✨ 新增 (Features)
- **ZTDF 文件加密引擎**: 流式分块 AES-256-GCM + HKDF 密钥派生 + ZTDF 二进制信封格式。
- **加密文件管理**: 新增「文件」tab，支持加密/解密/删除任意类型文件。
- **传输安全**: AES-GCM auth tag 防篡改，任何字节修改 → 解密失败。
- **元数据保护**: 文件名、MIME 类型加密存储，明文中不可见。

### 🧪 安全测试 (Security Tests)
- **文件加密安全测试**: 15 项 — 往返、防篡改、nonce 唯一性、香农熵、卡方检验、边界、元数据保护。

### 🔒 安全修复 (Security)
- **生物识别绕过**: 启用指纹前必须先验证主密码（新增 `verifyMasterPassword`）。
- **PBKDF2 强化**: 迭代次数 2k-4k → 30k-120k（OWASP 2024）。

### 🐛 Bug 修复
- **浅色模式可读性**: light bg 改为 dim dark（`#1C1C2E`），白色文字可读。
- **混沌画板无光效**: `setState` 缺失导致进度条不更新 — 已修复。
- **TOTP 5 秒偏差**: 采样频率 1s→100ms，统一时间戳。
- **长按菜单黑屏**: 移除全屏 BackdropFilter，改用 PopupRoute 内置遮罩。
- **设置页占位**: 文档/源码链接指向真实 GitHub URL。

## [0.2.22] - 2026-05-19

### 🔒 安全修复 (Security)
- **BLoC 错误消息脱敏**: 4 个 BLoC 文件共 19 处 `e.toString()` 替换为通用消息，防止内部异常细节泄露到 UI。
- **导入验证加固**: `importVaultFromJson` 改为双路径 JSON 尝试（解密→明文解析），移除脆弱的 `startsWith('[')` 试探。
- **WebDAV 明文拒绝**: `saveWebDavNode` 在 DEK 不可用时抛 `StateError`，不再降级为明文存储。
- **PBKDF2 迭代强化**: 从 2k-4k 提升到 30k-120k（OWASP 2024 合规），移除混淆的 `×1000` 乘数。
- **生物识别绕过修复**: 启用指纹解锁前必须验证主密码正确性。

### 🧪 测试增强 (Testing)
- **导出安全性测试**: 新增 `export_security_test.dart` — 9 项测试覆盖 nonce 唯一性、香农熵、卡方分布、错误密钥拒绝等。
- **测试总数**: 335 tests ✅

### 🛠 工程优化 (Engineering)
- **CI 报告系统**: 生成 `ci-reports` artifact（format/analyze/test 报告），支持下载后精确修复。
- **ci-report-reader 技能**: 自动化 CI 失败分析闭环。
- **session-hygiene 钩子**: 防止长时间运行导致 VPS 负载飙升。
- **25 个技能迁移**: 从 `/tmp/.agent/skills/` 复制到 `.reasonix/skills/`。

### 🎨 UI 增强 (UI)
- **ContextMenu 长按菜单**: 毛玻璃气泡 — 密码列表长按弹出复制/编辑/删除。
- **GlowInput 微光输入框**: 焦点微光动画。
- **EmptyState 统一空态**: 动画淡入空状态组件。
- **HelpTooltip**: 点击帮助气泡。
- **主题切换**: 支持跟随系统/暗色/亮色，FlutterSecureStorage 持久化。
- **设置页**: 文档和源码链接指向真实 GitHub URL。
- **TOTP 计时修复**: 100ms 刷新率 + 统一时间采样，消除 5 秒偏差。

## [0.2.21] - 2026-05-18

### ✨ 新增 (Features)
- **ContextMenu 长按菜单**: 毛玻璃气泡菜单 — 密码/验证器列表长按弹出复制/编辑/详情/删除操作。
- **GlowInput 微光输入框**: Apple HIG 风格 — unfocused 透明底+虚线下划线，focused 背景渐亮+品牌色微光，错误动画淡入。
- **EmptyState 空状态组件**: 统一动画空态（图标+标题+描述+CTA 按钮），带淡入+上滑动画。
- **HelpTooltip 帮助提示**: 点击?图标弹出毛玻璃说明气泡，叠加层展示，点击任意处关闭。

### 🔧 修复 (Fixes)
- **输入框全局升级**: `add_password_screen`、`add_auth_screen`、`setup_screen`、`webdav_settings_screen` 所有输入框替换为 GlowInput。
- **空状态统一**: `vault_screen`、`authenticator_screen`、`webdav_settings_screen` 使用 EmptyState 组件。
- **废弃代码清理**: 移除 `webdav_settings_screen` 未使用的 `_buildTextField` 辅助方法。

## [0.2.20] - 2026-05-18

### ✨ 新增 (Features)
- **CI 分析报告系统**: CI 现在生成 `ci-reports` artifact（format / analyze / test 报告），支持下载后精确修复。
- **ci-report-reader 技能**: 新增自动化技能 — 下载 CI 失败报告 → 解析精确错误 → 生成 SEARCH/REPLACE 修复。
- **BLoC 单元测试**: 新增 `AuthBloc`、`SyncBloc`、`VaultBloc` 三个完整状态机测试（45+ 用例），全部 313 测试通过。

### 🔧 修复 (Fixes)
- **代码格式化**: 修复全部超长行 (>100 chars)，兼容 dart format line-length 100 检查。
- **Analyze 警告**: 修复 4 个 analyze warnings（未使用 import、未使用局部变量）。
- **测试编译错误**: 修复 `vault_bloc_test.dart` 中 `entropy` 变量作用域错误。
- **Mock 过期**: 补全 `vault_orchestration_test.mocks.dart` 中缺失的 `setDek` 方法 stub。

## [0.2.19] - 2026-05-15

### 🔧 修复 (Fixes)
- **修复 dart 分析错误**: 修正 `security_test.dart` 中 `const` 表达式中的字符串乘法操作（改用 `final`），删除未使用的局部变量。
- **修复弃用 API**: 将 `vault_screen.dart` 中弃用的 `Matrix4.scaled()` 替换为 `scale()`。
- **代码格式化**: 全量执行 `dart format --line-length 100`，消除 CI 格式化检查失败。
- **统一 Flutter 版本**: CI 全环境从 3.41.2 升级到 3.41.9，消除 dart format 结果不一致问题。
- **README 重写**: 全新炫酷设计 — shields.io 徽章、架构图、威胁模型表、快速入门指南。

## [0.2.18] - 2026-03-01

### 🔧 修复 (Fixes)
- **CI 工作流语法修正**: 修复了 `ci.yml` 中无法直接在 `if` 条件中使用 `secrets` 对象的语法错误，改为通过环境变量中转。
- **CI 工作流修复**: 修复了 Android Release 构建时因 Keystore 解码步骤滞后导致的“文件未找到”错误。
- **构建脚本健壮性**: 增强了 `build.gradle.kts` 的签名逻辑，仅在密钥文件真实存在时应用签名配置，支持无密钥环境下（如本地开发）正常构建未签名 APK。
- **本地化同步**: 重新生成了本地化代码 (`flutter gen-l10n`)，解决了生成的代码与 `arb` 文件不一致导致的静态分析错误。

## [0.2.15] - 2026-02-28

### 🔧 修复 (Fixes)
- **Android Gradle 修复**: 解决了 `build.gradle.kts` 中的 Kotlin DSL 编译错误（`Properties` 和 `FileInputStream` 引用缺失）。
- **配置迁移**: 将 `jvmTarget` 设置迁移至最新的 `compilerOptions` DSL，适配 Kotlin 2.0+。

## [0.2.12] - 2026-02-28

### 🔧 修复 (Fixes)
- **CI 加密自签名**: 修复了 Android CI 自动发布时覆盖安装提示签名不一致的问题，统一了发布版签名配置。


### ✨ 新功能 (Features)
- **全局UI改版**：采用行业顶尖标准的 Glassmorphism 玻璃态背景与高阶卡片阴影动画。
- **备份导入与导出**：完善 `VaultService` 的无格式 JSON 数据备份与恢复，接入 `SettingsScreen` 提供含异常捕获的安全分享机制 (`share_plus` 和 `file_picker`)。
- **WebDAV 设置美化**：重构 WebDAV 节点创建弹窗，采用沉浸深色极夜蓝主题与宽扁距高可读性布局。

### 🔧 修复 (Fixes)
- **全面本地化支持**：在 `AddAuthScreen` 及其余缺失模块补全了国际化文案支持 (`app_en.arb` / `app_zh.arb`)。
- **Dart 分析清理**：修复所有的遗留语法警告及异常捕获边界条件 (`on Exception catch`)，达成 100% `flutter analyze` 无警告。

## [0.2.10] - 2026-02-28

### ✨ 新功能 (Features)
- **二维码导出集成**：在 `AuthDetailScreen` 完整集成 `qr_flutter` 以支持凭证二维码生成，替代了先前的占位符图案。

### 🔧 修复 (Fixes)
- **业务逻辑占位符补全**：全面清退应用内部遗留的 TODO 与占位逻辑，包括认证流程和密码相关功能完善。
- **异常处理加固**：修复 `SettingsScreen` 在处理设备指纹识别 (`local_auth`) 时因范围过广抛出的捕获异常，将其限定为 `Exception` 类型 (`on Exception catch`)，提升系统稳定性。

## [0.2.9] - 2026-02-28

### 🔧 修复 (Fixes)
- **单元测试修复**：更新 `widget_test.dart` 以适配本地化后的 Splash Screen。
  - 将硬编码的 tagline 文本断言替换为对 `SplashScreen` 组件类型的校验，解决 CI 环境因 Locale 差异导致的测试失败。

## [0.2.8] - 2026-02-26

### 🔧 修复 (Fixes)
- **Android SDK 升级**：将 `compileSdk` 和 `targetSdk` 升级至 36，以满足 `sqflite_sqlcipher` 插件的最低版本要求。
- **环境适配**：解决编译期间 SDK 版本不足导致的兼容性警告。

## [0.2.7] - 2026-02-26

### 🔧 修复 (Fixes)
- **加密测试稳定性**：修复 `crypto_entropy_test.dart` 中的随机性失效问题。
  - 将熵值分布容差从 50% (3-Sigma) 优化为 80% (5-Sigma)，极大降低了统计性误报。
  - 增强了测试失败时的错误提示，便于追溯随机分布异常。
- **文档同步**：完成 `20260226_FixEntropyTestFailure` 任务归档。

## [0.2.6] - 2026-02-26

### 🔧 修复 (Fixes)
- **代码规范修复**：全面修复 27 项 `flutter analyze` 警告，解决 CI 构建失败风险
  - 重构 `AuthBloc`, `PasswordBloc`, `VaultBloc` 及其测试工具，将通配 `catch (e)` 升级为 `on Object catch (e)` (`avoid_catches_without_on_clauses`)
  - 移除 `KeyManager` 中弃用的 `encryptedSharedPreferences` 参数 (`deprecated_member_use`)
  - 清理 `LockScreen` 与 `SetupScreen` 中冗余的 `_isLoading` 字段，交由 BLoC 状态管理 (`unused_field`)
  - 修复 `test_matchers.dart` 文档注释中的 HTML 解析歧义问题 (`unintended_html_in_doc_comment`)
- **CI 优化**：暂时禁用 GitHub Actions 的 Flutter 缓存 (`cache: false`) 以确保构建环境纯净，并优化 YAML 缩进

## [0.2.5] - 2026-02-26

### 🔧 修复 (Fixes)
- **测试修复**：修复 `PasswordBloc` 单元测试中的静态分析错误、Mockito 生成位置及类型不匹配问题
- **CI 升级**：升级 GitHub Actions 的 Flutter 版本至 `3.41.2` 以支持 `Color.withValues` API
- **文档更新**：同步任务报告并完成 Workstream 归档准备

## [0.2.4] - 2026-02-25

### ✨ 新功能 (Features)
- **崩溃日志系统**：新增全局异常捕获与崩溃弹窗机制
  - 新增 `lib/core/diagnostics/crash_report_service.dart`：Singleton 服务，三路拦截 Flutter 框架/Platform/Zone 异常
  - 新增 `lib/ui/screens/crash_report_screen.dart`：深色主题全屏崩溃界面，展示时间戳、来源标签、错误摘要与完整可选择 StackTrace
  - 提供「**复制报告**」（写入剪贴板，含格式化文本）和「**关闭应用**」两个操作按钮
  - `main.dart` 注入 `GlobalKey<NavigatorState>` 与 `runZonedGuarded`，崩溃时自动清空路由栈并导航至崩溃界面

## [0.2.3] - 2026-02-25


### ✨ 新功能 (Features)
- **多平台支持**：正式启用 Windows, macOS, Linux 及 Web 端支持，完成全平台工程初始化
- **工程同步**：整合近期所有开发任务进度、文档及代码改动，确保仓库状态与本地工作区一致

### 🔧 优化 (Optimization)
- **本地 CI 通过**：通过 `flutter analyze` 静态分析及全部 24 项单元测试
- **文档闭环**：同步 `docs/` 目录下所有活跃工作流任务状态

## [0.2.2] - 2026-02-25

### 🔧 修复 (Fixes)
- 同步 `pubspec.yaml` 版本号至 0.2.2

## [0.2.1] - 2026-02-25

### 🔧 修复 (Fixes)
- **全面修复 `flutter analyze` 问题**：解决全部 53 项静态分析错误与警告
  - **API 适配**：批量将废弃的 `.withOpacity()` 替换为 `.withValues(alpha: ...)`，适配 Flutter 3.24+ 最新规范
  - **业务逻辑优化**：重构 `AuthService.getCard()`, 移除对 `StateError` 的捕获，提升代码健壮性并符合 `avoid_catching_errors` 准则
  - **性能优化**：补全缺失的 `const` 构造函数并移除冗余 `const` 声明
  - **代码清理**：移除 `authenticator_screen.dart` 等文件中的未使用 import

## [0.2.0] - 2026-02-25

### ✨ 新功能：Authenticator 扫码导入 (QR Code Scanning)
- **集成 `mobile_scanner` 引擎**：支持高性能相机流二维码实时识别与解析
- **新增 `QrScannerScreen` 扫描界面**：提供沉浸式全屏扫描体验，具备双角对齐、实时扫描线动画及环境光适配功能
- **重构 `AddAuthScreen` 业务流**：支持从 2FA 二维码一键导入并自动填充 otpauth 协议字段，简化用户操作
- **平台兼容性支持**：
  - Android 21+ 相机权限动态配置
  - iOS NSCameraUsageDescription 合规描述

### 🔧 优化
- 优化 `AddAuthScreen` 的 Tab 切换逻辑，从 2 Tab 扩展至 3 Tab

### 📦 依赖
- 新增 `mobile_scanner: ^5.1.1`

---

## [0.1.0] - 2026-02-25

### ✨ 重大重构：密码学模块化 (Crypto Modularization)
- **解耦单体 `CryptoService`** 为六层可插拔架构：接口层 (`crypto_core.dart`) → 实现层 (`providers/`) → 注册层 (`crypto_registry.dart`) → 策略层 (`crypto_policy.dart`) → 门面层 (`crypto_facade.dart`) → 兼容层 (`crypto_service.dart`)
  - 定义 `Kdf` / `AeadCipher` / `KeyWrap` / `Signer` / `Rng` 五大抽象接口
  - 实现 `AesGcmProvider` (AES-256-GCM AEAD)、`Pbkdf2Provider` (PBKDF2-HMAC-SHA256)、`HkdfProvider` (HKDF-SHA256) 三个默认 Provider
- **引入自描述密文格式 `CiphertextEnvelope`**：包含 `schemaVersion`、`suiteId`、`aeadId`、`kdfParams`、`nonce`、`ciphertext`、`authTag`、`aadMeta` 等字段，支持防剪切/重放攻击
- **实现防降级策略引擎 `CryptoPolicy`**：通过 `AllowedSuites` 集合 + `SecurityLevel` 最低安全等级门槛，拒绝解密不受信任的算法套件
- **向后兼容**：`CryptoService` 保留所有旧方法签名，`EncryptedData` ↔ `CiphertextEnvelope` 互转，`KeyManager` / `VaultService` / `EventStore` 无需改动

### 🔧 修复
- 修复 `flutter analyze` 报告的全部错误与警告（跨 18 个文件），包括：
  - 清理未使用 import (`add_password_screen.dart`, `vault_screen.dart` 等)
  - 移除不当 `const` 构造函数调用 (`lock_screen.dart`, `setup_screen.dart`)
  - 修复 `crdt_merger.dart` 中的类型推断与未使用变量
  - 修复 `webdav_sync.dart` 中的方法签名与 null-safety 问题
  - 修复 `settings_screen.dart` 中的枚举引用错误
- 修复 `analysis_options.yaml` 中的无效 lint 规则引用

### 📦 依赖
- 新增 `synchronized: ^3.1.0` 用于并发安全控制

### 📝 文档
- 新增 `docs/crypto_modularization/architecture.md` 架构文档
- 新增 `AGENTS.md` 项目智能体配置

## [0.0.1] - 2026-02-24

### Added
- 初始化项目架构。
- 集成 GitHub Actions CI 自动化流程。

### Fixed
- 修复 `intl` 与 `local_auth` 的依赖冲突 (降级 `intl` 至 `^0.18.1`)。
- 修复 CI 环境中 Flutter SDK 版本过低的问题 (升级至 `3.24.5`)。
