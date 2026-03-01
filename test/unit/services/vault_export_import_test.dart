import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/services/vault_service.dart';
// Removed unused import
import 'package:ztd_password_manager/core/models/models.dart';
// Removed unused import
import 'vault_orchestration_test.mocks.dart';
import '../../helpers/test_helpers.dart';

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
    when(mockKeyManager.getSearchKey()).thenAnswer((_) async => Uint8List(32));
    when(mockKeyManager.getDeviceId()).thenAnswer((_) async => 'test-device');
  });

  group('VaultService Export/Import Tests', () {
    test(
        'exportVaultAsJson should return encrypted base64 when encrypted is true',
        () async {
      // Mock unlock
      final key = Uint8List(32);
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(key);
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async => Future.value());
      await vaultService.unlock('password');

      // Mock cards
      final card = PasswordCard(
        cardId: '1',
        encryptedPayload: 'payload',
        blindIndexes: [],
        createdAt: HLC.now('device'),
        updatedAt: HLC.now('device'),
        currentEventId: 'event',
      );
      when(mockDb.getAllActiveCards()).thenAnswer((_) async => [card]);

      // Mock decryptions
      final payload = makePasswordPayload();
      // VaultService.decryptCard uses deserialize then decryptString
      when(mockCrypto.decryptString(any, any))
          .thenReturn(jsonEncode(payload.toJson()));

      // Mock full export encryption
      final encryptedData = makeEncryptedData();
      when(mockCrypto.encryptString(any, any)).thenReturn(encryptedData);

      final result = await vaultService.exportVaultAsJson(encrypted: true);

      expect(result, equals(encryptedData.serialize()));
      verify(mockCrypto.encryptString(any, any)).called(1);
    });

    test('importVaultFromJson should handle plain JSON array', () async {
      // Mock unlock
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async => Future.value());
      await vaultService.unlock('password');

      // Mock card creation
      when(mockCrypto.encryptString(any, any)).thenReturn(makeEncryptedData());
      when(mockCrypto.generateBlindIndexes(any, any)).thenReturn(['idx']);
      when(mockDb.transaction(any)).thenAnswer((inv) async {
        final callback = inv.positionalArguments[0] as Function;
        await callback(MockTransaction());
      });
      when(mockDb.saveCard(any, txn: anyNamed('txn')))
          .thenAnswer((_) async => Future.value());
      when(mockEventStore.appendEvent(any, txn: anyNamed('txn')))
          .thenAnswer((_) async => Future.value());

      final plainJson = jsonEncode([makePasswordPayload().toJson()]);
      final count = await vaultService.importVaultFromJson(plainJson);

      expect(count, equals(1));
      verifyNever(mockCrypto.decryptString(any, any));
    });

    test('importVaultFromJson should handle encrypted backup', () async {
      // Mock unlock
      when(mockKeyManager.unlock(any)).thenAnswer((_) async => true);
      when(mockKeyManager.dek).thenReturn(Uint8List(32));
      when(mockCrypto.sha256String(any)).thenReturn('mock-key');
      when(mockDb.initialize(any)).thenAnswer((_) async => Future.value());
      await vaultService.unlock('password');

      final payload = makePasswordPayload();
      final plainJson = jsonEncode([payload.toJson()]);
      final encryptedData = makeEncryptedData();
      final encryptedBase64 = encryptedData.serialize();

      // Mock decryption of the backup
      when(mockCrypto.decryptString(any, any)).thenReturn(plainJson);

      // Mock card creation internals
      when(mockCrypto.encryptString(any, any)).thenReturn(makeEncryptedData());
      when(mockCrypto.generateBlindIndexes(any, any)).thenReturn(['idx']);
      when(mockDb.transaction(any)).thenAnswer((inv) async {
        final callback = inv.positionalArguments[0] as Function;
        await callback(MockTransaction());
      });

      final count = await vaultService.importVaultFromJson(encryptedBase64);

      expect(count, equals(1));
      verify(mockCrypto.decryptString(any, any)).called(1);
    });
  });
}
