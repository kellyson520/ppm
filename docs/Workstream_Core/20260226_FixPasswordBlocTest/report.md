# Task Report: Fix PasswordBloc Test Errors

## 1. 任务背景
修复 `test/unit/blocs/password_bloc_test.dart` 中的静态分析错误及运行错误，确保测试套件能够通过 CI 门禁。

## 2. 发现的问题
- **依赖冲突**: `bloc_test`, `mockito` 与 `freezed` 之间存在版本冲突，导致 `pub get` 失败。
- **语法错误**: `@GenerateMocks` 标注位置不正确且 import 语法有误。
- **构建缺失**: `password_bloc_test.mocks.dart` 文件未生成。
- **类型不匹配**: `deleteCard` 的 Mock 返回了 `Map` 而不是 `Future<bool>`。
- **Lint 警告**: 存在悬挂文档注释 (dangling_library_doc_comments) 和缺失的 `const` 构造函数。

## 3. 解决方案
- **依赖升级**: 执行 `flutter pub upgrade --major-versions` 解决了 transitive dependency 冲突。
- **代码重构**:
  - 将 `@GenerateMocks` 移至 `main()` 函数上方。
  - 添加 `library;` 声明以规避文档注释警告。
  - 修正 Mock 返回值为 `true`。
  - 为 `PasswordDeleteRequested` 添加 `const`。
- **代码生成**: 运行 `dart run build_runner build` 生成 mock 文件。

## 4. 验证结果
- **静态分析**: `flutter analyze` 无错误、无警告。
- **单元测试**: `flutter test` 全部 12 个用例通过。

```text
00:05 +12: All tests passed!
```

## 5. 归档
任务已闭环，相关文档已更新。
