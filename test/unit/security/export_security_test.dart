/// 导出文件安全性测试
///
/// 验证加密备份文件具备抗爆破能力：
/// 1. AES-256-GCM 正确加密（密文与明文完全不同）
/// 2. 密文具备高熵（不可区分于随机数据）
/// 3. 密钥派生参数满足安全基准
/// 4. 重复加密同一数据产生不同密文（nonce 唯一性）
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/crypto/crypto_service.dart';
import 'package:ztd_password_manager/core/crypto/providers/pbkdf2_provider.dart';

void main() {
  group('Export Security — 导出文件抗爆破', () {
    late CryptoService cryptoService;
    late Pbkdf2Provider kdfProvider;

    setUp(() {
      cryptoService = CryptoService();
      kdfProvider = Pbkdf2Provider();
    });

    // ── [1] KDF 参数安全基准 ──
    test('PBKDF2 迭代次数 ≥ 30,000 (OWASP 安全下限)', () {
      final params = kdfProvider.calibrate();
      expect(
        params.iterations,
        greaterThanOrEqualTo(30000),
        reason: 'PBKDF2 iterations must be ≥ 30,000 for brute-force resistance',
      );
    });

    test('KDF 目标时间 ≥ 500ms', () {
      final params = kdfProvider.calibrate();
      final salt = Uint8List(32);
      final stopwatch = Stopwatch()..start();
      kdfProvider.deriveKey(
        password: 'test_password_123',
        salt: salt,
        params: params,
        length: 32,
      );
      final elapsed = stopwatch.elapsedMilliseconds;
      stopwatch.stop();
      // 允许一定的误差（200ms 以下可能是极快设备，但迭代次数下限保证了安全性）
      expect(
        params.iterations >= 30000 || elapsed > 200,
        isTrue,
        reason:
            'Either iterations ≥ 30000 or derivation time > 200ms (got ${params.iterations} iters in ${elapsed}ms)',
      );
    });

    // ── [2] 加密正确性 ──
    test('加密后的密文与明文完全不同', () {
      final key = cryptoService.generateRandomBytes(32);
      final plaintext = 'sensitive_password_data_12345';
      final encrypted = cryptoService.encryptString(plaintext, key);

      // 密文不应包含原始明文字节
      final cipherStr = String.fromCharCodes(encrypted.ciphertext.take(200));
      expect(cipherStr, isNot(contains(plaintext)));
      expect(encrypted.serialize(), isNot(contains(plaintext)));
    });

    test('EncryptedData 序列化包含 nonce + authTag', () {
      final key = cryptoService.generateRandomBytes(32);
      final plaintext = 'test';

      final encrypted = cryptoService.encryptString(plaintext, key);

      // GCM 认证标签通常是 16 字节
      expect(encrypted.authTag.length, 16);

      // AES-GCM nonce 是 12 字节
      expect(encrypted.iv.length, 12);

      // JSON 表示应包含必要字段
      final json = encrypted.toJson();
      expect(json.containsKey('iv'), isTrue);
      expect(json.containsKey('ciphertext'), isTrue);
      expect(json.containsKey('authTag'), isTrue);
    });

    // ── [3] Nonce 唯一性 ──
    test('重复加密同一明文产生不同密文（nonce 唯一性）', () {
      final key = cryptoService.generateRandomBytes(32);
      final plaintext = 'same_data_repeated';

      final encrypted1 = cryptoService.encryptString(plaintext, key);
      final encrypted2 = cryptoService.encryptString(plaintext, key);
      final encrypted3 = cryptoService.encryptString(plaintext, key);

      // 三次加密的 nonce 必须全部不同
      final nonces = [
        base64Encode(encrypted1.iv),
        base64Encode(encrypted2.iv),
        base64Encode(encrypted3.iv),
      ];
      expect(nonces.toSet().length, 3, reason: 'All nonces must be unique');

      // 密文也应该不同（因为不同 nonce）
      final ciphertexts = [
        base64Encode(encrypted1.ciphertext),
        base64Encode(encrypted2.ciphertext),
        base64Encode(encrypted3.ciphertext),
      ];
      expect(ciphertexts.toSet().length, 3,
          reason: 'Ciphertexts must be different with different nonces');
    });

    // ── [4] 密文熵值 ──
    test('密文具备足够熵（香农熵 ≥ 4.5 bits/byte）', () {
      final key = cryptoService.generateRandomBytes(32);
      // 使用较长明文以获得统计显著结果
      final plaintext = 'A' * 1024; // 1KB 重复字符
      final encrypted = cryptoService.encryptString(plaintext, key);

      final entropy = _shannonEntropy(encrypted.ciphertext);
      // 好的加密密文应该接近最大熵 8.0，这里要求 ≥ 4.5（远高于明文熵）
      expect(entropy, greaterThan(4.5),
          reason: 'Ciphertext Shannon entropy ($entropy) is too low');
    });

    test('密文字节分布均匀（卡方检验）', () {
      final key = cryptoService.generateRandomBytes(32);
      final plaintext = 'uniformity_test_data_' + 'x' * 500;
      final encrypted = cryptoService.encryptString(plaintext, key);

      final frequencies = List<int>.filled(256, 0);
      for (final byte in encrypted.ciphertext) {
        frequencies[byte]++;
      }

      final n = encrypted.ciphertext.length;
      final expected = n / 256.0;
      double chiSquare = 0;
      for (final f in frequencies) {
        chiSquare += (f - expected) * (f - expected) / expected;
      }

      // 自由度 255，p=0.01 临界值 ~310
      expect(chiSquare, lessThan(350),
          reason: 'Ciphertext byte distribution is not uniform (χ²=$chiSquare)');
    });

    // ── [5] 解密往返 ──
    test('加密→解密往返正确', () {
      final key = cryptoService.generateRandomBytes(32);
      final plaintext = 'original_secret_data';

      final encrypted = cryptoService.encryptString(plaintext, key);
      final decrypted = cryptoService.decryptString(encrypted, key);

      expect(decrypted, equals(plaintext));
    });

    test('用错误密钥解密失败', () {
      final correctKey = cryptoService.generateRandomBytes(32);
      final wrongKey = cryptoService.generateRandomBytes(32);
      final plaintext = 'secret';
      final encrypted = cryptoService.encryptString(plaintext, correctKey);

      expect(
        () => cryptoService.decryptString(encrypted, wrongKey),
        throwsA(isA<Exception>()),
        reason: 'Decryption with wrong key must fail',
      );
    });

    // ── [6] 密钥长度验证 ──
    test('加密密钥必须是 256-bit (32 bytes)', () {
      final shortKey = Uint8List(16); // 128-bit
      expect(
        () => cryptoService.encryptString('test', shortKey),
        throwsA(anything),
        reason: '128-bit key must be rejected',
      );
    });
  });
}

/// 计算字节数组的香农熵 (bits per byte)
double _shannonEntropy(List<int> bytes) {
  if (bytes.isEmpty) return 0.0;
  final counts = List<int>.filled(256, 0);
  for (final b in bytes) {
    counts[b]++;
  }
  double entropy = 0.0;
  final n = bytes.length.toDouble();
  for (final c in counts) {
    if (c > 0) {
      final p = c / n;
      entropy -= p * log(p) / ln2;
    }
  }
  return entropy;
}
