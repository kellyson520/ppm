# Responsive Layout Spec

## 1. 断点定义 (Breakpoints)
- **Compact**: width < 600 dp (手机竖屏)
- **Medium**: 600 dp <= width < 840 dp (平板竖向、大折叠屏)
- **Expanded**: width >= 840 dp (平板横向、桌面)

## 2. 核心组件
- `ResponsiveLayout(compact: Widget, medium: Widget?, expanded: Widget?)`
- 如果 `medium` 未定义，后撤到 `compact`；如果 `expanded` 未定义，后撤到 `medium` 或 `compact`。

## 3. UI 策略

### 3.1 导航 (Navigation)
- **Compact**: 顶部 `AppBar`，底部 `BottomNavigationBar` (结合当前的毛玻璃设计)。
- **Medium / Expanded**: 丢弃 `BottomNavigationBar`，采用左侧侧边栏 `NavigationRail`，保留现有图标及色系。顶部视情况保留简化的 `AppBar`。

### 3.2 列表展示 (List)
- **Compact**: `ListView`。
- **Medium**: `GridView.builder` (横向双列)。
- **Expanded**: 左侧列表，右侧直接嵌入详情面版 (Master-Detail)。

### 3.3 交互表单 (Forms)
- 所有带输入框 (`TextField`) 的页面增加底部 padding 缓冲：`padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)`
- 并在外层嵌套 `SingleChildScrollView`。

## 4. 目录变动
- 增: `lib/ui/widgets/responsive_layout.dart`
- 改: `lib/ui/screens/vault_screen.dart` 等各个含 `TextField` 的界面
