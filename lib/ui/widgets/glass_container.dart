import 'dart:ui';
import 'package:flutter/material.dart';

/// 一个高度基于 iOS 毛玻璃风格的高级容器构建器（GlassContainer）。
/// 核心为高斯模糊（BackdropFilter），用以呈现深度三维背景透出。
class GlassContainer extends StatelessWidget {
  final Widget child;

  /// 圆角，根据设计规范通常给连续圆角大值
  final double borderRadius;

  /// 容器内补
  final EdgeInsetsGeometry? padding;

  /// 外容器补边距
  final EdgeInsetsGeometry? margin;

  /// 模糊的浓度 (Sigma 取 20-30 左右较深沉)
  final double blurSigma;

  /// 遮罩材质色：默认极低灰黑透紫
  final Color backgroundColor;

  /// 边缘光线，极细发光描边
  final BoxBorder? borderColor;

  /// 外投影颜色，苹果 HIG 更强调无界限，如需加深度可选微弱投影
  final List<BoxShadow>? boxShadows;

  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blurSigma = 24.0,
    this.backgroundColor = const Color(0x731E1E2A), // 默认接近深空的极低透明度
    this.borderColor,
    this.boxShadows,
  });

  @override
  Widget build(BuildContext context) {
    // 强制截流：Blur 只在 Clip 内奏效
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor,
              // Apple 往往有 0.5px 极薄的边线构建材质隔离
              border: borderColor ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.08), // 极细白边反光
                    width: 0.5,
                  ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
