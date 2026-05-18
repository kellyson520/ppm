import 'package:flutter/material.dart';
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

/// 展示一个 Apple HIG 风格的上下文菜单。
///
/// 简约实现：使用 PopupRoute 的半透明遮罩 + 毛玻璃菜单卡片。
/// 去除全屏 BackdropFilter（在某些设备上会导致黑屏）。
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
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => '关闭菜单';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final screenSize = MediaQuery.of(context).size;

    double top;
    double left;
    const menuHeight = 200.0;

    if (anchor != null) {
      if (anchor!.dy + menuHeight + 16 < screenSize.height) {
        top = anchor!.dy + 8;
      } else {
        top = anchor!.dy - menuHeight - 8;
      }
      left = (anchor!.dx - maxWidth / 2)
          .clamp(16.0, screenSize.width - maxWidth - 16.0);
    } else {
      top = (screenSize.height - menuHeight) / 2;
      left = (screenSize.width - maxWidth) / 2;
    }

    return Stack(
      children: [
        Positioned(
          top: top,
          left: left,
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              ),
              child: GlassContainer(
                borderRadius: 20,
                blurSigma: 28,
                backgroundColor: const Color(0xEE1A1A2E),
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
          ),
        ),
      ],
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
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
