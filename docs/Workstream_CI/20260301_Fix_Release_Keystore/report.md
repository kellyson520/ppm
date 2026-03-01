# Report: 修复 Android Release 签名校验失败的问题

## 问题分析 (Analysis)
在 CI 环境 (GitHub Actions) 中，Android Release 构建失败，报错如下：
`Keystore file '/home/runner/.config/.android/debug.keystore' not found for signing config 'release'.`

根本原因有两个：
1. **步骤顺序错误**: `ci.yml` 中 `Build Android APK` 位于 `Decode Keystore` 之前，导致构建时签名文件尚未生成。
2. **回退逻辑漏洞**: `build.gradle.kts` 在未找到 Release 签名时，会强制尝试回退到 `debug` 签名。但在 CI 运行中，`debug.keystore` 并不存在于默认路径，导致 Gradle 的 `validateSigningRelease` 任务报错。

## 解决建议 (Solution)
1. **调整 CI 工作流顺序**: 将 `Decode Keystore` 步骤移至所有构建步骤之前。
2. **增加条件判断**: 为 `Decode Keystore` 增加 `if` 条件，仅在 GitHub Secrets 存在时执行，防止空环境报错。
3. **增强 Gradle 构建脚本鲁棒性**:
   - 只有在 `debug.keystore` 物理存在时才进行回退。
   - 只有在 `storeFile` 物理存在时才为 `release` 构建指定 `signingConfig`。这允许在缺失密钥的环境下（如本地初次运行或未配置 Secret 的 CI 分支）成功构建出**未签名**的 APK，而不是崩溃。

## 变更详情 (Changes)
- [x] **.github/workflows/ci.yml**: 移动解码步骤，增加触发条件。
- [x] **android/app/build.gradle.kts**: 增强签名配置的校验逻辑。

## 验证结果 (Verification)
- 已修复由于脚本执行顺序导致的"文件未找到"错误。
- 即使不配置签名密钥，本地和 CI 构建也能通过（生成未签名版本），配置后则自动完成签名。

## 用户后续操作 (Action Required)
如果你希望 CI 能够自动签名并发布：
1. 确保在 GitHub 仓库中设置了以下 Secrets:
   - `UPLOAD_KEYSTORE_BASE64`
   - `KEY_ALIAS`
   - `KEY_PASSWORD`
   - `KEYSTORE_PASSWORD`
2. 之前的 `ci.yml` 提示需要手动取消注释，**现在已由 AI 自动调整并修复**，你无需再修改 `ci.yml`。

---
**Status: Tasks Completed.**
