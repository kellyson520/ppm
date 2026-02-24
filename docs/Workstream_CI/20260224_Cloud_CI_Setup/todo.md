# Cloud CI Setup (GitHub Actions)

## 背景 (Context)
构建云端 CI 编译流程，实现 Flutter 项目的自动化测试与构建。提高代码质量与交付效率。

## 策略 (Strategy)
使用 GitHub Actions 建立持续集成流程：
1. 环境准备：安装 Flutter SDK。
2. 质量保证：运行 `flutter analyze` 和 `flutter test`。
3. 自动化构建：生成 Android APK/AAB 和 Web 产物。
4. 产物归档：将生成的安装包上传为 Workflow Artifacts。

## 待办清单 (Checklist)

### Phase 1: 基础设施搭建
- [x] 创建 GitHub Actions 配置文件 `.github/workflows/ci.yml`
- [x] 配置 Flutter 环境初始化步骤
- [x] 配置依赖获取 (`flutter pub get`)

### Phase 2: 质量门禁
- [x] 添加代码静态分析步骤 (`flutter analyze`)
- [x] 添加单元测试步骤 (`flutter test`)

### Phase 3: 多平台构建
- [x] 添加 Android 构建步骤 (APK & AAB)
- [x] 添加 Web 构建步骤
- [x] 添加产物归档步骤 (upload-artifact)

### Phase 5: 依赖冲突修复
- [x] 降级 `intl` 版本以匹配 `local_auth` 约束 (`^0.18.1`)
- [x] 升级 CI 配置文件中的 Flutter SDK 版本到 `3.24.5`
- [x] 验证问题已解决 (基于用户提供的解决建议)
