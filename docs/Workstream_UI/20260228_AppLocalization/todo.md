# TODO: App Localization

## Context
用户要求对应用进行全面汉化。当前应用中存在大量硬编码的英文文本，需要迁移到官方的 `flutter_localizations` 方案。

## Strategy
1. 使用 `flutter_localizations` 结合 `intl` 插件。
2. 配置 `pubspec.yaml` 和 `l10n.yaml`。
3. 创建 `lib/l10n/` 目录并编写 `app_en.arb` 和 `app_zh.arb`。
4. 遍历 UI 逻辑，提取所有硬编码字符串。
5. 更新 `main.dart` 以支持多语言。
6. 验证汉化效果。

## Phased Checklist

### Phase 1: Environment Setup [ ]
- [ ] 在 `pubspec.yaml` 中添加 `flutter_localizations` 依赖。
- [ ] 在 `pubspec.yaml` 中启用 `generate: true`。
- [ ] 创建 `l10n.yaml` 配置文件。
- [ ] 创建 `lib/l10n/` 目录及其初始 `.arb` 文件。

### Phase 2: String Extraction [ ]
- [ ] 提取 `lib/main.dart` 中的字符串。
- [ ] 遍历 `lib/ui/screens/` 提取所有屏幕中的字符串。
- [ ] 遍历 `lib/ui/widgets/` 提取组件中的字符串。
- [ ] 自定义错误消息和提示语汉化。

### Phase 3: Implementation & Refactoring [ ]
- [ ] 更新 `MaterialApp` 配置 `localizationsDelegates` 和 `supportedLocales`。
- [ ] 使用 `AppLocalizations.of(context)!` 替换硬编码字符串。
- [ ] 处理不支持 `BuildContext` 的地方（如 Bloc 或 Service 中的错误消息）。

### Phase 4: Verification [ ]
- [ ] 运行 `flutter gen-l10n` 验证生成代码。
- [ ] 检查所有页面是否已完成汉化。
- [ ] 确保在中文系统环境下默认显示中文。
