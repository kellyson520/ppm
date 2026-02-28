# Fix Placeholder Implementation
Context: 全局搜索发现项目中存在部分 `TODO` 占位实现未完成业务逻辑，如 `url_launcher` 打开网页、列表中密码标题占位、及返回占位字符等问题。本任务负责打通占位逻辑，确保业务逻辑闭环。
Strategy: 检查和修复这些占位实现。在 vault 列表页获取所有的 title（用解密 payload），修复 `url_launcher` 跳转网页等。

### Phase 1: Planning
- [x] 找出所有的 `TODO` 和 `Placeholder`。发现4处主要问题（列表标题、网址跳转、Mock测试占位、指纹解锁(考虑到本地没设备先实现骨架)]
- [x] 创建任务并放入 `process.md`

### Phase 2: Implementation
- [x] 修复 Vault 列表中 `PasswordCardItem` 获取实际标题的问题 `_loadData` 预解密。
- [x] 增加 `url_launcher` 依赖，修复 PasswordDetail 中的网址打开。
- [x] 处理指纹识别 `local_auth`。

### Phase 3: Verification
- [x] 测试 PasswordCardItem 的标题展示正常。
- [x] 测试 Detail 页 URL 点击打开。
- [x] flutter test 运行通过。
