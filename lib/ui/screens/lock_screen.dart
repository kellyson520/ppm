import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/vault_service.dart';
import 'package:local_auth/local_auth.dart';
import '../../blocs/vault/vault_bloc.dart';
import '../../l10n/app_localizations.dart';

/// Storage keys for persisting brute-force protection state.
const _kFailedAttemptsKey = 'lock_screen_failed_attempts';
const _kLockoutUntilKey = 'lock_screen_lockout_until';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  bool _obscurePassword = true;
  String _errorMessage = '';
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  Timer? _cooldownTimer;
  int _remainingCooldownSeconds = 0;

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

    Future.microtask(() async {
      await _loadStoredAttempts();
      _checkBiometrics();
    });
  }

  // ---------------------------------------------------------------------------
  // Persistence & cooldown logic
  // ---------------------------------------------------------------------------

  /// Load persisted failed-attempt count and lockout timestamp from secure
  /// storage, then check whether the cooldown timer needs to start.
  Future<void> _loadStoredAttempts() async {
    final countStr = await _secureStorage.read(key: _kFailedAttemptsKey);
    final lockoutStr = await _secureStorage.read(key: _kLockoutUntilKey);

    final count = int.tryParse(countStr ?? '') ?? 0;
    DateTime? lockoutUntil;
    if (lockoutStr != null) {
      lockoutUntil = DateTime.tryParse(lockoutStr);
    }

    if (!mounted) return;

    setState(() {
      _failedAttempts = count;
      _lockoutUntil = lockoutUntil;
    });

    _checkAndStartCooldown();
  }

  /// If the lockout timestamp is still in the future, start the countdown
  /// timer and disable input until it expires.
  void _checkAndStartCooldown() {
    if (_lockoutUntil == null) return;

    final now = DateTime.now();
    if (_lockoutUntil!.isAfter(now)) {
      _startCooldownTimer();
    } else {
      setState(() {
        _lockoutUntil = null;
      });
    }
  }

  /// Exponential backoff delay based on the current failure count.
  ///
  /// | Attempts | Delay      |
  /// |----------|------------|
  /// | 1 – 4    | 0          |
  /// | 5 – 9    | 1 s        |
  /// | 10 – 14  | 5 s        |
  /// | 15 – 19  | 30 s       |
  /// | 20 – 24  | 60 s       |
  /// | 25+      | permanent  |
  Duration _getBackoffDelay(int attempts) {
    if (attempts >= 25) return const Duration(days: 36500); // permanent
    if (attempts >= 20) return const Duration(seconds: 60);
    if (attempts >= 15) return const Duration(seconds: 30);
    if (attempts >= 10) return const Duration(seconds: 5);
    if (attempts >= 5) return const Duration(seconds: 1);
    return Duration.zero;
  }

  /// Whether the password field and unlock button should be enabled.
  bool get _isUnlockAllowed {
    if (_lockoutUntil != null && _lockoutUntil!.isAfter(DateTime.now())) {
      return false;
    }
    return true;
  }

  /// Whether the vault is permanently locked (≥ 25 failed attempts).
  bool get _isPermanentLockout => _failedAttempts >= 25;

  /// Start a periodic 1-second timer that refreshes
  /// [_remainingCooldownSeconds] and clears the lockout when it expires.
  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _tickCooldown();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickCooldown();
    });
  }

  void _tickCooldown() {
    if (!mounted) {
      _cooldownTimer?.cancel();
      return;
    }
    if (_lockoutUntil == null) {
      _cooldownTimer?.cancel();
      return;
    }

    final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _cooldownTimer?.cancel();
      setState(() {
        _lockoutUntil = null;
        _remainingCooldownSeconds = 0;
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _remainingCooldownSeconds = remaining;
    });
  }

  /// Clear the failed-attempt count from memory and secure storage.
  Future<void> _resetFailedAttempts() async {
    _cooldownTimer?.cancel();
    await Future.wait([
      _secureStorage.delete(key: _kFailedAttemptsKey),
      _secureStorage.delete(key: _kLockoutUntilKey),
    ]);
    if (mounted) {
      setState(() {
        _failedAttempts = 0;
        _lockoutUntil = null;
        _remainingCooldownSeconds = 0;
        _errorMessage = '';
      });
    }
  }

  /// Format the remaining cooldown into a human-readable suffix.
  String _buildCooldownMessage(AppLocalizations l10n) {
    if (_isPermanentLockout) {
      return l10n.tooManyAttempts;
    }
    final remaining = _remainingCooldownSeconds;
    if (remaining > 0) {
      return '${l10n.tooManyAttempts} ${_formatCooldown(remaining)}';
    }
    return l10n.tooManyAttempts;
  }

  String _formatCooldown(int seconds) {
    if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      if (secs == 0) return '(${minutes}m)';
      return '(${minutes}m ${secs}s)';
    }
    return '(${seconds}s)';
  }

  // ---------------------------------------------------------------------------
  // Biometric helper
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _passwordController.dispose();
    _shakeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Unlock & attempt handling
  // ---------------------------------------------------------------------------

  void _unlock() {
    if (_passwordController.text.isEmpty) return;
    if (!_isUnlockAllowed) {
      // Double-check: reject if we are still in cooldown (button should be
      // disabled, but guard here anyway).
      setState(() {
        _errorMessage = _buildCooldownMessage(AppLocalizations.of(context)!);
      });
      return;
    }
    context.read<VaultBloc>().add(
          VaultUnlockRequested(_passwordController.text),
        );
  }

  void _handleFailedAttempt(AppLocalizations l10n) {
    _failedAttempts++;
    _shakeController.forward().then((_) => _shakeController.reset());
    HapticFeedback.heavyImpact();

    final delay = _getBackoffDelay(_failedAttempts);

    if (delay > Duration.zero) {
      _lockoutUntil = DateTime.now().add(delay);
      Future.wait([
        _secureStorage.write(
            key: _kFailedAttemptsKey, value: _failedAttempts.toString()),
        _secureStorage.write(
            key: _kLockoutUntilKey, value: _lockoutUntil!.toIso8601String()),
      ]);

      setState(() {
        _errorMessage = _buildCooldownMessage(l10n);
      });
      _startCooldownTimer();
    } else {
      _secureStorage.write(
          key: _kFailedAttemptsKey, value: _failedAttempts.toString());
      setState(() {
        _errorMessage =
            '${l10n.incorrectPassword} ${_failedAttempts > 1 ? '($_failedAttempts ${l10n.attempts})' : ''}';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<VaultBloc, VaultState>(
      listener: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        if (state.status == VaultStatus.locked &&
            state.errorMessage != null &&
            state.errorMessage == 'Invalid master password') {
          _handleFailedAttempt(l10n);
        } else if (state.status == VaultStatus.unlocked) {
          // Clear the counter on every successful unlock (password or biometric).
          _resetFailedAttempts();
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
                          enabled: !isLoading && _isUnlockAllowed,
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
                            onPressed: (isLoading || !_isUnlockAllowed)
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
