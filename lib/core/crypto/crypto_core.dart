import 'dart:convert';
import 'dart:typed_data';

/// 密码学模块核心接口与数据格式
///
/// 业务层只依赖此文件中的接口，不依赖具体算法实现。
/// 通过依赖注入 / 注册表加载具体 Provider。

// ==================== 抽象接口 ====================

/// KDF（密钥派生函数）接口
abstract interface class Kdf {
  /// 算法标识符，例如 "argon2id"、"pbkdf2-hmac-sha256"
  String get id;

  /// 基准测试，根据设备性能输出推荐参数
  KdfParams calibrate();

  /// 从密码派生密钥
  Uint8List deriveKey({
    required String password,
    required Uint8List salt,
    required KdfParams params,
    required int length,
  });
}

/// KDF 参数
class KdfParams {
  final String kdfId;
  final int memoryKB;
  final int iterations;
  final int parallelism;

  const KdfParams({
    required this.kdfId,
    this.memoryKB = 65536,
    this.iterations = 3,
    this.parallelism = 4,
  });

  Map<String, dynamic> toJson() => {
        'kdfId': kdfId,
        'memoryKB': memoryKB,
        'iterations': iterations,
        'parallelism': parallelism,
      };

  factory KdfParams.fromJson(Map<String, dynamic> json) {
    return KdfParams(
      kdfId: json['kdfId'] as String? ?? 'pbkdf2-hmac-sha256',
      memoryKB: json['memoryKB'] as int? ?? 65536,
      iterations: json['iterations'] as int? ?? 3,
      parallelism: json['parallelism'] as int? ?? 4,
    );
  }
}

/// AEAD（认证加密）接口
abstract interface class AeadCipher {
  /// 算法标识符，例如 "aes-256-gcm"、"xchacha20-poly1305"
  String get id;

  /// 推荐的 nonce 长度（字节）
  int get nonceLength;

  /// 加密
  EncryptedBox seal({
    required Uint8List plaintext,
    required Uint8List key,
    required Uint8List nonce,
    Uint8List? aad,
  });

  /// 解密
  Uint8List open({
    required EncryptedBox box,
    required Uint8List key,
    Uint8List? aad,
  });
}

/// 加密盒子（AEAD 输出）
class EncryptedBox {
  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List authTag;

  const EncryptedBox({
    required this.ciphertext,
    required this.nonce,
    required this.authTag,
  });
}

/// 密钥包装接口
abstract interface class KeyWrap {
  /// 算法标识符，例如 "aes-kw"、"rsa-oaep"
  String get id;

  /// 包装（加密）DEK
  Uint8List wrap({required Uint8List kek, required Uint8List dek});

  /// 解包（解密）DEK
  Uint8List unwrap({required Uint8List kek, required Uint8List wrappedDek});
}

/// 签名器接口
abstract interface class Signer {
  /// 算法标识符，例如 "ecdsa-p256-sha256"、"ed25519"
  String get id;

  /// 签名
  Uint8List sign(Uint8List message);

  /// 验签
  bool verify(Uint8List message, Uint8List signature);
}

/// 安全随机数生成器接口
abstract interface class Rng {
  /// 生成指定长度的随机字节
  Uint8List nextBytes(int length);
}

// ==================== 密文封装格式 ====================

/// 统一密文封装格式（Ciphertext Envelope）
///
/// 所有加密产物使用此自描述格式，包含：
/// - schemaVersion: 封装格式版本
/// - suiteId: 算法套件 ID
/// - kdfParams: KDF 参数
/// - keyVersion: 密钥版本
/// - nonce: 随机数
/// - ciphertext: 密文
/// - authTag: 认证标签
/// - aadMeta: AAD 绑定元数据
class CiphertextEnvelope {
  /// 封装格式版本（用于将来扩展字段）
  final int schemaVersion;

  /// 算法套件 ID
  final String suiteId;

  /// AEAD 算法标识
  final String aeadId;

  /// KDF 参数（可选，密钥直接提供时无需 KDF）
  final KdfParams? kdfParams;

  /// 密钥版本信息
  final KeyVersionInfo? keyInfo;

  /// Nonce / IV
  final Uint8List nonce;

  /// 密文
  final Uint8List ciphertext;

  /// 认证标签
  final Uint8List authTag;

  /// AAD 元数据（防止密文被剪切/重放）
  final Map<String, String>? aadMeta;

  const CiphertextEnvelope({
    this.schemaVersion = 1,
    required this.suiteId,
    required this.aeadId,
    this.kdfParams,
    this.keyInfo,
    required this.nonce,
    required this.ciphertext,
    required this.authTag,
    this.aadMeta,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'suiteId': suiteId,
        'aeadId': aeadId,
        if (kdfParams != null) 'kdfParams': kdfParams!.toJson(),
        if (keyInfo != null) 'keyInfo': keyInfo!.toJson(),
        'nonce': _bytesToBase64(nonce),
        'ciphertext': _bytesToBase64(ciphertext),
        'authTag': _bytesToBase64(authTag),
        if (aadMeta != null) 'aadMeta': aadMeta,
      };

  factory CiphertextEnvelope.fromJson(Map<String, dynamic> json) {
    return CiphertextEnvelope(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      suiteId: json['suiteId'] as String,
      aeadId: json['aeadId'] as String,
      kdfParams: json['kdfParams'] != null
          ? KdfParams.fromJson(json['kdfParams'] as Map<String, dynamic>)
          : null,
      keyInfo: json['keyInfo'] != null
          ? KeyVersionInfo.fromJson(json['keyInfo'] as Map<String, dynamic>)
          : null,
      nonce: _base64ToBytes(json['nonce'] as String),
      ciphertext: _base64ToBytes(json['ciphertext'] as String),
      authTag: _base64ToBytes(json['authTag'] as String),
      aadMeta: json['aadMeta'] != null
          ? Map<String, String>.from(json['aadMeta'] as Map)
          : null,
    );
  }

  // Base64 辅助（使用 dart:convert 标准实现）
  static String _bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  static Uint8List _base64ToBytes(String b64) {
    return base64Decode(b64);
  }
}

/// 密钥版本信息
class KeyVersionInfo {
  final int dekVersion;
  final String? kekBinding;

  const KeyVersionInfo({
    required this.dekVersion,
    this.kekBinding,
  });

  Map<String, dynamic> toJson() => {
        'dekVersion': dekVersion,
        if (kekBinding != null) 'kekBinding': kekBinding,
      };

  factory KeyVersionInfo.fromJson(Map<String, dynamic> json) {
    return KeyVersionInfo(
      dekVersion: json['dekVersion'] as int,
      kekBinding: json['kekBinding'] as String?,
    );
  }
}

// ==================== 算法套件 ====================

/// 算法套件定义
///
/// 将 AEAD + KDF + (可选的 KeyWrap + Signer) 组合为一个套件
class CryptoSuite {
  /// 套件 ID，例如 "ZTDPM_SUITE_2026_01"
  final String id;

  /// 人类可读名称
  final String displayName;

  /// AEAD 算法 ID
  final String aeadId;

  /// KDF 算法 ID
  final String kdfId;

  /// 密钥包装算法 ID（可选）
  final String? keyWrapId;

  /// 签名算法 ID（可选）
  final String? signerId;

  /// 最低安全等级（用于防降级）
  final int securityLevel;

  const CryptoSuite({
    required this.id,
    required this.displayName,
    required this.aeadId,
    required this.kdfId,
    this.keyWrapId,
    this.signerId,
    this.securityLevel = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'aeadId': aeadId,
        'kdfId': kdfId,
        if (keyWrapId != null) 'keyWrapId': keyWrapId,
        if (signerId != null) 'signerId': signerId,
        'securityLevel': securityLevel,
      };

  factory CryptoSuite.fromJson(Map<String, dynamic> json) {
    return CryptoSuite(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      aeadId: json['aeadId'] as String,
      kdfId: json['kdfId'] as String,
      keyWrapId: json['keyWrapId'] as String?,
      signerId: json['signerId'] as String?,
      securityLevel: json['securityLevel'] as int? ?? 1,
    );
  }
}
