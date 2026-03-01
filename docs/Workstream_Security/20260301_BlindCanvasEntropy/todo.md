# Workstream: Blind Canvas Entropy Integration

## 任务背景
在创建金库（主密码）时，引入“画板盲画”作为额外熵源，将人类行为的混沌物理属性（坐标、压力、时间戳）与系统伪随机数融合，以提升主密钥的不可预测性，抵抗针对PRNG漏洞的攻击，并增强用户安全感。

## 方案设计 (Spec)

### 1. 核心流程
1. **输入主密码**：用户设置并确认主密码。
2. **物理熵采集阶段**：跳转至“赛博画板”，用户在全黑屏幕（或深色背景）上随机涂鸦约 5-10 秒。
   - **盲画设计**：不实时绘制线条，或线条在 500ms 内淡出，防止图案泄露。
   - **数据采集**：记录 `Points(x, y, pressure, tilt, timestamp)`。
3. **熵值计算**：对所有采集到的点信息进行 `SHA-512` 哈希，得到 `EntropyBuffer`。
4. **密钥派生**：
   - 算法：`Argon2id`
   - 输入：`MasterPassword` + `EntropyBuffer` + `Salt`
5. **金库初始化**：使用派生出的密钥加密金库根数据。

### 2. UI/UX 细节
- **画板动画**：使用 `CustomPaint` 画布，背景为深色极简风格。手指划过处产生微弱的火花或粒子效果（随即消失）。
- **引导语**： "请闭上眼睛在屏幕上随意涂鸦，我们将采集您的指尖混沌状态来为您锻造金库钥匙。"
- **进度反馈**：底部显示能量条，当采集到的点数达到阈值（如 500 个点）时自动完成。

### 3. 技术指标
- **采集点属性**：
    - `x, y` (double)
    - `pressure` (double, 如果设备支持)
    - `timestamp` (nanoseconds)
- **哈希函数**：SHA-512 (SHA-2 Family)
- **密钥拉伸**：Argon2id (Memory-hard)

### 4. 架构改动
- **Service 层**：`VaultService.initialize` 增加 `Uint8List? entropy` 参数。
- **Crypto 层**：`CryptoService` 提供 `generateEntropyFromPoints` 工具函数。
- **UI 层**：`SetupScreen` 增加 `_buildEntropyCanvasPage` 页面。

## 待办事项 (TODO)
- [x] 初始化任务文档与环境 (PSB Phase 1 & 2)
- [x] 修改 `VaultEvent` 和 `VaultBloc` 以支持 `entropy` 参数传递
- [x] 实现 `EntropyCanvasWidget` 手势数据采集逻辑
- [x] 实现哈希融合逻辑 `SHA-512(raw_events) -> EntropyBuffer`
- [x] 集成到 `SetupScreen` 的 PageView 流转中
- [x] 验证密钥生成的确定性与安全性
