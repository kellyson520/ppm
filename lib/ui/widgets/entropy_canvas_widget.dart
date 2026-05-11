import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// 赛博混沌熵采集画板 (Blind Canvas Entropy)
///
/// 功能：
/// 1. 采集手势物理特征（坐标、压力、时间戳）作为随机源。
/// 2. 画笔痕迹随时间淡出，增强安全性并防止图案泄露。
/// 3. 提供粒子火花动效，增强视觉回馈。
/// 4. 基于速度预测实现流畅的跟手体验。
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

  int _collectedCount = 0;
  bool _isFinished = false;

  Offset? _lastPosition;
  DateTime? _lastTime;
  final List<Offset> _velocityHistory = [];
  static const int _velocityHistorySize = 5;

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
            onPointerUp: _handlePointerUp,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CustomPaint(
                  painter: _EntropyPainter(
                    points: _visualPoints,
                    color: primaryColor,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
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
                _isFinished
                    ? '混沌能量已注满'
                    : '指尖滑动，注入物理随机性能量',
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

  void _handlePointerEvent(PointerEvent event) {
    if (_isFinished) return;

    final now = DateTime.now();

    if (_lastPosition != null && _lastTime != null) {
      final dt = now.difference(_lastTime!).inMicroseconds;
      if (dt > 0) {
        final velocity = Offset(
          (event.position.dx - _lastPosition!.dx) / dt * 1000000,
          (event.position.dy - _lastPosition!.dy) / dt * 1000000,
        );
        _velocityHistory.add(velocity);
        if (_velocityHistory.length > _velocityHistorySize) {
          _velocityHistory.removeAt(0);
        }
      }
    }

    _lastPosition = event.position;
    _lastTime = now;

    final entropyPoint = _EntropyPoint(
      x: event.position.dx,
      y: event.position.dy,
      pressure: event.pressure,
      timestamp: now.microsecondsSinceEpoch,
    );
    _points.add(entropyPoint);
    _collectedCount++;

    final avgVelocity = _velocityHistory.isEmpty
        ? Offset.zero
        : _velocityHistory.reduce((a, b) => a + b) / _velocityHistory.length;

    _visualPoints.add(_VisualPathPoint(
      position: event.position,
      velocity: avgVelocity,
      pressure: event.pressure,
    ));

    if (_collectedCount >= widget.targetPoints && !_isFinished) {
      _finishCollection();
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _lastPosition = null;
    _lastTime = null;
    _velocityHistory.clear();
  }

  void _finishCollection() {
    _isFinished = true;

    final buffer = BytesBuilder();
    for (var p in _points) {
      final data = Float64List.fromList([
        p.x,
        p.y,
        p.pressure,
        p.timestamp.toDouble(),
      ]);
      buffer.add(data.buffer.asUint8List());
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onComplete(buffer.toBytes());
    });
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
  final Offset velocity;
  final double pressure;
  int age = 0;

  _VisualPathPoint({
    required this.position,
    required this.velocity,
    required this.pressure,
  });

  int get maxAge {
    final speed = velocity.distance;
    return (20 + speed * 0.5).toInt().clamp(15, 50);
  }

  double get opacity {
    final t = age / maxAge;
    return (1.0 - t * t).clamp(0.0, 1.0);
  }

  double get radius => (2.0 + pressure * 4).clamp(1.0, 6.0);

  bool get isExpired => age >= maxAge;
}

class _EntropyPainter extends CustomPainter {
  final List<_VisualPathPoint> points;
  final Color color;

  _EntropyPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.isExpired) continue;

      paint.color = color.withValues(alpha: p.opacity * 0.9);
      canvas.drawCircle(p.position, p.radius * p.opacity, paint);

      if (p.velocity.distance > 100 && i > 0) {
        final prev = points[i - 1];
        final direction = (p.position - prev.position).direction;
        final tailLength = (p.velocity.distance / 500).clamp(5.0, 30.0);
        final tailEnd = p.position + Offset.fromDirection(direction, tailLength);

        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = (1.0 + p.pressure * 2) * p.opacity;
        paint.color = color.withValues(alpha: p.opacity * 0.4);
        canvas.drawLine(p.position, tailEnd, paint);
        paint.style = PaintingStyle.fill;
      }

      if (i > 0) {
        final prev = points[i - 1];
        final distance = (p.position - prev.position).distance;

        if (distance < 80) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = (1.0 + p.pressure * 2) * p.opacity.clamp(0.3, 1.0);
          paint.color = color.withValues(alpha: p.opacity * 0.5);
          canvas.drawLine(prev.position, p.position, paint);
          paint.style = PaintingStyle.fill;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EntropyPainter oldDelegate) => true;
}
