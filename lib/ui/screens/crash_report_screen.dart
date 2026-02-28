import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/diagnostics/crash_report_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

/// 崩溃报告界面
///
/// 当应用抛出未被捕获的异常时，由 [CrashReportService] 触发导航到此界面。
class CrashReportScreen extends StatelessWidget {
  final CrashInfo crashInfo;

  const CrashReportScreen({
    super.key,
    required this.crashInfo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 24),
              _buildInfoCard(l10n),
              const SizedBox(height: 16),
              Expanded(child: _buildStackTrace(l10n)),
              const SizedBox(height: 20),
              _buildActions(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appCrashed,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.crashReport,
              style: const TextStyle(
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

  Widget _buildInfoCard(AppLocalizations l10n) {
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
          Text(
            l10n.errorInfo,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8888AA),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
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

  Widget _buildStackTrace(AppLocalizations l10n) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.list_alt_outlined,
                    size: 15, color: Color(0xFF8888AA)),
                const SizedBox(width: 6),
                Text(
                  l10n.stackTrace,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8888AA),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: SelectableText(
                crashInfo.stackTrace.isNotEmpty
                    ? crashInfo.stackTrace
                    : l10n.noStackTrace,
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

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            id: 'crash_copy_button',
            icon: Icons.copy_outlined,
            label: l10n.copyReport,
            color: const Color(0xFF6C63FF),
            onPressed: () => _copyReport(context, l10n),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            id: 'crash_restart_button',
            icon: Icons.refresh_rounded,
            label: l10n.restartApp,
            color: const Color(0xFFFF4C5B),
            onPressed: _restartApp,
          ),
        ),
      ],
    );
  }

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

  Future<void> _copyReport(BuildContext context, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: crashInfo.toPlainText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(l10n.reportCopied),
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

  void _restartApp() {
    runApp(const ZTDPasswordManagerApp());
  }
}

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
