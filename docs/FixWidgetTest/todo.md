# Task: 修复 widget_test.dart 错误

## 任务背景
`test/widget_test.dart` 存在编译错误，无法找到 `MyApp` 构造函数。这是因为 `lib/main.dart` 中的应用类名为 `ZTDPasswordManagerApp`，而非 `MyApp`。

## 目标
- 修复 `test/widget_test.dart` 中的类名错误。
- 确保测试能够正确运行或适配当前的应用逻辑。

## 待办事项
- [x] 环境预检：确认 `lib/main.dart` 中的应用类名。
- [x] 修复代码：更新 `test/widget_test.dart` 中的类名并重写测试逻辑（原计数器测试不适用）。
- [x] 验证：运行 `flutter test test/widget_test.dart`并通过。

## 进展
- 已确认 `lib/main.dart` 使用 `ZTDPasswordManagerApp`。
- 已将 `test/widget_test.dart` 重写为验证 Splash 页面，通过测试。
- 任务闭环。
