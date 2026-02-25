# 技能本地化适配 — 交付报告

## Summary
将 27 个技能的 SKILL.md 从通用模板（Python/FastAPI/SQLAlchemy/Gradle-only）全面适配为 ZTD Password Manager 项目的实际技术栈。

## 变更范围

### 核心架构对齐（17 个 SKILL.md 重写）
| 技能 | 变更要点 |
|------|---------|
| `core-engineering` | 架构矩阵改为 Flutter Clean Architecture (Widget/BLoC/Repository/DataSource/SQFLite) |
| `local-ci` | CI 流程从 Gradle/Flake8 改为 `flutter analyze → flutter test → build` |
| `architecture-auditor` | 审计规则从 Handler Purity/SQLAlchemy 改为 Widget Purity/BLoC Purity/层级隔离 |
| `database` | 从 Room/DAO 改为 SQFLite/SQLCipher，加入 password_cards/blind_index 等实际表结构 |
| `async-error-handling` | 从 Python asyncio/CancelledError 改为 Dart Future/Stream/BLoC 状态机错误 |
| `api-contract-manager` | 从 FastAPI audit 改为 freezed 序列化契约 + WebDAV 同步数据包校验 |
| `android-diagnostics` | 加入项目实际依赖链（sqflite_sqlcipher/mobile_scanner/flutter_secure_storage） |
| `db-migration-enforcer` | 从 SQLAlchemy migrate_db 改为 database_service.dart 的 onUpgrade 逻辑 |
| `python-runtime-diagnostics` | 从 Python ModuleNotFoundError 改为 Dart LateInitError/NoSuchMethod/DatabaseException |
| `realtime-architect` | 从 WebSocket/FastAPI 改为 WebDAV CRDT 同步（HLC/EventStore/multi-node 协议） |
| `full-system-verification` | 对齐 `.github/workflows/ci.yml` 实际步骤 |
| `windows-platform-adapter` | 加入 Flutter on Windows 场景（Gradle 编码、NDK、build_runner 文件锁） |
| `git-manager` | 版本管理从 build.gradle.kts 改为 pubspec.yaml |
| `workspace-hygiene` | 白名单对齐当前根目录实际文件 |
| `ui-ux-pro-max` | 注入项目设计系统（#6C63FF 主色、11 个 Screen 清单、安全 UI 约束） |
| `task-lifecycle-manager` | 路径对齐 lib/core/ lib/services/ lib/ui/ |
| `encoding-fixer` | 场景对齐 Flutter/Windows (Gradle GBK 输出/BOM/UTF-16LE 重定向) |

### AGENTS.md 描述更新
- 全部 27 个技能描述更新为中文，引用项目实际技术栈术语。

## Verification
- 所有 SKILL.md 中引用的路径（`lib/core/crypto/`, `lib/core/sync/`, `lib/core/storage/`, `lib/ui/screens/`, `test/`）在项目文件系统中已验证存在。
- 质量门禁命令（`flutter analyze`, `flutter test`, `dart run build_runner build`）与 CI 配置一致。

## 完成日期
2026-02-25
