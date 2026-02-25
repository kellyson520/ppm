# 技能本地化适配 (Skill Localization)

## 背景 (Context)
项目目前拥有一系列强大的技能（Skills），但大部分技能的说明文档（SKILL.md）及 `AGENTS.md` 中的描述均为英文。为了提升团队协作效率及符合 PSB 工程系统规范，需要对这些技能进行中文本地化适配。

## 策略 (Strategy)
1. **架构对齐**: 将原有的 Python/Generic 技能适配为 Flutter/Dart 核心技术栈（BLoC, SQFLite, WebDAV, build_runner）。
2. **批量翻译**: `AGENTS.md` 技能描述全面汉化。
3. **SKILL.md 深度适配**: 逐一更新核心技能的内部指令，删除无关的 Python 规范，加入 Flutter 质量门禁。
4. **Windows 环境优化**: 确保所有 Skill 脚本在 PowerShell 下运行无虞。

## 待办清单 (Checklist)

### Phase 1: 规划与初始化
- [x] 创建任务 Workstream 目录
- [x] 初始化 `todo.md` 与 `spec.md`
- [x] 注册任务至 `docs/process.md`

### Phase 2: 架构对齐与本地化 (Architecture & Localization)
- [ ] **AGENTS.md 全面汉化与架构对齐**: 将技能描述更新为符合 Flutter 项目的术语。
- [ ] **核心技能适配 (Flutter/Dart Focus)**:
    - [ ] `core-engineering`: 适配为 Flutter TDD、`build_runner` 与 `flutter analyze` 规范。
    - [ ] `local-ci`: 适配为 Flutter 检查流程（analyze -> test）。
    - [ ] `database`: 适配为 SQFLite/SQLCipher 规范。
    - [ ] `async-error-handling`: 适配为 Dart Future/Stream 错误处理。
    - [ ] `ui-ux-pro-max`: 适配为 Flutter Widget 树与 Theme 系统。
- [ ] **非核心/冗余技能清理**: 标记或移除与项目完全无关的 Python 技能（如 `vercel-deploy`, `telegram-bot` 如确认不需要）。

### Phase 3: 架构与平台适配
- [ ] 检查 Skill 中的脚本路径是否适配 Windows
- [ ] 确保 `SKILL.md` 中的 Trigger 与 Role 符合中文语境下的 AI 感知

### Phase 4: 验证与验收
- [ ] 运行 `task-syncer` 验证状态
- [ ] 生成交付报告 `report.md`
- [ ] 归档任务
