# Report: Blind Canvas Entropy Implementation

## 任务背景
在创建金库时引入“画板盲画”物理熵，提升主密钥的安全度与用户仪式感。

## 完成情况

### 1. 核心密码学增强
- **哈希引擎扩展**：在 `CryptoFacade` 和 `CryptoService` 中完成了 `SHA-512` 的集成。
- **混合熵池逻辑**：重构了 `KeyManager.initialize`，支持通过 `BytesBuilder` 将 32 字节系统随机数与用户手势轨迹数据混合后，通过 `SHA-512` 生成最终 Salt，提升了 256 位熵源的不可预测性。
- **密钥派生链路**：`VaultService` 和 `VaultBloc` 已全链路适配携带 `entropy` 参数的初始化请求。

### 2. 物理熵采集组件
- **`EntropyCanvasWidget`**：
    - 使用 `CustomPaint` 实现。
    - 采集 `(x, y, pressure, timestamp)` 纳秒级数据。
    - 提供了赛博朋克风格的粒子火花反馈，并支持线条随时间自动淡出（Blur out）以保护隐私。
    - 设定了 500 个采样点的充能阈值。

### 3. UI 流程集成
- **`SetupScreen` 重构**：
    - 将原有的 3 步骤 PageView 扩展为 4 步骤。
    - 增加了全新的“注入混沌能量”专门页面。
    - 进度条（LinearProgressIndicator）已同步适配 1/4 进度显示。

## 质量验证
- [x] **架构审计**：完全符合 DDD 规范，UI 与 Crypto 分层清晰。
- [x] **Lint 检查**：`flutter analyze` 无错误。
- [x] **构建检查**：Mock 类已更新，全代码可编译通过。
- [x] **功能验证**：通过单元测试验证了初始化流程的契约一致性。

## 交付
- 仓库代码已推送：`feat: implement blind canvas entropy for vault initialization`
- 已生成 Release 离线安装包（APK）。
