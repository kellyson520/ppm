# Tablet UI, Search, and Export Fixes

## Context
1. 平板模式下UI没有适配新UI，出现显示错误和文字错位。我们需要学习成熟方案，确保不同设备下的兼容性。
2. 搜索逻辑存在问题，搜索结果不匹配，需要修复。
3. 导出逻辑需要支持自定义保存路径。

## Strategy
1. **Tablet UI Fix**: 分析当前 `ResponsiveLayout` 或 `MasterDetailLayout`，检查宽屏模式下的布局是否错误应用或遗漏。修复字号错位和排版问题，确保Material 3响应式标准。
2. **Search Fix**: 检查 `SearchBloc` 或 `SearchDelegate` 中的查询匹配逻辑，修复大小写不敏感或部分匹配失效的问题。
3. **Export Fix**: 引入或调整 `file_picker` 插件中的导出方法，让用户可以选择目录保存导出的文件，修改相应的备份服务逻辑。

## Phased Checklist
### Phase 1: Tablet UI Responsive Fix
- [x] 检查 `ResponsiveLayout` 适配逻辑，确认阈值（如600px）。
- [x] 修复平板/横屏下出现文字错位与显示错误的问题。
- [x] 验证平板形态与桌面端形态下的兼容性。

### Phase 2: Search Logic Fix
- [x] 定位导致搜索结果不匹配的原因（可能是匹配算法或状态未更新）。
- [x] 修复搜索并进行单元测试验证。

### Phase 3: Custom Export Path Let
- [x] 定位导出功能文件。
- [x] 修改为使用 `file_picker` 或相关系统的 `saveFile` API 以支持自定义路径。

### Phase 4: Verification & Report
- [x] 执行架构规范检查 `flutter analyze`
- [x] 生成报告。
