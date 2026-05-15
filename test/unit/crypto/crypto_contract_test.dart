/// CryptoService 行为契约测试
///
/// 策略：测试加密/解密/哈希的"契约不变式"而非特定算法输出值。
/// 通用性：即使底层从 AES-GCM 换成 XChaCha20-Poly1305，
///         只要满足相同的加解密契约，这些测试不需任何修改。
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/crypto/crypto_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late CryptoService cs;

  setUp(() {
    cs = CryptoService();
  });

  // ==================== 随机性契约 ====================

  group('随机数生成 — 不可预测性契约', () {
    test('生成的字节长度正确', () {
      for (final len in [16, 32, 64]) {
        expect(cs.generateRandomBytes(len).length, equals(len));
      }
    });

    test('连续生成的随机字节互不相同', () {
      // 统计学保证：32字节相同的概率 = 2^(-256)
      final samples = List.generate(10, (_) => cs.generateRandomBytes(32));
      for (int i = 0; i < samples.length; i++) {
        for (int j = i + 1; j < samples.length; j++) {
          expect(samples[i], isNot(equals(samples[j])));
        }
      }
    });
  });

  // ==================== 对称加密契约 ====================

  group('AES-GCM — 加解密契约', () {
    test('加密后解密恢复原值（字节级）', () {
      final key = cs.generateRandomBytes(32);
      final plaintexts = [
        Uint8List.fromList([]), // 空明文
        Uint8List.fromList([0]), // 单字节
        cs.generateRandomBytes(1024), // 大块数据
        Uint8List.fromList(utf8.encode('Hello, 世界 🔐')), // Unicode
      ];
      for (final pt in plaintexts) {
        final encrypted = cs.encryptAESGCM(pt, key);
        final decrypted = cs.decryptAESGCM(encrypted, key);
        expect(decrypted, equals(pt));
      }
    });

    test('加密后解密恢复原值（字符串级）', () {
      final key = cs.generateRandomBytes(32);
      final strings = [
        '',
        'Simple ASCII',
        '中文测试 带特殊字符 @#\$%',
        '{"json": "payload", "nested": {"key": "value"}}',
        'A' * 10000, // 长字符串
      ];
      for (final s in strings) {
        expect(
          s,
          encryptsAndDecrypts(key, cs),
          reason: 'Failed for: "${s.substring(0, s.length > 30 ? 30 : s.length)}..."',
        );
      }
    });

    test('EncryptedData 结构完整', () {
      final key = cs.generateRandomBytes(32);
      final encrypted = cs.encryptAESGCM(utf8.encode('test'), key);
      expect(encrypted, isValidEncryptedData);
    });

    test('EncryptedData serialize/deserialize round-trip', () {
      final key = cs.generateRandomBytes(32);
      final encrypted = cs.encryptString('round-trip test', key);
      expect(encrypted, isSerializableEncryptedData);

      // 序列化后再解密，结果仍正确
      final serialized = encrypted.serialize();
      final deserialized = EncryptedData.deserialize(serialized);
      final decrypted = cs.decryptString(deserialized, key);
      expect(decrypted, equals('round-trip test'));
    });

    test('不同密钥无法解密', () {
      final key1 = cs.generateRandomBytes(32);
      final key2 = cs.generateRandomBytes(32);
      final encrypted = cs.encryptString('secret', key1);
      expect(() => cs.decryptString(encrypted, key2), throwsA(anything));
    });

    test('篡改密文导致解密失败', () {
      final key = cs.generateRandomBytes(32);
      final encrypted = cs.encryptString('integrity test', key);
      // 翻转一个比特
      final tampered = EncryptedData(
        ciphertext: Uint8List.fromList(encrypted.ciphertext.toList()..[0] ^= 0xFF),
        iv: encrypted.iv,
        authTag: encrypted.authTag,
      );
      expect(() => cs.decryptAESGCM(tampered, key), throwsA(anything));
    });

    test('相同明文+相同密钥，每次加密生成不同密文（IV 随机性）', () {
      final key = cs.generateRandomBytes(32);
      final e1 = cs.encryptString('determinism test', key);
      final e2 = cs.encryptString('determinism test', key);
      expect(e1.iv, isNot(equals(e2.iv)));
      expect(e1.ciphertext, isNot(equals(e2.ciphertext)));
    });
  });

  // ==================== HMAC 契约 ====================

  group('HMAC-SHA256 — 契约', () {
    test('相同输入产生相同输出（确定性）', () {
      final key = cs.generateRandomBytes(32);
      final data = Uint8List.fromList(utf8.encode('test'));
      final h1 = cs.hmacSha256(key, data);
      final h2 = cs.hmacSha256(key, data);
      expect(h1, equals(h2));
    });

    test('不同密钥产生不同 HMAC', () {
      final k1 = cs.generateRandomBytes(32);
      final k2 = cs.generateRandomBytes(32);
      final data = Uint8List.fromList(utf8.encode('test'));
      expect(cs.hmacSha256(k1, data), isNot(equals(cs.hmacSha256(k2, data))));
    });

    test('输出长度固定为 32 字节', () {
      final key = cs.generateRandomBytes(32);
      for (final len in [0, 1, 100, 10000]) {
        final data = cs.generateRandomBytes(len);
        expect(cs.hmacSha256(key, data).length, equals(32));
      }
    });
  });

  // ==================== HKDF 契约 ====================

  group('HKDF-SHA256 — 契约', () {
    test('输出长度可配置', () {
      final ikm = cs.generateRandomBytes(32);
      for (final len in [16, 32, 64]) {
        final derived = cs.hkdfSha256(ikm, length: len);
        expect(derived.length, equals(len));
      }
    });

    test('相同参数产生相同输出', () {
      final ikm = cs.generateRandomBytes(32);
      final salt = cs.generateRandomBytes(32);
      final info = Uint8List.fromList(utf8.encode('context'));
      final d1 = cs.hkdfSha256(ikm, salt: salt, info: info);
      final d2 = cs.hkdfSha256(ikm, salt: salt, info: info);
      expect(d1, equals(d2));
    });

    test('不同 info 产生不同输出（密钥隔离）', () {
      final ikm = cs.generateRandomBytes(32);
      final d1 = cs.hkdfSha256(ikm, info: Uint8List.fromList(utf8.encode('purpose-a')));
      final d2 = cs.hkdfSha256(ikm, info: Uint8List.fromList(utf8.encode('purpose-b')));
      expect(d1, isNot(equals(d2)));
    });
  });

  // ==================== SHA256 契约 ====================

  group('SHA256 — 契约', () {
    test('确定性：相同输入 → 相同哈希', () {
      final data = Uint8List.fromList(utf8.encode('hello'));
      expect(cs.sha256Hash(data), equals(cs.sha256Hash(data)));
    });

    test('输出固定 32 字节', () {
      expect(cs.sha256Hash(Uint8List(0)).length, equals(32));
      expect(cs.sha256Hash(cs.generateRandomBytes(10000)).length, equals(32));
    });

    test('字符串哈希与字节哈希一致', () {
      const data = 'test string';
      final fromString = cs.sha256String(data);
      final fromBytes = cs.bytesToHex(cs.sha256Hash(Uint8List.fromList(utf8.encode(data))));
      expect(fromString, equals(fromBytes));
    });
  });

  // ==================== 常量时间比较契约 ====================

  group('constantTimeEquals — 契约', () {
    test('相等数组返回 true', () {
      final a = Uint8List.fromList([1, 2, 3]);
      final b = Uint8List.fromList([1, 2, 3]);
      expect(cs.constantTimeEquals(a, b), isTrue);
    });

    test('不等数组返回 false', () {
      final a = Uint8List.fromList([1, 2, 3]);
      final b = Uint8List.fromList([1, 2, 4]);
      expect(cs.constantTimeEquals(a, b), isFalse);
    });

    test('不同长度返回 false', () {
      final a = Uint8List.fromList([1, 2]);
      final b = Uint8List.fromList([1, 2, 3]);
      expect(cs.constantTimeEquals(a, b), isFalse);
    });

    test('空数组比较', () {
      expect(cs.constantTimeEquals(Uint8List(0), Uint8List(0)), isTrue);
    });

    test('十六进制版本一致', () {
      final a = cs.generateRandomBytes(16);
      final hexA = cs.bytesToHex(a);
      expect(cs.constantTimeEqualsHex(hexA, hexA), isTrue);
      expect(cs.constantTimeEqualsHex(hexA, '0' * hexA.length), isFalse);
    });
  });

  // ==================== 盲索引契约 ====================

  group('盲索引 — 契约', () {
    test('相同输入+相同密钥 → 相同索引', () {
      final key = cs.generateRandomBytes(32);
      final idx1 = cs.generateBlindIndexes('test query', key);
      final idx2 = cs.generateBlindIndexes('test query', key);
      expect(idx1, equals(idx2));
    });

    test('不同密钥 → 不同索引', () {
      final k1 = cs.generateRandomBytes(32);
      final k2 = cs.generateRandomBytes(32);
      final idx1 = cs.generateBlindIndexes('test', k1);
      final idx2 = cs.generateBlindIndexes('test', k2);
      expect(idx1, isNot(equals(idx2)));
    });

    test('生成的索引非空', () {
      final key = cs.generateRandomBytes(32);
      final idx = cs.generateBlindIndexes('hello world', key);
      expect(idx, isNotEmpty);
    });
  });

  // ==================== 工具函数契约 ====================

  group('bytesToHex / hexToBytes — 互逆契约', () {
    test('round-trip', () {
      final bytes = cs.generateRandomBytes(32);
      final hex = cs.bytesToHex(bytes);
      final back = cs.hexToBytes(hex);
      expect(back, equals(bytes));
    });

    test('已知值', () {
      expect(cs.bytesToHex(Uint8List.fromList([0xAB, 0xCD])), equals('abcd'));
      expect(cs.hexToBytes('abcd'), equals(Uint8List.fromList([0xAB, 0xCD])));
    });
  });

  group('clearBuffer — 安全清除契约', () {
    test('清除后所有字节为零', () {
      final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      cs.clearBuffer(buffer);
      expect(buffer.every((b) => b == 0), isTrue);
    });
  });

  // ==================== DEK 生成契约 ====================

  group('DEK 生成 — 契约', () {
    test('DEK 长度为 32 字节', () {
      final dek = cs.generateDEK();
      expect(dek.length, equals(32));
    });

    test('每次生成不同的 DEK', () {
      final d1 = cs.generateDEK();
      final d2 = cs.generateDEK();
      expect(d1, isNot(equals(d2)));
    });
  });
}
