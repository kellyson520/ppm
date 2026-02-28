import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/vault_service.dart';
import '../../l10n/app_localizations.dart';
import '../../blocs/sync/sync_bloc.dart';
import 'webdav_settings_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';

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
  bool _isBiometricEnabled = false;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final enabled = await widget.vaultService.isBiometricEnabled();
    setState(() {
      _isBiometricEnabled = enabled;
    });
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
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeMasterPassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.currentPassword,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.confirmNewPassword,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.change),
          ),
        ],
      ),
    );

    if (result == true) {
      if (newPasswordController.text != confirmController.text) {
        _showError(l10n.passwordsDoNotMatch);
        return;
      }

      final success = await widget.vaultService.changeMasterPassword(
        oldPasswordController.text,
        newPasswordController.text,
      );

      if (success) {
        _showSuccess(l10n.passwordChanged);
      } else {
        _showError(l10n.failedToChangePassword);
      }
    }
  }

  Future<void> _toggleBiometrics(bool enable) async {
    final l10n = AppLocalizations.of(context)!;

    if (enable) {
      final passwordController = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.biometricAuth),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.masterPassword,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty) {
        bool authenticated = false;
        try {
          authenticated = await _localAuth.authenticate(
            localizedReason: 'Enable biometric authentication',
          );
        } on Exception catch (e) {
          _showError('Biometric error: $e');
        }

        if (authenticated) {
          await widget.vaultService.enableBiometricMode(result);
          setState(() {
            _isBiometricEnabled = true;
          });
          _showSuccess('Biometrics enabled');
        }
      }
    } else {
      await widget.vaultService.disableBiometricMode();
      setState(() {
        _isBiometricEnabled = false;
      });
      _showSuccess('Biometrics disabled');
    }
  }

  Future<void> _exportEmergencyKit() async {
    final passwordController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exportEmergencyKit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.exportEmergencyKitDesc,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.masterPassword,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.export),
          ),
        ],
      ),
    );

    if (result == true) {
      final kit = await widget.vaultService.exportEmergencyKit(
        passwordController.text,
      );

      if (kit != null) {
        _showSuccess(l10n.emergencyKitExported);
      } else {
        _showError(l10n.failedToExportEmergencyKit);
      }
    }
  }

  Future<void> _compactStorage() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.compactStorageQuestion),
        content: Text(l10n.compactStorageDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.compact),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.vaultService.createSnapshot();
      await _loadStats();

      _showSuccess(l10n.storageCompacted);
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

  void _showComingSoon() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.comingSoon),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportBackup() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final jsonStr = await widget.vaultService.exportVaultAsJson();
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/ztd_vault_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: l10n.exportBackup,
      );

      if (result.status == ShareResultStatus.success) {
        _showSuccess(l10n.backupExported);
      }
    } on Exception catch (e) {
      _showError('${l10n.exportFailed}: $e');
    }
  }

  Future<void> _importBackup() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();

        final count = await widget.vaultService.importVaultFromJson(jsonStr);
        if (count > 0) {
          _showSuccess(l10n.backupImported(count));
          await _loadStats();
        } else {
          _showError(l10n.importFailed);
        }
      }
    } on Exception catch (e) {
      _showError('${l10n.importFailed}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = ListView(
      children: [
        // Vault Statistics
        if (_stats != null)
          _buildSection(
            title: l10n.vaultStatistics,
            children: [
              _buildStatTile(
                l10n.passwords,
                '${_stats!.cardCount}',
                Icons.password,
              ),
              _buildStatTile(
                l10n.totalEvents,
                '${_stats!.eventCount}',
                Icons.history,
              ),
              _buildStatTile(
                l10n.pendingSync,
                '${_stats!.pendingSyncCount}',
                Icons.sync,
              ),
              _buildStatTile(
                l10n.snapshots,
                '${_stats!.snapshotCount}',
                Icons.backup,
              ),
            ],
          ),

        // Security
        _buildSection(
          title: l10n.security,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.changeMasterPassword),
              subtitle: Text(l10n.updateVaultPassword),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
            ListTile(
              leading: const Icon(Icons.emergency_outlined),
              title: Text(l10n.exportEmergencyKit),
              subtitle: Text(l10n.exportEmergencyKitDesc.split('.')[0]),
              trailing: const Icon(Icons.chevron_right),
              onTap: _exportEmergencyKit,
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: Text(l10n.biometricAuth),
              subtitle: Text(l10n.useFaceTouchID),
              trailing: Switch(
                value: _isBiometricEnabled,
                onChanged: _toggleBiometrics,
              ),
              onTap: () => _toggleBiometrics(!_isBiometricEnabled),
            ),
          ],
        ),

        // Sync
        _buildSection(
          title: l10n.synchronization,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_sync_outlined),
              title: Text(l10n.webdavNodes),
              subtitle: Text(l10n.configureSyncDestinations),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WebDavSettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(l10n.manualSync),
              subtitle: Text(l10n.syncNowWithNodes),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.read<SyncBloc>().add(SyncStarted());
                _showSuccess(l10n.syncStarted);
              },
            ),
          ],
        ),

        // Storage
        _buildSection(
          title: l10n.storage,
          children: [
            ListTile(
              leading: const Icon(Icons.compress),
              title: Text(l10n.compactStorage),
              subtitle: Text(l10n.compressEventHistory),
              trailing: const Icon(Icons.chevron_right),
              onTap: _compactStorage,
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(l10n.exportBackup),
              subtitle: Text(l10n.createEncryptedBackup),
              trailing: const Icon(Icons.chevron_right),
              onTap: _exportBackup,
            ),
            ListTile(
              leading: const Icon(Icons.upload_outlined),
              title: Text(l10n.importBackup),
              subtitle: Text(l10n.restoreFromBackup),
              trailing: const Icon(Icons.chevron_right),
              onTap: _importBackup,
            ),
          ],
        ),

        // About
        _buildSection(
          title: l10n.about,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.version),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.documentation),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: _showComingSoon,
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text(l10n.sourceCode),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: _showComingSoon,
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
              if (!widget.isEmbedded) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.lock),
            label: Text(l10n.lockVaultFull),
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
        title: Text(l10n.settings),
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
