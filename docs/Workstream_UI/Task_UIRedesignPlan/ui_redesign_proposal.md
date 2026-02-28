# 零信任密码管理器 (PPM) UI/UX 深度重构构思方案 (Apple HIG 驱动)

> **文档目的**: 根绝现有 UI 中散发的“粗糙组件堆叠/AI 味”，全面引入并贯彻 **Apple Human Interface Guidelines (HIG)** 的三大核心理念 —— 辨识度 (Clarity)、遵从内容 (Deference)、空间深度 (Depth)，打造克制、优雅且极致流畅的暗视野原生体验。
> **状态**: 构思中 (Conceptualization phase) - 待主理人审核

---

## 一、 当前痛点分析（违背 Apple 设计哲学的表现）

目前 PPM 的 UI 虽然通过配置实现了深色模式，但缺乏真正的“质感”和“生命力”，主要表现在：
1. **Z 轴深度缺失 (Lack of Spatial Depth)**: 所有的 Card 和 Button 均粘贴在同一平面层，仅使用粗暴的纯色填充（`#16213E`）和单调的投影来区分层级，导致浓厚的“安卓早期时代的盒子感”。
2. **生硬的交互阻尼 (Linear/Stiff Motion)**: 界面跳转（生硬的 Push/Pop）、点击反馈（突兀水波纹 Ripple）都缺乏真实世界的物理弹性与连续性。
3. **空间与排版拥挤 (Cluttered Layout)**: 屏幕上方同时存在粗重的 AppBar 和搜索框，未遵循“大标题 (Large Title) 引导 -> 滚动折叠”的内容退让原则。
4. **强行修饰 (Over-decoration)**: 大量使用显式的边框、分割线，违背了“利用留白和排版自然划分视觉区域”的减法原则。

---

## 二、 核心美学主张：【 空间质感与深远暗态 (Spatial & Profound Dark) 】

基于项目中已经确立的色系（背景 `#1A1A2E`, 主色 `#6C63FF`），我们将 Apple 的设计语言映射为以下三大原则体系：

### 1. 材质与景深 (Vibrancy, Blur & Depth)
- **废除绝对的扁平化色块**。引入 iOS 标志性的 **高斯模糊贴片 (Thin Materials / BackdropFilter)**。
- 体系构建：
  1. **深空暗底 (Base)**: `#1A1A2E`的沉浸式无尽空隙。
  2. **流体内容层 (Scrollable content)**: 取消厚重卡片，密码条目直接依托在底色上。
  3. **磨砂悬浮层 (Glassy Overlays)**: 设置面板、上下文菜单 (Context Menu)、底部 Tab 栏等将全部使用“高斯模糊 + 极低透明度底色 + 0.5px 极细微光边缘”的悬浮态呈现。此举极大幅度提升 App 的高端通透感。

### 2. 连续几何与无感排版 (Continuous Squircles & Typography)
- **平滑曲率**: 放弃标准的矩形切角，全局圆角 (12px-16px) 采用形同 Apple 硬件的 **平滑曲线 (Continuous Squircle)**。
- **大标题退让框架**:
  - 弃用传统的静态 `AppBar`。
  - 使用 `SliverAppBar` 搭配超大字号和超粗字重（`Heading 1`, Inter, Bold）。在用户向下滚动查看密码内容时，大标题会如物理沉入般平滑缩小到顶端栏并带有高斯模糊底板。

### 3. 基于物理直觉的微动画 (Physics-Based Fluid Motion)
- **可打断的弹簧动画 (Interruptible Springs)**: 界面的所有打开、收起、拖动，必须具备物理惯性（Spring Damping），告别线性/贝塞尔曲线（EaseInOut）。
- **指尖压感 (Tap & Hold Gestures)**:
  - 砍掉点击时的 Material Ripple 水波纹。
  - 替换为：手指按下任何一条密码条目时，该条目会产生 **0.95倍的阻尼微缩下陷**，同时背景微微变暗；松手即回弹。这是消除“安卓粗糙感/AI味”最关键的细节。
- **长按上下文菜单 (Context Menus)**: 替代长按进入多选模式或满屏的详情跳转。长按密码条目，周边高斯模糊变暗，从条目旁弹出气泡式的复制/编辑/删除菜单，这极大地提升了“单手效率和顺滑感”。

---

## 三、 关键模块改造拆解提案 (Actionable Plan)

### 【Vault 密码库主页】
*   **头部 (Header)**: 全面转换为 Apple 原生的折叠大标题 (Large Typography Header)。顶部提供随滚动的渐隐搜索栏（输入框自身也是极其通透的毛玻璃）。
*   **列表 (List)**:
    *   移除所有的 `Card` 包裹。
    *   通过 `ListTile` 的结构，左侧是精美的大倒圆角图标（带(`#6C63FF` 极低透明度背板)），右侧是高对比的主标题与次级信息（灰色透明字）。
    *   **分割线**: 不再使用横向黑线，仅靠精致的 `Padding` 白留白进行切分。

### 【新增/编辑 底面交互 (BottomSheet over Push)】
*   **交互逻辑变换**: 在深色模式下，屏幕突然全屏转场对眼睛是一种冲击。
*   修改为：点击「添加」或「编辑」，从屏幕底部弹出 **弹性模态底板 (Modal Bottom Sheet)**。该底板铺满约 90% 屏幕，并略微带有圆角。同时，底部的 Vault 主页面会自动进行一次极小幅度的缩小沉降（类似于 Apple Maps 的半屏交互面板体验），暗示层级关系。
*   **输入框**: 只有在未 Focused 时是一条极细的下划虚线；Focused 时背景微微点亮成藏青色 `#0F3460`，不加粗鲁的四周边框。

### 【生物解锁屏幕 (Lock Screen)】
*   将当前的解锁屏幕重构为**最纯粹的黑屏**，中间悬浮一个类似 Face ID 正在识别时刻的微小而有节奏呼吸的 `#6C63FF` 同心圆环（或者品牌 Logo 的微光动画）。
*   密码键盘：数字键点击不再是方块底色，而是瞬间圆形亮起与变暗。

---

## 四、 落地所需技术调整 (Flutter 层)

1. **控件替换**:
   - 弃用大量 `Material` 层控件，引入基于物理引擎的动画库 `flutter_animate` 用于处理按下缩小（`.scale(begin: Offset(1,1), end: Offset(0.95, 0.95))`）。
   - 将部分影响视觉深度的组件考虑切换到封装的 `GlassContainer` (里面混用 `CupertinoSliverNavigationBar` 与 `BackdropFilter`)。
2. **主题引擎调整 (ThemeData)**:
   - 全局关闭 `splashColor: Colors.transparent` 和 `highlightColor: Colors.transparent` 以彻底移除涟漪效应。
   - 专门定制 `BottomSheetTheme` 和 `DialogTheme` 以符合毛玻璃加圆角的设定。

---

## 五、 主理人审核请示

> 请主理人审阅这一版基于 **Apple 高级空间感与排版驱动** 的设计重组：
> 
> 1. 您是否偏好这种通过 **半透明毛玻璃、弹簧缩放、隐去边框、底层留白** 带来的高级感，以替代之前的方案？
> 2. 长按触出上下文菜单（Context Menu）和底层模态面板（Bottom Sheet）替换新开页面的设定是否符合您对操作流的心智预期？
> 
> 如果确认并定稿，我将首先在 **Vault 主界面 (密码库)** 进行这套视觉语言的技术验证及落地代码改写。
