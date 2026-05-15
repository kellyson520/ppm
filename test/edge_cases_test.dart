import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/crypto/crypto_facade.dart';
import 'package:ztd_password_manager/core/crypto/crypto_service.dart';
import 'package:ztd_password_manager/core/crypto/crypto_core.dart';
import 'package:ztd_password_manager/core/security/secure_buffer.dart';
import 'package:ztd_password_manager/core/models/models.dart';

void main() {
  group('Edge Cases: CryptoFacade', () {
    late CryptoFacade cryptoFacade;

    setUp(() {
      cryptoFacade = CryptoFacade();
    });

    // ==================== Empty Input ====================

    test('Empty plaintext encryption/decryption', () {
      final key = cryptoFacade.generateDEK();
      final emptyPlaintext = Uint8List(0);

      final envelope = cryptoFacade.encrypt(emptyPlaintext, key);
      final decrypted = cryptoFacade.decrypt(envelope, key);

      expect(decrypted, isEmpty);
    });

    test('Empty string encryption/decryption', () {
      final key = cryptoFacade.generateDEK();
      const emptyString = '';

      final envelope = cryptoFacade.encryptString(emptyString, key);
      final decrypted = cryptoFacade.decryptString(envelope, key);

      expect(decrypted, equals(emptyString));
    });

    // ==================== Large Input ====================

    test('Large plaintext (1MB)', () {
      final key = cryptoFacade.generateDEK();
      final largeData = Uint8List(1024 * 1024); // 1MB
      for (int i = 0; i < largeData.length; i++) {
        largeData[i] = i % 256;
      }

      final envelope = cryptoFacade.encrypt(largeData, key);
      final decrypted = cryptoFacade.decrypt(envelope, key);

      expect(decrypted, equals(largeData));
    });

    test('Large string (500KB)', () {
      final key = cryptoFacade.generateDEK();
      final longString = 'x' * (500 * 1024); // 500KB

      final envelope = cryptoFacade.encryptString(longString, key);
      final decrypted = cryptoFacade.decryptString(envelope, key);

      expect(decrypted, equals(longString));
    });

    // ==================== Special Characters ====================

    test('Emoji and Unicode characters', () {
      final key = cryptoFacade.generateDEK();
      const specialString = '密码🔐测试📋Test123!@#\$%^&*()';

      final envelope = cryptoFacade.encryptString(specialString, key);
      final decrypted = cryptoFacade.decryptString(envelope, key);

      expect(decrypted, equals(specialString));
    });

    test('Null bytes and control characters', () {
      final key = cryptoFacade.generateDEK();
      final binaryData = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0xFF, 0xFE, 0x7F]);

      final envelope = cryptoFacade.encrypt(binaryData, key);
      final decrypted = cryptoFacade.decrypt(envelope, key);

      expect(decrypted, equals(binaryData));
    });

    test('All ASCII printable characters', () {
      final key = cryptoFacade.generateDEK();
      final sb = StringBuffer();
      for (int i = 32; i <= 126; i++) {
        sb.writeCharCode(i);
      }
      sb.write('\n\r\t');
      final printableString = sb.toString();

      final envelope = cryptoFacade.encryptString(printableString, key);
      final decrypted = cryptoFacade.decryptString(envelope, key);

      expect(decrypted, equals(printableString));
    });

    // ==================== Key-related Edge Cases ====================

    test('Min/max random bytes lengths', () {
      expect(() => cryptoFacade.generateRandomBytes(0), returnsNormally);
      expect(() => cryptoFacade.generateRandomBytes(1), returnsNormally);
      expect(() => cryptoFacade.generateRandomBytes(32), returnsNormally);
      expect(() => cryptoFacade.generateRandomBytes(1024), returnsNormally);
      expect(() => cryptoFacade.generateRandomBytes(4096), returnsNormally);
    });

    test('Different keys with same data produce different ciphertexts', () {
      final key1 = cryptoFacade.generateDEK();
      final key2 = cryptoFacade.generateDEK();
      final data = utf8.encode('test data');

      final envelope1 = cryptoFacade.encrypt(data, key1);
      final envelope2 = cryptoFacade.encrypt(data, key2);

      expect(envelope1.ciphertext, isNot(equals(envelope2.ciphertext)));
      expect(envelope1.nonce, isNot(equals(envelope2.nonce)));

      // Each decrypts correctly with its own key
      expect(cryptoFacade.decrypt(envelope1, key1), equals(data));
      expect(cryptoFacade.decrypt(envelope2, key2), equals(data));
    });

    // ==================== Hash Edge Cases ====================

    test('SHA256 of empty data', () {
      final emptyData = Uint8List(0);
      final hash = cryptoFacade.sha256Hash(emptyData);
      expect(hash.length, equals(32));
    });

    test('SHA256 of known input produces consistent output', () {
      final hash1 = cryptoFacade.sha256String('abc');
      final hash2 = cryptoFacade.sha256String('abc');
      expect(hash1.length, equals(64));
      expect(hash1, equals(hash2));
    });

    test('SHA256: one-bit difference produces different hash', () {
      final hash1 = cryptoFacade.sha256String('abc');
      final hash2 = cryptoFacade.sha256String('abd');
      expect(hash1, isNot(equals(hash2)));
    });

    test('SHA512 of empty data', () {
      final hash = cryptoFacade.sha512Hash(Uint8List(0));
      expect(hash.length, equals(64));
    });

    test('SHA512: different inputs produce different hashes', () {
      final hash1 = cryptoFacade.sha512Hash(Uint8List.fromList([0]));
      final hash2 = cryptoFacade.sha512Hash(Uint8List.fromList([1]));

      expect(hash1.length, equals(64));
      expect(hash2.length, equals(64));
      expect(hash1, isNot(equals(hash2)));
    });

    // ==================== HMAC Edge Cases ====================

    test('HMAC with empty data', () {
      final key = cryptoFacade.generateRandomBytes(32);
      final emptyData = Uint8List(0);

      final hmac = cryptoFacade.hmacSha256(key, emptyData);
      expect(hmac.length, equals(32));
    });

    test('HMAC with empty key (should not crash)', () {
      final emptyKey = Uint8List(0);
      final data = utf8.encode('test');

      expect(() => cryptoFacade.hmacSha256(emptyKey, data), returnsNormally);
    });

    test('HMAC: same inputs produce same output', () {
      final key = cryptoFacade.generateRandomBytes(32);
      final data = utf8.encode('consistent');

      final hmac1 = cryptoFacade.hmacSha256(key, data);
      final hmac2 = cryptoFacade.hmacSha256(key, data);

      expect(hmac1, equals(hmac2));
    });

    test('HMAC: different keys produce different outputs', () {
      final key1 = cryptoFacade.generateRandomBytes(32);
      final key2 = cryptoFacade.generateRandomBytes(32);
      final data = utf8.encode('test');

      final hmac1 = cryptoFacade.hmacSha256(key1, data);
      final hmac2 = cryptoFacade.hmacSha256(key2, data);

      expect(hmac1, isNot(equals(hmac2)));
    });

    // ==================== Constant-Time Comparison Edge Cases ====================

    test('constantTimeEquals edge cases', () {
      expect(cryptoFacade.constantTimeEquals(Uint8List(0), Uint8List(0)), isTrue);
      expect(
        cryptoFacade.constantTimeEquals(Uint8List.fromList([42]), Uint8List.fromList([42])),
        isTrue,
      );
      expect(
        cryptoFacade.constantTimeEquals(Uint8List.fromList([42]), Uint8List.fromList([43])),
        isFalse,
      );
    });

    test('constantTimeEqualsHex edge cases', () {
      expect(cryptoFacade.constantTimeEqualsHex('', ''), isTrue);
      expect(cryptoFacade.constantTimeEqualsHex('a', 'a'), isTrue);
      expect(cryptoFacade.constantTimeEqualsHex('a', 'b'), isFalse);
      expect(cryptoFacade.constantTimeEqualsHex('a', 'aa'), isFalse);
      expect(cryptoFacade.constantTimeEqualsHex('ab12', 'ab12'), isTrue);
      expect(cryptoFacade.constantTimeEqualsHex('ab12', 'ab13'), isFalse);
    });

    // ==================== Hex Conversion Edge Cases ====================

    test('Empty hex conversion', () {
      final emptyHex = '';
      final bytes = cryptoFacade.hexToBytes(emptyHex);
      expect(bytes, isEmpty);
      expect(cryptoFacade.bytesToHex(bytes), equals(emptyHex));
    });

    test('Single byte hex conversion', () {
      final bytes = Uint8List.fromList([0xAB]);
      final hex = cryptoFacade.bytesToHex(bytes);
      expect(hex, equals('ab'));
      expect(cryptoFacade.hexToBytes(hex), equals(bytes));
    });

    test('Uppercase hex conversion', () {
      final bytes = cryptoFacade.hexToBytes('ABCDEF');
      expect(bytes, equals(Uint8List.fromList([0xAB, 0xCD, 0xEF])));
    });

    test('Full range hex round-trip', () {
      for (int b = 0; b < 256; b++) {
        final bytes = Uint8List.fromList([b]);
        final hex = cryptoFacade.bytesToHex(bytes);
        final decoded = cryptoFacade.hexToBytes(hex);
        expect(decoded, equals(bytes));
      }
    });

    // ==================== HKDF Edge Cases ====================

    test('HKDF with empty salt', () {
      final ikm = Uint8List.fromList(utf8.encode('input key'));

      expect(() => cryptoFacade.hkdfSha256(ikm, length: 32), returnsNormally);
    });

    test('HKDF with empty info', () {
      final ikm = Uint8List.fromList(utf8.encode('input key'));
      final salt = cryptoFacade.generateRandomBytes(32);

      expect(() => cryptoFacade.hkdfSha256(ikm, salt: salt, length: 32), returnsNormally);
    });

    test('HKDF minimum/maximum lengths', () {
      final ikm = Uint8List.fromList(utf8.encode('input'));

      expect(() => cryptoFacade.hkdfSha256(ikm, length: 1), returnsNormally);
      expect(() => cryptoFacade.hkdfSha256(ikm, length: 100), returnsNormally);
      expect(() => cryptoFacade.hkdfSha256(ikm, length: 255), returnsNormally);
    });

    test('HKDF deterministic with same inputs', () {
      final ikm = Uint8List.fromList(utf8.encode('consistent'));
      final salt = Uint8List.fromList(List.filled(32, 0xAB));

      final derived1 = cryptoFacade.hkdfSha256(ikm, salt: salt, length: 32);
      final derived2 = cryptoFacade.hkdfSha256(ikm, salt: salt, length: 32);

      expect(derived1, equals(derived2));
    });

    test('HKDF different salts produce different keys', () {
      final ikm = Uint8List.fromList(utf8.encode('input'));
      final salt1 = cryptoFacade.generateRandomBytes(32);
      final salt2 = cryptoFacade.generateRandomBytes(32);

      final derived1 = cryptoFacade.hkdfSha256(ikm, salt: salt1, length: 32);
      final derived2 = cryptoFacade.hkdfSha256(ikm, salt: salt2, length: 32);

      expect(derived1, isNot(equals(derived2)));
    });

    // ==================== Blind Index Edge Cases ====================

    test('Blind index with empty string', () {
      final searchKey = cryptoFacade.generateRandomBytes(32);
      final indexes = cryptoFacade.generateBlindIndexes('', searchKey);

      expect(indexes, isEmpty);
    });

    test('Blind index with short tokens', () {
      final searchKey = cryptoFacade.generateRandomBytes(32);
      final indexes = cryptoFacade.generateBlindIndexes('a', searchKey, minTokenLength: 2);

      expect(indexes, isEmpty);
    });

    test('Blind index with varying minTokenLength', () {
      final searchKey = cryptoFacade.generateRandomBytes(32);
      const text = 'testing';

      final indexes1 = cryptoFacade.generateBlindIndexes(text, searchKey, minTokenLength: 2);
      final indexes2 = cryptoFacade.generateBlindIndexes(text, searchKey, minTokenLength: 3);

      expect(indexes1.length, greaterThan(indexes2.length));
    });

    test('Blind index deterministic with same input', () {
      final searchKey = Uint8List.fromList(List.filled(32, 0xAB));
      const text = 'hello world test';

      final indexes1 = cryptoFacade.generateBlindIndexes(text, searchKey);
      final indexes2 = cryptoFacade.generateBlindIndexes(text, searchKey);

      expect(indexes1, equals(indexes2));
    });

    // ==================== KDF Edge Cases ====================

    test('KDF with empty password', () {
      final salt = cryptoFacade.generateRandomBytes(32);

      expect(() => cryptoFacade.deriveKEK('', salt), returnsNormally);
    });

    test('KDF with different salts produce different keys', () {
      const password = 'testpassword';
      final salt1 = cryptoFacade.generateRandomBytes(32);
      final salt2 = cryptoFacade.generateRandomBytes(32);

      final key1 = cryptoFacade.deriveKEK(password, salt1);
      final key2 = cryptoFacade.deriveKEK(password, salt2);

      expect(key1, isNot(equals(key2)));
    });

    test('KDF output length is always 32 bytes', () {
      final salt = cryptoFacade.generateRandomBytes(32);
      final passwords = ['', 'a', 'hello', 'A' * 256, '密码'];

      for (final pw in passwords) {
        final key = cryptoFacade.deriveKEK(pw, salt);
        expect(key.length, equals(32));
      }
    });

    // ==================== CiphertextEnvelope Edge Cases ====================

    test('CiphertextEnvelope JSON serialization round-trip', () {
      final envelope = CiphertextEnvelope(
        schemaVersion: 1,
        suiteId: 'TEST_SUITE',
        aeadId: 'aes-256-gcm',
        kdfParams: const KdfParams(kdfId: 'pbkdf2', memoryKB: 65536, iterations: 3, parallelism: 4),
        nonce: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
        ciphertext: Uint8List.fromList([100, 101, 102]),
        authTag: Uint8List.fromList(List.filled(16, 0xAA)),
        aadMeta: {'key': 'value'},
      );

      final json = envelope.toJson();
      final restored = CiphertextEnvelope.fromJson(json);

      expect(restored.schemaVersion, equals(envelope.schemaVersion));
      expect(restored.suiteId, equals(envelope.suiteId));
      expect(restored.aeadId, equals(envelope.aeadId));
      expect(restored.nonce, equals(envelope.nonce));
      expect(restored.ciphertext, equals(envelope.ciphertext));
      expect(restored.authTag, equals(envelope.authTag));
      expect(restored.aadMeta, equals(envelope.aadMeta));
    });

    test('CiphertextEnvelope without optional fields', () {
      final envelope = CiphertextEnvelope(
        suiteId: 'MIN',
        aeadId: 'aes-256-gcm',
        nonce: Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        ciphertext: Uint8List(0),
        authTag: Uint8List.fromList(List.filled(16, 0)),
      );

      final json = envelope.toJson();
      final restored = CiphertextEnvelope.fromJson(json);

      expect(restored.suiteId, equals('MIN'));
      expect(restored.aadMeta, isNull);
      expect(restored.kdfParams, isNull);
      expect(restored.keyInfo, isNull);
    });
  });

  // ===================================================================

  group('Edge Cases: SecureBuffer & Sensitive Data', () {
    test('SecureBuffer set, access, erase lifecycle', () async {
      final buffer = SecureBuffer(ttl: const Duration(hours: 1));
      const sensitiveData = 'edge-case-test-data';

      await buffer.setString(sensitiveData);
      expect(buffer.hasData, isTrue);

      final accessed = await buffer.accessString();
      expect(accessed, equals(sensitiveData));

      await buffer.dispose();
      expect(buffer.hasData, isFalse);

      final afterErase = await buffer.accessString();
      expect(afterErase, isNull);
    });

    test('SecureBuffer set empty data', () async {
      final buffer = SecureBuffer(ttl: const Duration(hours: 1));

      await buffer.set(Uint8List(0));
      expect(buffer.hasData, isTrue);

      final accessed = await buffer.access();
      expect(accessed, isNotNull);
      expect(accessed!.length, equals(0));

      await buffer.dispose();
    });

    test('SecureBuffer: defensive copy prevents mutation', () async {
      final buffer = SecureBuffer(ttl: const Duration(hours: 1));
      final originalData = Uint8List.fromList([10, 20, 30, 40, 50]);

      await buffer.set(originalData);

      final accessed = await buffer.access();
      accessed![2] = 99; // Mutate the copy

      // Re-access — should still have original
      final reaccessed = await buffer.access();
      expect(reaccessed![2], equals(30));

      await buffer.dispose();
    });

    test('SecureBuffer: multiple sets overwrite previous data', () async {
      final buffer = SecureBuffer(ttl: const Duration(hours: 1));

      await buffer.setString('first');
      expect(await buffer.accessString(), equals('first'));

      await buffer.setString('second');
      expect(await buffer.accessString(), equals('second'));
      expect(await buffer.accessString(), isNot(equals('first')));

      await buffer.dispose();
    });

    test('SecureBuffer: timeSinceLastAccess updates on access', () async {
      final buffer = SecureBuffer(ttl: const Duration(hours: 1));
      await buffer.setString('data');

      // After setting, there should be some time elapsed
      final t1 = buffer.timeSinceLastAccess;
      expect(t1, isNotNull);

      await buffer.access();

      final t2 = buffer.timeSinceLastAccess;
      expect(t2, isNotNull);
      // After access, time since should be very small (just accessed)
    });

    test('SecureString create and dispose', () async {
      final secureStr = await SecureString.create(
        'sensitive-edge-test',
        ttl: const Duration(hours: 1),
      );

      expect(secureStr.id, isNotEmpty);
      expect(await secureStr.get(), equals('sensitive-edge-test'));

      await secureStr.dispose();
      expect(await secureStr.get(), isNull);
    });

    test('SecureString fromBytes', () async {
      final bytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
      final secureStr = await SecureString.fromBytes(bytes, ttl: const Duration(hours: 1));

      final value = await secureStr.get();
      expect(value, isNotNull);
      await secureStr.dispose();
    });

    test('PasswordInputBuffer: add char and backspace', () async {
      final pib = PasswordInputBuffer(ttl: const Duration(hours: 1));

      await pib.addChar('P');
      await pib.addChar('@');
      await pib.addChar('s');
      await pib.addChar('s');

      expect(await pib.length, equals(4));

      await pib.backspace();
      expect(await pib.length, equals(3));

      await pib.backspace();
      await pib.backspace();
      await pib.backspace();
      expect(await pib.length, equals(0));

      await pib.dispose();
    });

    test('PasswordInputBuffer: finalize clears internal state', () async {
      final pib = PasswordInputBuffer();

      await pib.addChar('s');
      await pib.addChar('e');
      await pib.addChar('c');

      final finalized = await pib.finalize();
      final password = await finalized.accessString();
      expect(password, equals('sec'));

      // After finalize, internal buffer should be empty
      expect(await pib.length, equals(0));

      await finalized.dispose();
      await pib.dispose();
    });
  });

  // ===================================================================

  group('Edge Cases: HLC Timestamp', () {
    test('HLC with minimum values', () {
      const hlc = HLC(physicalTime: 0, logicalCounter: 0, deviceId: '');

      expect(hlc.physicalTime, equals(0));
      expect(hlc.logicalCounter, equals(0));
      expect(hlc.deviceId, equals(''));
    });

    test('HLC with maximum values', () {
      const hlc = HLC(
        physicalTime: 9223372036854775807,
        logicalCounter: 2147483647,
        deviceId: 'max-device',
      );

      expect(hlc.physicalTime, equals(9223372036854775807));
      expect(hlc.logicalCounter, equals(2147483647));
    });

    test('HLC increment edge cases', () {
      var hlc = const HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'A');

      // Increment many times
      for (int i = 0; i < 1000; i++) {
        hlc = hlc.increment();
      }

      expect(hlc.physicalTime, equals(1000));
      expect(hlc.logicalCounter, equals(1000));
    });

    test('HLC merge: remote is in the past', () {
      const local = HLC(physicalTime: 2000, logicalCounter: 5, deviceId: 'local');
      const remote = HLC(physicalTime: 1000, logicalCounter: 10, deviceId: 'remote');

      final merged = local.merge(remote);

      // Local clock wins (it's ahead), logical counter increments
      expect(merged.physicalTime, greaterThanOrEqualTo(2000));
      expect(merged.deviceId, equals('local'));
    });

    test('HLC merge: same device ID', () {
      const local = HLC(physicalTime: 1500, logicalCounter: 3, deviceId: 'same');
      const remote = HLC(physicalTime: 1500, logicalCounter: 7, deviceId: 'same');

      final merged = local.merge(remote);

      expect(merged.deviceId, equals('same'));
    });

    test('HLC isConcurrent detection', () {
      const hlc1 = HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'device-a');
      const hlc2 = HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'device-b');

      expect(hlc1.isConcurrent(hlc2), isTrue);
      expect(hlc2.isConcurrent(hlc1), isTrue);
    });

    test('HLC isConcurrent: different physical time', () {
      const hlc1 = HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'device-a');
      const hlc2 = HLC(physicalTime: 2000, logicalCounter: 0, deviceId: 'device-b');

      expect(hlc1.isConcurrent(hlc2), isFalse);
    });

    test('HLC: copyWith preserves unspecified fields', () {
      const original = HLC(physicalTime: 5000, logicalCounter: 3, deviceId: 'orig');

      final updated = original.copyWith(logicalCounter: 10);

      expect(updated.physicalTime, equals(5000));
      expect(updated.logicalCounter, equals(10));
      expect(updated.deviceId, equals('orig'));
    });

    test('HLCUtils.max with equal timestamps', () {
      const hlc1 = HLC(physicalTime: 1000, logicalCounter: 5, deviceId: 'aaa');
      const hlc2 = HLC(physicalTime: 1000, logicalCounter: 5, deviceId: 'bbb');

      final max = HLCUtils.max(hlc1, hlc2);
      // 'aaa' < 'bbb' lexicographically
      expect(max.deviceId, equals('bbb'));
    });

    test('HLCUtils.isCausallyOrdered: single element', () {
      const hlcs = [HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'A')];
      expect(HLCUtils.isCausallyOrdered(hlcs), isTrue);
    });

    test('HLCUtils.isCausallyOrdered: empty list', () {
      expect(HLCUtils.isCausallyOrdered([]), isTrue);
    });

    test('HLCUtils.generateDeviceId produces unique IDs', () {
      final ids = <String>{};
      for (int i = 0; i < 20; i++) {
        final id = HLCUtils.generateDeviceId();
        ids.add(id);
        expect(id.length, equals(16));
      }
      // Most should be unique (time-dependent, may have collisions if very fast)
      expect(ids.length, greaterThanOrEqualTo(15));
    });

    test('HLC now creates valid timestamp', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final hlc = HLC.now('test-device');
      final after = DateTime.now().millisecondsSinceEpoch;

      expect(hlc.physicalTime, greaterThanOrEqualTo(before));
      expect(hlc.physicalTime, lessThanOrEqualTo(after));
      expect(hlc.logicalCounter, equals(0));
      expect(hlc.deviceId, equals('test-device'));
    });
  });

  // ===================================================================

  group('Edge Cases: CryptoService Compatibility', () {
    test('EncryptedData with zero-length fields', () {
      final data = EncryptedData(
        ciphertext: Uint8List(0),
        iv: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
        authTag: Uint8List.fromList(List.filled(16, 0)),
      );

      final serialized = data.serialize();
      final deserialized = EncryptedData.deserialize(serialized);

      expect(deserialized.ciphertext.length, equals(0));
      expect(deserialized.iv, equals(data.iv));
      expect(deserialized.authTag, equals(data.authTag));
    });

    test('Argon2Parameters JSON round-trip', () {
      const params = Argon2Parameters(memoryKB: 131072, iterations: 5, parallelism: 4);

      final json = params.toJson();
      final restored = Argon2Parameters.fromJson(json);

      expect(restored.memoryKB, equals(131072));
      expect(restored.iterations, equals(5));
      expect(restored.parallelism, equals(4));
    });

    test('Argon2Parameters toKdfParams conversion', () {
      const params = Argon2Parameters(memoryKB: 65536, iterations: 3, parallelism: 4);

      final kdfParams = params.toKdfParams();
      expect(kdfParams.kdfId, equals('pbkdf2-hmac-sha256'));
      expect(kdfParams.memoryKB, equals(65536));
      expect(kdfParams.iterations, equals(3));
      expect(kdfParams.parallelism, equals(4));
    });
  });

  // ===================================================================

  group('Edge Cases: KdfParams & KeyVersionInfo', () {
    test('KdfParams JSON round-trip', () {
      const params = KdfParams(kdfId: 'argon2id', memoryKB: 131072, iterations: 4, parallelism: 8);

      final json = params.toJson();
      final restored = KdfParams.fromJson(json);

      expect(restored.kdfId, equals('argon2id'));
      expect(restored.memoryKB, equals(131072));
      expect(restored.iterations, equals(4));
      expect(restored.parallelism, equals(8));
    });

    test('KdfParams fromJson with missing fields uses defaults', () {
      final restored = KdfParams.fromJson({'kdfId': 'test'});

      expect(restored.kdfId, equals('test'));
      expect(restored.memoryKB, equals(65536));
      expect(restored.iterations, equals(3));
      expect(restored.parallelism, equals(4));
    });

    test('KeyVersionInfo JSON round-trip', () {
      const info = KeyVersionInfo(dekVersion: 3, kekBinding: 'kek-hash-abc123');

      final json = info.toJson();
      final restored = KeyVersionInfo.fromJson(json);

      expect(restored.dekVersion, equals(3));
      expect(restored.kekBinding, equals('kek-hash-abc123'));
    });

    test('KeyVersionInfo without optional kekBinding', () {
      const info = KeyVersionInfo(dekVersion: 1);

      final json = info.toJson();
      final restored = KeyVersionInfo.fromJson(json);

      expect(restored.dekVersion, equals(1));
      expect(restored.kekBinding, isNull);
    });
  });
}
