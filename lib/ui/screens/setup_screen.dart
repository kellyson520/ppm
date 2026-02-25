import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/diagnostics/crash_report_service.dart';
import '../../blocs/vault/vault_bloc.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _pageController = PageController();

  int _currentPage = 0;
  bool _isLoading = false;
  String _errorMessage = '';
  double _passwordStrength = 0;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _pageController.dispose();
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

  String _getStrengthText() {
    if (_passwordStrength < 0.4) return 'Weak';
    if (_passwordStrength < 0.7) return 'Medium';
    return 'Strong';
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  Future<void> _completeSetup() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
      });
      return;
    }

    context.read<VaultBloc>().add(
          VaultInitializeRequested(_passwordController.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VaultBloc, VaultState>(
      listener: (context, state) {
        if (state.status == VaultStatus.error) {
          setState(() {
            _errorMessage = state.errorMessage ?? 'Unknown error';
          });
        }
      },
      child: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, state) {
          final isLoading = state.status == VaultStatus.loading;

          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / 3,
                    backgroundColor: Colors.white10,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildWelcomePage(),
                        _buildPasswordPage(),
                        _buildConfirmPage(isLoading),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 80,
            color: Color(0xFF6C63FF),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to ZTD',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Zero-Trust Distributed Password Manager',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildFeatureItem(
            Icons.lock_outline,
            'End-to-End Encryption',
            'Your data is encrypted with AES-256-GCM',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.cloud_sync_outlined,
            'Distributed Sync',
            'Sync across devices via WebDAV',
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.offline_bolt_outlined,
            'Offline First',
            'Access your passwords anytime, anywhere',
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Create Master Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This password will encrypt all your data. Make it strong and memorable.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _passwordController,
            obscureText: true,
            onChanged: _calculatePasswordStrength,
            decoration: const InputDecoration(
              labelText: 'Master Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 16),
          // Password strength indicator
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _passwordStrength,
                  backgroundColor: Colors.white10,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_getStrengthColor()),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getStrengthText(),
                style: TextStyle(
                  color: _getStrengthColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPasswordRequirements(),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _passwordStrength >= 0.4 ? _nextPage : null,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirement(
          'At least 8 characters',
          password.length >= 8,
        ),
        _buildRequirement(
          'Contains uppercase letter',
          password.contains(RegExp(r'[A-Z]')),
        ),
        _buildRequirement(
          'Contains lowercase letter',
          password.contains(RegExp(r'[a-z]')),
        ),
        _buildRequirement(
          'Contains number',
          password.contains(RegExp(r'[0-9]')),
        ),
        _buildRequirement(
          'Contains special character',
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: met ? Colors.green : Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: met ? Colors.green : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPage(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Confirm Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your password again to confirm.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
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
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
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
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _completeSetup,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create Vault'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
