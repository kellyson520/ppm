import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// 赛博混沌熵采集画板 (Blind Canvas Entropy)
///
/// 功能：
/// 1. 采集手势物理特征（坐标、压力、时间戳）作为随机源。
/// 2. 画笔痕迹随时间淡出，增强安全性并防止图案泄露。
/// 3. 提供粒子火花动效，增强视觉回馈。
class EntropyCanvasWidget extends StatefulWidget {
  /// 完成采集所需的目标采样点数
  final int targetPoints;

  /// 采集完成回调
  final Function(Uint8List entropy) onComplete;

  const EntropyCanvasWidget({
    super.key,
    this.targetPoints = 500,
    required this.onComplete,
  });

  @override
  State<EntropyCanvasWidget> createState() => _EntropyCanvasWidgetState();
}

class _EntropyCanvasWidgetState extends State<EntropyCanvasWidget>
    with SingleTickerProviderStateMixin {
  final List<_EntropyPoint> _points = [];
  final List<_VisualPathPoint> _visualPoints = [];
  late AnimationController _animationController;

  int _collectedCount = 0;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();

    _animationController.addListener(() {
      _updateVisualPoints();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateVisualPoints() {
    if (_visualPoints.isEmpty) return;

    setState(() {
      _visualPoints.removeWhere((p) => p.isExpired);
      for (var p in _visualPoints) {
        p.age++;
      }
    });
  }

  void _handlePointerEvent(PointerEvent event) {
    if (_isFinished) return;

    // 采集底层数据（物理熵）
    final point = _EntropyPoint(
      x: event.position.dx,
      y: event.position.dy,
      pressure: event.pressure,
      timestamp: DateTime.now().microsecondsSinceEpoch,
    );
    _points.add(point);
    _collectedCount++;

    // 添加视觉反馈点（火花粒子）
    _visualPoints.add(_VisualPathPoint(event.position));

    // 检查是否达到阈值
    if (_collectedCount >= widget.targetPoints && !_isFinished) {
      _finishCollection();
    }
  }

  void _finishCollection() {
    _isFinished = true;

    // 生成哈希熵
    final buffer = BytesBuilder();
    for (var p in _points) {
      // 将双精度转为字节流
      final data =
          Float64List.fromList([p.x, p.y, p.pressure, p.timestamp.toDouble()]);
      buffer.add(data.buffer.asUint8List());
    }

    // 异步执行回调，确保 UI 刷新后再通知
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onComplete(buffer.toBytes());
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_collectedCount / widget.targetPoints).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      children: [
        Expanded(
          child: Listener(
            onPointerMove: _handlePointerEvent,
            onPointerDown: _handlePointerEvent,
            child: CustomPaint(
              painter: _EntropyPainter(
                points: _visualPoints,
                color: primaryColor,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        // 进度条
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isFinished ? '混沌能量已注满' : '指尖滑动，注入物理随机性能量',
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntropyPoint {
  final double x, y, pressure;
  final int timestamp;
  _EntropyPoint({
    required this.x,
    required this.y,
    required this.pressure,
    required this.timestamp,
  });
}

class _VisualPathPoint {
  final Offset position;
  int age = 0;
  static const int maxAge = 25; // 线条淡出速度

  _VisualPathPoint(this.position);

  bool get isExpired => age >= maxAge;
  double get opacity => (1.0 - (age / maxAge)).clamp(0.0, 1.0);
}

class _EntropyPainter extends CustomPainter {
  final List<_VisualPathPoint> points;
  final Color color;

  _EntropyPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      paint.color = color.withValues(alpha: p.opacity * 0.6);

      // 绘制火花点（带轻微模糊效果）
      canvas.drawCircle(p.position, 2.0 * p.opacity, paint);

      // 如果有多点，连接成虚幻的线条
      if (i > 0) {
        final prev = points[i - 1];
        if ((p.position - prev.position).distance < 50) {
          paint.strokeWidth = 1.5 * p.opacity;
          canvas.drawLine(prev.position, p.position, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EntropyPainter oldDelegate) => true;
}
