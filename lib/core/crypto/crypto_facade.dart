import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'crypto_core.dart';
import 'crypto_registry.dart';
import 'crypto_policy.dart';
import 'providers/hkdf_provider.dart';

/// 密码学门面（Facade）
/// 
/// 供业务层（Vault/Sync/Event）调用的稳定 API。
/// 业务代码**只依赖此类**，不直接依赖具体算法实现。
/// 
/// 功能：
/// - 对称加密/解密（通过 CiphertextEnvelope 自描述格式）
/// - 密钥派生（KDF）
/// - 密钥拉伸（HKDF）
/// - HMAC
/// - 哈希
/// - 盲索引
/// - 安全工具（常量时间比较、内存清除）
class CryptoFacade {
  final CryptoRegistry _registry;
  final CryptoPolicyEngine _policy;
  final HkdfProvider _hkdf;

  // 安全随机数生成器
  final SecureRandom _secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(Uint8List.fromList(
      List.generate(32, (_) => Random.secure().nextInt(256)),
    )));

  /// 单例
  static CryptoFacade? _instance;
  factory CryptoFacade({
    CryptoRegistry? registry,
    CryptoPolicyEngine? policy,
  }) {
    _instance ??= CryptoFacade._internal(
      registry: registry ?? CryptoRegistry(),
      policy: policy ?? CryptoPolicyEngine(),
    );
    return _instance!;
  }

  CryptoFacade._internal({
    required CryptoRegistry registry,
    required CryptoPolicyEngine policy,
  })  : _registry = registry,
        _policy = policy,
        _hkdf = HkdfProvider();

  // ==================== 随机数生成 ====================

  /// 生成密码学安全随机字节
  Uint8List generateRandomBytes(int length) {
    return _secureRandom.nextBytes(length);
  }

  // ==================== KDF（密钥派生）====================

  /// 自动校准 KDF 参数（基准测试）
  KdfParams calibrateKdf() {
    final suite = _policy.defaultSuite;
    final kdf = _registry.getKdf(suite.kdfId);
    if (kdf == null) {
      throw StateError('KDF "${suite.kdfId}" 未注册');
    }
    return kdf.calibrate();
  }

  /// 从主密码派生 KEK
  Uint8List deriveKEK(
    String password,
    Uint8List salt, {
    KdfParams? params,
  }) {
    final suite = _policy.defaultSuite;
    final kdf = _registry.getKdf(suite.kdfId);
    if (kdf == null) {
      throw StateError('KDF "${suite.kdfId}" 未注册');
    }

    final effectiveParams = params ?? KdfParams(
      kdfId: suite.kdfId,
      memoryKB: 65536,
      iterations: 3,
      parallelism: 4,
    );

    return kdf.deriveKey(
      password: password,
      salt: salt,
      params: effectiveParams,
      length: 32,
    );
  }

  // ==================== AEAD 加密/解密 ====================

  /// 生成随机 256-bit DEK
  Uint8List generateDEK() => generateRandomBytes(32);

  /// 加密数据（返回 CiphertextEnvelope）
  /// 
  /// 使用默认套件加密。返回的 Envelope 包含算法元数据，
  /// 使密文自描述、可向后兼容。
  CiphertextEnvelope encrypt(
    Uint8List plaintext,
    Uint8List key, {
    Map<String, String>? aadMeta,
    KeyVersionInfo? keyInfo,
  }) {
    final suite = _policy.defaultSuite;
    final aead = _registry.getAead(suite.aeadId);
    if (aead == null) {
      throw StateError('AEAD "${suite.aeadId}" 未注册');
    }

    final nonce = generateRandomBytes(aead.nonceLength);

    // 构造 AAD（将 aadMeta 序列化为 AAD）
    final aad = aadMeta != null
        ? Uint8List.fromList(utf8.encode(jsonEncode(aadMeta)))
        : null;

    final box = aead.seal(
      plaintext: plaintext,
      key: key,
      nonce: nonce,
      aad: aad,
    );

    return CiphertextEnvelope(
      schemaVersion: 1,
      suiteId: suite.id,
      aeadId: suite.aeadId,
      keyInfo: keyInfo,
      nonce: box.nonce,
      ciphertext: box.ciphertext,
      authTag: box.authTag,
      aadMeta: aadMeta,
    );
  }

  /// 解密数据（从 CiphertextEnvelope）
  /// 
  /// 自动根据 Envelope 中的 suiteId/aeadId 选择算法。
  /// 防降级：校验套件是否在允许列表中。
  Uint8List decrypt(CiphertextEnvelope envelope, Uint8List key) {
    // 防降级校验
    final rejection = _policy.validateForDecryption(envelope.suiteId);
    if (rejection != null) {
      throw SecurityException(rejection);
    }

    final aead = _registry.getAead(envelope.aeadId);
    if (aead == null) {
      throw StateError('AEAD "${envelope.aeadId}" 未注册，无法解密');
    }

    // 重构 AAD
    final aad = envelope.aadMeta != null
        ? Uint8List.fromList(utf8.encode(jsonEncode(envelope.aadMeta)))
        : null;

    final box = EncryptedBox(
      ciphertext: envelope.ciphertext,
      nonce: envelope.nonce,
      authTag: envelope.authTag,
    );

    return aead.open(box: box, key: key, aad: aad);
  }

  /// 加密字符串（便捷方法）
  CiphertextEnvelope encryptString(String plaintext, Uint8List key, {
    Map<String, String>? aadMeta,
  }) {
    return encrypt(
      Uint8List.fromList(utf8.encode(plaintext)),
      key,
      aadMeta: aadMeta,
    );
  }

  /// 解密为字符串（便捷方法）
  String decryptString(CiphertextEnvelope envelope, Uint8List key) {
    final decrypted = decrypt(envelope, key);
    return utf8.decode(decrypted);
  }

  // ==================== 兼容旧格式 ====================

  /// 从旧格式 EncryptedData 加密（兼容 CryptoService 的调用方式）
  EncryptedBox encryptAESGCM(Uint8List plaintext, Uint8List key) {
    final suite = _policy.defaultSuite;
    final aead = _registry.getAead(suite.aeadId);
    if (aead == null) {
      throw StateError('AEAD "${suite.aeadId}" 未注册');
    }

    final nonce = generateRandomBytes(aead.nonceLength);
    return aead.seal(
      plaintext: plaintext,
      key: key,
      nonce: nonce,
    );
  }

  /// 从旧格式解密（兼容 CryptoService 的调用方式）
  Uint8List decryptAESGCM(EncryptedBox box, Uint8List key) {
    final suite = _policy.defaultSuite;
    final aead = _registry.getAead(suite.aeadId);
    if (aead == null) {
      throw StateError('AEAD "${suite.aeadId}" 未注册');
    }
    return aead.open(box: box, key: key);
  }

  // ==================== HKDF ====================

  /// HKDF-SHA256 密钥拉伸
  Uint8List hkdfSha256(
    Uint8List ikm, {
    Uint8List? salt,
    Uint8List? info,
    int length = 32,
  }) {
    return _hkdf.derive(ikm, salt: salt, info: info, length: length);
  }

  // ==================== HMAC ====================

  /// HMAC-SHA256
  Uint8List hmacSha256(Uint8List key, Uint8List data) {
    final hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
    return hmac.process(data);
  }

  /// HMAC-SHA256（字符串版本）
  String hmacSha256String(String key, String data) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final result = hmacSha256(
      Uint8List.fromList(keyBytes),
      Uint8List.fromList(dataBytes),
    );
    return base64Encode(result);
  }

  // ==================== 哈希 ====================

  /// SHA256 哈希
  Uint8List sha256Hash(Uint8List data) {
    return Uint8List.fromList(sha256.convert(data).bytes);
  }

  /// SHA256 哈希（字符串版本）
  String sha256String(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  // ==================== 常量时间操作 ====================

  /// 常量时间比较（防止时序攻击）
  bool constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// 常量时间比较（十六进制字符串版本）
  bool constantTimeEqualsHex(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  // ==================== 盲索引 ====================

  /// 生成搜索盲索引
  List<String> generateBlindIndexes(
    String plaintext,
    Uint8List searchKey, {
    int minTokenLength = 2,
  }) {
    final tokens = _tokenize(plaintext.toLowerCase(), minTokenLength);
    return tokens.map((token) {
      final hmacResult = hmacSha256(searchKey, Uint8List.fromList(utf8.encode(token)));
      return base64Encode(hmacResult);
    }).toList();
  }

  /// 分词
  List<String> _tokenize(String text, int minLength) {
    final tokens = <String>[];
    final words = text.split(RegExp(r'[\s\-_\.@]+'));
    for (final word in words) {
      if (word.length >= minLength) {
        tokens.add(word);
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
    return tokens.toSet().toList();
  }

  // ==================== 工具函数 ====================

  /// 字节转十六进制
  String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 十六进制转字节
  Uint8List hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  /// 安全清除内存缓冲区
  void clearBuffer(Uint8List buffer) {
    buffer.fillRange(0, buffer.length, 0x00);
    buffer.fillRange(0, buffer.length, 0xFF);
    buffer.fillRange(0, buffer.length, 0x00);
  }

  // ==================== 策略信息 ====================

  /// 获取当前策略引擎
  CryptoPolicyEngine get policy => _policy;

  /// 获取注册表
  CryptoRegistry get registry => _registry;

  /// 获取默认套件信息
  CryptoSuite get defaultSuite => _policy.defaultSuite;
}

/// 安全异常（防降级攻击等安全违规时抛出）
class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
