# Report: 崩溃日志系统 (Crash Log System)

**任务 ID**: 20260225_CrashLogSystem  
**完成时间**: 2026-02-25  
**状态**: ✅ 完成

---

## 产出总结

### 新增文件

| 文件路径 | 说明 |
|:---|:---|
| `lib/core/diagnostics/crash_report_service.dart` | 崩溃捕获核心服务，Singleton |
| `lib/ui/screens/crash_report_screen.dart` | 崩溃 UI 界面（复制 + 关闭） |

### 修改文件

| 文件路径 | 变更内容 |
|:---|:---|
| `lib/main.dart` | 注入 `GlobalKey<NavigatorState>`, `runZonedGuarded`, 三路钩子注册 |

---

## 架构说明

```
main.dart
├── GlobalKey<NavigatorState> navigatorKey   ← 全局 Navigator Key
└── main()
    ├── CrashReportService.instance.setHandler(...)   ← 崩溃 UI 路由回调
    ├── registerFlutterErrorHook()   ← FlutterError.onError
    ├── registerPlatformErrorHook()  ← PlatformDispatcher.onError
    └── runZonedGuarded(runApp, onError: reportZoneError)

lib/core/diagnostics/
└── crash_report_service.dart
    ├── class CrashInfo        ← 纯数据类（errorMessage, stackTrace, timestamp, source）
    ├── typedef CrashHandler   ← 回调类型别名
    └── class CrashReportService (singleton)
        ├── setHandler()
        ├── registerFlutterErrorHook()
        ├── registerPlatformErrorHook()
        ├── reportZoneError()
        └── _report()          ← 内部统一入口

lib/ui/screens/
└── crash_report_screen.dart
    ├── class CrashReportScreen   ← 主界面
    │   ├── _buildHeader()        ← Bug 图标 + 标题
    │   ├── _buildInfoCard()      ← 时间/来源 Chip + 错误摘要
    │   ├── _buildStackTrace()    ← 可滚动 + 可选择文本堆栈区
    │   └── _buildActions()      ← 「复制报告」+ 「关闭应用」
    └── class _ActionButton       ← 复用按钮组件
```

---

## 捕获范围

| 来源标签 | 触发条件 |
|:---|:---|
| `FlutterError` | Flutter 框架同步异常（Widget build 错误等） |
| `PlatformDispatcher` | Dart 平台层未捕获异常（Engine 层） |
| `Zone` | `async/await` Zone 内未被 try-catch 的异步错误 |

---

## 质量验证

- [x] `flutter analyze` — **No issues found** ✅
- [x] 零 `withOpacity` 废弃 API（已迁移至 `withValues(alpha:)`）
- [x] 零 `unnecessary_const` / `prefer_const_constructors` 告警
- [x] 架构分层合规：Service 在 `lib/core/`，UI 在 `lib/ui/screens/`
