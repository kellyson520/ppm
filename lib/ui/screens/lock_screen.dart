import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/vault_service.dart';
import 'package:local_auth/local_auth.dart';
import '../../blocs/vault/vault_bloc.dart';
import '../../l10n/app_localizations.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _errorMessage = '';
  int _failedAttempts = 0;

  bool _isBiometricEnabled = false;
  final _localAuth = LocalAuthentication();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    Future.microtask(_checkBiometrics);
  }

  Future<void> _checkBiometrics() async {
    final service = context.read<VaultService>();
    final enabled = await service.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = enabled;
      });
    }
  }

  Future<void> _unlockWithBiometric() async {
    final l10n = AppLocalizations.of(context)!;
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: l10n.biometricAuth,
      );
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '${l10n.error}: $e';
        });
      }
    }

    if (authenticated && mounted) {
      final service = context.read<VaultService>();
      final pwd = await service.getStoredBiometricPassword();
      if (!mounted) return;
      if (pwd != null) {
        context.read<VaultBloc>().add(VaultUnlockRequested(pwd));
      } else {
        setState(() {
          _errorMessage =
              'Biometric token expired. Please enter password and re-enable in Settings.';
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _unlock() {
    if (_passwordController.text.isEmpty) return;
    context.read<VaultBloc>().add(
          VaultUnlockRequested(_passwordController.text),
        );
  }

  void _handleFailedAttempt(AppLocalizations l10n) {
    _failedAttempts++;
    _shakeController.forward().then((_) => _shakeController.reset());
    HapticFeedback.heavyImpact();

    setState(() {
      if (_failedAttempts >= 5) {
        _errorMessage = l10n.tooManyAttempts;
      } else {
        _errorMessage =
            '${l10n.incorrectPassword} ${_failedAttempts > 1 ? '($_failedAttempts ${l10n.attempts})' : ''}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VaultBloc, VaultState>(
      listener: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        if (state.status == VaultStatus.locked &&
            state.errorMessage != null &&
            state.errorMessage == 'Invalid master password') {
          _handleFailedAttempt(l10n);
        } else if (state.status == VaultStatus.error) {
          setState(() {
            _errorMessage = state.errorMessage ?? l10n.anErrorOccurred;
          });
        }
      },
      child: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          final isLoading = state.status == VaultStatus.loading;

          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lock icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF00BFA6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF)
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Title
                        Text(
                          l10n.vaultLocked,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.enterMasterPassword,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Password field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          enabled: !isLoading && _failedAttempts < 5,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _unlock(),
                          decoration: InputDecoration(
                            labelText: l10n.masterPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
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
                          ),
                        ),
                        // Error message
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Unlock button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (isLoading || _failedAttempts >= 5)
                                ? null
                                : _unlock,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(l10n.unlock),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Biometric option
                        if (_isBiometricEnabled)
                          TextButton.icon(
                            onPressed: _unlockWithBiometric,
                            icon: const Icon(Icons.fingerprint),
                            label: Text(l10n.useBiometric),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
