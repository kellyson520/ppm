import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../core/models/auth_card.dart';
import '../../core/crypto/totp_generator.dart';
import 'add_auth_screen.dart';
import '../../l10n/app_localizations.dart';

/// 验证器详情页
///
/// 展示解密后的 TOTP 详情，支持：
/// - 实时验证码显示
/// - 导出为文件 (otpauth:// URI)
/// - 导出为二维码
/// - 编辑 / 删除
class AuthDetailScreen extends StatefulWidget {
  final AuthService authService;
  final AuthCard card;
  final AuthPayload payload;
  final Uint8List? dek;
  final Uint8List? searchKey;
  final String? deviceId;

  const AuthDetailScreen({
    super.key,
    required this.authService,
    required this.card,
    required this.payload,
    this.dek,
    this.searchKey,
    this.deviceId,
  });

  @override
  State<AuthDetailScreen> createState() => _AuthDetailScreenState();
}

class _AuthDetailScreenState extends State<AuthDetailScreen> {
  Timer? _timer;
  String _currentCode = '';
  int _remaining = 30;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _updateCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCode();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCode() {
    setState(() {
      _currentCode = TOTPGenerator.generateCode(
        widget.payload.secret,
        algorithm: widget.payload.algorithm,
        digits: widget.payload.digits,
        period: widget.payload.period,
      );
      _remaining = TOTPGenerator.getRemainingSeconds(
        period: widget.payload.period,
      );
      _progress = TOTPGenerator.getProgress(
        period: widget.payload.period,
      );
    });
  }

  void _copyToClipboard(String text, String label) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ${l10n.copiedToClipboard}'),
        backgroundColor: const Color(0xFF00BFA6),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // 10 秒后清除敏感数据
    Future.delayed(const Duration(seconds: 10), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }

  /// 导出为文件 (otpauth:// URI)
  void _exportAsText() {
    final l10n = AppLocalizations.of(context)!;
    final uri = widget.payload.toOtpAuthUri();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exportURI),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.exportWarning,
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                uri,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _copyToClipboard(uri, 'URI');
              Navigator.pop(context);
            },
            icon: const Icon(Icons.copy, size: 16),
            label: Text(l10n.copy),
          ),
        ],
      ),
    );
  }

  /// 导出为二维码
  void _exportAsQrCode() {
    final l10n = AppLocalizations.of(context)!;
    final uri = widget.payload.toOtpAuthUri();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.qrCodeExport),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.qrWarning,
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // 简易二维码展示（使用文本图案模拟）
            // 实际生产中应使用 qr_flutter 套件
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 100, color: Colors.black87),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.payload.issuer,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '需集成 qr_flutter',
                      style: TextStyle(fontSize: 9, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.qrScanTip,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _copyToClipboard(uri, 'URI');
              Navigator.pop(context);
            },
            icon: const Icon(Icons.copy, size: 16),
            label: Text(l10n.copyURI),
          ),
        ],
      ),
    );
  }

  /// 编辑
  Future<void> _editEntry() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddAuthScreen(
          authService: widget.authService,
          dek: widget.dek,
          searchKey: widget.searchKey,
          deviceId: widget.deviceId,
          editCard: widget.card,
          editPayload: widget.payload,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  /// 删除
  Future<void> _deleteEntry() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAuthenticatorLabel),
        content: Text(
          '${l10n.deleteAuthenticatorConfirmPart1} "${widget.payload.issuer}" ${l10n.deleteAuthenticatorConfirmPart2}\n\n'
          '⚠️ ${l10n.deleteAuthenticatorWarning}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.8),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.authService.deleteCard(
        widget.card.cardId,
        widget.deviceId ?? 'default',
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.payload.issuer.isNotEmpty
            ? widget.payload.issuer
            : l10n.authenticatorDetails),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editEntry();
                  break;
                case 'export_text':
                  _exportAsText();
                  break;
                case 'export_qr':
                  _exportAsQrCode();
                  break;
                case 'delete':
                  _deleteEntry();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit, size: 20),
                  title: Text(l10n.edit),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'export_text',
                child: ListTile(
                  leading: const Icon(Icons.text_snippet, size: 20),
                  title: Text(l10n.exportAsFile),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'export_qr',
                child: ListTile(
                  leading: const Icon(Icons.qr_code, size: 20),
                  title: Text(l10n.exportAsQrCode),
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading:
                      const Icon(Icons.delete, color: Colors.red, size: 20),
                  title: Text(l10n.delete,
                      style: const TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ====== 验证码区域 ======
          Card(
            elevation: 4,
            color: const Color(0xFF1A2744),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF6C63FF), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 发行方图标 + 名称
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BFA6), Color(0xFF6C63FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.payload.issuer,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.payload.account.isNotEmpty)
                    Text(
                      widget.payload.account,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // 验证码
                  GestureDetector(
                    onTap: () => _copyToClipboard(_currentCode, l10n.code),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3460),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatCode(_currentCode),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 8,
                              fontFamily: 'monospace',
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.copy_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 倒计时
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 1.0 - _progress,
                              strokeWidth: 3,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _remaining <= 5
                                    ? Colors.red
                                    : _remaining <= 10
                                        ? Colors.orange
                                        : const Color(0xFF00BFA6),
                              ),
                            ),
                            Text(
                              '$_remaining',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    _remaining <= 5 ? Colors.red : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.refreshInSeconds,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ====== 详情信息 ======
          _buildSectionTitle(l10n.detailsLabel),
          Card(
            elevation: 0,
            color: const Color(0xFF16213E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                    l10n.issuer, widget.payload.issuer, Icons.business),
                _buildInfoTile(
                    l10n.account, widget.payload.account, Icons.person_outline),
                _buildInfoTile(
                    l10n.algorithm, widget.payload.algorithm, Icons.settings),
                _buildInfoTile(l10n.digits,
                    '${widget.payload.digits} ${l10n.digitSpan}', Icons.pin),
                _buildInfoTile(
                  l10n.refreshPeriod,
                  '${widget.payload.period} ${l10n.secondSpan}',
                  Icons.timer,
                ),
                if (widget.payload.notes != null &&
                    widget.payload.notes!.isNotEmpty)
                  _buildInfoTile(
                      l10n.notes, widget.payload.notes!, Icons.notes),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ====== 导出按钮 ======
          _buildSectionTitle(l10n.exportLabel),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.text_snippet_outlined,
                  label: l10n.exportText,
                  color: const Color(0xFF6C63FF),
                  onPressed: _exportAsText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code,
                  label: l10n.exportQrCodeButton,
                  color: const Color(0xFF00BFA6),
                  onPressed: _exportAsQrCode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ====== 危险操作 ======
          _buildSectionTitle(l10n.dangerZone),
          _buildActionButton(
            icon: Icons.delete_forever,
            label: l10n.deleteThisAuthenticator,
            color: Colors.red.withValues(alpha: 0.8),
            onPressed: _deleteEntry,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6C63FF),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
      title: Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.white60)),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _formatCode(String code) {
    if (code.length <= 3) return code;
    final mid = code.length ~/ 2;
    return '${code.substring(0, mid)} ${code.substring(mid)}';
  }
}
