import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/vault_service.dart';
import '../../core/models/models.dart';
import 'add_password_screen.dart';

class PasswordDetailScreen extends StatefulWidget {
  final VaultService vaultService;
  final PasswordCard card;

  const PasswordDetailScreen({
    super.key,
    required this.vaultService,
    required this.card,
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
        content: Text('$label copied to clipboard'),
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

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deletePassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password?'),
        content: const Text(
          'This will move the password to trash. You can restore it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_payload == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Failed to decrypt password'),
        ),
      );
    }

    final payload = _payload!;

    return Scaffold(
      appBar: AppBar(
        title: Text(payload.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editPassword,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deletePassword,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title card
          _buildInfoCard(
            icon: Icons.label_outline,
            label: 'Title',
            value: payload.title,
            onCopy: () => _copyToClipboard(payload.title, 'Title'),
          ),
          const SizedBox(height: 12),
          
          // Username card
          _buildInfoCard(
            icon: Icons.person_outline,
            label: 'Username',
            value: payload.username,
            onCopy: () => _copyToClipboard(payload.username, 'Username'),
          ),
          const SizedBox(height: 12),
          
          // Password card
          _buildPasswordCard(payload.password),
          const SizedBox(height: 12),
          
          // URL card (if present)
          if (payload.url != null && payload.url!.isNotEmpty) ...[
            _buildInfoCard(
              icon: Icons.link,
              label: 'Website',
              value: payload.url!,
              onCopy: () => _copyToClipboard(payload.url!, 'URL'),
              onLaunch: () {
                // TODO: Launch URL
              },
            ),
            const SizedBox(height: 12),
          ],
          
          // Notes card (if present)
          if (payload.notes != null && payload.notes!.isNotEmpty) ...[
            _buildInfoCard(
              icon: Icons.notes,
              label: 'Notes',
              value: payload.notes!,
              multiline: true,
            ),
            const SizedBox(height: 12),
          ],
          
          // Metadata
          const SizedBox(height: 24),
          _buildMetadataSection(),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
    VoidCallback? onLaunch,
    bool multiline = false,
  }) {
    return Card(
      elevation: 0,
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.white60),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: multiline ? 14 : 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (onCopy != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: onCopy,
                    tooltip: 'Copy',
                  ),
                if (onLaunch != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: onLaunch,
                    tooltip: 'Open',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(String password) {
    return Card(
      elevation: 0,
      color: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 18, color: Colors.white60),
                const SizedBox(width: 8),
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
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
                  ),
                  label: Text(_showPassword ? 'Hide' : 'Show'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3460),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _showPassword ? password : '•' * password.length,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(password, 'Password'),
                  tooltip: 'Copy Password',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metadata',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetadataRow(
            'Created',
            _formatDateTime(widget.card.createdAt.physicalTime),
          ),
          const SizedBox(height: 8),
          _buildMetadataRow(
            'Last Updated',
            _formatDateTime(widget.card.updatedAt.physicalTime),
          ),
          const SizedBox(height: 8),
          _buildMetadataRow(
            'Device ID',
            widget.card.updatedAt.deviceId.substring(0, 8),
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
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
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
