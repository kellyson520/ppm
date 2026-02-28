# Task: UI Redesign Plan - implementation Checklist

## 概述 (Overview)
应用基于 Apple HIG 和空间质感的美学（毛玻璃、底层沉降缩放、无水波纹阻尼点击、去框化）来全面重构当前 "AI味/传统 Material 卡片堆叠" 的 UI。
**保留底栏三基础结构**: 密码 (Vault) / 认证器 (2FA) / 设置 (Settings)。

## 环境预检 (Pre-Flight)
- [x] 当前在正确的 `docs/Workstream_UI/Task_UIRedesignPlan` 目录下工作。
- [x] 遵守 `ui-ux-pro-max` 约束，确保 `useMaterial3: true` 以及黑暗主基调 `#1A1A2E`。

---

## 阶段一：核心基建与原子组件 (Phase 1: Core Foundation)
- [x] **1. 全局动画引擎配置**:
  - [x] 移除所有的 `InkWell` 与水波纹 (`splashColor: Colors.transparent`, `highlightColor: Colors.transparent`)。
  - [x] 创建 `BouncingWidget` 基础组件：利用 `AnimationController` 实现基于弹簧物理 (Spring physics) 的 0.95x 缩放下陷反馈（TapDown 缩小，TapUp 原速回弹带 HapticFeedback）。
- [x] **2. 核心材质与高斯模糊封装**:
  - [x] 编写 `GlassContainer` Widget：整合 `BackdropFilter`、`BoxDecoration` (0.05~0.15 极低透明度的深蓝背景) 及 `1px rgba(255,255,255,0.08)` 发光描边。
- [x] **3. Apple HIG 排版系统**:
  - [x] 更新 `ThemeData.textTheme`：严格定义大标题 (LargeTitle, 34px bold)、标头 (Title, 22px bold)、正文 (Body, 17px)、及说明 (Caption, 13px)。消除花里胡哨的冗余字号。

## 阶段二：全局框架与导航栏 (Phase 2: Scaffolding & Navigation)
- [x] **1. 绘制三维深度背景 (Depth Background)**:
  - [x] 设计一个全局唯一的 `Scaffold` 底层，背景色定死为 `#101018`。加入极淡的 `#6C63FF` 径向渐变 (Radial Gradient) 作为环境呼吸光晕。
- [x] **2. 玻璃态悬浮状态底栏 (Floating Glass Dock)**:
  - [x] 从传统 `BottomNavigationBar` 彻底切换脱壳。
  - [x] 实现距离屏幕底部 30px 的半透明悬浮孤岛。内部严格只保留三个图标： **Vault (锁)**, **2FA (时钟/盾)**, **Settings (齿轮)**。
  - [x] 图标激活状态使用高亮 `#6C63FF` 配合极小的原点指示器。

## 阶段三：主战场 - 密码库重建 (Phase 3: Vault Screen Reborn)
- [x] **1. Sliver 大标题引擎**:
  - [x] 废去 `AppBar`，引入 `CustomScrollView` 与 `SliverAppBar.large`。向上反滑时，搜索框和 `Vault` 标题缩小且呈现模糊磨砂态。
- [x] **2. 呼吸式列表重塑 (List Decardification)**:
  - [x] 取消现有使用 `Card` 的厚重密码列表包裹。
  - [x] 改写单个密码条目组件 `VaultItemWidget`：纯色底透明度为 0，只有极细的 `1px` 分割线。左侧是圆角为 12px 的图标背板，右侧排版清晰的主副标题组合。
  - [x] 裹入 `BouncingWidget`，实现一键点按物理沉降效果。
- [x] **3. 悬浮底板沉浸式动画 (The iOS 3D Modal Effect)**:
  - [x] 在 `Navigator` 层定制专属的底板开启交互（替代 `push` 跳转新页面）。
  - [x] 当在此主屏幕中弹出「新建密码」或者「查看密码详情」时，运用缩放将 `Vault` 主层等比缩小到 `0.92x` 并稍微下沉（附带变暗层）。产生 "iOS空间退让" 的极致高端感。

## 阶段四：底面板详情与交互 (Phase 4: Bottom Sheet Details)
- [x] **1. 设计万用模态详情层 (Modal Detail Bottom Sheet)**:
  - [x] 重构 `PasswordDetailScreen` 与 `AddPasswordScreen` 为圆角透明 `Scaffold` 底，由底端向上抽出并带有拖层胶囊条 (Drag Handle)。
  - [x] 去掉这些子界面的背景与阴影，采用 Xcode / Apple 设计规范中的暗色流沙材质填充，以接住背后的模糊透视底色。
- [x] **2. 手势拉回与状态刷新**:
  - [x] 保证通过自带手势向下关闭底板时，`onThen` 或者 `whenComplete` 能够正确把 `Vault` 屏幕解除 "沉缩" 的状态，变回原有透视层级。
- [ ] **3. 表单微光化与长按气泡**:
  - [ ] 取消厚重的输入框黑底外挂阴影，保持通透的极低透明度底板。
  - [ ] "长按气泡 (Context Menu)" 与小微交互补足。

## 阶段五：2FA 与设置平移 (Phase 5: Authenticator & Settings)
- [x] **1. 认证器页面融合**:
  - [x] 无缝继承 Phase 3 的 Sliver 大标题及极简条目流。
  - [x] TOTP 倒计时圆环采用更加纤细的 (StrokeWidth=2.0) 和深红/亮绿渐变高亮。
- [x] **2. 设置页扁平化**:
  - [x] 将所有的设置使用圆角外框（平滑曲线苹果风组），内部条目之间采用极细玻璃分割线 `Divider(color: Colors.white.withOpacity(0.05))` 融合呈现，放弃全卡片突兀堆积。

---

> 主理人：以上是结合您的 "Apple HIG 方案" 与 "维持 Vault/2FA/Setting 三键底栏" 的核心重构工作细分流 (Todo Stream)。
> 请审查，若通过我们将直接进入 [阶段一] 开始手撕高斯底板与弹簧物理组件引擎！
