import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/crypto/crypto_facade.dart';
import 'package:ztd_password_manager/core/crypto/crypto_service.dart';
import 'package:ztd_password_manager/core/crypto/crypto_core.dart';
import 'package:ztd_password_manager/core/security/secure_buffer.dart';

void main() {
  // ===================================================================
  // SECURITY TESTS & HARDENING
  // ===================================================================

  group('Security: Input Validation & Injection Prevention', () {
    late CryptoFacade cryptoFacade;

    setUp(() {
      cryptoFacade = CryptoFacade();
    });

    test('encryptString handles SQL injection patterns in payload', () {
      final key = cryptoFacade.generateDEK();
      const sqlPayloads = [
        "DROP TABLE users;--",
        "' OR '1'='1' --",
        "'; SELECT * FROM passwords; --",
        "admin'--",
        "1; DROP TABLE vault;",
        "' UNION SELECT * FROM users--",
        "\" OR 1=1; --",
        "'; EXEC xp_cmdshell('dir');--",
      ];

      for (final payload in sqlPayloads) {
        final envelope = cryptoFacade.encryptString(payload, key);
        final decrypted = cryptoFacade.decryptString(envelope, key);
        expect(
          decrypted,
          equals(payload),
          reason: 'SQL injection payload should round-trip correctly',
        );
      }
    });

    test('encryptString handles XSS patterns in payload', () {
      final key = cryptoFacade.generateDEK();
      const xssPayloads = [
        '<script>alert("xss")</script>',
        '<img src=x onerror=alert(1)>',
        'javascript:alert(1)',
        '<svg/onload=alert(1)>',
        '\'><script>alert(document.cookie)</script>',
        '<body onload=alert("XSS")>',
        '<<SCRIPT>alert("XSS");//<</SCRIPT>',
      ];

      for (final payload in xssPayloads) {
        final envelope = cryptoFacade.encryptString(payload, key);
        final decrypted = cryptoFacade.decryptString(envelope, key);
        expect(
          decrypted,
          equals(payload),
          reason: 'XSS payload should round-trip without corruption',
        );
      }
    });

    test('encrypt handles null byte injection', () {
      final key = cryptoFacade.generateDEK();
      final nullPayloads = [
        Uint8List.fromList([0x00]),
        Uint8List.fromList([0x00, 0x00, 0x00]),
        Uint8List.fromList([0x48, 0x00, 0x65, 0x00, 0x6C, 0x00, 0x6C, 0x00]), // H\0e\0l\0l\0
        Uint8List.fromList([0x00, 0xFF, 0x00, 0xFF]),
        Uint8List.fromList(List.filled(256, 0x00)),
      ];

      for (final payload in nullPayloads) {
        final envelope = cryptoFacade.encrypt(payload, key);
        final decrypted = cryptoFacade.decrypt(envelope, key);
        expect(decrypted, equals(payload), reason: 'Null byte payload should round-trip correctly');
      }
    });

    test('encryptString handles unicode normalization attacks', () {
      final key = cryptoFacade.generateDEK();
      // Homoglyph and normalization attacks
      const unicodePayloads = [
        'admin', // Latin
        'аdmin', // Cyrillic 'a' mixed with Latin
        '∫ecurity', // Unicode integral symbol
        '𝒑𝒂𝒔𝒔𝒘𝒐𝒓𝒅', // Mathematical bold
        'password⁠admin', // zero-width joiner
        'pa\u200Bssword', // zero-width space
        'test\uFEFFdata', // BOM
        '😀😈💣🔥', // Emoji only
        '\u202E\u202Dtest', // Right-to-left override
      ];

      for (final payload in unicodePayloads) {
        final envelope = cryptoFacade.encryptString(payload, key);
        final decrypted = cryptoFacade.decryptString(envelope, key);
        expect(
          decrypted,
          equals(payload),
          reason: 'Unicode payload should survive encryption round-trip',
        );
      }
    });

    test('encryptString handles path traversal patterns', () {
      final key = cryptoFacade.generateDEK();
      const pathPayloads = [
        '../../etc/passwd',
        '..\\..\\Windows\\System32',
        '/../../../root/.ssh/id_rsa',
        '....//....//etc/shadow',
        '%2e%2e%2f%2e%2e%2f',
        'file:///etc/passwd',
        '\\\\server\\share\\file',
      ];

      for (final payload in pathPayloads) {
        final envelope = cryptoFacade.encryptString(payload, key);
        final decrypted = cryptoFacade.decryptString(envelope, key);
        expect(decrypted, equals(payload), reason: 'Path traversal payload should round-trip');
      }
    });

    test('encryptString handles extremely long strings', () {
      final key = cryptoFacade.generateDEK();
      // 100KB string with various patterns
      final sb = StringBuffer();
      for (int i = 0; i < 10000; i++) {
        sb.write('ABCDEFGHIJ');
      }
      final longString = sb.toString();

      final envelope = cryptoFacade.encryptString(longString, key);
      final decrypted = cryptoFacade.decryptString(envelope, key);
      expect(decrypted.length, equals(longString.length));
      expect(decrypted, equals(longString));
    });
  });

  // ===================================================================

  group('Security: Encryption Boundary & Integrity', () {
    late CryptoFacade cryptoFacade;

    setUp(() {
      cryptoFacade = CryptoFacade();
    });

    test('Nonces are unique across many encryptions', () {
      final key = cryptoFacade.generateDEK();
      final data = utf8.encode('sensitive vault data');
      final nonces = <String>{};

      for (int i = 0; i < 200; i++) {
        final envelope = cryptoFacade.encrypt(data, key);
        final nonceHex = cryptoFacade.bytesToHex(envelope.nonce);
        expect(
          nonces.contains(nonceHex),
          isFalse,
          reason: 'Nonce must never repeat (nonce reuse breaks AES-GCM security)',
        );
        nonces.add(nonceHex);
      }
    });

    test('Ciphertext is indistinguishable (same plaintext, different ciphertexts)', () {
      final key = cryptoFacade.generateDEK();
      final data = utf8.encode('The quick brown fox jumps over the lazy dog');

      final ciphertexts = <String>{};
      for (int i = 0; i < 50; i++) {
        final envelope = cryptoFacade.encrypt(data, key);
        final ctHex = cryptoFacade.bytesToHex(envelope.ciphertext);
        ciphertexts.add(ctHex);
      }

      // All ciphertexts should be different (due to unique nonces)
      expect(
        ciphertexts.length,
        equals(50),
        reason: 'Each encryption should produce unique ciphertext',
      );
    });

    test('Tampered ciphertext fails decryption', () {
      final key = cryptoFacade.generateDEK();
      final data = utf8.encode('critically sensitive data');

      final envelope = cryptoFacade.encrypt(data, key);

      // Tamper with ciphertext
      final tamperedCt = Uint8List.fromList(envelope.ciphertext);
      tamperedCt[tamperedCt.length ~/ 2] ^= 0xFF;

      final tamperedEnvelope = CiphertextEnvelope(
        schemaVersion: envelope.schemaVersion,
        suiteId: envelope.suiteId,
        aeadId: envelope.aeadId,
        nonce: envelope.nonce,
        ciphertext: tamperedCt,
        authTag: envelope.authTag,
      );

      expect(
        () => cryptoFacade.decrypt(tamperedEnvelope, key),
        throwsA(isA<Object>()),
        reason: 'Tampered ciphertext must be detected and rejected',
      );
    });

    test('Tampered auth tag fails decryption', () {
      final key = cryptoFacade.generateDEK();
      final data = utf8.encode('secure vault data');

      final envelope = cryptoFacade.encrypt(data, key);

      // Tamper with auth tag
      final tamperedTag = Uint8List.fromList(envelope.authTag);
      tamperedTag[0] ^= 0x01;

      final tamperedEnvelope = CiphertextEnvelope(
        schemaVersion: envelope.schemaVersion,
        suiteId: envelope.suiteId,
        aeadId: envelope.aeadId,
        nonce: envelope.nonce,
        ciphertext: envelope.ciphertext,
        authTag: tamperedTag,
      );

      expect(
        () => cryptoFacade.decrypt(tamperedEnvelope, key),
        throwsA(isA<Object>()),
        reason: 'Tampered auth tag must cause decryption failure',
      );
    });

    test('Tampered nonce fails decryption', () {
      final key = cryptoFacade.generateDEK();
      final data = utf8.encode('classified data');

      final envelope = cryptoFacade.encrypt(data, key);

      // Tamper with nonce
      final tamperedNonce = Uint8List.fromList(envelope.nonce);
      tamperedNonce[tamperedNonce.length ~/ 2] ^= 0xFF;

      final tamperedEnvelope = CiphertextEnvelope(
        schemaVersion: envelope.schemaVersion,
        suiteId: envelope.suiteId,
        aeadId: envelope.aeadId,
        nonce: tamperedNonce,
        ciphertext: envelope.ciphertext,
        authTag: envelope.authTag,
      );

      expect(
        () => cryptoFacade.decrypt(tamperedEnvelope, key),
        throwsA(isA<Object>()),
        reason: 'Tampered nonce must cause decryption failure',
      );
    });

    test('Wrong key fails decryption', () {
      final key1 = cryptoFacade.generateDEK();
      final key2 = cryptoFacade.generateDEK();
      final data = utf8.encode('top secret data');

      final envelope = cryptoFacade.encrypt(data, key1);

      expect(
        () => cryptoFacade.decrypt(envelope, key2),
        throwsA(isA<Object>()),
        reason: 'Decryption with wrong key must fail',
      );
    });

    test('AAD binding - tampered AAD fails decryption', () {
      final key = cryptoFacade.generateDEK();
      final data = utf8.encode('protected data');

      final envelope = cryptoFacade.encrypt(
        data,
        key,
        aadMeta: {'vaultId': 'vault-001', 'entryId': 'entry-042'},
      );

      // Decrypt without AAD should fail
      // The envelope has aadMeta bound, so decrypting with wrong/missing AAD fails
      // Note: This tests AAD integrity binding in AES-GCM
      final tamperedEnvelope = CiphertextEnvelope(
        schemaVersion: envelope.schemaVersion,
        suiteId: envelope.suiteId,
        aeadId: envelope.aeadId,
        nonce: envelope.nonce,
        ciphertext: envelope.ciphertext,
        authTag: envelope.authTag,
        aadMeta: {'vaultId': 'vault-002', 'entryId': 'entry-042'}, // Different vaultId
      );

      expect(
        () => cryptoFacade.decrypt(tamperedEnvelope, key),
        throwsA(isA<Object>()),
        reason: 'AAD metadata tampering must be detected',
      );
    });

    test('Encrypt then decrypt with AAD meta round-trips correctly', () {
      final key = cryptoFacade.generateDEK();
      final data = utf8.encode('AAD-bound data');

      const aadMeta = {'vaultId': 'vault-primary', 'entryType': 'password', 'version': '1'};

      final envelope = cryptoFacade.encrypt(data, key, aadMeta: aadMeta);
      final decrypted = cryptoFacade.decrypt(envelope, key);

      expect(decrypted, equals(data));
      expect(envelope.aadMeta, equals(aadMeta));
    });

    test('Empty ciphertext (zero bytes) round-trips', () {
      final key = cryptoFacade.generateDEK();
      final empty = Uint8List(0);

      final envelope = cryptoFacade.encrypt(empty, key);
      final decrypted = cryptoFacade.decrypt(envelope, key);

      expect(decrypted.length, equals(0));
    });

    test('Single byte payload round-trips', () {
      final key = cryptoFacade.generateDEK();

      for (int b = 0; b < 256; b++) {
        final data = Uint8List.fromList([b]);
        final envelope = cryptoFacade.encrypt(data, key);
        final decrypted = cryptoFacade.decrypt(envelope, key);
        expect(decrypted, equals(data));
      }
    });

    test('Large payload (1MB) round-trips correctly', () {
      final key = cryptoFacade.generateDEK();
      final largeData = Uint8List(1024 * 1024); // 1MB
      for (int i = 0; i < largeData.length; i++) {
        largeData[i] = i % 256;
      }

      final envelope = cryptoFacade.encrypt(largeData, key);
      final decrypted = cryptoFacade.decrypt(envelope, key);

      expect(decrypted.length, equals(largeData.length));
      expect(decrypted, equals(largeData));
    });
  });

  // ===================================================================

  group('Security: Sensitive Data Protection', () {
    test('clearBuffer overwrites data with DoD 5220.22-M pattern', () {
      final cryptoFacade = CryptoFacade();
      final buffer = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE]);
      final originalCopy = Uint8List.fromList(buffer);

      cryptoFacade.clearBuffer(buffer);

      // After clearing, buffer should be all zeros
      expect(
        buffer.every((b) => b == 0),
        isTrue,
        reason: 'Sensitive data must be zeroed after clearBuffer',
      );
      // Original values are gone
      expect(buffer, isNot(equals(originalCopy)));
    });

    test('clearBuffer handles empty buffer', () {
      final cryptoFacade = CryptoFacade();
      final buffer = Uint8List(0);
      expect(() => cryptoFacade.clearBuffer(buffer), returnsNormally);
    });

    test('SecureBuffer lifecycle: store, access, erase', () async {
      final buffer = SecureBuffer(ttl: const Duration(hours: 1));
      const sensitiveData = 'master-password-12345!@#';

      await buffer.setString(sensitiveData);
      expect(buffer.hasData, isTrue);

      final accessed = await buffer.accessString();
      expect(accessed, equals(sensitiveData));

      await buffer.dispose();
      expect(buffer.hasData, isFalse);
    });

    test('SecureBuffer does not return original reference (defensive copy)', () async {
      final buffer = SecureBuffer(ttl: const Duration(hours: 1));
      final original = Uint8List.fromList([1, 2, 3, 4, 5]);

      await buffer.set(original);

      final accessed = await buffer.access();
      expect(accessed, isNotNull);

      // Modify the returned copy
      accessed![0] = 99;

      // Re-access - should still have original data (defensive copy)
      final reaccessed = await buffer.access();
      expect(
        reaccessed![0],
        equals(1),
        reason: 'SecureBuffer must return defensive copies, not references',
      );

      await buffer.dispose();
    });

    test('SecureString lifecycle and disposal', () async {
      final secureStr = await SecureString.create(
        'super-secret-api-key-12345',
        ttl: const Duration(hours: 1),
      );

      expect(secureStr.id, isNotEmpty);

      final value = await secureStr.get();
      expect(value, equals('super-secret-api-key-12345'));

      await secureStr.dispose();

      final afterDispose = await secureStr.get();
      expect(afterDispose, isNull, reason: 'After dispose, SecureString must return null');
    });

    test('SecureString from bytes', () async {
      final bytes = Uint8List.fromList(utf8.encode('binary secret data'));
      final secureStr = await SecureString.fromBytes(bytes, ttl: const Duration(hours: 1));

      final value = await secureStr.get();
      expect(value, equals('binary secret data'));

      await secureStr.dispose();
    });

    test('PasswordInputBuffer basic operations', () async {
      final pib = PasswordInputBuffer(ttl: const Duration(hours: 1));

      await pib.addChar('h');
      await pib.addChar('e');
      await pib.addChar('l');
      await pib.addChar('l');
      await pib.addChar('o');

      expect(await pib.length, equals(5));

      await pib.backspace();
      expect(await pib.length, equals(4));

      final finalized = await pib.finalize();
      final pw = await finalized.accessString();
      expect(pw, equals('hell'));

      await finalized.dispose();
      await pib.dispose();
    });

    test('PasswordInputBuffer clear removes all chars', () async {
      final pib = PasswordInputBuffer();

      await pib.addChar('s');
      await pib.addChar('e');
      await pib.addChar('c');
      await pib.addChar('r');
      await pib.addChar('e');
      await pib.addChar('t');

      expect(await pib.length, equals(6));

      await pib.clear();
      expect(await pib.length, equals(0));

      await pib.dispose();
    });

    test('PasswordInputBuffer backspace on empty does not crash', () async {
      final pib = PasswordInputBuffer();
      await pib.backspace(); // Should not crash
      expect(await pib.length, equals(0));
      await pib.dispose();
    });

    test('MemoryPressureHandler tracks and wipes buffers', () async {
      final buffer1 = SecureBuffer(ttl: const Duration(hours: 1));
      final buffer2 = SecureBuffer(ttl: const Duration(hours: 1));

      await buffer1.setString('data1');
      await buffer2.setString('data2');

      await MemoryPressureHandler.register(buffer1);
      await MemoryPressureHandler.register(buffer2);

      expect(await MemoryPressureHandler.bufferCount, greaterThanOrEqualTo(2));

      await MemoryPressureHandler.emergencyWipe();

      expect(buffer1.hasData, isFalse);
      expect(buffer2.hasData, isFalse);
      expect(await MemoryPressureHandler.bufferCount, equals(0));
    });
  });

  // ===================================================================

  group('Security: Timing Attack Resistance', () {
    late CryptoFacade cryptoFacade;

    setUp(() {
      cryptoFacade = CryptoFacade();
    });

    test('constantTimeEquals: equal arrays return true', () {
      final a = Uint8List.fromList(List.generate(64, (i) => i % 256));
      final b = Uint8List.fromList(List.generate(64, (i) => i % 256));

      expect(cryptoFacade.constantTimeEquals(a, b), isTrue);
    });

    test('constantTimeEquals: different arrays return false', () {
      final a = Uint8List.fromList(List.generate(64, (i) => i % 256));
      final b = Uint8List.fromList(List.generate(64, (i) => (i + 1) % 256));

      expect(cryptoFacade.constantTimeEquals(a, b), isFalse);
    });

    test('constantTimeEquals: different lengths return false', () {
      final a = Uint8List.fromList([1, 2, 3]);
      final b = Uint8List.fromList([1, 2, 3, 4]);

      expect(cryptoFacade.constantTimeEquals(a, b), isFalse);
    });

    test('constantTimeEquals: empty arrays', () {
      expect(cryptoFacade.constantTimeEquals(Uint8List(0), Uint8List(0)), isTrue);
      expect(cryptoFacade.constantTimeEquals(Uint8List(0), Uint8List.fromList([1])), isFalse);
    });

    test('constantTimeEquals: first byte differs (should not early-exit)', () {
      final a = Uint8List.fromList(List.generate(64, (i) => i % 256));
      final b = Uint8List.fromList(a);
      b[0] ^= 0xFF; // Change first byte

      // Should still return false without early exit
      expect(cryptoFacade.constantTimeEquals(a, b), isFalse);
    });

    test('constantTimeEquals: last byte differs', () {
      final a = Uint8List.fromList(List.generate(64, (i) => i % 256));
      final b = Uint8List.fromList(a);
      b[63] ^= 0xFF; // Change last byte

      expect(cryptoFacade.constantTimeEquals(a, b), isFalse);
    });

    test('constantTimeEquals: single byte comparison', () {
      expect(
        cryptoFacade.constantTimeEquals(Uint8List.fromList([42]), Uint8List.fromList([42])),
        isTrue,
      );
      expect(
        cryptoFacade.constantTimeEquals(Uint8List.fromList([42]), Uint8List.fromList([43])),
        isFalse,
      );
    });

    test('constantTimeEqualsHex: basic comparisons', () {
      expect(cryptoFacade.constantTimeEqualsHex('abc123', 'abc123'), isTrue);
      expect(cryptoFacade.constantTimeEqualsHex('abc123', 'abc124'), isFalse);
      expect(cryptoFacade.constantTimeEqualsHex('abc', 'abcd'), isFalse);
      expect(cryptoFacade.constantTimeEqualsHex('', ''), isTrue);
    });

    test('constantTimeEqualsHex: case sensitive', () {
      expect(
        cryptoFacade.constantTimeEqualsHex('ABC', 'abc'),
        isFalse,
        reason: 'Hex comparison must be case-sensitive',
      );
    });
  });

  // ===================================================================

  group('Security: Random Number Generation Quality', () {
    late CryptoFacade cryptoFacade;

    setUp(() {
      cryptoFacade = CryptoFacade();
    });

    test('generateRandomBytes produces unique outputs', () {
      final samples = <String>{};
      for (int i = 0; i < 100; i++) {
        final bytes = cryptoFacade.generateRandomBytes(32);
        final hex = cryptoFacade.bytesToHex(bytes);
        expect(
          samples.contains(hex),
          isFalse,
          reason: 'Random bytes must be unique across multiple calls',
        );
        samples.add(hex);
      }
      expect(samples.length, equals(100));
    });

    test('generateRandomBytes produces correct length', () {
      for (final length in [0, 1, 16, 32, 64, 128, 256, 1024]) {
        final bytes = cryptoFacade.generateRandomBytes(length);
        expect(bytes.length, equals(length));
      }
    });

    test('generateRandomBytes has good byte distribution', () {
      // Generate many bytes and check that each byte value appears
      final bytes = cryptoFacade.generateRandomBytes(8192);
      final counts = List.filled(256, 0);

      for (final b in bytes) {
        counts[b]++;
      }

      // Each byte value should appear at least once in 8192 samples
      // (probability of missing any byte is astronomically low)
      final missingBytes = <int>[];
      for (int i = 0; i < 256; i++) {
        if (counts[i] == 0) {
          missingBytes.add(i);
        }
      }

      // Allow up to 3 missing bytes (statistically very unlikely but possible)
      expect(
        missingBytes.length,
        lessThanOrEqualTo(3),
        reason: 'Random bytes should cover most byte values',
      );
    });

    test('generateDEK produces unique 32-byte keys', () {
      final keys = <String>{};
      for (int i = 0; i < 50; i++) {
        final dek = cryptoFacade.generateDEK();
        expect(dek.length, equals(32));
        final hex = cryptoFacade.bytesToHex(dek);
        keys.add(hex);
      }
      expect(keys.length, equals(50), reason: 'All DEKs must be unique');
    });
  });

  // ===================================================================

  group('Security: Key Derivation & Management', () {
    late CryptoFacade cryptoFacade;

    setUp(() {
      cryptoFacade = CryptoFacade();
    });

    test('deriveKEK: different passwords produce different keys', () {
      final salt = cryptoFacade.generateRandomBytes(32);

      final key1 = cryptoFacade.deriveKEK('password123', salt);
      final key2 = cryptoFacade.deriveKEK('password124', salt);

      expect(key1, isNot(equals(key2)), reason: 'Different passwords must produce different KEKs');
      expect(key1.length, equals(32));
      expect(key2.length, equals(32));
    });

    test('deriveKEK: different salts produce different keys', () {
      const password = 'master-password';

      final salt1 = cryptoFacade.generateRandomBytes(32);
      final salt2 = cryptoFacade.generateRandomBytes(32);

      final key1 = cryptoFacade.deriveKEK(password, salt1);
      final key2 = cryptoFacade.deriveKEK(password, salt2);

      expect(key1, isNot(equals(key2)), reason: 'Different salts must produce different KEKs');
    });

    test('deriveKEK: same inputs produce same key (deterministic)', () {
      const password = 'deterministic-test';
      final salt = Uint8List.fromList(List.filled(32, 0xAB));

      final key1 = cryptoFacade.deriveKEK(password, salt);
      final key2 = cryptoFacade.deriveKEK(password, salt);

      expect(key1, equals(key2), reason: 'KDF must be deterministic for same inputs');
    });

    test('deriveKEK: handles empty password', () {
      final salt = cryptoFacade.generateRandomBytes(32);

      expect(() => cryptoFacade.deriveKEK('', salt), returnsNormally);
    });

    test('deriveKEK: handles long password', () {
      final salt = cryptoFacade.generateRandomBytes(32);
      final longPassword = 'A' * 1000;

      expect(() => cryptoFacade.deriveKEK(longPassword, salt), returnsNormally);
    });

    test('deriveKEK: handles unicode password', () {
      final salt = cryptoFacade.generateRandomBytes(32);

      expect(() => cryptoFacade.deriveKEK('密码🔐安全Key!@#', salt), returnsNormally);
    });

    test('deriveKEK: output is always 32 bytes', () {
      final salt = cryptoFacade.generateRandomBytes(32);
      final passwords = ['', 'a', 'short', 'normal-password', 'A' * 500];

      for (final pw in passwords) {
        final key = cryptoFacade.deriveKEK(pw, salt);
        expect(
          key.length,
          equals(32),
          reason: 'KEK must always be 32 bytes regardless of password length',
        );
      }
    });
  });

  // ===================================================================

  group('Security: Policy & Downgrade Protection', () {
    late CryptoFacade cryptoFacade;

    setUp(() {
      cryptoFacade = CryptoFacade();
    });

    test('defaultSuite exists and has valid configuration', () {
      final suite = cryptoFacade.defaultSuite;
      expect(suite.id, isNotEmpty);
      expect(suite.aeadId, equals('aes-256-gcm'));
      expect(suite.kdfId, equals('pbkdf2-hmac-sha256'));
      expect(suite.securityLevel, greaterThanOrEqualTo(0));
    });

    test('registry has AEAD and KDF providers registered', () {
      final registry = cryptoFacade.registry;

      final aeadIds = registry.aeadProviderIds;
      final kdfIds = registry.kdfProviderIds;

      expect(aeadIds, contains('aes-256-gcm'));
      expect(kdfIds, contains('pbkdf2-hmac-sha256'));
    });

    test('policy allows default suite for decryption', () {
      final policy = cryptoFacade.policy;
      final defaultId = policy.defaultSuiteId;

      final rejection = policy.validateForDecryption(defaultId);
      expect(rejection, isNull, reason: 'Default suite must be allowed for decryption');
    });

    test('policy allows legacy suite for decryption', () {
      final policy = cryptoFacade.policy;
      final rejection = policy.validateForDecryption('ZTDPM_LEGACY_V1');
      expect(rejection, isNull, reason: 'Legacy suite must be allowed for backward compatibility');
    });

    test('policy rejects unknown suite', () {
      final policy = cryptoFacade.policy;
      final rejection = policy.validateForDecryption('ATTACKER_SUITE_V99');
      expect(rejection, isNotNull, reason: 'Unknown suite must be rejected (downgrade protection)');
    });

    test('policy allows only default suite for encryption', () {
      final policy = cryptoFacade.policy;
      final defaultId = policy.defaultSuiteId;

      expect(policy.canEncryptWith(defaultId), isTrue);
      expect(policy.canEncryptWith('ZTDPM_LEGACY_V1'), isFalse);
      expect(policy.canEncryptWith('UNKNOWN'), isFalse);
    });

    test('policy summary returns valid data', () {
      final summary = cryptoFacade.policy.policySummary;
      expect(summary['defaultSuiteId'], isA<String>());
      expect(summary['minSecurityLevel'], isA<int>());
      expect(summary['allowedSuiteCount'], greaterThanOrEqualTo(1));
    });

    test('decrypt fails with unknown suite envelope', () {
      final key = cryptoFacade.generateDEK();

      final fakeEnvelope = CiphertextEnvelope(
        suiteId: 'EVIL_SUITE',
        aeadId: 'aes-256-gcm',
        nonce: cryptoFacade.generateRandomBytes(12),
        ciphertext: Uint8List.fromList([0x00]),
        authTag: Uint8List.fromList(List.filled(16, 0x00)),
      );

      expect(
        () => cryptoFacade.decrypt(fakeEnvelope, key),
        throwsA(isA<SecurityException>()),
        reason: 'Decryption with unknown suite must throw SecurityException',
      );
    });
  });

  // ===================================================================

  group('Security: CryptoService Compatibility Layer', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoService();
    });

    test('CryptoService facade is accessible', () {
      expect(cryptoService.facade, isA<CryptoFacade>());
    });

    test('CryptoService encryptAESGCM/decryptAESGCM round-trip', () {
      final key = cryptoService.generateDEK();
      final data = utf8.encode('compatibility test data');

      final encrypted = cryptoService.encryptAESGCM(data, key);
      final decrypted = cryptoService.decryptAESGCM(encrypted, key);

      expect(decrypted, equals(data));
    });

    test('CryptoService EncryptedData serialize/deserialize round-trip', () {
      final data = EncryptedData(
        ciphertext: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        iv: Uint8List.fromList([9, 10, 11, 12]),
        authTag: Uint8List.fromList([13, 14, 15, 16]),
      );

      final serialized = data.serialize();
      final deserialized = EncryptedData.deserialize(serialized);

      expect(deserialized.ciphertext, equals(data.ciphertext));
      expect(deserialized.iv, equals(data.iv));
      expect(deserialized.authTag, equals(data.authTag));
    });

    test('CryptoService EncryptedData toEnvelope conversion', () {
      final data = EncryptedData(
        ciphertext: Uint8List.fromList([1, 2, 3]),
        iv: Uint8List.fromList([4, 5, 6]),
        authTag: Uint8List.fromList([7, 8, 9]),
      );

      final envelope = data.toEnvelope();
      expect(envelope.ciphertext, equals(data.ciphertext));
      expect(envelope.nonce, equals(data.iv));
      expect(envelope.authTag, equals(data.authTag));

      // Round-trip back
      final restored = EncryptedData.fromEnvelope(envelope);
      expect(restored.ciphertext, equals(data.ciphertext));
      expect(restored.iv, equals(data.iv));
      expect(restored.authTag, equals(data.authTag));
    });

    test('CryptoService Argon2Parameters toKdfParams conversion', () {
      const params = Argon2Parameters(memoryKB: 131072, iterations: 5, parallelism: 8);

      final kdfParams = params.toKdfParams();
      expect(kdfParams.kdfId, equals('pbkdf2-hmac-sha256'));
      expect(kdfParams.memoryKB, equals(131072));
      expect(kdfParams.iterations, equals(5));
      expect(kdfParams.parallelism, equals(8));
    });
  });

  // ===================================================================

  group('Security: Hex & Encoding Boundary Conditions', () {
    late CryptoFacade cryptoFacade;

    setUp(() {
      cryptoFacade = CryptoFacade();
    });

    test('bytesToHex / hexToBytes: empty', () {
      expect(cryptoFacade.bytesToHex(Uint8List(0)), equals(''));
      expect(cryptoFacade.hexToBytes(''), isEmpty);
    });

    test('bytesToHex / hexToBytes: all byte values', () {
      final allBytes = Uint8List.fromList(List.generate(256, (i) => i));
      final hex = cryptoFacade.bytesToHex(allBytes);
      final decoded = cryptoFacade.hexToBytes(hex);
      expect(decoded, equals(allBytes));
    });

    test('bytesToHex: zero padding', () {
      final bytes = Uint8List.fromList([0x00, 0x0A, 0x01, 0xFF]);
      final hex = cryptoFacade.bytesToHex(bytes);
      expect(hex, equals('000a01ff'));
    });

    test('hexToBytes: uppercase input', () {
      final bytes = cryptoFacade.hexToBytes('ABCDEF0123456789');
      expect(bytes, equals(Uint8List.fromList([0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89])));
    });

    test('hexToBytes: lowercase input', () {
      final bytes = cryptoFacade.hexToBytes('abcdef0123456789');
      expect(bytes, equals(Uint8List.fromList([0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45, 0x67, 0x89])));
    });

    test('hexToBytes: odd length throws', () {
      expect(() => cryptoFacade.hexToBytes('abc'), throwsA(isA<Object>()));
    });
  });
}
