# 审计任务 TODO

**Context**: 对 ZTD Password Manager v0.2.4 进行全面的代码鲁棒性、架构合规性和安全性审计。

**Strategy**: 按 architecture-auditor + core-engineering 技能规范，执行架构层级审计、静态分析、安全扫描并生成分级修复方案。

---

## Phase 1: Audit Execution

- [x] 加载 architecture-auditor、core-engineering、task-lifecycle-manager 技能
- [x] 扫描项目目录结构（lib/、services/、core/、ui/）
- [x] 执行 flutter analyze 静态分析
- [x] 扫描 UI 层对 VaultService/DatabaseService 的直接依赖（架构合规检查）
- [x] 扫描 services/core 层对 Flutter UI 的依赖（反向依赖检查）
- [x] 扫描 catch 块异常处理质量
- [x] 扫描 TODO/FIXME 标记（功能完整性检查）
- [x] 扫描文件大小（God Component 检查）
- [x] 审阅核心模块（main.dart, vault_service.dart, key_manager.dart, database_service.dart, event_store.dart, crypto_facade.dart）

## Phase 2: Report Generation

- [x] 生成分级审计报告 (`report.md`)
  - P0: 架构红线（立即修复）
  - P1: 技术债（本迭代修复）
  - P2: 优化建议（下迭代）
- [x] 生成 Fix Backlog 清单
- [x] 安全审计矩阵
- [x] 测试覆盖率评估

## Phase 3: Fix

- [x] [P0-1] 修复 vault_service.dart + auth_service.dart decryptCard() / _encryptPayload() Bug（IV/authTag 硬编码零字节）
- [x] [P0-2] 修复 database_service.dart static _db → 实例变量 + 单例模式
- [x] [P0-3] 重构 exportDatabase() 接受 encryptionKey 参数，删除抛 UnimplementedError 的 _getEncryptionKey()
- [~] [P1-1] 引入 Provider/BLoC 解耦 UI 与业务层（大型重构，列入下迭代）
- [x] [P1-2] 禁用 settings_screen.dart 中的未实现功能（统一 _showComingSoon() 提示）
- [x] [P1-3] main.dart catch (e, stack) + CrashReportService（已在上次会话修复）
- [x] [P1-4] key_manager.dart 所有 catch(Exception) 加 e, stack 变量 + CrashReportService 日志
- [~] [P1-5] rotateDEK 完整重加密所有 card（复杂迁移，列入下迭代）
- [x] [P1-6] add_auth_screen.dart createCard/updateCard 已验证为同步方法，代码路径正确
- [x] [P2-3] crash_report_service.dart debugPrint 用 kDebugMode 条件控制
- [x] [P2-4] database_service.dart clearAllData() 包裹 transaction 保证原子性

## Quality Gate (Verify 结果)

- [x] `flutter analyze`（7个修改文件）: **No issues found**
