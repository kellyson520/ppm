# CI/CD 规范

本文档定义了 ZTD Password Manager 项目的持续集成和持续部署流程。

---

## 目录

1. [CI/CD 概述](#1-cicd-概述)
2. [工作流配置](#2-工作流配置)
3. [质量门禁](#3-质量门禁)
4. [构建产物](#4-构建产物)
5. [发布流程](#5-发布流程)
6. [故障排查](#6-故障排查)

---

## 1. CI/CD 概述

### 1.1 架构

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Actions                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Push/PR ──→ Checkout ──→ Setup ──→ Analyze ──→ Test ──→   │
│                                                  Build ──→   │
│                                                  Release     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 CI 触发条件

| 事件 | 说明 |
|------|------|
| Push to `main` | 主分支更新 |
| Pull Request to `main` | PR 审查 |
| Tag `v*` | 版本发布 |
| Manual Trigger | 手动运行 |

---

## 2. 工作流配置

### 2.1 完整 CI 配置

位置: `.github/workflows/ci.yml`

```yaml
name: ZTD Password Manager CI

on:
  push:
    branches: [ "main" ]
    tags: [ "v*" ]
  pull_request:
    branches: [ "main" ]
  workflow_dispatch:  # 手动触发

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      # ==================== 环境设置 ====================
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.2'
          channel: 'stable'
          cache: false

      - name: Set up Android NDK
        uses: nttld/setup-ndk@v1
        with:
          ndk-version: r27

      # ==================== 依赖安装 ====================
      - name: Install dependencies
        run: flutter pub get

      # ==================== 质量门禁 ====================
      - name: Analyze code
        run: flutter analyze

      - name: Run tests
        run: flutter test

      # ==================== 构建 ====================
      - name: Decode Keystore
        env:
          UPLOAD_KEYSTORE_BASE64: ${{ secrets.UPLOAD_KEYSTORE_BASE64 }}
        if: ${{ env.UPLOAD_KEYSTORE_BASE64 != '' }}
        run: echo "$UPLOAD_KEYSTORE_BASE64" | base64 --decode > android/app/upload-keystore.jks

      - name: Build Android APK
        run: flutter build apk --release
        env:
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEYSTORE_FILE_PATH: upload-keystore.jks

      - name: Build Android AppBundle
        run: flutter build appbundle --release
        env:
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEYSTORE_FILE_PATH: upload-keystore.jks

      - name: Build Web
        run: flutter build web --release

      # ==================== 产物上传 ====================
      - name: Upload Android APK
        uses: actions/upload-artifact@v4
        with:
          name: app-release-apk
          path: build/app/outputs/flutter-apk/app-release.apk

      - name: Upload Android AppBundle
        uses: actions/upload-artifact@v4
        with:
          name: app-release-aab
          path: build/app/outputs/bundle/release/app-release.aab

      - name: Upload Web Build
        uses: actions/upload-artifact@v4
        with:
          name: web-build
          path: build/web/

      # ==================== 发布 ====================
      - name: Zip Web Build
        run: cd build/web && zip -r ../../web-release.zip .

      - name: Create Release and Upload Assets
        if: startsWith(github.ref, 'refs/tags/v')
        uses: softprops/action-gh-release@v2
        with:
          files: |
            build/app/outputs/flutter-apk/app-release.apk
            build/app/outputs/bundle/release/app-release.aab
            web-release.zip
          generate_release_notes: true
          draft: false
          prerelease: false
          fail_on_unmatched_files: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 3. 质量门禁

### 3.1 静态分析 (`flutter analyze`)

**检查内容：**
- Dart 语法错误
- Lint 规则违规
- 类型错误
- 未使用的导入
- 未使用的变量

**Lint 规则配置：** 见 `analysis_options.yaml`

**失败处理：**
```bash
# 本地复现 CI 错误
flutter analyze

# 修复后提交
git add .
git commit -m "fix(lint): 修复 flutter analyze 错误"
git push
```

### 3.2 单元测试 (`flutter test`)

**测试覆盖目标：**

| 模块 | 覆盖率目标 | 关键测试 |
|------|------------|----------|
| `crypto` | ≥ 90% | 加密/解密、密钥派生 |
| `crdt` | ≥ 90% | 合并、冲突解决 |
| `models` | ≥ 85% | 序列化、验证 |
| `services` | ≥ 80% | 业务逻辑 |
| `blocs` | ≥ 80% | 状态转换 |

**运行测试：**
```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/unit/crypto/

# 带覆盖率
flutter test --coverage
```

### 3.3 构建验证

**目标平台：**

| 平台 | 构建命令 | 产物路径 |
|------|----------|----------|
| Android APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/` |
| Android AppBundle | `flutter build appbundle --release` | `build/app/outputs/bundle/release/` |
| Web | `flutter build web --release` | `build/web/` |

---

## 4. 构建产物

### 4.1 产物说明

| 产物 | 用途 | 命名格式 |
|------|------|----------|
| `app-release.apk` | 直接安装 | `app-release.apk` |
| `app-release.aab` | Play Store | `app-release.aab` |
| `web-release.zip` | Web 部署 | `web-release.zip` |

### 4.2 产物下载

CI 运行完成后，在 Artifacts 部分下载：

```
GitHub Actions → Run Details → Artifacts
```

### 4.3 构建缓存

Flutter 依赖缓存配置：

```yaml
- name: Set up Flutter
  uses: subosito/flutter-action@v2
  with:
    cache: true
    cache-dependency-path: pubspec.lock
```

---

## 5. 发布流程

### 5.1 自动发布 (Tag Push)

```bash
# 1. 确保 main 分支最新
git checkout main
git pull origin main

# 2. 创建发布分支（可选）
git checkout -b release/v0.2.20

# 3. 更新版本号
# 编辑 pubspec.yaml
version: 0.2.20+20

# 4. 更新 CHANGELOG.md
git add .
git commit -m "chore(release): prepare v0.2.20"

# 5. 合并到 main
git checkout main
git merge release/v0.2.20
git push origin main

# 6. 创建 tag 并推送
git tag v0.2.20
git push origin v0.2.20

# 7. CI 自动执行
# - 构建所有平台
# - 创建 GitHub Release
# - 上传构建产物
```

### 5.2 手动发布

通过 GitHub Actions 手动触发：

```
Actions → ZTD Password Manager CI → Run workflow
```

### 5.3 Release 内容

自动生成的 Release 包含：
- 构建产物 (APK, AAB, Web)
- 自动生成的更新日志
- Commit 历史

---

## 6. 故障排查

### 6.1 常见 CI 错误

#### `flutter analyze` 失败

**症状：**
```
Error: 1 error and 1 warning
```

**排查步骤：**
1. 查看 CI 日志中的具体错误
2. 本地运行 `flutter analyze`
3. 修复错误
4. 推送更新

#### `flutter test` 失败

**症状：**
```
Expected: <value>
Actual: <other_value>
```

**排查步骤：**
1. 查看失败的测试名称
2. 本地运行 `flutter test`
3. 修复测试或代码
4. 确保所有测试通过

#### 构建超时

**症状：**
```
The runner has received a truncated artifact.
```

**解决方案：**
1. 减少构建产物大小
2. 增加超时时间
3. 检查网络连接

### 6.2 环境问题

#### Java 版本不匹配

```yaml
- name: Set up Java
  uses: actions/setup-java@v4
  with:
    distribution: 'temurin'
    java-version: '17'  # 确保与 Android Gradle 兼容
```

#### Flutter 版本问题

```yaml
- name: Set up Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.41.2'  # 使用稳定版本
```

#### NDK 版本问题

```yaml
- name: Set up Android NDK
  uses: nttld/setup-ndk@v1
  with:
    ndk-version: r27  # 与 build.gradle.kts 一致
```

### 6.3 Debug 技巧

#### 启用调试日志

```yaml
- name: Debug CI
  run: |
    echo "=== Flutter Version ==="
    flutter --version
    echo "=== Dart Version ==="
    dart --version
    echo "=== Pub Cache ==="
    ls -la ~/.pub-cache
```

#### 本地模拟 CI 环境

```bash
# 使用 Docker (Ubuntu-based)
docker run -it ubuntu:22.04 bash

# 安装 Flutter
apt update
apt install curl git unzip xz-utils
cd /opt
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.41.2-stable.tar.xz
tar xf flutter_linux_3.41.2-stable.tar.xz
export PATH="$PATH:/opt/flutter/bin"

# 运行 CI 检查
flutter analyze
flutter test
```

---

## 附录：CI 环境详情

### Ubuntu 版本
```
Ubuntu 22.04.4 LTS (Jammy Jellyfish)
```

### Flutter 版本
```
Flutter 3.41.2 • channel stable • framework
Dart 3.8.1 • DevTools 2.36.0
```

### Java 版本
```
OpenJDK 17 (Temurin)
```

### Android NDK
```
NDK r27 (27.0.12077973)
```

### 存储
```
Android SDK (自动配置)
Flutter SDK (缓存)
```

---

*本文档由项目维护者维护，最后更新：2026-05-10*
