import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR 码扫描页面
///
/// 全屏相机扫描界面，用于扫描 2FA 设置二维码：
/// - 自动识别 otpauth:// URI
/// - 支持手电筒开关
/// - 支持前后摄像头切换
/// - 扫描成功后自动返回 URI 字符串
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasScanned = false; // 防止重复扫描
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    // 扫描线动画
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  /// 处理扫描结果
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;

      // 检查是否为 otpauth:// URI
      if (rawValue.startsWith('otpauth://')) {
        _hasScanned = true;
        HapticFeedback.heavyImpact();

        // 短暂延迟后返回结果，让用户看到成功动画
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.pop(context, rawValue);
          }
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 相机预览
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),

          // 扫描框遮罩
          _buildScanOverlay(),

          // 顶部操作栏
          _buildTopBar(),

          // 底部控制栏
          _buildBottomControls(),

          // 成功状态覆盖层
          if (_hasScanned) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  /// 构建扫描框遮罩
  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - scanAreaSize) / 2;
        final top = (constraints.maxHeight - scanAreaSize) / 2 - 40;

        return Stack(
          children: [
            // 半透明遮罩
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.red, // 任意颜色，会被 srcOut 裁剪
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 扫描框四角装饰
            Positioned(
              left: left,
              top: top,
              child: _buildCornerDecoration(scanAreaSize),
            ),

            // 扫描线动画
            Positioned(
              left: left + 16,
              top: top,
              child: _ScanLineWidget(
                animation: _scanLineAnimation,
                scanAreaSize: scanAreaSize,
              ),
            ),

            // 提示文字
            Positioned(
              left: 0,
              right: 0,
              top: top + scanAreaSize + 24,
              child: const Text(
                '将 2FA 设置二维码放入框内',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: top + scanAreaSize + 52,
              child: const Text(
                '自动识别 otpauth:// 二维码',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 扫描框四角装饰
  Widget _buildCornerDecoration(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: const Color(0xFF00BFA6),
          cornerLength: 24,
          strokeWidth: 3,
          radius: 20,
        ),
      ),
    );
  }

  /// 顶部操作栏
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // 返回按钮
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                shape: const CircleBorder(),
              ),
            ),
            const Expanded(
              child: Text(
                '扫描二维码',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 占位，保持标题居中
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  /// 底部控制栏
  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 手电筒
              ValueListenableBuilder(
                valueListenable: _cameraController,
                builder: (context, state, child) {
                  final torchOn = state.torchState == TorchState.on;
                  return _buildControlButton(
                    icon: torchOn ? Icons.flash_on : Icons.flash_off,
                    label: torchOn ? '关闭照明' : '开启照明',
                    isActive: torchOn,
                    onTap: () => _cameraController.toggleTorch(),
                  );
                },
              ),
              // 切换摄像头
              _buildControlButton(
                icon: Icons.cameraswitch_outlined,
                label: '切换摄像头',
                isActive: false,
                onTap: () => _cameraController.switchCamera(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF00BFA6).withOpacity(0.3)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? const Color(0xFF00BFA6) : Colors.white30,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF00BFA6) : Colors.white70,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF00BFA6) : Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// 扫描成功覆盖层
  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA6).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF00BFA6),
                size: 56,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '扫描成功',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 扫描线动画组件
class _ScanLineWidget extends AnimatedWidget {
  final double scanAreaSize;

  const _ScanLineWidget({
    required Animation<double> animation,
    required this.scanAreaSize,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Transform.translate(
      offset: Offset(0, animation.value * (scanAreaSize - 4)),
      child: Container(
        width: scanAreaSize - 32,
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF00BFA6).withValues(alpha: 0.8),
              const Color(0xFF6C63FF),
              const Color(0xFF00BFA6).withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BFA6).withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// 四角装饰画笔
class _CornerPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double radius;

  _CornerPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = radius;
    final cl = cornerLength;

    // 左上角
    canvas.drawPath(
      Path()
        ..moveTo(0, cl)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(cl, 0),
      paint,
    );

    // 右上角
    canvas.drawPath(
      Path()
        ..moveTo(w - cl, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, cl),
      paint,
    );

    // 左下角
    canvas.drawPath(
      Path()
        ..moveTo(0, h - cl)
        ..lineTo(0, h - r)
        ..quadraticBezierTo(0, h, r, h)
        ..lineTo(cl, h),
      paint,
    );

    // 右下角
    canvas.drawPath(
      Path()
        ..moveTo(w - cl, h)
        ..lineTo(w - r, h)
        ..quadraticBezierTo(w, h, w, h - r)
        ..lineTo(w, h - cl),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
