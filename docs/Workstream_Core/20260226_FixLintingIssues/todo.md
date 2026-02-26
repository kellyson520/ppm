# Task: Fix Flutter Linting Issues

**Context**: 项目开启了严格的 Lint 检查，共有 42 个问题（info/warning）会导致 CI 构建失败。需要通过自动修复和手动修复相结合的方式解决。

**Strategy**:
1. 执行 `dart fix --apply` 自动修复基础问题。
2. 手动修复无法自动完成的业务规范问题（如 `avoid_catches_without_on_clauses`, `deprecated_member_use`, `unused_field`, `dangling_library_doc_comments`, `non_constant_identifier_names`）。
3. 最终通过 `flutter analyze` 验证。

## Phased Checklist

### Phase 1: Plan & Setup [x]
- [x] 初始化任务目录与 `todo.md`
- [x] 注册任务到 `process.md`
- [x] 运行 `flutter analyze` 确认当前错误基准

### Phase 2: Build (Automatic Fix) [x]
- [x] 运行 `dart fix --apply` 并记录修复情况 (已运行，部分问题已被前序工作解决)

### Phase 3: Build (Manual Fix) [x]
- [x] 修复 `avoid_catches_without_on_clauses` (添加 `on Object`)
- [x] 修复 `deprecated_member_use` (删掉 `encryptedSharedPreferences`)
- [x] 修复 `unused_field` (`_isLoading`)
- [x] 修复 `dangling_library_doc_comments` (斜杠修改 / 验证已修复)
- [x] 修复 `non_constant_identifier_names` (驼峰化 / 验证已修复)
- [x] 修复 `unintended_html_in_doc_comment` (添加反引号)

### Phase 4: Verify & Report [x]
- [x] 运行 `flutter analyze` 确认 "No issues found!"
- [x] 生成任务报告并归档
