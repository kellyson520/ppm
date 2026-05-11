import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/services/vault_service.dart';
import 'package:ztd_password_manager/core/models/models.dart';
import '../helpers/test_helpers.dart';
import 'vault_export_import_test.mocks.dart';

void main() {
  late VaultService vaultService;
  late MockDatabaseService mockDb;
  late MockCryptoService mockCrypto;
  late MockKeyManager mockKeyManager;
  late MockEventStore mockEventStore;

  setUp(() {
    mockDb = MockDatabaseService();
    mockCrypto = MockCryptoService();
    mockKeyManager = MockKeyManager();
    mockEventStore = MockEventStore();

    vaultService = VaultService(
      database: mockDb,
      cryptoService: mockCrypto,
      keyManager: mockKeyManager,
    );

    when(mockDb.eventStore).thenReturn(mockEventStore);
    when(mockKeyManager.getSearchKey())
        .thenAnswer((_) async => Uint8List(32));
    when(mockKeyManager.getDeviceId()).thenAnswer((_) async => 'test-device');
  });

  group('VaultService Export Tests', () {
    test('exportVaultAsJson returns encrypted data when encrypted=true',
        () async {
      final key = Uint8List(32);
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(key);
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async {});
      await vaultService.unlock('password');

      final card = makePasswordCard();
      when(mockDb.getAllActiveCards()).thenAnswer((_) async => [card]);

      final payload = makePasswordPayload();
      when(mockCrypto.decryptString(any, any))
          .thenReturn(jsonEncode(payload.toJson()));

      final encryptedData = makeEncryptedData();
      when(mockCrypto.encryptString(any, any)).thenReturn(encryptedData);

      final result = await vaultService.exportVaultAsJson(encrypted: true);

      expect(result, equals(encryptedData.serialize()));
      verify(mockCrypto.encryptString(any, any)).called(1);
    });

    test('exportVaultAsJson returns plain JSON when encrypted=false',
        () async {
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async {});
      await vaultService.unlock('password');

      final card = makePasswordCard();
      when(mockDb.getAllActiveCards()).thenAnswer((_) async => [card]);

      final payload = makePasswordPayload();
      when(mockCrypto.decryptString(any, any))
          .thenReturn(jsonEncode(payload.toJson()));

      final result = await vaultService.exportVaultAsJson(encrypted: false);

      expect(result, startsWith('['));
      expect(result, contains('Test Title'));
    });

    test('exportVaultAsJson handles empty vault', () async {
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async {});
      await vaultService.unlock('password');

      when(mockDb.getAllActiveCards()).thenAnswer((_) async => []);

      final result = await vaultService.exportVaultAsJson(encrypted: false);

      expect(result, equals('[]'));
    });
  });

  group('VaultService Import Tests', () {
    test('importVaultFromJson handles plain JSON array', () async {
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async {});
      await vaultService.unlock('password');

      when(mockCrypto.encryptString(any, any))
          .thenReturn(makeEncryptedData());
      when(mockCrypto.generateBlindIndexes(any, any)).thenReturn(['idx']);
      when(mockDb.transaction(any)).thenAnswer((inv) async {
        final callback = inv.positionalArguments[0] as Function;
        await callback(MockTransaction());
      });
      when(mockDb.saveCard(any, txn: anyNamed('txn')))
          .thenAnswer((_) async {});
      when(mockEventStore.appendEvent(any, txn: anyNamed('txn')))
          .thenAnswer((_) async {});

      final plainJson = jsonEncode([makePasswordPayload().toJson()]);
      final count = await vaultService.importVaultFromJson(plainJson);

      expect(count, equals(1));
      verifyNever(mockCrypto.decryptString(any, any));
    });

    test('importVaultFromJson handles encrypted backup', () async {
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async {});
      await vaultService.unlock('password');

      final payload = makePasswordPayload();
      final plainJson = jsonEncode([payload.toJson()]);
      final encryptedData = makeEncryptedData();
      final encryptedBase64 = encryptedData.serialize();

      when(mockCrypto.decryptString(any, any)).thenReturn(plainJson);
      when(mockCrypto.encryptString(any, any))
          .thenReturn(makeEncryptedData());
      when(mockCrypto.generateBlindIndexes(any, any)).thenReturn(['idx']);
      when(mockDb.transaction(any)).thenAnswer((inv) async {
        final callback = inv.positionalArguments[0] as Function;
        await callback(MockTransaction());
      });

      final count =
          await vaultService.importVaultFromJson(encryptedBase64);

      expect(count, equals(1));
      verify(mockCrypto.decryptString(any, any)).called(1);
    });

    test('importVaultFromJson skips invalid items', () async {
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async {});
      await vaultService.unlock('password');

      when(mockCrypto.encryptString(any, any))
          .thenReturn(makeEncryptedData());
      when(mockCrypto.generateBlindIndexes(any, any)).thenReturn(['idx']);
      when(mockDb.transaction(any)).thenAnswer((inv) async {
        final callback = inv.positionalArguments[0] as Function;
        await callback(MockTransaction());
      });
      when(mockDb.saveCard(any, txn: anyNamed('txn')))
          .thenAnswer((_) async {});
      when(mockEventStore.appendEvent(any, txn: anyNamed('txn')))
          .thenAnswer((_) async {});

      final validPayload = makePasswordPayload(title: 'Valid Entry');
      final invalidItem = {'invalid': 'data'};
      final jsonArray = jsonEncode([validPayload.toJson(), invalidItem]);

      final count = await vaultService.importVaultFromJson(jsonArray);

      expect(count, equals(1));
    });

    test('importVaultFromJson handles empty JSON array', () async {
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async {});
      await vaultService.unlock('password');

      final count = await vaultService.importVaultFromJson('[]');

      expect(count, equals(0));
    });

    test('importVaultFromJson throws on completely invalid format', () async {
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async {});
      await vaultService.unlock('password');

      expect(
        () => vaultService.importVaultFromJson('not json at all'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('VaultService Biometric Tests', () {
    test('isBiometricEnabled returns true when password is stored', () async {
      when(mockKeyManager.getStoredBiometricPassword())
          .thenAnswer((_) async => 'stored-password');

      final result = await vaultService.isBiometricEnabled();

      expect(result, isTrue);
    });

    test('isBiometricEnabled returns false when no password stored', () async {
      when(mockKeyManager.getStoredBiometricPassword())
          .thenAnswer((_) async => null);

      final result = await vaultService.isBiometricEnabled();

      expect(result, isFalse);
    });

    test('enableBiometricMode stores password', () async {
      await vaultService.enableBiometricMode('master-password');

      verify(mockKeyManager.savePasswordForBiometric('master-password'))
          .called(1);
    });

    test('disableBiometricMode clears stored password', () async {
      await vaultService.disableBiometricMode();

      verify(mockKeyManager.clearPasswordForBiometric()).called(1);
    });

    test('getStoredBiometricPassword returns stored password', () async {
      when(mockKeyManager.getStoredBiometricPassword())
          .thenAnswer((_) async => 'stored-password');

      final result = await vaultService.getStoredBiometricPassword();

      expect(result, equals('stored-password'));
    });
  });

  group('VaultService Stats Tests', () {
    test('getStats returns correct statistics', () async {
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async {});
      await vaultService.unlock('password');

      when(mockDb.getCardCount()).thenAnswer((_) async => 10);
      when(mockEventStore.getEventCount()).thenAnswer((_) async => 25);
      when(mockEventStore.getPendingCount()).thenAnswer((_) async => 3);
      when(mockEventStore.getAllSnapshots())
          .thenAnswer((_) async => [makePasswordEvent()]);

      final stats = await vaultService.getStats();

      expect(stats.cardCount, equals(10));
      expect(stats.eventCount, equals(25));
      expect(stats.pendingSyncCount, equals(3));
    });

    test('getStats handles empty snapshots', () async {
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async {});
      await vaultService.unlock('password');

      when(mockDb.getCardCount()).thenAnswer((_) async => 0);
      when(mockEventStore.getEventCount()).thenAnswer((_) async => 0);
      when(mockEventStore.getPendingCount()).thenAnswer((_) async => 0);
      when(mockEventStore.getAllSnapshots()).thenAnswer((_) async => []);

      final stats = await vaultService.getStats();

      expect(stats.cardCount, equals(0));
      expect(stats.snapshotCount, equals(0));
      expect(stats.latestSnapshotVersion, isNull);
    });
  });

  group('VaultService Emergency Kit Tests', () {
    test('exportEmergencyKit delegates to KeyManager', () async {
      when(mockKeyManager.exportEmergencyKit('password'))
          .thenAnswer((_) async => '{"version": 1}');

      final result = await vaultService.exportEmergencyKit('password');

      expect(result, equals('{"version": 1}'));
      verify(mockKeyManager.exportEmergencyKit('password')).called(1);
    });

    test('importEmergencyKit delegates to KeyManager', () async {
      when(mockKeyManager.importEmergencyKit(any))
          .thenAnswer((_) async => true);

      final result = await vaultService.importEmergencyKit('{"version": 1}');

      expect(result, isTrue);
      verify(mockKeyManager.importEmergencyKit('{"version": 1}')).called(1);
    });
  });

  group('VaultService Change Password Tests', () {
    test('changeMasterPassword delegates to KeyManager', () async {
      when(mockKeyManager.changeMasterPassword('old', 'new'))
          .thenAnswer((_) async => true);

      final result =
          await vaultService.changeMasterPassword('old', 'new');

      expect(result, isTrue);
      verify(mockKeyManager.changeMasterPassword('old', 'new')).called(1);
    });

    test('changeMasterPassword returns false on failure', () async {
      when(mockKeyManager.changeMasterPassword('old', 'new'))
          .thenAnswer((_) async => false);

      final result =
          await vaultService.changeMasterPassword('old', 'new');

      expect(result, isFalse);
    });
  });
}
