import 'package:flutter/material.dart';

/// 全局响应式布局断点与核心包裹组件
class ResponsiveLayout extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  const ResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  /// 判断当前是否为 Compact (手机设备/屏幕较小)
  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// 判断当前是否为 Medium (平板竖向显示/大折叠屏)
  static bool isMedium(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 840;

  /// 判断当前是否为 Expanded (平板横向/桌面端显示)
  static bool isExpanded(BuildContext context) =>
      MediaQuery.of(context).size.width >= 840;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return expanded ?? medium ?? compact;
        } else if (constraints.maxWidth >= 600) {
          return medium ?? compact;
        } else {
          return compact;
        }
      },
    );
  }
}
