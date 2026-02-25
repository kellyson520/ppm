import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/diagnostics/crash_report_service.dart';
import '../../services/vault_service.dart';
import '../../core/models/models.dart';

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
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    final password = List.generate(16, (index) {
      return chars[(random + index * 17) % chars.length];
    }).join();

    setState(() {
      _passwordController.text = password;
      _calculatePasswordStrength(password);
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
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
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editCard != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Password' : 'Add Password'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Google, Netflix, Bank',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username / Email *',
                hintText: 'your@email.com',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
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
                labelText: 'Password *',
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
                      tooltip: 'Generate Password',
                    ),
                  ],
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
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
                      ? 'Weak'
                      : _passwordStrength < 0.7
                          ? 'Medium'
                          : 'Strong',
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
              decoration: const InputDecoration(
                labelText: 'Website URL',
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional information...',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}
