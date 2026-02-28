import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// HKDF-SHA256 密钥派生
///
/// 用于密钥拉伸（Key Stretching），不是密码派生。
/// 从 IKM（Input Keying Material）派生指定用途的子密钥。
class HkdfProvider {
  static const String id = 'hkdf-sha256';

  /// 从输入密钥材料派生密钥
  ///
  /// [ikm]: 输入密钥材料
  /// [salt]: 盐值（可选）
  /// [info]: 上下文信息（区分不同用途的子密钥）
  /// [length]: 输出密钥长度（字节）
  Uint8List derive(
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
}
