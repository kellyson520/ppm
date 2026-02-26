# Task: Fix PasswordBloc Test Errors

**Context**: `test/unit/blocs/password_bloc_test.dart` 存在代码静态分析错误，需要修复以通过 CI 门禁。

**Strategy**: 使用 `flutter analyze` 定位错误 -> 修复 Mockito 生成或依赖引用问题 -> 运行 `flutter test` 验证。

## Phased Checklist

### Phase 1: Plan & Setup [x]
- [x] 初始化任务目录与 `todo.md`
- [x] 注册任务到 `process.md`
- [x] 运行静态分析定位具体错误 (环境已修复及初始化)

### Phase 2: Build (Fixing) [x]
- [x] 修复 Mock 调用不一致或参数匹配错误 (deleteCard 返回值)
- [x] 修复缺失的导入或成员引用
- [x] 确保 `password_bloc_test.mocks.dart` 正常生成

### Phase 3: Verify & Report [x]
- [x] 运行 `flutter test test/unit/blocs/password_bloc_test.dart`
- [x] 生成任务报告并归档
