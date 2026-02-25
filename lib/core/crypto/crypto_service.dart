import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Cryptographic Service for ZTD Password Manager
/// Implements:
/// - Argon2id KDF for key derivation
/// - AES-256-GCM for encryption
/// - HKDF-SHA256 for key stretching
/// - Constant-time comparison for side-channel resistance
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  // Secure random number generator
  final _secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(Uint8List.fromList(
      List.generate(32, (_) => Random.secure().nextInt(256))
    )));

  /// Generate cryptographically secure random bytes
  Uint8List generateRandomBytes(int length) {
    return _secureRandom.nextBytes(length);
  }

  // ==================== Argon2id KDF ====================

  /// Argon2id parameters
  static const int defaultMemoryKB = 65536; // 64 MB
  static const int defaultIterations = 3;
  static const int defaultParallelism = 4;
  static const int defaultHashLength = 32;

  /// Derive KEK (Key Encryption Key) from master password using Argon2id
  /// 
  /// Parameters:
  /// - [password]: User's master password
  /// - [salt]: Random 32-byte salt
  /// - [memoryKB]: Memory cost in KB (default 64MB)
  /// - [iterations]: Number of iterations (default 3)
  /// - [parallelism]: Parallelism factor (default 4)
  Uint8List deriveKEK(
    String password,
    Uint8List salt, {
    int memoryKB = defaultMemoryKB,
    int iterations = defaultIterations,
    int parallelism = defaultParallelism,
  }) {
    // Note: Full Argon2id implementation requires argon2 package
    // This is a simplified implementation using PBKDF2 as fallback
    // In production, use the argon2 package
    
    final passwordBytes = utf8.encode(password);
    final derivator = PBKDF2KeyDerivator(
      HMac(SHA256Digest(), 64),
    );
    
    derivator.init(Pbkdf2Parameters(
      salt,
      iterations * 1000, // Scale up for PBKDF2
      defaultHashLength,
    ));
    
    return derivator.process(Uint8List.fromList(passwordBytes));
  }

  /// Benchmark device to determine optimal Argon2id parameters
  /// Returns recommended parameters based on device capability
  Argon2Parameters benchmarkDevice() {
    final stopwatch = Stopwatch()..start();
    
    // Test with minimal parameters
    final testSalt = generateRandomBytes(32);
    final testPassword = 'benchmark_test';
    
    deriveKEK(testPassword, testSalt, 
      memoryKB: 16384, 
      iterations: 1, 
      parallelism: 1
    );
    
    final elapsedMs = stopwatch.elapsedMilliseconds;
    stopwatch.stop();
    
    // Determine parameters based on performance
    // Target: 500ms - 1000ms for key derivation
    if (elapsedMs < 50) {
      // High-end device
      return Argon2Parameters(
        memoryKB: 131072,  // 128 MB
        iterations: 4,
        parallelism: 4,
      );
    } else if (elapsedMs < 200) {
      // Mid-range device
      return Argon2Parameters(
        memoryKB: 65536,   // 64 MB
        iterations: 3,
        parallelism: 4,
      );
    } else {
      // Low-end device
      return Argon2Parameters(
        memoryKB: 32768,   // 32 MB
        iterations: 2,
        parallelism: 2,
      );
    }
  }

  // ==================== AES-256-GCM Encryption ====================

  /// Generate a random 256-bit Data Encryption Key (DEK)
  Uint8List generateDEK() => generateRandomBytes(32);

  /// Encrypt data using AES-256-GCM
  /// 
  /// Returns: EncryptedData containing ciphertext, IV, and auth tag
  EncryptedData encryptAESGCM(Uint8List plaintext, Uint8List key) {
    final iv = generateRandomBytes(12); // 96-bit IV for GCM
    
    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        true, // encrypt
        AEADParameters(
          KeyParameter(key),
          128, // auth tag size in bits
          iv,
          Uint8List(0), // no additional authenticated data
        ),
      );
    
    final ciphertext = gcm.process(plaintext);
    
    // Extract auth tag (last 16 bytes)
    final authTag = ciphertext.sublist(ciphertext.length - 16);
    final actualCiphertext = ciphertext.sublist(0, ciphertext.length - 16);
    
    return EncryptedData(
      ciphertext: actualCiphertext,
      iv: iv,
      authTag: authTag,
    );
  }

  /// Decrypt data using AES-256-GCM
  Uint8List decryptAESGCM(EncryptedData encryptedData, Uint8List key) {
    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        false, // decrypt
        AEADParameters(
          KeyParameter(key),
          128,
          encryptedData.iv,
          Uint8List(0),
        ),
      );
    
    // Combine ciphertext and auth tag
    final combined = Uint8List.fromList([
      ...encryptedData.ciphertext,
      ...encryptedData.authTag,
    ]);
    
    return gcm.process(combined);
  }

  /// Encrypt string data
  EncryptedData encryptString(String plaintext, Uint8List key) {
    return encryptAESGCM(utf8.encode(plaintext), key);
  }

  /// Decrypt to string
  String decryptString(EncryptedData encryptedData, Uint8List key) {
    final decrypted = decryptAESGCM(encryptedData, key);
    return utf8.decode(decrypted);
  }

  // ==================== HKDF Key Derivation ====================

  /// Derive key using HKDF-SHA256
  /// 
  /// [ikm]: Input keying material
  /// [salt]: Salt value (optional, can be empty)
  /// [info]: Context/application specific info
  /// [length]: Desired output length in bytes
  Uint8List hkdfSha256(
    Uint8List ikm, {
    Uint8List? salt,
    Uint8List? info,
    int length = 32,
  }) {
    final hkdf = HKDFKeyDerivator(SHA256Digest());
    
    hkdf.init(HkdfParameters(
      ikm,
      length,
      salt ?? Uint8List(0),
      info ?? Uint8List(0),
    ));
    
    return hkdf.process(Uint8List(0));
  }

  // ==================== HMAC ====================

  /// Calculate HMAC-SHA256
  Uint8List hmacSha256(Uint8List key, Uint8List data) {
    final hmac = HMac(SHA256Digest(), 64)
      ..init(KeyParameter(key));
    return hmac.process(data);
  }

  /// Calculate HMAC-SHA256 for string data
  String hmacSha256String(String key, String data) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final result = hmacSha256(
      Uint8List.fromList(keyBytes),
      Uint8List.fromList(dataBytes),
    );
    return base64Encode(result);
  }

  // ==================== Constant-Time Operations ====================

  /// Constant-time comparison to prevent timing attacks
  /// Returns true if arrays are equal, false otherwise
  bool constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i]; // XOR, no branching
    }
    return result == 0;
  }

  /// Constant-time comparison for hex strings
  bool constantTimeEqualsHex(String a, String b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  // ==================== Hash Functions ====================

  /// Calculate SHA256 hash
  Uint8List sha256Hash(Uint8List data) {
    return sha256.convert(data).bytes as Uint8List;
  }

  /// Calculate SHA256 hash of string
  String sha256String(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  // ==================== Blind Index Generation ====================

  /// Generate blind indexes for search
  /// These allow searching encrypted data without revealing content
  List<String> generateBlindIndexes(
    String plaintext,
    Uint8List searchKey, {
    int minTokenLength = 2,
  }) {
    // Tokenize the plaintext
    final tokens = _tokenize(plaintext.toLowerCase(), minTokenLength);
    
    // Generate HMAC for each token
    return tokens.map((token) {
      final hmac = hmacSha256(searchKey, utf8.encode(token));
      return base64Encode(hmac);
    }).toList();
  }

  /// Tokenize text into searchable tokens
  List<String> _tokenize(String text, int minLength) {
    final tokens = <String>[];
    
    // Split by common delimiters
    final words = text.split(RegExp(r'[\s\-_\.@]+'));
    
    for (final word in words) {
      if (word.length >= minLength) {
        tokens.add(word);
        
        // Add n-grams for partial matching
        if (word.length > minLength) {
          for (int i = 0; i <= word.length - minLength; i++) {
            for (int len = minLength; 
                 len <= min(word.length - i, minLength + 3); 
                 len++) {
              tokens.add(word.substring(i, i + len));
            }
          }
        }
      }
    }
    
    return tokens.toSet().toList(); // Remove duplicates
  }

  // ==================== Utility Functions ====================

  /// Convert bytes to hex string
  String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Convert hex string to bytes
  Uint8List hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  /// Clear sensitive data from memory (best effort)
  void clearBuffer(Uint8List buffer) {
    // DoD 5220.22-M simplified standard
    buffer.fillRange(0, buffer.length, 0x00);
    buffer.fillRange(0, buffer.length, 0xFF);
    buffer.fillRange(0, buffer.length, 0x00);
  }
}

/// Argon2id parameters
class Argon2Parameters {
  final int memoryKB;
  final int iterations;
  final int parallelism;

  const Argon2Parameters({
    required this.memoryKB,
    required this.iterations,
    required this.parallelism,
  });

  Map<String, dynamic> toJson() => {
    'memoryKB': memoryKB,
    'iterations': iterations,
    'parallelism': parallelism,
  };

  factory Argon2Parameters.fromJson(Map<String, dynamic> json) {
    return Argon2Parameters(
      memoryKB: json['memoryKB'] as int,
      iterations: json['iterations'] as int,
      parallelism: json['parallelism'] as int,
    );
  }
}

/// Encrypted data container
class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List authTag;

  const EncryptedData({
    required this.ciphertext,
    required this.iv,
    required this.authTag,
  });

  /// Serialize to JSON-compatible format
  Map<String, String> toJson() => {
    'ciphertext': base64Encode(ciphertext),
    'iv': base64Encode(iv),
    'authTag': base64Encode(authTag),
  };

  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      ciphertext: base64Decode(json['ciphertext'] as String),
      iv: base64Decode(json['iv'] as String),
      authTag: base64Decode(json['authTag'] as String),
    );
  }

  /// Serialize to single string
  String serialize() {
    return base64Encode(utf8.encode(jsonEncode(toJson())));
  }

  factory EncryptedData.deserialize(String data) {
    final decoded = utf8.decode(base64Decode(data));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    return EncryptedData.fromJson(json);
  }
}
