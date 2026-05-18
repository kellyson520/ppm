import 'package:flutter/material.dart';

/// 帮助提示图标按钮，Apple HIG 风格。
///
/// 特性：
/// - 小问号圆形图标
/// - 点击弹出毛玻璃 tooltip 气泡
/// - 自适应定位（优先下方，无空间时上方）
class HelpTooltip extends StatelessWidget {
  final String message;
  final double size;

  const HelpTooltip({
    super.key,
    required this.message,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _show(context),
      child: Container(
        width: size + 8,
        height: size + 8,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.help_outline_rounded,
          size: size,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  void _show(BuildContext context) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => entry.remove(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: (position.dx + size.width / 2 - 130).clamp(16.0, MediaQuery.of(context).size.width - 276),
              top: position.dy + size.height + 8,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xEE1E1E2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    overlay.insert(entry);
  }
}
