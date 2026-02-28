import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// TOTP (Time-Based One-Time Password) 计算器
///
/// 实现 RFC 6238 标准，纯 Dart 实现，无外部依赖
/// 支持 SHA1, SHA256, SHA512 算法
class TOTPGenerator {
  /// 生成 TOTP 验证码
  ///
  /// [secret]: Base32 编码的密钥
  /// [algorithm]: 哈希算法 (SHA1, SHA256, SHA512)
  /// [digits]: 验证码位数 (6 或 8)
  /// [period]: 刷新周期(秒)
  /// [timeMs]: 自定义时间戳(毫秒)，默认当前时间
  static String generateCode(
    String secret, {
    String algorithm = 'SHA1',
    int digits = 6,
    int period = 30,
    int? timeMs,
  }) {
    final time = timeMs ?? DateTime.now().millisecondsSinceEpoch;
    final timeStep = (time ~/ 1000) ~/ period;

    // 将 timeStep 转换为 8 字节 big-endian
    final timeBytes = Uint8List(8);
    var remaining = timeStep;
    for (var i = 7; i >= 0; i--) {
      timeBytes[i] = remaining & 0xFF;
      remaining >>= 8;
    }

    // Base32 解码密钥
    final keyBytes = _base32Decode(secret);

    // 计算 HMAC
    final hmacResult = _computeHmac(algorithm, keyBytes, timeBytes);

    // Dynamic truncation (RFC 4226)
    final offset = hmacResult[hmacResult.length - 1] & 0x0F;
    final code = ((hmacResult[offset] & 0x7F) << 24) |
        ((hmacResult[offset + 1] & 0xFF) << 16) |
        ((hmacResult[offset + 2] & 0xFF) << 8) |
        (hmacResult[offset + 3] & 0xFF);

    // 取模获取指定位数
    final otp = code % _pow10(digits);

    return otp.toString().padLeft(digits, '0');
  }

  /// 计算当前周期剩余秒数
  static int getRemainingSeconds({int period = 30}) {
    final currentSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return period - (currentSeconds % period);
  }

  /// 获取当前周期进度 (0.0 ~ 1.0)
  static double getProgress({int period = 30}) {
    final currentSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (currentSeconds % period) / period;
  }

  /// 计算 HMAC
  static List<int> _computeHmac(
      String algorithm, Uint8List key, Uint8List data) {
    Hash hashAlgo;
    switch (algorithm.toUpperCase()) {
      case 'SHA256':
        hashAlgo = sha256;
        break;
      case 'SHA512':
        hashAlgo = sha512;
        break;
      case 'SHA1':
      default:
        hashAlgo = sha1;
        break;
    }

    final hmacInstance = Hmac(hashAlgo, key);
    return hmacInstance.convert(data).bytes;
  }

  /// Base32 解码
  static Uint8List _base32Decode(String input) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

    // 清理输入，移除空格和等号填充
    final cleanInput = input.replaceAll(RegExp(r'[\s=]'), '').toUpperCase();

    final output = <int>[];
    var buffer = 0;
    var bitsLeft = 0;

    for (var i = 0; i < cleanInput.length; i++) {
      final charIndex = base32Chars.indexOf(cleanInput[i]);
      if (charIndex < 0) continue; // 跳过无效字符

      buffer = (buffer << 5) | charIndex;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        output.add((buffer >> (bitsLeft - 8)) & 0xFF);
        bitsLeft -= 8;
      }
    }

    return Uint8List.fromList(output);
  }

  /// Base32 编码
  static String base32Encode(Uint8List data) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

    final buffer = StringBuffer();
    var currentByte = 0;
    var bitsRemaining = 0;

    for (final byte in data) {
      currentByte = (currentByte << 8) | byte;
      bitsRemaining += 8;

      while (bitsRemaining >= 5) {
        buffer.write(base32Chars[(currentByte >> (bitsRemaining - 5)) & 0x1F]);
        bitsRemaining -= 5;
      }
    }

    if (bitsRemaining > 0) {
      buffer.write(base32Chars[(currentByte << (5 - bitsRemaining)) & 0x1F]);
    }

    return buffer.toString();
  }

  /// 10 的 n 次幂
  static int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}
