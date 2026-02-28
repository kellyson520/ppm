import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../crypto_core.dart';

/// AES-256-GCM AEAD 算法实现
///
/// 特性：
/// - 256-bit 密钥
/// - 96-bit (12字节) nonce
/// - 128-bit (16字节) 认证标签
/// - 硬件加速友好（AES-NI）
class AesGcmProvider implements AeadCipher {
  @override
  String get id => 'aes-256-gcm';

  @override
  int get nonceLength => 12; // 96-bit nonce

  @override
  EncryptedBox seal({
    required Uint8List plaintext,
    required Uint8List key,
    required Uint8List nonce,
    Uint8List? aad,
  }) {
    assert(key.length == 32, 'AES-256 requires 32-byte key');
    assert(nonce.length == 12, 'GCM requires 12-byte nonce');

    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        true, // encrypt
        AEADParameters(
          KeyParameter(key),
          128, // auth tag size in bits
          nonce,
          aad ?? Uint8List(0),
        ),
      );

    final output = gcm.process(plaintext);

    // PointyCastle 将 auth tag 附加在密文末尾（最后 16 字节）
    final authTag = output.sublist(output.length - 16);
    final ciphertext = output.sublist(0, output.length - 16);

    return EncryptedBox(
      ciphertext: ciphertext,
      nonce: nonce,
      authTag: authTag,
    );
  }

  @override
  Uint8List open({
    required EncryptedBox box,
    required Uint8List key,
    Uint8List? aad,
  }) {
    assert(key.length == 32, 'AES-256 requires 32-byte key');

    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        false, // decrypt
        AEADParameters(
          KeyParameter(key),
          128,
          box.nonce,
          aad ?? Uint8List(0),
        ),
      );

    // 拼接 ciphertext + authTag（PointyCastle 期望的格式）
    final combined = Uint8List.fromList([
      ...box.ciphertext,
      ...box.authTag,
    ]);

    return gcm.process(combined);
  }
}
