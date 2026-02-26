# Task Report: Fix Flutter Linting Issues

## 1. 任务概述
修复了项目中由 `flutter analyze` 报告的 27 个静态分析问题（info/warning）。这些问题的修复对于通过 CI（GitHub Actions）门禁至关重要。

## 2. 变更详情

### 2.1 自动修复
- 运行了 `dart fix --apply`，处理了大部分简单的规范问题。

### 2.2 手动修复
- **`avoid_catches_without_on_clauses`**:
    - 在 `AuthBloc`, `PasswordBloc`, `VaultBloc` 及其相关测试辅助工具中，将通配 `catch (e)` 修改为 `on Object catch (e)`。
    - 提升了异常处理的规范性。
- **`deprecated_member_use`**:
    - `lib/core/crypto/key_manager.dart`: 删除了 `flutter_secure_storage` 中已弃用的 `encryptedSharedPreferences: true` 参数。
- **`unused_field`**:
    - `lib/ui/screens/lock_screen.dart` & `lib/ui/screens/setup_screen.dart`: 删除了未使用的 `_isLoading` 状态字段（已由 BlocState 替代）。
- **`unintended_html_in_doc_comment`**:
    - `test/helpers/test_matchers.dart`: 为文档注释中的范型代码添加了反引号，防止 HTML 解析歧义。

## 3. 验证结果
- **静态分析**: `flutter analyze` 结果为 `No issues found!`。
- **单元测试**: 运行并通过了以下核心测试：
    - `test/unit/blocs/password_bloc_test.dart`
    - `test/unit/crdt/crdt_contract_test.dart`

## 4. 结论
任务完成，代码库现已符合严格的 Lint 规范，可安全推送到 GitHub 触发 CI。
