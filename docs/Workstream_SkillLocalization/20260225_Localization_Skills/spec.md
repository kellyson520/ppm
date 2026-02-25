# 技能本地化技术方案

## 1. 翻译准则
- **核心术语保留**: 某些特定的技术术语（如 `Workstream`, `PSB`, `Trigger`, `SOP`）保留或中英对照。
- **动作动词标准化**: 使用“执行”、“调用”、“验证”、“生成”等专业动词。
- **符合 AI 感知**: 确保 Prompt (Role & Context) 翻译后，Model 的理解力不下降。

## 2. 结构适配
- **SKILL.md 结构**:
    - `name`: 保持英文
    - `description`: 翻译为中文
    - `Triggers`: 增加中文关键词触发
    - `Workflow`: 全面汉化
- **AGENTS.md**:
    - `description`: 翻译为简洁的中文摘要。

## 3. Windows 平台适配
- 检查 `scripts/` 调用是否使用 `python path/to/script.py` 而非 `./script.sh`。
- 确保路径分隔符在说明文档中是清晰的。
