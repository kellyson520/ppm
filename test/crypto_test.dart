import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/crypto/crypto_service.dart';

void main() {
  group('CryptoService Tests', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoService();
    });

    test('generateRandomBytes produces different values', () {
      final bytes1 = cryptoService.generateRandomBytes(32);
      final bytes2 = cryptoService.generateRandomBytes(32);
      
      expect(bytes1.length, equals(32));
      expect(bytes2.length, equals(32));
      expect(bytes1, isNot(equals(bytes2)));
    });

    test('AES-256-GCM encryption and decryption', () {
      final key = cryptoService.generateRandomBytes(32);
      final plaintext = utf8.encode('Hello, World!');
      
      final encrypted = cryptoService.encryptAESGCM(plaintext, key);
      final decrypted = cryptoService.decryptAESGCM(encrypted, key);
      
      expect(decrypted, equals(plaintext));
    });

    test('string encryption and decryption', () {
      final key = cryptoService.generateRandomBytes(32);
      final plaintext = 'Secret message';
      
      final encrypted = cryptoService.encryptString(plaintext, key);
      final decrypted = cryptoService.decryptString(encrypted, key);
      
      expect(decrypted, equals(plaintext));
    });

    test('HKDF key derivation', () {
      final ikm = Uint8List.fromList(utf8.encode('input key material'));
      final salt = cryptoService.generateRandomBytes(32);
      final info = utf8.encode('context info');
      
      final derived = cryptoService.hkdfSha256(
        ikm,
        salt: salt,
        info: Uint8List.fromList(info),
        length: 32,
      );
      
      expect(derived.length, equals(32));
    });

    test('HMAC-SHA256', () {
      final key = cryptoService.generateRandomBytes(32);
      final data = utf8.encode('test data');
      
      final hmac = cryptoService.hmacSha256(key, data);
      
      expect(hmac.length, equals(32));
    });

    test('constantTimeEquals returns true for equal arrays', () {
      final a = Uint8List.fromList([1, 2, 3, 4, 5]);
      final b = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      expect(cryptoService.constantTimeEquals(a, b), isTrue);
    });

    test('constantTimeEquals returns false for different arrays', () {
      final a = Uint8List.fromList([1, 2, 3, 4, 5]);
      final b = Uint8List.fromList([1, 2, 3, 4, 6]);
      
      expect(cryptoService.constantTimeEquals(a, b), isFalse);
    });

    test('constantTimeEquals returns false for different lengths', () {
      final a = Uint8List.fromList([1, 2, 3, 4, 5]);
      final b = Uint8List.fromList([1, 2, 3, 4]);
      
      expect(cryptoService.constantTimeEquals(a, b), isFalse);
    });

    test('SHA256 hash', () {
      final data = utf8.encode('test');
      final hash = cryptoService.sha256Hash(data);
      
      expect(hash.length, equals(32));
    });

    test('blind index generation', () {
      final searchKey = cryptoService.generateRandomBytes(32);
      final plaintext = 'test password entry';
      
      final indexes = cryptoService.generateBlindIndexes(plaintext, searchKey);
      
      expect(indexes, isNotEmpty);
      expect(indexes.length, greaterThan(1));
    });

    test('bytes to hex conversion', () {
      final bytes = Uint8List.fromList([0xAB, 0xCD, 0xEF]);
      final hex = cryptoService.bytesToHex(bytes);
      
      expect(hex, equals('abcdef'));
    });

    test('hex to bytes conversion', () {
      final hex = 'abcdef';
      final bytes = cryptoService.hexToBytes(hex);
      
      expect(bytes, equals(Uint8List.fromList([0xAB, 0xCD, 0xEF])));
    });

    test('clearBuffer overwrites data', () {
      final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
      cryptoService.clearBuffer(buffer);
      
      expect(buffer.every((b) => b == 0), isTrue);
    });
  });

  group('EncryptedData Tests', () {
    test('serialization and deserialization', () {
      final data = EncryptedData(
        ciphertext: Uint8List.fromList([1, 2, 3]),
        iv: Uint8List.fromList([4, 5, 6]),
        authTag: Uint8List.fromList([7, 8, 9]),
      );
      
      final serialized = data.serialize();
      final deserialized = EncryptedData.deserialize(serialized);
      
      expect(deserialized.ciphertext, equals(data.ciphertext));
      expect(deserialized.iv, equals(data.iv));
      expect(deserialized.authTag, equals(data.authTag));
    });
  });
}
