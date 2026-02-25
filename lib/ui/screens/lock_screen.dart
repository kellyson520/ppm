import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/vault_service.dart';

class LockScreen extends StatefulWidget {
  final VaultService vaultService;
  final VoidCallback onUnlocked;

  const LockScreen({
    super.key,
    required this.vaultService,
    required this.onUnlocked,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';
  int _failedAttempts = 0;
  
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
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final success = await widget.vaultService.unlock(_passwordController.text);
      
      if (success) {
        HapticFeedback.mediumImpact();
        widget.onUnlocked();
      } else {
        _handleFailedAttempt();
      }
    } on Exception {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _handleFailedAttempt() {
    _failedAttempts++;
    _shakeController.forward().then((_) => _shakeController.reset());
    HapticFeedback.heavyImpact();
    
    setState(() {
      _isLoading = false;
      if (_failedAttempts >= 5) {
        _errorMessage = 'Too many failed attempts. Please wait.';
      } else {
        _errorMessage = 'Incorrect password. ${_failedAttempts > 1 ? '($_failedAttempts attempts)' : ''}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
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
                  const Text(
                    'Vault Locked',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your master password to unlock',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Password field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading && _failedAttempts < 5,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _unlock(),
                    decoration: InputDecoration(
                      labelText: 'Master Password',
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
                        color: Colors.red.withOpacity(0.2),
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
                      onPressed: (_isLoading || _failedAttempts >= 5)
                          ? null
                          : _unlock,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Unlock'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Biometric option (placeholder)
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement biometric authentication
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Biometric auth coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use Biometric'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
