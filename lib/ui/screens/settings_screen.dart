import 'package:flutter/material.dart';
import '../../services/vault_service.dart';

class SettingsScreen extends StatefulWidget {
  final VaultService vaultService;
  final VoidCallback onLockRequested;
  final bool isEmbedded;

  const SettingsScreen({
    super.key,
    required this.vaultService,
    required this.onLockRequested,
    this.isEmbedded = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  VaultStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await widget.vaultService.getStats();
    setState(() {
      _stats = stats;
    });
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Master Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (newPasswordController.text != confirmController.text) {
        _showError('New passwords do not match');
        return;
      }

      final success = await widget.vaultService.changeMasterPassword(
        oldPasswordController.text,
        newPasswordController.text,
      );

      if (success) {
        _showSuccess('Password changed successfully');
      } else {
        _showError('Failed to change password');
      }
    }
  }

  Future<void> _exportEmergencyKit() async {
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Emergency Kit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will export your encryption keys for emergency recovery. '
              'Store this securely!',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Master Password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (result == true) {
      final kit = await widget.vaultService.exportEmergencyKit(
        passwordController.text,
      );

      if (kit != null) {
        // TODO: Save or share the emergency kit
        _showSuccess('Emergency kit exported');
      } else {
        _showError('Failed to export emergency kit');
      }
    }
  }

  Future<void> _compactStorage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compact Storage?'),
        content: const Text(
          'This will compress your event history and create a snapshot. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Compact'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.vaultService.createSnapshot();
      await _loadStats();

      _showSuccess('Storage compacted successfully');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
        children: [
          // Vault Statistics
          if (_stats != null)
            _buildSection(
              title: 'Vault Statistics',
              children: [
                _buildStatTile(
                  'Passwords',
                  '${_stats!.cardCount}',
                  Icons.password,
                ),
                _buildStatTile(
                  'Total Events',
                  '${_stats!.eventCount}',
                  Icons.history,
                ),
                _buildStatTile(
                  'Pending Sync',
                  '${_stats!.pendingSyncCount}',
                  Icons.sync,
                ),
                _buildStatTile(
                  'Snapshots',
                  '${_stats!.snapshotCount}',
                  Icons.backup,
                ),
              ],
            ),

          // Security
          _buildSection(
            title: 'Security',
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Master Password'),
                subtitle: const Text('Update your vault password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePassword,
              ),
              ListTile(
                leading: const Icon(Icons.emergency_outlined),
                title: const Text('Export Emergency Kit'),
                subtitle: const Text('Backup your encryption keys'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportEmergencyKit,
              ),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Biometric Authentication'),
                subtitle: const Text('Use Face ID / Touch ID'),
                trailing: Switch(
                  value: false, // TODO: Implement
                  onChanged: (value) {
                    // TODO: Implement
                  },
                ),
              ),
            ],
          ),

          // Sync
          _buildSection(
            title: 'Synchronization',
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_sync_outlined),
                title: const Text('WebDAV Nodes'),
                subtitle: const Text('Configure sync destinations'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to WebDAV settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Manual Sync'),
                subtitle: const Text('Sync now with all nodes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Trigger sync
                  _showSuccess('Sync started');
                },
              ),
            ],
          ),

          // Storage
          _buildSection(
            title: 'Storage',
            children: [
              ListTile(
                leading: const Icon(Icons.compress),
                title: const Text('Compact Storage'),
                subtitle: const Text('Compress event history'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _compactStorage,
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Export Backup'),
                subtitle: const Text('Create encrypted backup file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Export backup
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: const Text('Import Backup'),
                subtitle: const Text('Restore from backup file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Import backup
                },
              ),
            ],
          ),

          // About
          _buildSection(
            title: 'About',
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Documentation'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  // TODO: Open documentation
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Source Code'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  // TODO: Open GitHub
                },
              ),
            ],
          ),

          // Lock Vault
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onLockRequested();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.lock),
              label: const Text('Lock Vault'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: body,
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C63FF),
              letterSpacing: 1,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: const Color(0xFF16213E),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6C63FF)),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
