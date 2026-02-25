# 架构演进：解耦 UI 与 DEK 全量重加密

**Context**: 针对审计发现的架构耦合（UI 直接持有 Service）和 DEK 旋转未实现全量重加密的问题进行修复。

**Strategy**: 
1. 引入 BLoC 设计模式，将业务逻辑从 Widget 中剥离。
2. 实现全量数据的解密-重加密流程，确保护卫密钥旋转的安全性。

---

## Phase 1: BLoC 基础设施

- [ ] 创建 `lib/blocs/` 目录结构
- [ ] 实现 `VaultBloc` (State: Locked, Unlocking, Unlocked, Initializing, Error)
- [ ] 实现 `PasswordBloc` (State: Loading, Loaded, Error)
- [ ] 实现 `AuthBloc` (State: Loading, Loaded, Error)
- [ ] 修改 `main.dart`: 引入 `MultiBlocProvider` 与 `BlocBuilder` 替换 `AppNavigator` 的 `setState` 状态机

## Phase 2: 核心安全能力 (P1-5)

- [ ] 实现 `VaultService.reencryptAllData(Uint8List oldDek, Uint8List newDek)`
- [ ] 完善 `VaultService.rotateDEK()`: 调用重加密逻辑并确保原子性
- [ ] 在 `KeyManager` 异常处理中集成更详细的日志记录

## Phase 3: UI 迁移 (P1-1)

- [ ] 重构 `LockScreen`: 使用 `VaultBloc` 提交 Unlock 事件
- [ ] 重构 `SetupScreen`: 使用 `VaultBloc` 提交 Initialize 事件
- [ ] 重构 `VaultScreen`: 使用 `PasswordBloc` 驱动列表展示
- [ ] 重构 `AuthenticatorScreen`: 使用 `AuthBloc` 驱动列表展示
- [ ] 移除 Widget 中所有直接调用的 `VaultService` 属性

## Phase 4: 验证

- [ ] 执行 `flutter analyze`
- [ ] 验证 DEK 旋转后数据是否依然可读
- [ ] 验证 Lock/Unlock 状态流转是否正确
