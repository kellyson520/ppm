# 技能本地化适配 (Skill Localization)

## 背景 (Context)
将技能系统的内容从通用模板适配为项目实际的 Flutter/Dart 技术栈（SQLCipher、WebDAV CRDT 同步、零信任加密架构）。

## 策略 (Strategy)
1. **架构对齐**: 将技能内容中的路径、工具、命令替换为项目实际使用的（`flutter analyze`、`build_runner`、`sqflite_sqlcipher`）。
2. **删除无关引用**: 消除所有 Python/SQLAlchemy/FastAPI/Gradle-only 的残留指令。
3. **注入项目知识**: 将 `ARCHITECTURE.md` 中的组件关系（Crypto → KeyManager → EventStore → WebDAV Sync）直接嵌入技能文档。
4. **Windows 适配**: 确保命令兼容 PowerShell。

## 待办清单 (Checklist)

### Phase 1: 规划与初始化
- [x] 创建任务 Workstream 目录
- [x] 初始化 `todo.md` 与 `spec.md`
- [x] 注册任务至 `docs/process.md`

### Phase 2: 架构对齐 — 核心技能 SKILL.md 重写
- [x] `core-engineering` — Flutter TDD + Quality Gate (flutter analyze/test/build_runner)
- [x] `local-ci` — Flutter CI 流程 (analyze → test → build)
- [x] `architecture-auditor` — Flutter Clean Architecture 审计规则
- [x] `database` — SQFLite/SQLCipher 规范 (password_cards/blind_index/events/snapshots)
- [x] `async-error-handling` — Dart Future/Stream + BLoC 异步错误治理
- [x] `api-contract-manager` — 零信任同步契约 (freezed/json_serializable + WebDAV)
- [x] `android-diagnostics` — Flutter 构建诊断 (sqflite_sqlcipher/mobile_scanner 原生插件)
- [x] `db-migration-enforcer` — SQLCipher Schema 版本管理 (database_service.dart)
- [x] `python-runtime-diagnostics` → Dart 运行时诊断 (LateInitError/NoSuchMethod/DatabaseException)
- [x] `realtime-architect` → WebDAV CRDT 同步架构 (HLC/EventStore/multi-node)
- [x] `full-system-verification` — 对齐 CI (flutter analyze → test → build apk)
- [x] `windows-platform-adapter` — Flutter on Windows (Gradle 编码/NDK/PowerShell)
- [x] `git-manager` — pubspec.yaml 版本管理 + Conventional Commits
- [x] `workspace-hygiene` — 根目录白名单对齐实际文件结构
- [x] `ui-ux-pro-max` — Flutter Widget/Theme/Design System (#6C63FF 主色)
- [x] `task-lifecycle-manager` — 项目路径对齐 (lib/core/ lib/services/ lib/ui/)
- [x] `encoding-fixer` — Flutter/Windows 编码场景 (Gradle GBK/BOM/UTF-16)

### Phase 3: AGENTS.md 描述对齐
- [x] 所有技能描述更新为符合项目实际架构的中文摘要

### Phase 4: 验证
- [x] 确认所有 SKILL.md 引用的路径在项目中存在
- [ ] 生成交付报告 `report.md`
