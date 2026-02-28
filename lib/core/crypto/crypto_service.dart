import 'dart:convert';
import 'dart:typed_data';
import 'crypto_core.dart';
import 'crypto_facade.dart';

/// Cryptographic Service for ZTD Password Manager (向后兼容层)
///
/// **已重构**：此类现在是 [CryptoFacade] 的薄包装层。
/// 所有加密算法通过可插拔的 Provider 注册表加载，
/// 不再硬编码具体算法实现。
///
/// 新代码应直接使用 [CryptoFacade]。
/// 此类保留是为了已有业务代码（KeyManager, EventStore,
/// DatabaseService, VaultService）的平滑过渡。
///
/// 架构层次：
/// - CryptoService (此类, 兼容层)
///   -> CryptoFacade (门面层)
///     -> CryptoRegistry + CryptoPolicyEngine (注册/策略)
///       -> Provider 实现 (aes_gcm, pbkdf2, hkdf...)
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;

  late final CryptoFacade _facade;

  CryptoService._internal() {
    _facade = CryptoFacade();
  }

  /// 获取底层 CryptoFacade（新代码推荐直接使用）
  CryptoFacade get facade => _facade;

  // ==================== 随机数生成 ====================

  /// 生成密码学安全随机字节
  Uint8List generateRandomBytes(int length) {
    return _facade.generateRandomBytes(length);
  }

  // ==================== Argon2id / KDF ====================

  /// Argon2id 参数（兼容旧接口）
  static const int defaultMemoryKB = 65536;
  static const int defaultIterations = 3;
  static const int defaultParallelism = 4;
  static const int defaultHashLength = 32;

  /// 从主密码派生 KEK（兼容旧签名）
  Uint8List deriveKEK(
    String password,
    Uint8List salt, {
    int memoryKB = defaultMemoryKB,
    int iterations = defaultIterations,
    int parallelism = defaultParallelism,
  }) {
    return _facade.deriveKEK(
      password,
      salt,
      params: KdfParams(
        kdfId: _facade.defaultSuite.kdfId,
        memoryKB: memoryKB,
        iterations: iterations,
        parallelism: parallelism,
      ),
    );
  }

  /// 基准测试设备（兼容旧接口，返回 Argon2Parameters）
  Argon2Parameters benchmarkDevice() {
    final kdfParams = _facade.calibrateKdf();
    return Argon2Parameters(
      memoryKB: kdfParams.memoryKB,
      iterations: kdfParams.iterations,
      parallelism: kdfParams.parallelism,
    );
  }

  // ==================== AES-256-GCM （兼容旧接口）====================

  /// 生成随机 DEK
  Uint8List generateDEK() => _facade.generateDEK();

  /// AES-256-GCM 加密（兼容旧 EncryptedData 格式）
  EncryptedData encryptAESGCM(Uint8List plaintext, Uint8List key) {
    final box = _facade.encryptAESGCM(plaintext, key);
    return EncryptedData(
      ciphertext: box.ciphertext,
      iv: box.nonce,
      authTag: box.authTag,
    );
  }

  /// AES-256-GCM 解密（兼容旧 EncryptedData 格式）
  Uint8List decryptAESGCM(EncryptedData encryptedData, Uint8List key) {
    final box = EncryptedBox(
      ciphertext: encryptedData.ciphertext,
      nonce: encryptedData.iv,
      authTag: encryptedData.authTag,
    );
    return _facade.decryptAESGCM(box, key);
  }

  /// 加密字符串（兼容旧接口）
  EncryptedData encryptString(String plaintext, Uint8List key) {
    return encryptAESGCM(Uint8List.fromList(utf8.encode(plaintext)), key);
  }

  /// 解密字符串（兼容旧接口）
  String decryptString(EncryptedData encryptedData, Uint8List key) {
    final decrypted = decryptAESGCM(encryptedData, key);
    return utf8.decode(decrypted);
  }

  // ==================== HKDF ====================

  /// HKDF-SHA256 密钥拉伸
  Uint8List hkdfSha256(
    Uint8List ikm, {
    Uint8List? salt,
    Uint8List? info,
    int length = 32,
  }) {
    return _facade.hkdfSha256(ikm, salt: salt, info: info, length: length);
  }

  // ==================== HMAC ====================

  /// HMAC-SHA256
  Uint8List hmacSha256(Uint8List key, Uint8List data) {
    return _facade.hmacSha256(key, data);
  }

  /// HMAC-SHA256（字符串版本）
  String hmacSha256String(String key, String data) {
    return _facade.hmacSha256String(key, data);
  }

  // ==================== 常量时间操作 ====================

  /// 常量时间比较
  bool constantTimeEquals(Uint8List a, Uint8List b) {
    return _facade.constantTimeEquals(a, b);
  }

  /// 常量时间比较（十六进制字符串）
  bool constantTimeEqualsHex(String a, String b) {
    return _facade.constantTimeEqualsHex(a, b);
  }

  // ==================== 哈希 ====================

  /// SHA256 哈希
  Uint8List sha256Hash(Uint8List data) {
    return _facade.sha256Hash(data);
  }

  /// SHA256 哈希（字符串版本）
  String sha256String(String data) {
    return _facade.sha256String(data);
  }

  // ==================== 盲索引 ====================

  /// 生成搜索盲索引
  List<String> generateBlindIndexes(
    String plaintext,
    Uint8List searchKey, {
    int minTokenLength = 2,
  }) {
    return _facade.generateBlindIndexes(
      plaintext,
      searchKey,
      minTokenLength: minTokenLength,
    );
  }

  // ==================== 工具函数 ====================

  /// 字节转十六进制
  String bytesToHex(Uint8List bytes) {
    return _facade.bytesToHex(bytes);
  }

  /// 十六进制转字节
  Uint8List hexToBytes(String hex) {
    return _facade.hexToBytes(hex);
  }

  /// 安全清除内存
  void clearBuffer(Uint8List buffer) {
    _facade.clearBuffer(buffer);
  }
}

/// Argon2id 参数（兼容旧代码）
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

  /// 转换为新的 KdfParams 格式
  KdfParams toKdfParams() => KdfParams(
        kdfId: 'pbkdf2-hmac-sha256',
        memoryKB: memoryKB,
        iterations: iterations,
        parallelism: parallelism,
      );
}

/// 加密数据容器（兼容旧代码）
///
/// 新代码应使用 [CiphertextEnvelope] 替代（包含算法元数据）。
class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List authTag;

  const EncryptedData({
    required this.ciphertext,
    required this.iv,
    required this.authTag,
  });

  /// 从旧格式 JSON 反序列化
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

  /// 序列化为单个字符串
  String serialize() {
    return base64Encode(utf8.encode(jsonEncode(toJson())));
  }

  factory EncryptedData.deserialize(String data) {
    final decoded = utf8.decode(base64Decode(data));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    return EncryptedData.fromJson(json);
  }

  /// 转换为新的 CiphertextEnvelope 格式
  CiphertextEnvelope toEnvelope({
    String suiteId = 'ZTDPM_LEGACY_V1',
    String aeadId = 'aes-256-gcm',
  }) {
    return CiphertextEnvelope(
      schemaVersion: 1,
      suiteId: suiteId,
      aeadId: aeadId,
      nonce: iv,
      ciphertext: ciphertext,
      authTag: authTag,
    );
  }

  /// 从 CiphertextEnvelope 转换回来（兼容旧代码）
  factory EncryptedData.fromEnvelope(CiphertextEnvelope envelope) {
    return EncryptedData(
      ciphertext: envelope.ciphertext,
      iv: envelope.nonce,
      authTag: envelope.authTag,
    );
  }
}
