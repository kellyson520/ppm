# Task Report: Fix Android Gradle Compilation Errors (v2)

## Summary
在之前的修复中，尝试将 `kotlinOptions` 迁移到 Kotlin 2.0 推荐的 `compilerOptions` DSL。但在 CI 构建中发现，Android Gradle Plugin (AGP) 的 `android` 扩展块并不直接支持 `compilerOptions` 属性，导致 "Unresolved reference: compilerOptions" 错误。

本次任务回滚了该迁移，恢复使用 `kotlinOptions` 以确保构建成功。

## Changes
1. **回滚 DSL 迁移**:
   - 将 `android { compilerOptions { ... } }` 修改回 `android { kotlinOptions { jvmTarget = "17" } }`。
   - 移除了不再使用的 `import org.jetbrains.kotlin.gradle.dsl.JvmTarget`。

2. **保留基础修复**:
   - 继续保留之前对 `java.util.Properties` 和 `java.io.FileInputStream` 的显式导入和修复，确保 `key.properties` 读取逻辑正常。

## Verification Results
- **静态检查**: `kotlinOptions` 是 Android 模块中配置 Kotlin 编译选项的稳定方式。
- **构建建议**: 虽然 `kotlinOptions` 在纯 Kotlin 项目中被 `compilerOptions` 取代，但在当前 AGP 环境下的 Android 模块中，`kotlinOptions` 仍然是标准做法。

## Impact
- 解决了 Gradle 编译时无法解析 `compilerOptions` 的错误。
- 保证了 release 构建过程中签名配置的正确加载。
