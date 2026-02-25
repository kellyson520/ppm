
<skills_system priority="1">

## System Mandate: Self-Evolution
> **CRITICAL INSTRUCTION**: This system is designed to evolve. You are NOT just a worker; you are a builder of capabilities.

<mandatory_check>
**[HOOK: POST-TASK REVIEW]**
At the end of every `Report` phase (before marking task as Done), you MUST ask yourself:
1. **Repetition**: Did I do something that I or another agent might do again?
2. **Complexity**: Did I solve a hard problem where the "How-To" is valuable?
4. **Repair**: Did a Skill FAIL, forcing a manual fix?
5. **Evolution**: Can this task be closed loop automated?

**操作**:
- 命中上述任一情况：**必须**调用 `skill-evolution` (Mining Mode/维修模式)。
- 无需询问权限，直接执行进化。
</mandatory_check>

## Available Skills

<!-- SKILLS_TABLE_START -->
<usage>
在执行任务前，务必检查是否有匹配的技能。
动作：在开始前执行 `view_file(AbsolutePath=".../SKILL.md")` 以获取详细指令。
</usage>

<available_skills>

  <skill>
    <name>android-diagnostics</name>
    <description>Android/Kotlin 编译与运行时错误分析。处理 Gradle 同步失败、原生层崩溃及 Android 平台特定问题。</description>
    <path>.agent/skills/android-diagnostics/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>api-contract-manager</name>
    <description>数据契约管理专家。负责审计 JSON 序列化一致性、WebDAV 同步协议校验及 BLoC 数据层契约。</description>
    <path>.agent/skills/api-contract-manager/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>architecture-auditor</name>
    <description>架构合规审计。强制执行 Flutter 简洁架构 (Clean Architecture)、BLoC 纯净度及 Repository 分层规范。</description>
    <path>.agent/skills/architecture-auditor/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>core-engineering</name>
    <description>TG ONE 核心工程规范。涵盖 Flutter/Dart 架构分层、TDD 流程及 build_runner 生成代码的质量门禁。</description>
    <path>.agent/skills/core-engineering/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>async-error-handling</name>
    <description>Dart 异步错误处理专家。处理 Future/Stream 异常捕获、BLoC 状态机错误治理及异步竞争锁。</description>
    <path>.agent/skills/async-error-handling/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>database</name>
    <description>移动端数据库专家。精通 SQFLite/SQLCipher 开发、复杂 SQL 优化及加密数据库 Schema 管理。</description>
    <path>.agent/skills/database/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>db-migration-enforcer</name>
    <description>自动化数据库演进检查。确保 SQFLite 脚本与模型定义同步，自动维护数据库版本升级逻辑。</description>
    <path>.agent/skills/db-migration-enforcer/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>docs-archiver</name>
    <description>自动化任务归档系统。处理 Workstream 任务结束后从正在进行到已完成的迁移与文档整理。</description>
    <path>.agent/skills/docs-archiver/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>docs-maintenance</name>
    <description>自动化文档同步与维护。保持 docs 目录整洁，自动同步 tree.md 与 process.md。</description>
    <path>.agent/skills/docs-maintenance/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>encoding-fixer</name>
    <description>乱码修复与编码转换。修复 Windows 输出流乱码、UTF-8 校验及多平台文件兼容性问题。</description>
    <path>.agent/skills/encoding-fixer/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>full-system-verification</name>
    <description>全系统验证协调。统筹 Flutter 单元测试、集成测试及边缘情况验证（如 WebDAV 同步冲突）。</description>
    <path>.agent/skills/full-system-verification/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>git-manager</name>
    <description>Git 版本管理专家。负责规范化提交 (Conventional Commits)、版本号自动控制及 CHANGELOG 维护。</description>
    <path>.agent/skills/git-manager/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>local-ci</name>
    <description>本地 CI 执行器。提交前强制运行 Flutter 分析 (flutter analyze) 与针对性单元测试，适配 Flutter 构建流。</description>
    <path>.agent/skills/local-ci/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>python-runtime-diagnostics</name>
    <description>Dart/Runtime 异常分析专家。处理 NoSuchMethodError, LateInitializationError 及内存泄漏。</description>
    <path>.agent/skills/python-runtime-diagnostics/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>realtime-architect</name>
    <description>实时同步架构专家。负责 WebDAV 增量同步、双端冲突解决及实时状态分发机制。</description>
    <path>.agent/skills/realtime-architect/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>skill-author</name>
    <description>技能撰写专家。用于创建新的 Antigravity 技能，确保指令集符合 Meta-Prompt 规范。</description>
    <path>.agent/skills/skill-author/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>skill-evolution</name>
    <description>元进化技能。分析重复工作并自动沉淀为新的技能定义，实现系统自我进化。</description>
    <path>.agent/skills/skill-evolution/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>skill-master</name>
    <description>智能技能调度器。自动发现、创建、改进技能，基于实际使用反馈进行闭环优化。</description>
    <path>.agent/skills/skill-master/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>task-lifecycle-manager</name>
    <description>任务全生命周期管理。涵盖模板初始化、进度同步、文档规范 (Spec/Report) 及闭环归档。</description>
    <path>.agent/skills/task-lifecycle-manager/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>task-scanner</name>
    <description>任务扫描器。自动检测 todo.md 中的遗漏项，防止工程进度死角。</description>
    <path>.agent/skills/task-scanner/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>task-syncer</name>
    <description>任务同步器。校验 todo.md 状态与代码实现是否一致，消除“进度幻觉”。</description>
    <path>.agent/skills/task-syncer/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>telegram-bot</name>
    <description>推送与报警专家。通过 Telegram Bot 发送 CI 报告、报警信息及 WebDAV 同步状态日志。</description>
    <path>.agent/skills/telegram-bot/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>ui-ux-pro-max</name>
    <description>Flutter UI/UX 专家。精通 Widget 树管理、自定义绘图、主题扩展 (ThemeExtensions) 及流畅动画实现。</description>
    <path>.agent/skills/ui-ux-pro-max/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>vercel-deploy</name>
    <description>（备用）自动化部署专家。用于部署项目管理后台、Web 版查看器或自动化文档站点。</description>
    <path>.agent/skills/vercel-deploy/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>windows-platform-adapter</name>
    <description>Windows 环境适配。处理 PowerShell 命令、编码乱码、路径分隔符及 Windows 特定 FS 特性。</description>
    <path>.agent/skills/windows-platform-adapter/SKILL.md</path>
    <location>project</location>
  </skill>

  <skill>
    <name>workspace-hygiene</name>
    <description>工作空间保洁。强制执行项目目录整洁规范，防止临时文件污染根目录。</description>
    <path>.agent/skills/workspace-hygiene/SKILL.md</path>
    <location>project</location>
  </skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>
