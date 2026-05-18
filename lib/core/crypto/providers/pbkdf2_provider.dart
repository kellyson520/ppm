import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../crypto_core.dart';

/// PBKDF2-HMAC-SHA256 KDF 实现
///
/// 作为 Argon2id 的降级替代（Argon2id 需要原生 FFI 支持）。
/// 生产环境建议：当平台支持 Argon2id 时，应使用 Argon2idProvider 替换。
///
/// OWASP 2024 建议 PBKDF2-HMAC-SHA256 最低 600,000 次迭代。
/// 移动设备妥协值：高端 120,000 / 中端 60,000 / 低端 30,000。
class Pbkdf2Provider implements Kdf {
  @override
  String get id => 'pbkdf2-hmac-sha256';

  /// 目标派生时间 (ms) — 设备越慢，迭代次数越低，但始终 ≥ 安全下限
  static const int _targetMs = 600;
  static const int _minIterations = 30000; // 绝对安全下限

  @override
  KdfParams calibrate() {
    final stopwatch = Stopwatch()..start();

    // 用 500 次迭代做基准，推断目标迭代次数
    const benchmarkIterations = 500;
    final testSalt = Uint8List(32);
    deriveKey(
      password: 'benchmark_test',
      salt: testSalt,
      params: KdfParams(
        kdfId: id,
        memoryKB: 65536,
        iterations: benchmarkIterations,
        parallelism: 4,
      ),
      length: 32,
    );

    final elapsedMs = stopwatch.elapsedMilliseconds;
    stopwatch.stop();

    // 根据基准推算目标迭代次数
    int targetIterations;
    if (elapsedMs > 0) {
      targetIterations = (benchmarkIterations * _targetMs / elapsedMs).round();
    } else {
      targetIterations = 120000; // 极快设备兜底
    }

    // 确保不低于安全下限
    if (targetIterations < _minIterations) {
      targetIterations = _minIterations;
    }

    // 根据性能分档决定并行度
    int parallelism;
    int memoryKB;
    if (elapsedMs < 20) {
      parallelism = 4;
      memoryKB = 131072; // 128 MB
    } else if (elapsedMs < 80) {
      parallelism = 2;
      memoryKB = 65536; // 64 MB
    } else {
      parallelism = 1;
      memoryKB = 32768; // 32 MB
    }

    return KdfParams(
      kdfId: id,
      memoryKB: memoryKB,
      iterations: targetIterations,
      parallelism: parallelism,
    );
  }

  @override
  Uint8List deriveKey({
    required String password,
    required Uint8List salt,
    required KdfParams params,
    required int length,
  }) {
    final passwordBytes = utf8.encode(password);

    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));

    derivator.init(
      Pbkdf2Parameters(
        salt,
        params.iterations, // 直接使用，不再乘 1000
        length,
      ),
    );

    return derivator.process(Uint8List.fromList(passwordBytes));
  }
}
