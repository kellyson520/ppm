import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

      // Pass bytes so FilePicker handles writing on supported mobile platforms
      final bytes = utf8.encode(jsonStr);
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: l10n.exportBackup,
        fileName:
            'ztd_vault_export_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(bytes),
      );

      // On Desktop, if it just returns path and didn't write bytes, write manually.
      if (outputFile != null) {
        final file = File(outputFile);
        if (!file.existsSync() || file.lengthSync() == 0) {
          await file.writeAsBytes(bytes);
        }
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

    final content = CustomScrollView(
      slivers: [
        SliverAppBar.large(
          backgroundColor: Colors.transparent,
          expandedHeight: 140,
          collapsedHeight: 64,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: Text(
              l10n.settings,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            background: Container(color: Colors.transparent),
          ),
        ),

        // Vault Statistics
        if (_stats != null)
          SliverToBoxAdapter(
            child: _buildSection(
              title: l10n.vaultStatistics,
              children: [
                _buildStatTile(l10n.passwords, '${_stats!.cardCount}',
                    Icons.password_rounded),
                _buildDivider(),
                _buildStatTile(l10n.totalEvents, '${_stats!.eventCount}',
                    Icons.history_rounded),
                _buildDivider(),
                _buildStatTile(l10n.pendingSync, '${_stats!.pendingSyncCount}',
                    Icons.sync_rounded),
                _buildDivider(),
                _buildStatTile(l10n.snapshots, '${_stats!.snapshotCount}',
                    Icons.backup_rounded),
              ],
            ),
          ),

        // Security
        SliverToBoxAdapter(
          child: _buildSection(
            title: l10n.security,
            children: [
              _buildListTile(
                icon: Icons.lock_open_rounded,
                title: l10n.changeMasterPassword,
                subtitle: l10n.updateVaultPassword,
                onTap: _changePassword,
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.emergency_share_rounded,
                title: l10n.exportEmergencyKit,
                subtitle: l10n.exportEmergencyKitDesc.split('.')[0],
                onTap: _exportEmergencyKit,
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.fingerprint_rounded,
                title: l10n.biometricAuth,
                subtitle: l10n.useFaceTouchID,
                value: _isBiometricEnabled,
                onChanged: _toggleBiometrics,
              ),
            ],
          ),
        ),

        // Sync
        SliverToBoxAdapter(
          child: _buildSection(
            title: l10n.synchronization,
            children: [
              _buildListTile(
                icon: Icons.cloud_done_rounded,
                title: l10n.webdavNodes,
                subtitle: l10n.configureSyncDestinations,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WebDavSettingsScreen()),
                  );
                },
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.sync_rounded,
                title: l10n.manualSync,
                subtitle: l10n.syncNowWithNodes,
                onTap: () {
                  context.read<SyncBloc>().add(SyncStarted());
                  _showSuccess(l10n.syncStarted);
                },
              ),
            ],
          ),
        ),

        // Storage
        SliverToBoxAdapter(
          child: _buildSection(
            title: l10n.storage,
            children: [
              _buildListTile(
                icon: Icons.compress_rounded,
                title: l10n.compactStorage,
                subtitle: l10n.compressEventHistory,
                onTap: _compactStorage,
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.download_rounded,
                title: l10n.exportBackup,
                subtitle: l10n.createEncryptedBackup,
                onTap: _exportBackup,
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.upload_rounded,
                title: l10n.importBackup,
                subtitle: l10n.restoreFromBackup,
                onTap: _importBackup,
              ),
            ],
          ),
        ),

        // About
        SliverToBoxAdapter(
          child: _buildSection(
            title: l10n.about,
            children: [
              _buildInfoTile(Icons.info_outline_rounded, l10n.version, '1.0.0'),
              _buildDivider(),
              _buildListTile(
                icon: Icons.description_outlined,
                title: l10n.documentation,
                onTap: _showComingSoon,
                showArrow: true,
              ),
              _buildDivider(),
              _buildListTile(
                icon: Icons.code_rounded,
                title: l10n.sourceCode,
                onTap: _showComingSoon,
                showArrow: true,
              ),
            ],
          ),
        ),

        // Lock Action
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(24, 32, 24, 32 + 80), // 为 Dock 留白
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onLockRequested();
                if (!widget.isEmbedded) Navigator.pop(context);
              },
              icon: const Icon(Icons.lock_rounded, size: 20),
              label: Text(l10n.lockVaultFull),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.15),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) return content;

    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      body: content,
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 24, 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1,
        indent: 56,
        endIndent: 16,
        color: Colors.white.withValues(alpha: 0.05));
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.4)))
          : null,
      trailing: showArrow
          ? Icon(Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.2))
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF6C63FF),
        activeThumbColor: Colors.white,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 15, color: Colors.white)),
      trailing: Text(value,
          style: TextStyle(
              fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF00BFA6), size: 18),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 15, color: Colors.white)),
      trailing: Text(value,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}
