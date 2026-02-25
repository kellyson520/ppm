import 'dart:async';
import 'dart:convert';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/models.dart';
import '../crypto/crypto_service.dart';

/// Event Store for Event Sourcing
///
/// Stores immutable event log in SQLCipher-encrypted SQLite
/// Supports:
/// - Event append-only storage
/// - Event retrieval by various criteria
/// - Event chain validation
/// - Snapshot management
class EventStore {
  final Database _db;
  final CryptoService _cryptoService;

  // Table names
  static const String _eventsTable = 'password_events';
  static const String _snapshotsTable = 'snapshots';
  static const String _syncStateTable = 'sync_state';

  EventStore(this._db, {CryptoService? cryptoService})
      : _cryptoService = cryptoService ?? CryptoService();

  /// Initialize database tables
  static Future<void> initializeTables(Database db) async {
    // Events table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_eventsTable (
        event_id TEXT PRIMARY KEY,
        hlc_physical INTEGER NOT NULL,
        hlc_logical INTEGER NOT NULL,
        hlc_device TEXT NOT NULL,
        device_id TEXT NOT NULL,
        type TEXT NOT NULL,
        card_id TEXT NOT NULL,
        payload_ciphertext TEXT NOT NULL,
        payload_iv TEXT NOT NULL,
        payload_auth_tag TEXT NOT NULL,
        prev_event_hash TEXT,
        signature TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        synced_at TEXT
      )
    ''');

    // Indexes for efficient queries
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_events_card_id ON $_eventsTable(card_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_events_hlc ON $_eventsTable(hlc_physical, hlc_logical, hlc_device)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_events_synced ON $_eventsTable(is_synced)
    ''');

    // Snapshots table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_snapshotsTable (
        snapshot_id TEXT PRIMARY KEY,
        version INTEGER NOT NULL,
        timestamp_physical INTEGER NOT NULL,
        timestamp_logical INTEGER NOT NULL,
        timestamp_device TEXT NOT NULL,
        state_json TEXT NOT NULL,
        event_range_start TEXT NOT NULL,
        event_range_end TEXT NOT NULL,
        checksum TEXT NOT NULL,
        previous_snapshot TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Sync state table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_syncStateTable (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        last_sync_at TEXT,
        last_sync_hlc_physical INTEGER,
        last_sync_hlc_logical INTEGER,
        last_sync_hlc_device TEXT,
        pending_count INTEGER DEFAULT 0
      )
    ''');

    // Insert initial sync state
    await db.insert(
      _syncStateTable,
      {'id': 1, 'pending_count': 0},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ==================== Event Operations ====================

  /// Append a new event to the log
  Future<void> appendEvent(PasswordEvent event, {Transaction? txn}) async {
    final executor = txn ?? _db;

    await executor.insert(
      _eventsTable,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update pending count
    await _incrementPendingCount(txn: txn);
  }

  /// Append multiple events
  Future<void> appendEvents(List<PasswordEvent> events,
      {Transaction? txn}) async {
    final executor = txn ?? _db;
    final batch = executor.batch();
    for (final event in events) {
      batch.insert(
        _eventsTable,
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);

    // Update pending count
    await _updatePendingCount(events.length, txn: txn);
  }

  /// Get event by ID
  Future<PasswordEvent?> getEvent(String eventId) async {
    final result = await _db.query(
      _eventsTable,
      where: 'event_id = ?',
      whereArgs: [eventId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return PasswordEvent.fromMap(result.first);
  }

  /// Get all events for a card
  Future<List<PasswordEvent>> getEventsForCard(String cardId) async {
    final result = await _db.query(
      _eventsTable,
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'hlc_physical, hlc_logical, hlc_device',
    );

    return result.map((r) => PasswordEvent.fromMap(r)).toList();
  }

  /// Get all events sorted by HLC
  Future<List<PasswordEvent>> getAllEvents() async {
    final result = await _db.query(
      _eventsTable,
      orderBy: 'hlc_physical, hlc_logical, hlc_device',
    );

    return result.map((r) => PasswordEvent.fromMap(r)).toList();
  }

  /// Get events after a specific HLC (for incremental sync)
  Future<List<PasswordEvent>> getEventsAfterHlc(HLC hlc) async {
    final result = await _db.query(
      _eventsTable,
      where: '''
        hlc_physical > ? OR 
        (hlc_physical = ? AND hlc_logical > ?) OR
        (hlc_physical = ? AND hlc_logical = ? AND hlc_device > ?)
      ''',
      whereArgs: [
        hlc.physicalTime,
        hlc.physicalTime,
        hlc.logicalCounter,
        hlc.physicalTime,
        hlc.logicalCounter,
        hlc.deviceId,
      ],
      orderBy: 'hlc_physical, hlc_logical, hlc_device',
    );

    return result.map((r) => PasswordEvent.fromMap(r)).toList();
  }

  /// Get unsynced events
  Future<List<PasswordEvent>> getUnsyncedEvents() async {
    final result = await _db.query(
      _eventsTable,
      where: 'is_synced = 0',
      orderBy: 'hlc_physical, hlc_logical, hlc_device',
    );

    return result.map((r) => PasswordEvent.fromMap(r)).toList();
  }

  /// Mark events as synced
  Future<void> markEventsAsSynced(List<String> eventIds,
      {Transaction? txn}) async {
    final executor = txn ?? _db;
    final batch = executor.batch();
    for (final eventId in eventIds) {
      batch.update(
        _eventsTable,
        {
          'is_synced': 1,
          'synced_at': DateTime.now().toIso8601String(),
        },
        where: 'event_id = ?',
        whereArgs: [eventId],
      );
    }
    await batch.commit(noResult: true);

    // Recalculate pending count
    await _recalculatePendingCount(txn: txn);
  }

  /// Get latest HLC from events
  Future<HLC?> getLatestHlc() async {
    final result = await _db.query(
      _eventsTable,
      columns: ['hlc_physical', 'hlc_logical', 'hlc_device'],
      orderBy: 'hlc_physical DESC, hlc_logical DESC, hlc_device DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return HLC.fromJson({
      'physicalTime': result.first['hlc_physical'] as int,
      'logicalCounter': result.first['hlc_logical'] as int,
      'deviceId': result.first['hlc_device'] as String,
    });
  }

  /// Get event count
  Future<int> getEventCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $_eventsTable',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get events by type
  Future<List<PasswordEvent>> getEventsByType(EventType type) async {
    final result = await _db.query(
      _eventsTable,
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'hlc_physical, hlc_logical, hlc_device',
    );

    return result.map((r) => PasswordEvent.fromMap(r)).toList();
  }

  /// Delete old events (after compaction)
  Future<void> deleteEventsBeforeHlc(HLC hlc) async {
    await _db.delete(
      _eventsTable,
      where: '''
        hlc_physical < ? OR 
        (hlc_physical = ? AND hlc_logical < ?) OR
        (hlc_physical = ? AND hlc_logical = ? AND hlc_device <= ?)
      ''',
      whereArgs: [
        hlc.physicalTime,
        hlc.physicalTime,
        hlc.logicalCounter,
        hlc.physicalTime,
        hlc.logicalCounter,
        hlc.deviceId,
      ],
    );
  }

  // ==================== Snapshot Operations ====================

  /// Create a snapshot
  Future<void> createSnapshot({
    required int version,
    required Map<String, dynamic> stateJson,
    required HLC eventRangeStart,
    required HLC eventRangeEnd,
    String? previousSnapshotId,
  }) async {
    final stateString = jsonEncode(stateJson);
    final checksum = _cryptoService.sha256String(stateString);

    final snapshotId = _cryptoService
        .generateRandomBytes(16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    await _db.insert(_snapshotsTable, {
      'snapshot_id': snapshotId,
      'version': version,
      'timestamp_physical': DateTime.now().millisecondsSinceEpoch,
      'timestamp_logical': 0,
      'timestamp_device': 'local',
      'state_json': stateString,
      'event_range_start': jsonEncode(eventRangeStart.toJson()),
      'event_range_end': jsonEncode(eventRangeEnd.toJson()),
      'checksum': checksum,
      'previous_snapshot': previousSnapshotId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get latest snapshot
  Future<Snapshot?> getLatestSnapshot() async {
    final result = await _db.query(
      _snapshotsTable,
      orderBy: 'version DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Snapshot.fromMap(result.first);
  }

  /// Get snapshot by version
  Future<Snapshot?> getSnapshotByVersion(int version) async {
    final result = await _db.query(
      _snapshotsTable,
      where: 'version = ?',
      whereArgs: [version],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Snapshot.fromMap(result.first);
  }

  /// Get all snapshots
  Future<List<Snapshot>> getAllSnapshots() async {
    final result = await _db.query(
      _snapshotsTable,
      orderBy: 'version DESC',
    );

    return result.map((r) => Snapshot.fromMap(r)).toList();
  }

  /// Delete old snapshots (keep last N)
  Future<void> pruneSnapshots(int keepCount) async {
    final snapshots = await getAllSnapshots();
    if (snapshots.length <= keepCount) return;

    final toDelete = snapshots.sublist(keepCount);
    final batch = _db.batch();
    for (final snapshot in toDelete) {
      batch.delete(
        _snapshotsTable,
        where: 'snapshot_id = ?',
        whereArgs: [snapshot.snapshotId],
      );
    }
    await batch.commit(noResult: true);
  }

  // ==================== Sync State Operations ====================

  /// Update last sync timestamp
  Future<void> updateLastSync(HLC hlc) async {
    await _db.update(
      _syncStateTable,
      {
        'last_sync_at': DateTime.now().toIso8601String(),
        'last_sync_hlc_physical': hlc.physicalTime,
        'last_sync_hlc_logical': hlc.logicalCounter,
        'last_sync_hlc_device': hlc.deviceId,
      },
      where: 'id = 1',
    );
  }

  /// Get last sync HLC
  Future<HLC?> getLastSyncHlc() async {
    final result = await _db.query(
      _syncStateTable,
      columns: [
        'last_sync_hlc_physical',
        'last_sync_hlc_logical',
        'last_sync_hlc_device',
      ],
      where: 'id = 1',
      limit: 1,
    );

    if (result.isEmpty) return null;
    final row = result.first;
    if (row['last_sync_hlc_physical'] == null) return null;

    return HLC.fromJson({
      'physicalTime': row['last_sync_hlc_physical'] as int,
      'logicalCounter': row['last_sync_hlc_logical'] as int,
      'deviceId': row['last_sync_hlc_device'] as String,
    });
  }

  /// Get pending sync count
  Future<int> getPendingCount() async {
    final result = await _db.query(
      _syncStateTable,
      columns: ['pending_count'],
      where: 'id = 1',
      limit: 1,
    );

    if (result.isEmpty) return 0;
    return (result.first['pending_count'] as int?) ?? 0;
  }

  // ==================== Private Methods ====================

  Future<void> _incrementPendingCount({Transaction? txn}) async {
    final executor = txn ?? _db;
    await executor.rawUpdate('''
      UPDATE $_syncStateTable 
      SET pending_count = pending_count + 1 
      WHERE id = 1
    ''');
  }

  Future<void> _updatePendingCount(int delta, {Transaction? txn}) async {
    final executor = txn ?? _db;
    await executor.rawUpdate('''
      UPDATE $_syncStateTable 
      SET pending_count = pending_count + ? 
      WHERE id = 1
    ''', [delta]);
  }

  Future<void> _recalculatePendingCount({Transaction? txn}) async {
    final executor = txn ?? _db;
    final result = await executor.rawQuery('''
      SELECT COUNT(*) as count FROM $_eventsTable WHERE is_synced = 0
    ''');
    final count = (result.first['count'] as int?) ?? 0;

    await executor.update(
      _syncStateTable,
      {'pending_count': count},
      where: 'id = 1',
    );
  }

  /// Close the database
  Future<void> close() async {
    await _db.close();
  }
}

/// Snapshot data class
class Snapshot {
  final String snapshotId;
  final int version;
  final HLC timestamp;
  final Map<String, dynamic> stateJson;
  final HLC eventRangeStart;
  final HLC eventRangeEnd;
  final String checksum;
  final String? previousSnapshotId;
  final DateTime createdAt;

  Snapshot({
    required this.snapshotId,
    required this.version,
    required this.timestamp,
    required this.stateJson,
    required this.eventRangeStart,
    required this.eventRangeEnd,
    required this.checksum,
    this.previousSnapshotId,
    required this.createdAt,
  });

  factory Snapshot.fromMap(Map<String, dynamic> map) {
    return Snapshot(
      snapshotId: map['snapshot_id'] as String,
      version: map['version'] as int,
      timestamp: HLC.fromJson({
        'physicalTime': map['timestamp_physical'] as int,
        'logicalCounter': map['timestamp_logical'] as int,
        'deviceId': map['timestamp_device'] as String,
      }),
      stateJson:
          jsonDecode(map['state_json'] as String) as Map<String, dynamic>,
      eventRangeStart: HLC.fromJson(
        jsonDecode(map['event_range_start'] as String) as Map<String, dynamic>,
      ),
      eventRangeEnd: HLC.fromJson(
        jsonDecode(map['event_range_end'] as String) as Map<String, dynamic>,
      ),
      checksum: map['checksum'] as String,
      previousSnapshotId: map['previous_snapshot'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Verify checksum
  bool verifyChecksum(CryptoService cryptoService) {
    final stateString = jsonEncode(stateJson);
    final calculated = cryptoService.sha256String(stateString);
    return calculated == checksum;
  }
}
