# Task: 完善导出导入与UI美化

## Context
用户需要：1. 完善本地导出和导入功能；2. 美化 WebDAV 的创建节点界面；3. 全局美化和整理 UI 界面，使其简洁、流畅，交互体验达到行业顶尖水平（遵循 `ui-ux-pro-max` 技能的设计系统）。

## Strategy
1. **导出和导入功能**:
   - 检查 `settings_screen.dart` 中现有的导出/导入占位符。
   - 实现无格式备份 (JSON) 或加密备份 (Vault/DB 级)。
   - 使用 `file_picker` 或 `path_provider` 进行本地文件读写。
2. **WebDAV 节点创建界面**:
   - 检查 `webdav_settings_screen.dart` 或触发创建节点的 AlertDialog。
   - 重构对话框，使用项目标准色系和圆边输入框（12px radius，`#0F3460` bg 等）。
3. **全局 UI 美化**:
   - 回顾 `lib/ui/theme.dart` 确保暗黑主题色符合 `#1A1A2E`, 卡片 `#16213E`, 输入框 `#0F3460`, 主色 `#6C63FF`。
   - 添加平滑动画、Ripple 效果、清晰的布局。
   - 更新 ListView，增加平滑滚动与过度动画效果。

## Phased Checklist
- [x] Phase 1: 系统初始化与状态梳理
- [x] Phase 2: 实现本地数据导入与导出服务 (`export_import_service.dart` / `vault_service.dart`)
- [x] Phase 3: 美化 WebDAV 创建节点界面
- [x] Phase 4: 全局 UI 美化复查与更新（Theme、ListViews、Buttons）
- [x] Phase 5: 测试与验证，生成 report.md
