import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/crypto/file_crypto_service.dart';
import 'package:ztd_password_manager/core/crypto/crypto_facade.dart';

void main() {
  group('FileCryptoService — ZTDF 文件加密安全测试', () {
    late FileCryptoService service;
    late CryptoFacade facade;
    late Uint8List sessionDEK;

    setUp(() {
      facade = CryptoFacade();
      service = FileCryptoService(facade: facade);
      sessionDEK = facade.generateRandomBytes(32);
    });

    // ── [1] 加密正确性 ──
    test('加密→解密往返一致（小文件）', () {
      final plaintext = Uint8List.fromList('Hello, ZTDF!'.codeUnits);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'test.txt', plaintext: plaintext);
      final result = service.decrypt(sessionDEK: sessionDEK, envelope: envelope);
      expect(result.bytes, equals(plaintext));
      expect(result.fileName, equals('test.txt'));
    });

    test('加密→解密往返一致（大文件 1MB+）', () {
      final plaintext = facade.generateRandomBytes(1024 * 1024 + 777);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'large.bin', plaintext: plaintext);
      final result = service.decrypt(sessionDEK: sessionDEK, envelope: envelope);
      expect(result.bytes, equals(plaintext));
    });

    // ── [2] 安全性 ──
    test('错误密钥解密失败', () {
      final plaintext = Uint8List.fromList('secret'.codeUnits);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'x', plaintext: plaintext);
      final wrongDEK = facade.generateRandomBytes(32);
      expect(
        () => service.decrypt(sessionDEK: wrongDEK, envelope: envelope),
        throwsA(isA<Exception>()),
      );
    });

    test('错误 magic 解密失败', () {
      final plaintext = Uint8List.fromList('data'.codeUnits);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'x', plaintext: plaintext);
      // Corrupt magic
      final corrupted = Uint8List.fromList(envelope);
      corrupted[0] = 0x00;
      expect(
        () => service.decrypt(sessionDEK: sessionDEK, envelope: corrupted),
        throwsA(isA<Exception>()),
      );
    });

    // ── [3] Nonce 唯一性 ──
    test('同一文件重复加密 → 不同密文（文件级 nonce 唯一）', () {
      final plaintext = Uint8List.fromList('repeat'.codeUnits);
      final e1 = service.encrypt(sessionDEK: sessionDEK, fileName: 'a', plaintext: plaintext);
      final e2 = service.encrypt(sessionDEK: sessionDEK, fileName: 'a', plaintext: plaintext);
      final e3 = service.encrypt(sessionDEK: sessionDEK, fileName: 'a', plaintext: plaintext);
      expect(e1, isNot(equals(e2)));
      expect(e2, isNot(equals(e3)));
      expect(e1, isNot(equals(e3)));
    });

    // ── [4] 防篡改 ──
    test('修改密文 1 字节 → 解密失败（GCM auth tag 检测）', () {
      final plaintext = facade.generateRandomBytes(1024);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'f', plaintext: plaintext);
      final corrupted = Uint8List.fromList(envelope);
      // Flip a byte in the middle of the first chunk
      corrupted[corrupted.length ~/ 2] ^= 0xFF;
      expect(
        () => service.decrypt(sessionDEK: sessionDEK, envelope: corrupted),
        throwsA(isA<Exception>()),
      );
    });

    test('截断密文 → 解密失败', () {
      final plaintext = facade.generateRandomBytes(2048);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'f', plaintext: plaintext);
      final truncated = Uint8List.fromList(envelope.sublist(0, envelope.length - 20));
      expect(
        () => service.decrypt(sessionDEK: sessionDEK, envelope: truncated),
        throwsA(isA<Exception>()),
      );
    });

    // ── [5] 熵检验 ──
    test('密文香农熵 ≥ 4.5 bits/byte', () {
      final plaintext = Uint8List(2048); // all zeros
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'e', plaintext: plaintext);
      // Skip header (66 bytes) + encrypted metadata
      final metaLen = _read32LE(envelope, 50);
      final dataStart = 66 + 12 + metaLen; // header + metaIv(12) + metaCipher
      if (dataStart >= envelope.length) return; // edge case
      final data = envelope.sublist(dataStart);
      final entropy = _shannonEntropy(data);
      expect(entropy, greaterThan(4.5), reason: 'Entropy $entropy too low');
    });

    test('卡方均匀性检验', () {
      final plaintext = Uint8List(4096); // all zeros
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'f', plaintext: plaintext);
      final metaLen = _read32LE(envelope, 50);
      final dataStart = 66 + 12 + metaLen;
      final data = envelope.sublist(dataStart);
      final chi = _chiSquare(data);
      expect(chi, lessThan(350), reason: 'Chi-square $chi too high (non-uniform)');
    });

    // ── [6] 边界条件 ──
    test('空文件加密/解密', () {
      final plaintext = Uint8List(0);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'empty', plaintext: plaintext);
      final result = service.decrypt(sessionDEK: sessionDEK, envelope: envelope);
      expect(result.bytes, isEmpty);
    });

    test('单字节文件加密/解密', () {
      final plaintext = Uint8List.fromList([42]);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'one', plaintext: plaintext);
      final result = service.decrypt(sessionDEK: sessionDEK, envelope: envelope);
      expect(result.bytes, equals(plaintext));
    });

    test('精确 64KB 边界对齐', () {
      final plaintext = facade.generateRandomBytes(65536);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: '64k', plaintext: plaintext, chunkSize: 65536);
      final result = service.decrypt(sessionDEK: sessionDEK, envelope: envelope);
      expect(result.bytes, equals(plaintext));
    });

    // ── [7] 元数据保护 ──
    test('文件名正确保留在加密元数据中', () {
      final plaintext = Uint8List.fromList('content'.codeUnits);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: '机密文档.pdf', plaintext: plaintext);
      // 验证 envelope 中不包含明文文件名
      final envelopeStr = String.fromCharCodes(envelope.take(200));
      expect(envelopeStr, isNot(contains('机密文档.pdf')));
      // 解密后文件名恢复
      final result = service.decrypt(sessionDEK: sessionDEK, envelope: envelope);
      expect(result.fileName, equals('机密文档.pdf'));
    });

    // ── [8] 导出/导入往返 ──
    test('加密→保存到字节→重新加载→解密 往返', () {
      final plaintext = facade.generateRandomBytes(50000);
      final envelope = service.encrypt(sessionDEK: sessionDEK, fileName: 'export_test.dat', plaintext: plaintext);
      // 模拟保存到文件再加载
      final reloaded = Uint8List.fromList(envelope);
      final result = service.decrypt(sessionDEK: sessionDEK, envelope: reloaded);
      expect(result.bytes, equals(plaintext));
      expect(result.fileName, equals('export_test.dat'));
    });
  });
}

// ── Helper functions ──

double _shannonEntropy(List<int> bytes) {
  if (bytes.isEmpty) return 0;
  final counts = List.filled(256, 0);
  for (final b in bytes) counts[b]++;
  double e = 0;
  final n = bytes.length.toDouble();
  for (final c in counts) {
    if (c > 0) {
      final p = c / n;
      e -= p * log(p) / ln2;
    }
  }
  return e;
}

double _chiSquare(List<int> bytes) {
  if (bytes.isEmpty) return 0;
  final counts = List.filled(256, 0);
  for (final b in bytes) counts[b]++;
  final n = bytes.length / 256.0;
  double chi = 0;
  for (final c in counts) {
    chi += (c - n) * (c - n) / n;
  }
  return chi;
}

int _read32LE(Uint8List d, int o) => d.buffer.asByteData().getUint32(o, Endian.little);
