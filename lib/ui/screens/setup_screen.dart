import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/vault/vault_bloc.dart';
import '../../l10n/app_localizations.dart';

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

  String _getStrengthText(AppLocalizations l10n) {
    if (_passwordStrength < 0.4) return l10n.weak;
    if (_passwordStrength < 0.7) return l10n.medium;
    return l10n.strong;
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

  Future<void> _completeSetup(AppLocalizations l10n) async {
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = l10n.passwordsDoNotMatch;
      });
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _errorMessage = l10n.passwordTooShort;
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
        final l10n = AppLocalizations.of(context)!;
        if (state.status == VaultStatus.error) {
          setState(() {
            _errorMessage = state.errorMessage ?? l10n.unknownError;
          });
        }
      },
      child: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
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
                        _buildWelcomePage(l10n),
                        _buildPasswordPage(l10n),
                        _buildConfirmPage(l10n, isLoading),
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

  Widget _buildWelcomePage(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 80,
          color: Color(0xFF6C63FF),
        ),
        const SizedBox(height: 32),
        Text(
          l10n.welcomeToZTD,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.appTitle,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        _buildFeatureItem(
          Icons.lock_outline,
          l10n.e2eEncryption,
          l10n.e2eEncryptionDesc,
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          Icons.cloud_sync_outlined,
          l10n.distributedSync,
          l10n.distributedSyncDesc,
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          Icons.offline_bolt_outlined,
          l10n.offlineFirst,
          l10n.offlineFirstDesc,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _nextPage,
          child: Text(l10n.getStarted),
        ),
      ],
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

  Widget _buildPasswordPage(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 32),
        Text(
          l10n.createMasterPassword,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.masterPasswordDesc,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _passwordController,
          obscureText: true,
          onChanged: _calculatePasswordStrength,
          decoration: InputDecoration(
            labelText: l10n.masterPassword,
            prefixIcon: const Icon(Icons.lock_outline),
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
                valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getStrengthText(l10n),
              style: TextStyle(
                color: _getStrengthColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildPasswordRequirements(l10n),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                child: Text(l10n.back),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _passwordStrength >= 0.4 ? _nextPage : null,
                child: Text(l10n.continueText),
              ),
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 32 : 0),
      ],
    );
  }

  Widget _buildPasswordRequirements(AppLocalizations l10n) {
    final password = _passwordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirement(
          l10n.atLeast8Chars,
          password.length >= 8,
        ),
        _buildRequirement(
          l10n.containsUpper,
          password.contains(RegExp(r'[A-Z]')),
        ),
        _buildRequirement(
          l10n.containsLower,
          password.contains(RegExp(r'[a-z]')),
        ),
        _buildRequirement(
          l10n.containsNumber,
          password.contains(RegExp(r'[0-9]')),
        ),
        _buildRequirement(
          l10n.containsSpecial,
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

  Widget _buildConfirmPage(AppLocalizations l10n, bool isLoading) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 32),
        Text(
          l10n.confirmPassword,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.enterPasswordAgain,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _confirmController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.confirmPassword,
            prefixIcon: const Icon(Icons.lock_outline),
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
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                child: Text(l10n.back),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _completeSetup(l10n),
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
                    : Text(l10n.createVault),
              ),
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 32 : 0),
      ],
    );
  }
}
