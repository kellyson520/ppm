# Task: 崩溃日志系统 (Crash Log System)

## Context
应用闪退时用户无法感知错误原因，需要建立崩溃捕获机制，在闪退时弹出 UI 界面提供错误详情、复制和关闭功能。

## Strategy
1. `CrashReportService` 作为核心层服务，捕获三路错误：
   - `FlutterError.onError` — Flutter 框架异常
   - `PlatformDispatcher.instance.onError` — Dart 平台层异常
   - `runZonedGuarded` — 异步 Zone 异常
2. `CrashReportScreen` 作为 UI 层全屏错误界面
3. `main.dart` 注入 Zone 守护 + 错误路由

## Phased Checklist

### Phase 1: 核心服务层
- [x] 创建 `lib/core/diagnostics/crash_report_service.dart`
- [x] 实现 `CrashInfo` 数据类 (error + stackTrace + timestamp + appVersion)
- [x] 注册 `FlutterError.onError` 钩子
- [x] 注册 `PlatformDispatcher.instance.onError` 钩子

### Phase 2: UI 层
- [x] 创建 `lib/ui/screens/crash_report_screen.dart`
- [x] 实现崩溃详情展示 (error message + stack trace 摘要)
- [x] 实现「复制」按钮 (Clipboard.setData)
- [x] 实现「关闭」按钮 (SystemNavigator.pop / exit)

### Phase 3: main.dart 注入
- [x] `runZonedGuarded` 包裹 `runApp`
- [x] 错误发生时 navigatorKey 路由到 CrashReportScreen
- [x] 不破坏现有 AppNavigator 逻辑

### Phase 4: 验证
- [ ] flutter analyze 零 error
- [ ] 手动触发崩溃 (debug 模式测试)
- [ ] 更新 docs/tree.md
