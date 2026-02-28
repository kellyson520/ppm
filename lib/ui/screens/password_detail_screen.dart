import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/vault_service.dart';
import '../../core/models/models.dart';
import 'add_password_screen.dart';
import '../../l10n/app_localizations.dart';

class PasswordDetailScreen extends StatefulWidget {
  final VaultService vaultService;
  final PasswordCard card;
  final bool isEmbedded;

  const PasswordDetailScreen({
    super.key,
    required this.vaultService,
    required this.card,
    this.isEmbedded = false,
  });

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  PasswordPayload? _payload;
  bool _isLoading = true;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final payload = await widget.vaultService.decryptCard(widget.card);
    setState(() {
      _payload = payload;
      _isLoading = false;
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('$label ${AppLocalizations.of(context)!.copiedToClipboard}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editPassword() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddPasswordScreen(
          vaultService: widget.vaultService,
          editCard: widget.card,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deletePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePasswordQuestion),
        content: Text(l10n.deletePasswordDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.vaultService.deleteCard(widget.card.cardId);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Material(
        color: Colors.transparent,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_payload == null) {
      return Material(
        color: Colors.transparent,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(l10n.failedToDecryptPassword,
                style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
    }

    final payload = _payload!;

    // Apple 风格的面包屑模态底板结构
    final content = Container(
      decoration: BoxDecoration(
          color: const Color(0xFF16213E)
              .withValues(alpha: 0.95), // 强制极黑且微量透明以支撑背后模糊
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
              top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ))),
      child: Column(
        children: [
          // 悬浮在顶部的拖拽胶囊指示器 (Drag Handle)
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          // 定制的无界限标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    payload.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: _editPassword,
                      tooltip: l10n.edit,
                      color: Colors.white,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _deletePassword,
                      tooltip: l10n.delete,
                      color: Colors.redAccent,
                    ),
                    if (!widget.isEmbedded) // 给模态框加一个关闭按钮
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        color: Colors.white54,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                // Title card
                _buildInfoCard(
                  context: context,
                  label: 'ACCOUNT', // 使用大写的英文字体做 HIG 副标题隔离
                  value: payload.username,
                  onCopy: () =>
                      _copyToClipboard(payload.username, l10n.usernameLabel),
                ),
                const SizedBox(height: 24),

                // Password card
                _buildPasswordCard(payload.password, l10n),
                const SizedBox(height: 24),

                // URL card (if present)
                if (payload.url != null && payload.url!.isNotEmpty) ...[
                  _buildInfoCard(
                    context: context,
                    label: 'WEBSITE',
                    value: payload.url!,
                    onCopy: () => _copyToClipboard(payload.url!, l10n.website),
                    onLaunch: () async {
                      final uri = Uri.tryParse(payload.url!);
                      if (uri != null) {
                        try {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } on Exception catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${l10n.error}: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Notes card (if present)
                if (payload.notes != null && payload.notes!.isNotEmpty) ...[
                  _buildInfoCard(
                    context: context,
                    label: 'NOTES',
                    value: payload.notes!,
                    multiline: true,
                  ),
                  const SizedBox(height: 24),
                ],

                // Metadata
                _buildMetadataSection(l10n),
                const SizedBox(height: 64), // Safe bottom area
              ],
            ),
          ),
        ],
      ),
    );

    // 如果是被横屏嵌入的，直接显示内容；否则包裹成透明底准备做弹窗
    if (widget.isEmbedded) {
      return content;
    }

    // Scaffold 的背景设置成完全透明，依赖外部调用的 showModalBottomSheet
    // 如果不是从 bottom sheet 拉起，作为普通 push 时也是透明底悬空
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9, // 占屏 90%
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    IconData? icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
    VoidCallback? onLaunch,
    bool multiline = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      color: Colors.transparent, // iOS 扁平无色底
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white60),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600, // Apple style secondary bold
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                          alpha: 0.05), // Input field like flat area
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: multiline ? 15 : 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (onCopy != null)
                  IconButton(
                    icon: Icon(Icons.copy,
                        size: 20, color: Colors.white.withValues(alpha: 0.5)),
                    onPressed: onCopy,
                    tooltip: l10n.copy,
                  ),
                if (onLaunch != null)
                  IconButton(
                    icon: Icon(Icons.open_in_new,
                        size: 20, color: Colors.white.withValues(alpha: 0.5)),
                    onPressed: onLaunch,
                    tooltip: l10n.open,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(String password, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'PASSWORD', // 纯大写隔离
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  label: Text(
                    _showPassword ? l10n.hide : l10n.show,
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _showPassword
                          ? password
                          : '•' * (password.length > 20 ? 20 : password.length),
                      style: TextStyle(
                        fontSize: _showPassword ? 17 : 24, // 掩码状态大一点
                        fontFamily: 'monospace',
                        color: Colors.white,
                        letterSpacing: _showPassword ? 1 : 4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy,
                      size: 20, color: Colors.white.withValues(alpha: 0.5)),
                  onPressed: () =>
                      _copyToClipboard(password, l10n.passwordLabel),
                  tooltip: l10n.copyPassword,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // 对齐上方内容
      decoration: BoxDecoration(
        color: Colors.transparent, // 抛弃背景色
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.metadata.toUpperCase(), // 大写作为分类符
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow(
            l10n.created,
            _formatDateTime(widget.card.createdAt.physicalTime),
          ),
          const SizedBox(height: 8),
          _buildMetadataRow(
            l10n.lastUpdated,
            _formatDateTime(widget.card.updatedAt.physicalTime),
          ),
          const SizedBox(height: 8),
          _buildMetadataRow(
            l10n.deviceID,
            widget.card.updatedAt.deviceId.substring(
                0,
                widget.card.updatedAt.deviceId.length > 8
                    ? 8
                    : widget.card.updatedAt.deviceId.length),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
