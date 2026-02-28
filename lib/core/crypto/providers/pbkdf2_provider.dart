import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../crypto_core.dart';

/// PBKDF2-HMAC-SHA256 KDF 实现
///
/// 作为 Argon2id 的降级替代（Argon2id 需要原生 FFI 支持）。
/// 生产环境建议：当平台支持 Argon2id 时，应使用 Argon2idProvider 替换。
///
/// 安全参数基准：
/// - iterations: 3000 (PBKDF2 等效参数)
/// - salt: 32 bytes
/// - output: 32 bytes (256-bit)
class Pbkdf2Provider implements Kdf {
  @override
  String get id => 'pbkdf2-hmac-sha256';

  /// 默认参数
  static const int _defaultIterations = 3;
  static const int _defaultMemoryKB = 65536;
  static const int _defaultParallelism = 4;

  @override
  KdfParams calibrate() {
    final stopwatch = Stopwatch()..start();

    // 使用最小参数进行基准测试
    final testSalt = Uint8List(32);
    deriveKey(
      password: 'benchmark_test',
      salt: testSalt,
      params: KdfParams(
        kdfId: id,
        memoryKB: 16384,
        iterations: 1,
        parallelism: 1,
      ),
      length: 32,
    );

    final elapsedMs = stopwatch.elapsedMilliseconds;
    stopwatch.stop();

    // 根据性能确定参数
    // 目标：500ms - 1000ms 的密钥派生时间
    if (elapsedMs < 50) {
      // 高端设备
      return KdfParams(
        kdfId: id,
        memoryKB: 131072, // 128 MB
        iterations: 4,
        parallelism: 4,
      );
    } else if (elapsedMs < 200) {
      // 中端设备
      return KdfParams(
        kdfId: id,
        memoryKB: _defaultMemoryKB,
        iterations: _defaultIterations,
        parallelism: _defaultParallelism,
      );
    } else {
      // 低端设备
      return KdfParams(
        kdfId: id,
        memoryKB: 32768,
        iterations: 2,
        parallelism: 2,
      );
    }
  }

  @override
  Uint8List deriveKey({
    required String password,
    required Uint8List salt,
    required KdfParams params,
    required int length,
  }) {
    final passwordBytes = utf8.encode(password);

    final derivator = PBKDF2KeyDerivator(
      HMac(SHA256Digest(), 64),
    );

    derivator.init(Pbkdf2Parameters(
      salt,
      params.iterations * 1000, // 将 Argon2id 等效 iterations 放大
      length,
    ));

    return derivator.process(Uint8List.fromList(passwordBytes));
  }
}
