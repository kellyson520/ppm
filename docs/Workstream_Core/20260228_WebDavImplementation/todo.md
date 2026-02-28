# 任务: WebDAV 同步完整实现

## 状态
- [x] 数据库表扩展 (`webdav_nodes`)
- [x] `WebDavSyncManager` 完善 (移除占位符, 优化同步逻辑)
- [x] `SyncService` 实现 (管理多节点同步与持久化)
- [x] `SyncBloc` 实现 (UI 状态驱动)
- [x] `WebDavSettingsScreen` UI 实现
- [x] 集成测试与验证

## 完成事项
- [x] 修改 `DatabaseService` 添加 `webdav_nodes` 表，并处理 V2 数据库迁移。
- [x] 实现 `KeyManager.getDeviceId()` 在同步逻辑中的正确调用。
- [x] 优化 `WebDavSyncManager._syncNode` 使用 `manifest` 差异比对，仅在有新变更时下载。
- [x] 实现 `SyncService` 服务层，集成多节点管理。
- [x] 在 `SettingsScreen` 添加 WebDav 配置与手动同步入口。
- [x] 全面移除所有 `unknown-device` 占位符。
- [x] 完善中英文语言支持。
