import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 一个高度基于物理弹簧（Spring Physics）的交互封装 Widget，
/// 专用于替代 Material 的 InkWell 或 Ripple，
/// 可以在点击时提供极为顺滑的沉浸感与阻尼微缩（Apple HIG 风格）。
class BouncingWidget extends StatefulWidget {
  final Widget child;

  /// 点击回呼函数
  final VoidCallback? onTap;

  /// 长按回调 (Optional Context Menu Trigger)
  final VoidCallback? onLongPress;

  /// 按下时的目标缩放比，通常在 0.90 - 0.98 之间
  final double scaleFactor;

  /// 动画运动曲线配置
  final Duration duration;
  final Duration reverseDuration;

  const BouncingWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.95,
    this.duration = const Duration(milliseconds: 150),
    this.reverseDuration = const Duration(milliseconds: 250),
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
    );

    // 使用非线性曲线，按下时平滑，松开时有真实物理回弹感 (elasticOut 会稍微夸张，
    // 这里采用类似 apple 真实的弹性阻尼曲线 easeOutCubic/easeOutBack)
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      // 在完成 Tap 时，加入触控反馈（极低的震动带来高级感）
      HapticFeedback.lightImpact();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.reverse();
    }
  }

  void _onLongPress() {
    if (widget.onLongPress != null) {
      HapticFeedback.mediumImpact();
      widget.onLongPress!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector 拦截各类点击事件
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: _onLongPress,
      // 动效核心缩盖
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
