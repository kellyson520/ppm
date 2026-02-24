# 技术方案: 云端 CI 编译 (GitHub Actions)

## 1. 背景 (Background)
ZTD Password Manager 作为一个高安全性要求的项目，需要自动化的 CI 流程来确保每次代码变更都通过了静态检查和单元测试。同时，自动化的构建流程可以为发布提供一致的产物。

## 2. CI/CD 工具选择 (Tool Choice)
- **平台**: GitHub Actions
- **原因**: 与 GitHub 紧密集成，对 Flutter 的支持非常成熟（有官方或社区维护的 actions）。

## 3. 工作流设计 (Workflow Design)

### 3.1 触发条件 (Triggers)
- 推送 (Push) 到 `main` 分支。
- 针对 `main` 分支的 拉取请求 (Pull Request)。

### 3.2 运行环境 (Environment)
- **OS**: `ubuntu-latest` (对于 Android 和 Web 构建)
- **Note**: 如果后续需要构建 iOS/macOS，则需要 `macos-latest`。目前优先保障 Android 和 Web。

### 3.3 核心步骤 (Steps)
1.  **Checkout**: 获取源代码。
2.  **Java Setup**: 必须配置 Java 环境，因为 Android 构建依赖 Java。
3.  **Flutter Setup**: 使用 `subosito/flutter-action` 安装指定版本的 Flutter。
4.  **Dependencies**: 运行 `flutter pub get`。
5.  **Analyze**: 运行 `flutter analyze` 确保代码符合规范。
6.  **Test**: 运行 `flutter test`。
7.  **Build Android**: 
    - `flutter build apk --release`
    - `flutter build appbundle --release`
8.  **Build Web**:
    - `flutter build web --release`
9.  **Archive**: 导出产物。

## 4. 关键配置 (Key Configuration)

### Java 版本
需要 JDK 17 或更高版本以支持最新的 Android Gradle Plugin。

### Flutter 版本
应与 `pubspec.yaml` 中的要求一致，通常使用 `stable` 渠道。

## 5. 安全考量 (Security)
- CI 流程不应包含任何私钥或敏感信息。
- 如果需要签署 APK，应使用 GitHub Secrets 存储 keystore 并进行 Base64 编码。当前版本优先构建未签署的 release 版本。
