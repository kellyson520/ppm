# Report: 修复 Android 虚拟机覆盖安装失败的问题 (Signature Mismatch)

## 问题描述 (Root Cause)
不同版本的 App 在安装时（如在 Android 虚拟机中测试），系统提示必须先卸载旧版本才能安装新版本。其根本原因是 **签名不一致 (Signature Mismatch)**。
因为 GitHub Actions 每次运行 CI 时，如果未指定用于 `release` 构建的 keystore，Android 构建工具会自动生成一个临时的 `debug.keystore`（动态生成，每次不同）。因此，每次 CI 构建出来的 APK 签名都不一样，Android 系统出于安全机制（防止恶意应用伪装升级），拒绝了不同签名的覆盖验证。

## 解决策略 (Strategy)
为了保证每次 CI 打包出来的 release 签名永久一致：
1. **修改 `build.gradle.kts`**: 增加 `release` 专属的 `signingConfigs`。优先从 `key.properties` 读取本地签名信息；如果在 CI/CD 环境，则从系统的环境变量 (`KEYSTORE_PASSWORD`, 等) 中读取；若都没有，则默认使用 `debug`（保证本地不会因缺失 Secret 报错）。
2. **修改 GitHub Action `ci.yml`**: 在 `flutter build apk` 和 `appbundle` 步骤中，加入了 `env` 环境变量的注入，通过 `${{ secrets.XXX }}` 抓取 GitHub Secrets 中配置的签名密钥信息。

## 需要用户执行的操作 (Action Required)
要彻底应用此修复，用户需要生成一个固定的 keystore 并上传到 GitHub 的 Secrets，流程如下：

1. **生成 Keystore**:
   在你本地电脑上执行命令（需要 Java 的 `keytool`）：
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   *记住设置的密码 (例如 `ztdpassword`)*。

2. **转为 Base64 并上传 Secret**:
   为了安全将 keystore 给 GitHub CI，转 Base64（避免二进制文件乱码）：
   ```bash
   # Linux / macOS
   base64 upload-keystore.jks > encoded_keystore.txt
   
   # Windows PowerShell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Out-File encoded_keystore.txt
   ```
   复制内容并在你的 GitHub 仓库 `Settings > Secrets and variables > Actions -> New repository secret` 里添加以下内容：
   - `KEY_ALIAS`: `upload` (刚创建 keystore 的真实别名)
   - `KEY_PASSWORD`: (keystore 的 key 密码)
   - `KEYSTORE_PASSWORD`: (keystore 的 store 密码)
   - `UPLOAD_KEYSTORE_BASE64`: 粘贴转成 Base64 后的内容。

3. **解除 `ci.yml` 里的代码注释**:
   在 `.github/workflows/ci.yml` 第 58-59 行附近，有两行被注释的 `# - name: Decode Keystore`。等你添加完以上 4 个 Secret 之后，把前面的 `#` 删掉，提交代码。

**注意**: 安装此补丁且配置好 Secret 之后，由于之前的 APK 使用了散列签名，你**最后一次**需要手动在虚拟机中卸载旧版。从那以后的任何升级，系统都会识别到一致的签名，顺利完成平滑升级，再也不用先卸载了。
