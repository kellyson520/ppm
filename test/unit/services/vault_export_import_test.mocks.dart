// Mocks for Vault Export/Import tests
// Manual implementation instead of code generation

import 'dart:async';
import 'dart:typed_data';
import 'package:mockito/mockito.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:ztd_password_manager/core/crypto/crypto_service.dart';
import 'package:ztd_password_manager/core/crypto/key_manager.dart';
import 'package:ztd_password_manager/core/events/event_store.dart';
import 'package:ztd_password_manager/core/storage/database_service.dart';
import 'package:ztd_password_manager/core/models/models.dart';

class MockDatabaseService extends Mock implements DatabaseService {
  @override
  Database get db => throw UnimplementedError();

  @override
  EventStore get eventStore => MockEventStore();

  @override
  Future<void> initialize(String encryptionKey) async {}

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction action) action) async {
    return action(MockTransaction());
  }

  @override
  Future<void> saveCard(PasswordCard card, {Transaction? txn}) async {}

  @override
  Future<PasswordCard?> getCard(String cardId) async => null;

  @override
  Future<List<PasswordCard>> getAllActiveCards() async => [];

  @override
  Future<List<PasswordCard>> getCardsUpdatedAfterHlc(HLC hlc) async => [];

  @override
  Future<void> deleteCard(String cardId, String deviceId, String eventId, {Transaction? txn}) async {}

  @override
  Future<void> permanentlyDeleteCard(String cardId, {Transaction? txn}) async {}

  @override
  Future<int> getCardCount() async => 0;

  @override
  Future<List<PasswordCard>> searchByBlindIndexes(List<String> searchHashes) async => [];

  @override
  Future<List<PasswordCard>> searchByDecryptedContent(
    String query,
    Future<String> Function(PasswordCard card) decryptFn,
  ) async => [];

  @override
  Future<void> generateBlindIndexes(String cardId, String plaintext, Uint8List searchKey) async {}

  @override
  Future<void> saveWebDavNode(WebDavNode node) async {}

  @override
  Future<List<WebDavNode>> getAllWebDavNodes() async => [];

  @override
  Future<void> deleteWebDavNode(String name) async {}

  @override
  Future<void> compact() async {}

  @override
  Future<int> getDatabaseSize() async => 0;

  @override
  Future<String> exportDatabase(String encryptionKey) async => '';

  @override
  Future<void> importDatabase(String backupPath) async {}

  @override
  Future<void> clearAllData() async {}

  @override
  Future<void> close() async {}
}

class MockCryptoService extends Mock implements CryptoService {
  @override
  CryptoFacade get facade => throw UnimplementedError();

  @override
  Uint8List generateRandomBytes(int length) => Uint8List(length);

  @override
  Uint8List deriveKEK(
    String password,
    Uint8List salt, {
    int memoryKB = 65536,
    int iterations = 3,
    int parallelism = 4,
  }) => Uint8List(32);

  @override
  Argon2Parameters benchmarkDevice() => throw UnimplementedError();

  @override
  Uint8List generateDEK() => Uint8List(32);

  @override
  EncryptedData encryptAESGCM(Uint8List plaintext, Uint8List key) {
    return EncryptedData(
      ciphertext: plaintext,
      iv: Uint8List(12),
      authTag: Uint8List(16),
    );
  }

  @override
  Uint8List decryptAESGCM(EncryptedData encryptedData, Uint8List key) => Uint8List(0);

  @override
  EncryptedData encryptString(String plaintext, Uint8List key) {
    return EncryptedData(
      ciphertext: Uint8List.fromList(plaintext.codeUnits),
      iv: Uint8List(12),
      authTag: Uint8List(16),
    );
  }

  @override
  String decryptString(EncryptedData encryptedData, Uint8List key) => '';

  @override
  Uint8List hkdfSha256(Uint8List ikm, {Uint8List? salt, Uint8List? info, int length = 32}) => Uint8List(length);

  @override
  Uint8List hmacSha256(Uint8List key, Uint8List data) => Uint8List(32);

  @override
  String hmacSha256String(String key, String data) => '';

  @override
  bool constantTimeEquals(Uint8List a, Uint8List b) => true;

  @override
  bool constantTimeEqualsHex(String a, String b) => true;

  @override
  Uint8List sha256Hash(Uint8List data) => Uint8List(32);

  @override
  String sha256String(String data) => '';

  @override
  Uint8List sha512Hash(Uint8List data) => Uint8List(64);

  @override
  List<String> generateBlindIndexes(String plaintext, Uint8List searchKey, {int minTokenLength = 2}) => [];

  @override
  String bytesToHex(Uint8List bytes) => '';

  @override
  Uint8List hexToBytes(String hex) => Uint8List(0);

  @override
  void clearBuffer(Uint8List buffer) {}
}

class MockKeyManager extends Mock implements KeyManager {
  @override
  bool get isUnlocked => false;

  @override
  Uint8List? get dek => Uint8List(32);

  @override
  Future<void> initialize(String masterPassword, {Uint8List? userEntropy}) async {}

  @override
  Future<bool> unlock(String masterPassword) async => true;

  @override
  void lock() {}

  @override
  Future<Uint8List?> getSearchKey() async => Uint8List(32);

  @override
  Future<String?> getDeviceId() async => 'test-device';

  @override
  Future<bool> changeMasterPassword(String oldPassword, String newPassword) async => true;

  @override
  Future<Uint8List?> rotateDEK(String masterPassword) async => Uint8List(32);

  @override
  Future<bool> isInitialized() async => true;

  @override
  Future<void> reset() async {}

  @override
  Future<String?> exportEmergencyKit(String masterPassword) async => '{"version": 1}';

  @override
  Future<bool> importEmergencyKit(String kitJson) async => true;

  @override
  Future<void> savePasswordForBiometric(String masterPassword) async {}

  @override
  Future<void> clearPasswordForBiometric() async {}

  @override
  Future<String?> getStoredBiometricPassword() async => null;
}

class MockEventStore extends Mock implements EventStore {
  @override
  Future<void> appendEvent(PasswordEvent event, {Transaction? txn}) async {}

  @override
  Future<void> appendEvents(List<PasswordEvent> events, {Transaction? txn}) async {}

  @override
  Future<PasswordEvent?> getEvent(String eventId) async => null;

  @override
  Future<List<PasswordEvent>> getEventsForCard(String cardId) async => [];

  @override
  Future<List<PasswordEvent>> getAllEvents() async => [];

  @override
  Future<List<PasswordEvent>> getEventsAfterHlc(HLC hlc) async => [];

  @override
  Future<List<PasswordEvent>> getUnsyncedEvents() async => [];

  @override
  Future<void> markEventsAsSynced(List<String> eventIds, {Transaction? txn}) async {}

  @override
  Future<HLC?> getLatestHlc() async => null;

  @override
  Future<int> getEventCount() async => 0;

  @override
  Future<List<PasswordEvent>> getEventsByType(EventType type) async => [];

  @override
  Future<void> deleteEventsBeforeHlc(HLC hlc) async {}

  @override
  Future<void> createSnapshot({
    required int version,
    required Map<String, dynamic> stateJson,
    required HLC eventRangeStart,
    required HLC eventRangeEnd,
    String? previousSnapshotId,
  }) async {}

  @override
  Future<Snapshot?> getLatestSnapshot() async => null;

  @override
  Future<Snapshot?> getSnapshotByVersion(int version) async => null;

  @override
  Future<List<Snapshot>> getAllSnapshots() async => [];

  @override
  Future<void> pruneSnapshots(int keepCount) async {}

  @override
  Future<void> updateLastSync(HLC hlc) async {}

  @override
  Future<HLC?> getLastSyncHlc() async => null;

  @override
  Future<int> getPendingCount() async => 0;

  @override
  Future<void> close() async {}
}

class MockTransaction extends Mock implements Transaction {
  @override
  Database get database => throw UnimplementedError();

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {}

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> insert(String table, Map<String, Object?>? values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async => 0;

  @override
  Future<List<Map<String, Object?>>> query(String table, {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) async => [];

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async => [];

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> update(String table, Map<String, Object?>? values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async => 0;

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async => 0;

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async => 0;

  @override
  Batch batch() => MockBatch();
}

class MockBatch extends Mock implements Batch {
  @override
  Database get database => throw UnimplementedError();
}
