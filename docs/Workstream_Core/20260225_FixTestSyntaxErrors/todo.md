# Task: 修复测试文件语法错误 (Fix Test Syntax Errors)

**Context**: 两个核心测试文件 `crypto_entropy_test.dart` 和 `vault_orchestration_test.dart` 存在语法错误，导致 CI 或静态分析失败。

**Strategy**:
1. 使用 `flutter analyze` 精确识别错误位置。
2. 修复类名、方法名或导入路径的冲突。
3. 确保测试逻辑符合最新的 BLoC 和架构变更。

## Phased Checklist

### Phase 1: Planning & Setup
- [x] 初始化任务文档。
- [x] 运行静态分析识别错误。

### Phase 2: Build (Fixing)
- [x] 修复 `test/unit/crypto/crypto_entropy_test.dart`。
- [x] 修复 `test/unit/services/vault_orchestration_test.dart`。

### Phase 3: Verification
- [x] 运行 `flutter analyze` 确保无报错。
- [x] 运行目标测试文件确保 pass。

### Phase 4: Reporting
- [x] 生成 `report.md`。
- [x] 更新 `process.md`。
