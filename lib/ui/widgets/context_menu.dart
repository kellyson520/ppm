import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_container.dart';

/// 单个上下文菜单选项
class ContextMenuOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const ContextMenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
}

/// 展示一个 Apple HIG 风格的毛玻璃上下文菜单。
///
/// 特性：
/// - 高斯模糊半透明遮罩底层
/// - 菜单容器：毛玻璃卡片 + 连续圆角
/// - 弹簧缩放入场 + 淡入
/// - 点击外部 / 按返回键关闭
/// - 支持破坏性操作（红色文字）
///
/// [anchor] 是菜单的锚点位置（全局坐标），如果为 null 则居中显示。
Future<void> showContextMenu({
  required BuildContext context,
  required List<ContextMenuOption> options,
  Offset? anchor,
  double maxWidth = 220,
}) {
  return Navigator.of(context).push(
    _ContextMenuRoute(
      options: options,
      anchor: anchor,
      maxWidth: maxWidth,
    ),
  );
}

class _ContextMenuRoute extends PopupRoute<void> {
  final List<ContextMenuOption> options;
  final Offset? anchor;
  final double maxWidth;

  _ContextMenuRoute({
    required this.options,
    required this.anchor,
    required this.maxWidth,
  });

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.35);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _ContextMenuOverlay(
      animation: animation,
      options: options,
      anchor: anchor,
      maxWidth: maxWidth,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class _ContextMenuOverlay extends StatelessWidget {
  final Animation<double> animation;
  final List<ContextMenuOption> options;
  final Offset? anchor;
  final double maxWidth;

  const _ContextMenuOverlay({
    required this.animation,
    required this.options,
    required this.anchor,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    // 计算菜单位置
    double top;
    double left;

    if (anchor != null) {
      // 优先放在锚点下方或上方
      const menuHeight = 200.0; // 预估
      if (anchor!.dy + menuHeight + 16 < screenSize.height) {
        top = anchor!.dy + 8;
      } else {
        top = anchor!.dy - menuHeight - 8;
      }
      left = (anchor!.dx - maxWidth / 2).clamp(16.0, screenSize.width - maxWidth - 16.0);
    } else {
      top = (screenSize.height - 200) / 2;
      left = (screenSize.width - maxWidth) / 2;
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // 毛玻璃遮罩（点击关闭）
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),
          // 菜单
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final curved = Curves.elasticOut.transform(animation.value);
              return Positioned(
                top: top,
                left: left,
                child: Transform.scale(
                  scale: 0.85 + 0.15 * curved,
                  child: Opacity(
                    opacity: animation.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              );
            },
            child: GlassContainer(
              borderRadius: 20,
              blurSigma: 28,
              backgroundColor: const Color(0xCC1A1A2E),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < options.length; i++) ...[
                      _MenuOptionTile(option: options[i]),
                      if (i < options.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white.withValues(alpha: 0.06),
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuOptionTile extends StatelessWidget {
  final ContextMenuOption option;

  const _MenuOptionTile({required this.option});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        option.onTap();
      },
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            Icon(
              option.icon,
              size: 20,
              color: option.destructive
                  ? const Color(0xFFFF6B6B)
                  : Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 14),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: option.destructive
                    ? const Color(0xFFFF6B6B)
                    : Colors.white.withValues(alpha: 0.9),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
