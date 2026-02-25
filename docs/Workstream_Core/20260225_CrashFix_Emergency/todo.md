# Task: 紧急修复应用闪退及日志缺失 (Crash Fix Emergency)

**Context**: 用户反馈应用打开即闪退，且现有的崩溃日志系统未捕获到任何信息。怀疑是在 Navigator 初始化之前的早期崩溃，或者崩溃系统本身存在盲区。

**Strategy**: 
1. 增强 CrashReportService 的鲁棒性，确保在 Navigator 未就绪时仍能通过 fallback 机制显示 UI 或至少通过控制台打印。
2. 修复主程序初始化逻辑中的潜在风险。
3. 检查数据库初始化等早期环节的 FFI/Native 加载问题。

## Phased Checklist

### Phase 1: Robustness Enhancement (Crash Reporting)
- [x] 增强 `lib/main.dart` 中的 `crashService` 回调，支持 Navigator 为空时的 fallback。
- [x] 在 `CrashReportService._report` 中强制执行 `debugPrint`，确保控制台始终有输出。
- [x] 增加 `WidgetsFlutterBinding.ensureInitialized()` 后的全局异常捕获。
- [x] 移除 `CrashReportService` 对 `intl` 的依赖，消除库初始化导致的次生崩溃。

### Phase 2: Initialization Audit & Native Fix
- [x] 修复 `android/app/src/main/res/values/styles.xml` 中的主题冲突（AppCompat 缺失导致 FragmentActivity 闪退）。
- [x] 在 `android/app/build.gradle.kts` 中显式引入 `appcompat` 依赖。
- [ ] 审计 `VaultService.isInitialized()` 调用链。
- [ ] 检查 `DatabaseService.initialize()` 在 Windows 环境下的兼容性（FFI）。

### Phase 3: Verification
- [ ] 运行 `flutter analyze` 确保无代码质量问题。
- [ ] 模拟一个早期异常（如在 `main` 中 throw）验证新机制。

### Phase 4: Reporting
- [ ] 生成 `report.md`。
- [ ] 更新 `process.md`。
