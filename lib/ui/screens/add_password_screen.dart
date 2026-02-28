import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/diagnostics/crash_report_service.dart';
import '../../services/vault_service.dart';
import '../../core/models/models.dart';
import '../../l10n/app_localizations.dart';

class AddPasswordScreen extends StatefulWidget {
  final VaultService vaultService;
  final PasswordCard? editCard;

  const AddPasswordScreen({
    super.key,
    required this.vaultService,
    this.editCard,
  });

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  double _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    if (widget.editCard != null) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    final payload = await widget.vaultService.decryptCard(widget.editCard!);
    if (payload != null) {
      setState(() {
        _titleController.text = payload.title;
        _usernameController.text = payload.username;
        _passwordController.text = payload.password;
        _urlController.text = payload.url ?? '';
        _notesController.text = payload.notes ?? '';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculatePasswordStrength(String password) {
    double strength = 0;

    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.15;

    setState(() {
      _passwordStrength = strength.clamp(0, 1);
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength < 0.4) return Colors.red;
    if (_passwordStrength < 0.7) return Colors.orange;
    return Colors.green;
  }

  void _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final randomValue = DateTime.now().millisecondsSinceEpoch;
    final password = List.generate(16, (index) {
      return chars[(randomValue + index * 17) % chars.length];
    }).join();

    setState(() {
      _passwordController.text = password;
      _calculatePasswordStrength(password);
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final payload = PasswordPayload(
        title: _titleController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        url: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (widget.editCard != null) {
        await widget.vaultService.updateCard(widget.editCard!.cardId, payload);
      } else {
        await widget.vaultService.createCard(payload);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Exception catch (e, stack) {
      CrashReportService.instance
          .reportError(e, stack, source: 'AddPasswordScreen');
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.unknownError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.editCard != null;

    final content = Container(
      decoration: BoxDecoration(
          color:
              const Color(0xFF16213E).withValues(alpha: 0.95), // Xcode 风格暗黑玻璃
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
              top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ))),
      child: Column(
        children: [
          // 悬浮在顶部的拖拽胶囊指示器
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
                    isEditing ? l10n.editPassword : l10n.addPassword,
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
                    if (_isLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _save,
                        style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6C63FF),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 17)),
                        child: Text(l10n.save),
                      ),
                    // 给模态框加一个关闭按钮
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
            child: Form(
              key: _formKey,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: l10n.titleWithAsterisk,
                      hintText: l10n.titleHint,
                      prefixIcon: const Icon(Icons.label_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.titleRequired;
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: l10n.usernameWithAsterisk,
                      hintText: l10n.usernameHint,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.usernameRequired;
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: _calculatePasswordStrength,
                    decoration: InputDecoration(
                      labelText: l10n.passwordWithAsterisk,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _generatePassword,
                            tooltip: l10n.generatePassword,
                          ),
                        ],
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.passwordRequired;
                      }
                      if (value.length < 6) {
                        return l10n.passwordTooShortShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Password strength indicator
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _passwordStrength,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStrengthColor(),
                          ),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _passwordStrength < 0.4
                            ? l10n.weak
                            : _passwordStrength < 0.7
                                ? l10n.medium
                                : l10n.strong,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStrengthColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // URL
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: l10n.websiteURL,
                      hintText: 'https://example.com',
                      prefixIcon: const Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: l10n.notes,
                      hintText: l10n.notesHint,
                      prefixIcon: const Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 64), // Safe space for scrolling
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: content,
          ),
        ),
      ),
    );
  }
}
