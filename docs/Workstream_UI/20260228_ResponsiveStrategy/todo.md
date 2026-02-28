# 响应式布局与平板适配 (Responsive Strategy)

## Context
当前应用在多尺寸设备（特别是小屏幕横版填表、平板竖屏宽屏等）下存在布局溢出或空间利用率低的问题。需要引入符合 Material 3 与 KISS 原则的原生响应式架构。

## Strategy
基于 `LayoutBuilder` 划分为 Compact(<600), Medium(600~840), Expanded(>=840)。不同模式下使用不同的导航和内容呈现策略：
- Compact: 手机样式 (BottomNavigationBar + ListView)
- Medium: 平板竖向 (NavigationRail + GridView)
- Expanded: 平板横向 (NavigationRail + 双栏 Master-Detail)
- 全局: Keyboard SafeArea 与 Form 自动加滚动条

## Phased Checklist

### Phase 1: Infrastructure
- [x] 创建 `todo.md` 引流
- [x] 更新 `process.md`
- [x] 编写 `lib/ui/widgets/responsive_layout.dart`

### Phase 2: Navigation Refactoring
- [x] 改造 `VaultScreen` 为响应式 (使用 `ResponsiveLayout` 区分模式)
- [x] 增加 `NavigationRail` 支持

### Phase 3: Master-Detail System
- [x] 改造密码及验证器列表页，支持宽屏下的 Master-Detail (双栏并排)

### Phase 4: Form & SafeArea
- [x] 对现有所有的 `AddXxx` 等表单页实施 SafeArea 保障及横屏键盘滚动修复

### Verification
- [x] 宽屏/窄屏测试无 `A RenderFlex overflowed` 问题
- [x] 导航状态一致性检查
- [x] 所有测试通过 (`flutter test`)
