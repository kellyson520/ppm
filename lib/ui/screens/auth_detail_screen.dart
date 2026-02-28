import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../core/models/auth_card.dart';
import '../../core/crypto/totp_generator.dart';
import 'add_auth_screen.dart';
import '../../l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  final bool isEmbedded;

  const AuthDetailScreen({
    super.key,
    required this.authService,
    required this.card,
    required this.payload,
    this.dek,
    this.searchKey,
    this.deviceId,
    this.isEmbedded = false,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: uri,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101018).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // 拖动手柄
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              // 自定义头部
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.payload.issuer.isNotEmpty
                            ? widget.payload.issuer
                            : l10n.authenticatorDetails,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz,
                          color: Colors.white.withValues(alpha: 0.6)),
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
                            leading: const Icon(Icons.delete,
                                color: Colors.red, size: 20),
                            title: Text(l10n.delete,
                                style: const TextStyle(color: Colors.red)),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.5)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    // ====== 验证码展示卡片 ======
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          // 验证码
                          GestureDetector(
                            onTap: () =>
                                _copyToClipboard(_currentCode, l10n.code),
                            child: Column(
                              children: [
                                Text(
                                  _formatCode(_currentCode),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4,
                                    fontFamily: 'monospace',
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 14,
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '点击复制',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Colors.white.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 进度条
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: 1.0 - _progress,
                                    minHeight: 6,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _remaining <= 5
                                          ? Colors.red.withValues(alpha: 0.8)
                                          : _remaining <= 10
                                              ? Colors.orange
                                                  .withValues(alpha: 0.8)
                                              : const Color(0xFF00BFA6),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${_remaining}s',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _remaining <= 5
                                      ? Colors.red
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ====== 详情信息 ======
                    _buildSectionTitle(l10n.detailsLabel),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildInfoTile(l10n.issuer, widget.payload.issuer,
                              Icons.business),
                          _buildDivider(),
                          _buildInfoTile(l10n.account, widget.payload.account,
                              Icons.person_outline),
                          _buildDivider(),
                          _buildInfoTile(l10n.algorithm,
                              widget.payload.algorithm, Icons.settings),
                          _buildDivider(),
                          _buildInfoTile(
                              l10n.digits,
                              '${widget.payload.digits} ${l10n.digitSpan}',
                              Icons.pin_outlined),
                          _buildDivider(),
                          _buildInfoTile(
                            l10n.refreshPeriod,
                            '${widget.payload.period} ${l10n.secondSpan}',
                            Icons.timer_outlined,
                          ),
                          if (widget.payload.notes != null &&
                              widget.payload.notes!.isNotEmpty) ...[
                            _buildDivider(),
                            _buildInfoTile(l10n.notes, widget.payload.notes!,
                                Icons.notes_rounded),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ====== 操作按钮 ======
                    _buildSectionTitle(l10n.exportLabel),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.link_rounded,
                            label: l10n.exportText,
                            color: Colors.white.withValues(alpha: 0.1),
                            onPressed: _exportAsText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.qr_code_rounded,
                            label: l10n.exportQrCodeButton,
                            color: Colors.white.withValues(alpha: 0.1),
                            onPressed: _exportAsQrCode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: l10n.deleteThisAuthenticator,
                      color: Colors.red.withValues(alpha: 0.15),
                      textColor: Colors.redAccent,
                      onPressed: _deleteEntry,
                    ),
                    SizedBox(height: bottomPadding + 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 20,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
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
    Color textColor = Colors.white,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
