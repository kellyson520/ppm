import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../crypto/crypto_service.dart';

class BiometricAuthManager {
  static const String _bioCredentialKeyName = 'ztd_bio_credential';
  static const String _bioSaltKeyName = 'ztd_bio_salt';
  static const String _bioIvKeyName = 'ztd_bio_iv';
  static const String _bioAuthEnabledKeyName = 'ztd_bio_auth_enabled';
  static const String _failedAttemptsKeyName = 'ztd_failed_attempts';
  static const String _lockoutUntilKeyName = 'ztd_lockout_until';

  final FlutterSecureStorage _secureStorage;
  final CryptoService _cryptoService;
  final LocalAuthentication _localAuth;

  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  BiometricAuthManager({
    FlutterSecureStorage? secureStorage,
    CryptoService? cryptoService,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
                storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
              ),
              iOptions: IOSOptions(
                accountName: 'ztd_password_manager',
                accessibility: KeychainAccessibility.unlocked,
              ),
            ),
        _cryptoService = cryptoService ?? CryptoService(),
        _localAuth = localAuth ?? LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics || canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _bioAuthEnabledKeyName);
    return enabled == 'true';
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final isLocked = await _isLockedOut();
      if (isLocked) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock your vault',
      );

      if (!authenticated) {
        await _incrementFailedAttempts();
      } else {
        await _resetFailedAttempts();
      }

      return authenticated;
    } catch (_) {
      return false;
    }
  }

  Future<void> enableBiometricMode(String masterPassword) async {
    final salt = _cryptoService.generateRandomBytes(32);
    final iv = _cryptoService.generateRandomBytes(12);

    final credential = _cryptoService.encryptAesGcmWithIv(
      Uint8List.fromList(utf8.encode(masterPassword)),
      salt,
      iv,
    );

    await _secureStorage.write(key: _bioCredentialKeyName, value: credential);
    await _secureStorage.write(key: _bioSaltKeyName, value: base64Encode(salt));
    await _secureStorage.write(key: _bioIvKeyName, value: base64Encode(iv));
    await _secureStorage.write(key: _bioAuthEnabledKeyName, value: 'true');
  }

  Future<String?> getCredentialAfterBiometricAuth() async {
    try {
      final authenticated = await authenticateWithBiometrics();
      if (!authenticated) {
        return null;
      }

      final encryptedCredential = await _secureStorage.read(key: _bioCredentialKeyName);
      final saltBase64 = await _secureStorage.read(key: _bioSaltKeyName);
      final ivBase64 = await _secureStorage.read(key: _bioIvKeyName);

      if (encryptedCredential == null || saltBase64 == null || ivBase64 == null) {
        return null;
      }

      final salt = base64Decode(saltBase64);
      final iv = base64Decode(ivBase64);

      final decrypted = _cryptoService.decryptAesGcmWithIv(
        encryptedCredential,
        salt,
        iv,
      );

      return String.fromCharCodes(decrypted);
    } catch (_) {
      return null;
    }
  }

  Future<void> disableBiometricMode() async {
    await _secureStorage.delete(key: _bioCredentialKeyName);
    await _secureStorage.delete(key: _bioSaltKeyName);
    await _secureStorage.delete(key: _bioIvKeyName);
    await _secureStorage.write(key: _bioAuthEnabledKeyName, value: 'false');
    await _resetFailedAttempts();
  }

  Future<bool> _isLockedOut() async {
    final lockoutUntilStr = await _secureStorage.read(key: _lockoutUntilKeyName);
    if (lockoutUntilStr == null) return false;

    final lockoutUntil = DateTime.parse(lockoutUntilStr);
    if (DateTime.now().isBefore(lockoutUntil)) {
      return true;
    }

    await _resetFailedAttempts();
    return false;
  }

  Future<int> _getFailedAttempts() async {
    final attemptsStr = await _secureStorage.read(key: _failedAttemptsKeyName);
    return attemptsStr != null ? int.tryParse(attemptsStr) ?? 0 : 0;
  }

  Future<void> _incrementFailedAttempts() async {
    final attempts = await _getFailedAttempts();
    await _secureStorage.write(
      key: _failedAttemptsKeyName,
      value: '${attempts + 1}',
    );

    if (attempts + 1 >= maxFailedAttempts) {
      final lockoutUntil = DateTime.now().add(lockoutDuration);
      await _secureStorage.write(
        key: _lockoutUntilKeyName,
        value: lockoutUntil.toIso8601String(),
      );
    }
  }

  Future<void> _resetFailedAttempts() async {
    await _secureStorage.delete(key: _failedAttemptsKeyName);
    await _secureStorage.delete(key: _lockoutUntilKeyName);
  }

  Future<Duration?> getRemainingLockoutTime() async {
    final lockoutUntilStr = await _secureStorage.read(key: _lockoutUntilKeyName);
    if (lockoutUntilStr == null) return null;

    final lockoutUntil = DateTime.parse(lockoutUntilStr);
    final remaining = lockoutUntil.difference(DateTime.now());

    if (remaining.isNegative) {
      await _resetFailedAttempts();
      return null;
    }

    return remaining;
  }

  Future<int> getRemainingAttempts() async {
    final attempts = await _getFailedAttempts();
    return maxFailedAttempts - attempts;
  }
}
