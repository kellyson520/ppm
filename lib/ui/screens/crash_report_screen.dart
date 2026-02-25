import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/diagnostics/crash_report_service.dart';

/// 崩溃报告界面
///
/// 当应用抛出未被捕获的异常时，由 [CrashReportService] 触发导航到此界面。
/// 提供：
/// - 错误摘要与调用堆栈展示
/// - 「复制报告」按钮（写入系统剪贴板）
/// - 「关闭应用」按钮（退出进程）
class CrashReportScreen extends StatelessWidget {
  final CrashInfo crashInfo;

  const CrashReportScreen({
    super.key,
    required this.crashInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 标题区 ───────────────────────────────────────────────
              _buildHeader(),
              const SizedBox(height: 24),

              // ─── 基本信息卡片 ─────────────────────────────────────────
              _buildInfoCard(),
              const SizedBox(height: 16),

              // ─── 堆栈可滚动区域 ───────────────────────────────────────
              Expanded(child: _buildStackTrace()),
              const SizedBox(height: 20),

              // ─── 操作按钮区 ──────────────────────────────────────────
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 子组件构建方法
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4C5B).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.bug_report_outlined,
            color: Color(0xFFFF4C5B),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '应用崩溃',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Crash Report',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFFF4C5B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF4C5B).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间 + 来源
          Row(
            children: [
              _infoChip(
                icon: Icons.schedule_outlined,
                label: crashInfo.timestamp,
                color: const Color(0xFF6C63FF),
              ),
              const SizedBox(width: 8),
              _infoChip(
                icon: Icons.layers_outlined,
                label: crashInfo.source,
                color: const Color(0xFFFF9F43),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 错误标签
          const Text(
            '错误信息',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF8888AA),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          // 错误内容（最多显示前 3 行）
          Text(
            _truncate(crashInfo.errorMessage, 200),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFFFD6D9),
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackTrace() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 堆栈标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Icon(Icons.list_alt_outlined,
                    size: 15, color: Color(0xFF8888AA)),
                SizedBox(width: 6),
                Text(
                  'Stack Trace',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8888AA),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          // 可滚动堆栈区
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: SelectableText(
                crashInfo.stackTrace.isNotEmpty
                    ? crashInfo.stackTrace
                    : '（无堆栈信息）',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9999BB),
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        // 「复制报告」
        Expanded(
          child: _ActionButton(
            id: 'crash_copy_button',
            icon: Icons.copy_outlined,
            label: '复制报告',
            color: const Color(0xFF6C63FF),
            onPressed: () => _copyReport(context),
          ),
        ),
        const SizedBox(width: 12),
        // 「关闭应用」
        Expanded(
          child: _ActionButton(
            id: 'crash_close_button',
            icon: Icons.close_rounded,
            label: '关闭应用',
            color: const Color(0xFFFF4C5B),
            onPressed: _closeApp,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 辅助方法
  // ──────────────────────────────────────────────────────────────────────────

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }

  /// 将完整报告写入剪贴板并显示提示
  Future<void> _copyReport(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: crashInfo.toPlainText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('崩溃报告已复制到剪贴板'),
            ],
          ),
          backgroundColor: const Color(0xFF6C63FF),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 退出应用
  void _closeApp() {
    SystemNavigator.pop();
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 操作按钮组件
// ────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key(id),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
