// Mocks for WebDAV Sync tests
// Manual implementation instead of code generation

import 'dart:async';
import 'dart:typed_data';
import 'package:mockito/mockito.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:ztd_password_manager/core/events/event_store.dart';
import 'package:ztd_password_manager/core/crypto/key_manager.dart';
import 'package:ztd_password_manager/core/models/models.dart';

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

class MockKeyManager extends Mock implements KeyManager {
  @override
  bool get isUnlocked => false;

  @override
  Future<void> initialize(String masterPassword, {Uint8List? userEntropy}) async {}

  @override
  Future<bool> unlock(String masterPassword) async => false;

  @override
  void lock() {}

  @override
  Future<Uint8List?> getSearchKey() async => null;

  @override
  Future<String?> getDeviceId() async => null;

  @override
  Future<bool> changeMasterPassword(String oldPassword, String newPassword) async => false;

  @override
  Future<Uint8List?> rotateDEK(String masterPassword) async => null;

  @override
  Future<bool> isInitialized() async => false;

  @override
  Future<void> reset() async {}

  @override
  Future<String?> exportEmergencyKit(String masterPassword) async => null;

  @override
  Future<bool> importEmergencyKit(String kitJson) async => false;

  @override
  Future<void> savePasswordForBiometric(String masterPassword) async {}

  @override
  Future<void> clearPasswordForBiometric() async {}

  @override
  Future<String?> getStoredBiometricPassword() async => null;
}
