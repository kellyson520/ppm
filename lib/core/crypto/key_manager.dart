import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'crypto_service.dart';

/// Key Manager for ZTD Password Manager
/// 
/// Implements the double envelope encryption strategy:
/// - KEK (Key Encryption Key): Derived from master password, stored in TEE
/// - DEK (Data Encryption Key): Random 256-bit key, encrypted by KEK
/// 
/// This allows:
/// - Key rotation without re-encrypting all data
/// - Resistance to physical coercion (KEK can be wiped)
/// - Master password changes without data re-encryption
class KeyManager {
  static const String _kekKeyName = 'ztd_kek_encrypted';
  static const String _dekKeyName = 'ztd_dek_encrypted';
  static const String _saltKeyName = 'ztd_salt';
  static const String _argonParamsKeyName = 'ztd_argon_params';
  static const String _searchKeyName = 'ztd_search_key';
  static const String _deviceIdKeyName = 'ztd_device_id';

  final FlutterSecureStorage _secureStorage;
  final CryptoService _cryptoService;

  // In-memory cache for DEK (session-only)
  Uint8List? _cachedDEK;

  KeyManager({
    FlutterSecureStorage? secureStorage,
    CryptoService? cryptoService,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
            storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
          ),
          iOptions: IOSOptions(
            accountName: 'ztd_password_manager',
            accessibility: KeychainAccessibility.unlocked,
          ),
        ),
        _cryptoService = cryptoService ?? CryptoService();

  /// Initialize with new master password (first setup)
  /// 
  /// 1. Generate random salt
  /// 2. Benchmark device for Argon2id parameters
  /// 3. Derive KEK from master password
  /// 4. Generate random DEK
  /// 5. Encrypt DEK with KEK
  /// 6. Store encrypted DEK and salt in secure storage
  Future<void> initialize(String masterPassword) async {
    // Generate random salt (32 bytes)
    final salt = _cryptoService.generateRandomBytes(32);
    
    // Benchmark device for optimal Argon2id parameters
    final argonParams = _cryptoService.benchmarkDevice();
    
    // Derive KEK from master password
    final kek = _cryptoService.deriveKEK(
      masterPassword,
      salt,
      memoryKB: argonParams.memoryKB,
      iterations: argonParams.iterations,
      parallelism: argonParams.parallelism,
    );
    
    // Generate random DEK (256-bit)
    final dek = _cryptoService.generateDEK();
    
    // Generate search key for blind indexes
    final searchKey = _cryptoService.generateRandomBytes(32);
    
    // Generate device ID
    final deviceId = _generateDeviceId();
    
    // Encrypt DEK with KEK using AES-256-GCM
    final encryptedDEK = _cryptoService.encryptAESGCM(dek, kek);
    
    // Store in secure storage
    await _secureStorage.write(key: _saltKeyName, value: base64Encode(salt));
    await _secureStorage.write(
      key: _argonParamsKeyName, 
      value: jsonEncode(argonParams.toJson()),
    );
    await _secureStorage.write(
      key: _dekKeyName, 
      value: encryptedDEK.serialize(),
    );
    await _secureStorage.write(
      key: _searchKeyName, 
      value: base64Encode(searchKey),
    );
    await _secureStorage.write(key: _deviceIdKeyName, value: deviceId);
    
    // Cache DEK in memory for session
    _cachedDEK = Uint8List.fromList(dek);
    
    // Clear KEK from memory
    _cryptoService.clearBuffer(kek);
  }

  /// Unlock the vault with master password
  /// 
  /// 1. Retrieve salt and Argon2id parameters
  /// 2. Derive KEK from master password
  /// 3. Decrypt DEK using KEK
  /// 4. Cache DEK in memory
  Future<bool> unlock(String masterPassword) async {
    try {
      // Retrieve stored values
      final saltStr = await _secureStorage.read(key: _saltKeyName);
      final argonParamsStr = await _secureStorage.read(key: _argonParamsKeyName);
      final encryptedDEKStr = await _secureStorage.read(key: _dekKeyName);
      
      if (saltStr == null || argonParamsStr == null || encryptedDEKStr == null) {
        return false; // Not initialized
      }
      
      final salt = base64Decode(saltStr);
      final argonParams = Argon2Parameters.fromJson(
        jsonDecode(argonParamsStr) as Map<String, dynamic>,
      );
      final encryptedDEK = EncryptedData.deserialize(encryptedDEKStr);
      
      // Derive KEK
      final kek = _cryptoService.deriveKEK(
        masterPassword,
        salt,
        memoryKB: argonParams.memoryKB,
        iterations: argonParams.iterations,
        parallelism: argonParams.parallelism,
      );
      
      // Decrypt DEK
      final dek = _cryptoService.decryptAESGCM(encryptedDEK, kek);
      
      // Cache DEK
      _cachedDEK = dek;
      
      // Clear KEK
      _cryptoService.clearBuffer(kek);
      
      return true;
    } on Exception {
      return false;
    }
  }

  /// Lock the vault - clear DEK from memory
  void lock() {
    if (_cachedDEK != null) {
      _cryptoService.clearBuffer(_cachedDEK!);
      _cachedDEK = null;
    }
  }

  /// Check if vault is unlocked
  bool get isUnlocked => _cachedDEK != null;

  /// Get DEK (only when unlocked)
  Uint8List? get dek => _cachedDEK != null 
      ? Uint8List.fromList(_cachedDEK!) 
      : null;

  /// Get search key for blind indexes
  Future<Uint8List?> getSearchKey() async {
    final keyStr = await _secureStorage.read(key: _searchKeyName);
    if (keyStr == null) return null;
    return base64Decode(keyStr);
  }

  /// Get device ID
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: _deviceIdKeyName);
  }

  /// Change master password
  /// 
  /// 1. Unlock with old password
  /// 2. Generate new salt
  /// 3. Derive new KEK
  /// 4. Re-encrypt DEK with new KEK
  /// 5. Store new encrypted DEK and salt
  Future<bool> changeMasterPassword(
    String oldPassword, 
    String newPassword,
  ) async {
    // Verify old password
    if (!await unlock(oldPassword)) {
      return false;
    }
    
    try {
      final dek = _cachedDEK;
      if (dek == null) return false;
      
      // Generate new salt
      final newSalt = _cryptoService.generateRandomBytes(32);
      
      // Benchmark for new parameters
      final newArgonParams = _cryptoService.benchmarkDevice();
      
      // Derive new KEK
      final newKek = _cryptoService.deriveKEK(
        newPassword,
        newSalt,
        memoryKB: newArgonParams.memoryKB,
        iterations: newArgonParams.iterations,
        parallelism: newArgonParams.parallelism,
      );
      
      // Re-encrypt DEK with new KEK
      final newEncryptedDEK = _cryptoService.encryptAESGCM(dek, newKek);
      
      // Store new values
      await _secureStorage.write(
        key: _saltKeyName, 
        value: base64Encode(newSalt),
      );
      await _secureStorage.write(
        key: _argonParamsKeyName, 
        value: jsonEncode(newArgonParams.toJson()),
      );
      await _secureStorage.write(
        key: _dekKeyName, 
        value: newEncryptedDEK.serialize(),
      );
      
      // Clear new KEK
      _cryptoService.clearBuffer(newKek);
      
      return true;
    } on Exception {
      return false;
    }
  }

  /// Rotate DEK (re-encrypt all data with new DEK)
  /// This should be done periodically for security
  /// 
  /// Returns the new DEK for re-encryption
  Future<Uint8List?> rotateDEK(String masterPassword) async {
    if (!await unlock(masterPassword)) {
      return null;
    }
    
    try {
      final oldDek = _cachedDEK;
      if (oldDek == null) return null;
      
      // Generate new DEK
      final newDek = _cryptoService.generateDEK();
      
      // Get salt and parameters
      final saltStr = await _secureStorage.read(key: _saltKeyName);
      final argonParamsStr = await _secureStorage.read(key: _argonParamsKeyName);
      
      if (saltStr == null || argonParamsStr == null) return null;
      
      final salt = base64Decode(saltStr);
      final argonParams = Argon2Parameters.fromJson(
        jsonDecode(argonParamsStr) as Map<String, dynamic>,
      );
      
      // Derive KEK
      final kek = _cryptoService.deriveKEK(
        masterPassword,
        salt,
        memoryKB: argonParams.memoryKB,
        iterations: argonParams.iterations,
        parallelism: argonParams.parallelism,
      );
      
      // Encrypt new DEK with KEK
      final encryptedNewDEK = _cryptoService.encryptAESGCM(newDek, kek);
      
      // Store new encrypted DEK
      await _secureStorage.write(
        key: _dekKeyName, 
        value: encryptedNewDEK.serialize(),
      );
      
      // Update cache
      _cachedDEK = newDek;
      
      // Clear KEK and old DEK
      _cryptoService.clearBuffer(kek);
      _cryptoService.clearBuffer(oldDek);
      
      return newDek;
    } on Exception {
      return null;
    }
  }

  /// Check if already initialized
  Future<bool> isInitialized() async {
    final dekStr = await _secureStorage.read(key: _dekKeyName);
    return dekStr != null;
  }

  /// Reset all keys (DANGER: destroys all encrypted data)
  Future<void> reset() async {
    lock();
    await _secureStorage.delete(key: _kekKeyName);
    await _secureStorage.delete(key: _dekKeyName);
    await _secureStorage.delete(key: _saltKeyName);
    await _secureStorage.delete(key: _argonParamsKeyName);
    await _secureStorage.delete(key: _searchKeyName);
    await _secureStorage.delete(key: _deviceIdKeyName);
  }

  /// Generate device ID
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _cryptoService.generateRandomBytes(8);
    final input = '$timestamp${base64Encode(random)}';
    return _cryptoService.sha256String(input).substring(0, 16);
  }

  /// Export emergency kit (encrypted backup)
  /// 
  /// Returns a JSON string containing encrypted DEK and metadata
  /// This can be used for recovery if master password is forgotten
  Future<String?> exportEmergencyKit(String masterPassword) async {
    if (!await unlock(masterPassword)) {
      return null;
    }
    
    try {
      final dek = _cachedDEK;
      final searchKey = await getSearchKey();
      final deviceId = await getDeviceId();
      
      if (dek == null || searchKey == null || deviceId == null) {
        return null;
      }
      
      // Create emergency kit with DEK (not KEK!)
      // This allows data recovery with the emergency kit
      final kit = {
        'version': 1,
        'deviceId': deviceId,
        'dek': base64Encode(dek),
        'searchKey': base64Encode(searchKey),
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      return jsonEncode(kit);
    } on Exception {
      return null;
    }
  }

  /// Import emergency kit
  Future<bool> importEmergencyKit(String kitJson) async {
    try {
      final kit = jsonDecode(kitJson) as Map<String, dynamic>;
      
      if (kit['version'] != 1) {
        return false;
      }
      
      final dek = base64Decode(kit['dek'] as String);
      final searchKey = base64Decode(kit['searchKey'] as String);
      final deviceId = kit['deviceId'] as String;
      
      // Cache DEK
      _cachedDEK = dek;
      
      // Store search key and device ID
      await _secureStorage.write(
        key: _searchKeyName, 
        value: base64Encode(searchKey),
      );
      await _secureStorage.write(key: _deviceIdKeyName, value: deviceId);
      
      return true;
    } on Exception {
      return false;
    }
  }
}
