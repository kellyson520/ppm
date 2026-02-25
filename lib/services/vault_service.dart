import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../core/diagnostics/crash_report_service.dart';
import '../core/models/models.dart';
import '../core/crypto/crypto_service.dart';
import '../core/crypto/key_manager.dart';
import '../core/storage/database_service.dart';
import '../core/events/event_store.dart';
import '../core/crdt/crdt_merger.dart';

/// Vault Service - Main business logic for password management
///
/// Coordinates between:
/// - KeyManager (encryption keys)
/// - DatabaseService (persistent storage)
/// - EventStore (event sourcing)
/// - CryptoService (cryptographic operations)
class VaultService {
  final KeyManager _keyManager;
  final DatabaseService _database;
  final CryptoService _cryptoService;

  // Session state
  bool _isUnlocked = false;
  Uint8List? _sessionDek;
  Uint8List? _sessionSearchKey;
  String? _deviceId;

  VaultService({
    KeyManager? keyManager,
    DatabaseService? database,
    CryptoService? cryptoService,
  })  : _keyManager = keyManager ?? KeyManager(),
        _database = database ?? DatabaseService(),
        _cryptoService = cryptoService ?? CryptoService();

  // ==================== Getters ====================

  bool get isUnlocked => _isUnlocked;

  Uint8List? get sessionDek =>
      _sessionDek != null ? Uint8List.fromList(_sessionDek!) : null;

  Uint8List? get sessionSearchKey =>
      _sessionSearchKey != null ? Uint8List.fromList(_sessionSearchKey!) : null;

  String? get deviceId => _deviceId;

  // ==================== Lifecycle ====================

  /// Check if vault is initialized
  Future<bool> isInitialized() async {
    return await _keyManager.isInitialized();
  }

  /// Initialize new vault with master password
  Future<void> initialize(String masterPassword) async {
    // Initialize key manager
    await _keyManager.initialize(masterPassword);

    // Get encryption key for database (derived from DEK)
    final dek = _keyManager.dek;
    if (dek == null) {
      throw StateError('Failed to initialize encryption keys');
    }

    // Initialize database with encrypted key
    final dbKey = _cryptoService.sha256String(base64Encode(dek));
    await _database.initialize(dbKey);

    // Load session state
    await _loadSessionState();

    _isUnlocked = true;
    _sessionDek = Uint8List.fromList(dek);
  }

  /// Unlock vault with master password
  Future<bool> unlock(String masterPassword) async {
    if (_isUnlocked) return true;

    // Unlock key manager
    if (!await _keyManager.unlock(masterPassword)) {
      return false;
    }

    // Get DEK
    final dek = _keyManager.dek;
    if (dek == null) {
      return false;
    }

    // Initialize database
    final dbKey = _cryptoService.sha256String(base64Encode(dek));
    await _database.initialize(dbKey);

    // Load session state
    await _loadSessionState();

    _isUnlocked = true;
    _sessionDek = Uint8List.fromList(dek);

    return true;
  }

  /// Lock vault
  Future<void> lock() async {
    _isUnlocked = false;

    // Clear session keys
    if (_sessionDek != null) {
      _cryptoService.clearBuffer(_sessionDek!);
      _sessionDek = null;
    }
    if (_sessionSearchKey != null) {
      _cryptoService.clearBuffer(_sessionSearchKey!);
      _sessionSearchKey = null;
    }

    _deviceId = null;

    // Lock key manager
    _keyManager.lock();

    // Close database
    await _database.close();
  }

  // ==================== Password Card Operations ====================

  /// Create a new password card
  Future<PasswordCard> createCard(PasswordPayload payload) async {
    _ensureUnlocked();

    // Encrypt payload
    final encryptedPayload = await _encryptPayload(payload);

    // Generate blind indexes for search
    final searchKey = _sessionSearchKey;
    if (searchKey == null) {
      throw StateError(
          'Search key is not initialized. Ensure vault is unlocked.');
    }
    final searchableText =
        '${payload.title} ${payload.username} ${payload.url ?? ''}';
    final blindIndexes = _cryptoService.generateBlindIndexes(
      searchableText,
      searchKey,
    );

    // Create event
    final event = PasswordEvent.create(
      type: EventType.cardCreated,
      cardId: const Uuid().v4(),
      payload: EncryptedPayload(
        ciphertext: base64Encode(encryptedPayload.ciphertext),
        iv: base64Encode(encryptedPayload.iv),
        authTag: base64Encode(encryptedPayload.authTag),
      ),
      deviceId: _deviceId ?? 'unknown-device',
    );

    // 将完整三段（ciphertext + iv + authTag）序列化存入 card.encryptedPayload
    // 以便 decryptCard() 能正确重建 IV 和 authTag 进行 AES-GCM 解密
    final serializedPayload = encryptedPayload.serialize();

    // Create card
    final card = PasswordCard(
      cardId: event.cardId,
      encryptedPayload: serializedPayload,
      blindIndexes: blindIndexes,
      createdAt: event.hlc,
      updatedAt: event.hlc,
      currentEventId: event.eventId,
      isDeleted: false,
    );

    // Save to database atomically
    await _database.transaction((txn) async {
      await _database.saveCard(card, txn: txn);
      await _database.eventStore.appendEvent(event, txn: txn);
    });

    return card;
  }

  /// Update an existing password card
  Future<PasswordCard?> updateCard(
    String cardId,
    PasswordPayload newPayload,
  ) async {
    _ensureUnlocked();

    // Get existing card
    final existingCard = await _database.getCard(cardId);
    if (existingCard == null || existingCard.isDeleted) {
      return null;
    }

    // Encrypt new payload
    final encryptedPayload = await _encryptPayload(newPayload);

    // Generate new blind indexes
    final searchKey = _sessionSearchKey;
    if (searchKey == null) {
      throw StateError(
          'Search key is not initialized. Ensure vault is unlocked.');
    }
    final searchableText =
        '${newPayload.title} ${newPayload.username} ${newPayload.url ?? ''}';
    final blindIndexes = _cryptoService.generateBlindIndexes(
      searchableText,
      searchKey,
    );

    // Create update event
    final event = PasswordEvent.create(
      type: EventType.cardUpdated,
      cardId: cardId,
      payload: EncryptedPayload(
        ciphertext: base64Encode(encryptedPayload.ciphertext),
        iv: base64Encode(encryptedPayload.iv),
        authTag: base64Encode(encryptedPayload.authTag),
      ),
      deviceId: _deviceId ?? 'unknown-device',
      prevEventHash: existingCard.currentEventId,
    );

    // 将完整三段序列化存入 updatedCard，与 createCard 保持一致
    final serializedPayload = encryptedPayload.serialize();

    // Update card
    final updatedCard = existingCard.copyWith(
      encryptedPayload: serializedPayload,
      blindIndexes: blindIndexes,
      updatedAt: event.hlc,
      currentEventId: event.eventId,
    );

    // Save to database atomically
    await _database.transaction((txn) async {
      await _database.saveCard(updatedCard, txn: txn);
      await _database.eventStore.appendEvent(event, txn: txn);
    });

    return updatedCard;
  }

  /// Delete a password card (soft delete)
  Future<bool> deleteCard(String cardId) async {
    _ensureUnlocked();

    final card = await _database.getCard(cardId);
    if (card == null || card.isDeleted) {
      return false;
    }

    // Create delete event
    final event = PasswordEvent.create(
      type: EventType.cardDeleted,
      cardId: cardId,
      payload: const EncryptedPayload(
        ciphertext: '',
        iv: '',
        authTag: '',
      ),
      deviceId: _deviceId ?? 'unknown-device',
      prevEventHash: card.currentEventId,
    );

    // Apply tombstone atomically
    await _database.transaction((txn) async {
      await _database.deleteCard(cardId, _deviceId!, event.eventId, txn: txn);
      await _database.eventStore.appendEvent(event, txn: txn);
    });

    return true;
  }

  /// Permanently delete a card (hard delete)
  Future<bool> permanentlyDeleteCard(String cardId) async {
    _ensureUnlocked();
    await _database.permanentlyDeleteCard(cardId);
    return true;
  }

  /// Get a password card
  Future<PasswordCard?> getCard(String cardId) async {
    _ensureUnlocked();
    return await _database.getCard(cardId);
  }

  /// Get all active password cards
  Future<List<PasswordCard>> getAllCards() async {
    _ensureUnlocked();
    return await _database.getAllActiveCards();
  }

  /// Decrypt a password card
  ///
  /// card.encryptedPayload 存储的是 EncryptedData.serialize() 的完整序列化字符串，
  /// 包含 ciphertext、iv、authTag 三段，需使用 deserialize 完整重建后再解密。
  Future<PasswordPayload?> decryptCard(PasswordCard card) async {
    _ensureUnlocked();

    try {
      // 反序列化完整三段（ciphertext + iv + authTag），不再使用硬编码零字节
      final encryptedData = EncryptedData.deserialize(card.encryptedPayload);

      final decrypted = _cryptoService.decryptString(
        encryptedData,
        _sessionDek!,
      );

      return PasswordPayload.fromJson(
        jsonDecode(decrypted) as Map<String, dynamic>,
      );
    } on Object catch (e, stack) {
      CrashReportService.instance.reportError(
        e,
        stack,
        source: 'VaultService.decryptCard(${card.cardId})',
      );
      return null;
    }
  }

  // ==================== Search Operations ====================

  /// Search password cards using blind indexes
  Future<List<PasswordCard>> search(String query) async {
    _ensureUnlocked();

    if (query.isEmpty) {
      return await getAllCards();
    }

    // Generate search hashes
    final searchKey = _sessionSearchKey;
    if (searchKey == null) {
      throw StateError(
          'Search key is not initialized. Ensure vault is unlocked.');
    }
    final searchHashes = _cryptoService.generateBlindIndexes(
      query.toLowerCase(),
      searchKey,
    );

    // Search using blind indexes
    return await _database.searchByBlindIndexes(searchHashes);
  }

  // ==================== Event Operations ====================

  /// Get all events
  Future<List<PasswordEvent>> getAllEvents() async {
    _ensureUnlocked();
    return await _database.eventStore.getAllEvents();
  }

  /// Get events for a specific card
  Future<List<PasswordEvent>> getCardEvents(String cardId) async {
    _ensureUnlocked();
    return await _database.eventStore.getEventsForCard(cardId);
  }

  /// Get unsynced events
  Future<List<PasswordEvent>> getUnsyncedEvents() async {
    _ensureUnlocked();
    return await _database.eventStore.getUnsyncedEvents();
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    _ensureUnlocked();
    return await _database.eventStore.getPendingCount();
  }

  // ==================== Snapshot Operations ====================

  /// Create a snapshot (compaction)
  Future<void> createSnapshot() async {
    _ensureUnlocked();

    final events = await _database.eventStore.getAllEvents();
    final cards = await _database.getAllActiveCards();

    // Build state from events
    final state = CrdtMerger.buildStateFromEvents(events);

    // Compact events
    final compactedEvents = CrdtMerger.compactEvents(events, state);

    // Get event range
    final eventRangeStart =
        events.isNotEmpty ? events.first.hlc : HLC.now(_deviceId!);
    final eventRangeEnd =
        events.isNotEmpty ? events.last.hlc : HLC.now(_deviceId!);

    // Get latest snapshot version
    final latestSnapshot = await _database.eventStore.getLatestSnapshot();
    final newVersion = (latestSnapshot?.version ?? 0) + 1;

    // Create snapshot
    await _database.eventStore.createSnapshot(
      version: newVersion,
      stateJson: {
        'cards': cards.map((c) => c.toMap()).toList(),
        'compactedEvents': compactedEvents.map((e) => e.toJson()).toList(),
      },
      eventRangeStart: eventRangeStart,
      eventRangeEnd: eventRangeEnd,
      previousSnapshotId: latestSnapshot?.snapshotId,
    );

    // Prune old snapshots (keep last 3)
    await _database.eventStore.pruneSnapshots(3);

    // Delete old events
    await _database.eventStore.deleteEventsBeforeHlc(eventRangeEnd);
  }

  /// Get all snapshots
  Future<List<Snapshot>> getSnapshots() async {
    _ensureUnlocked();
    return await _database.eventStore.getAllSnapshots();
  }

  // ==================== Security Operations ====================

  /// Change master password
  Future<bool> changeMasterPassword(
    String oldPassword,
    String newPassword,
  ) async {
    return await _keyManager.changeMasterPassword(oldPassword, newPassword);
  }

  /// Rotate DEK
  Future<bool> rotateDEK(String masterPassword) async {
    final newDek = await _keyManager.rotateDEK(masterPassword);
    if (newDek == null) return false;

    // Re-encrypt all cards with new DEK
    // This is a complex operation that should be done carefully
    // For now, we'll just update the session
    _sessionDek = newDek;

    return true;
  }

  /// Export emergency kit
  Future<String?> exportEmergencyKit(String masterPassword) async {
    return await _keyManager.exportEmergencyKit(masterPassword);
  }

  /// Import emergency kit
  Future<bool> importEmergencyKit(String kitJson) async {
    return await _keyManager.importEmergencyKit(kitJson);
  }

  /// Get vault statistics
  Future<VaultStats> getStats() async {
    _ensureUnlocked();

    final cardCount = await _database.getCardCount();
    final eventCount = await _database.eventStore.getEventCount();
    final pendingCount = await _database.eventStore.getPendingCount();
    final snapshots = await _database.eventStore.getAllSnapshots();

    return VaultStats(
      cardCount: cardCount,
      eventCount: eventCount,
      pendingSyncCount: pendingCount,
      snapshotCount: snapshots.length,
      latestSnapshotVersion:
          snapshots.isNotEmpty ? snapshots.first.version : null,
    );
  }

  // ==================== Private Methods ====================

  void _ensureUnlocked() {
    if (!_isUnlocked) {
      throw StateError('Vault is locked. Call unlock() first.');
    }
  }

  Future<void> _loadSessionState() async {
    _sessionSearchKey = await _keyManager.getSearchKey();
    _deviceId = await _keyManager.getDeviceId();

    if (_sessionSearchKey == null || _deviceId == null) {
      throw StateError('Failed to load session state');
    }
  }

  Future<EncryptedData> _encryptPayload(PasswordPayload payload) async {
    final jsonPayload = jsonEncode(payload.toJson());
    return _cryptoService.encryptString(jsonPayload, _sessionDek!);
  }

  /// Dispose
  Future<void> dispose() async {
    await lock();
  }
}

/// Vault Statistics
class VaultStats {
  final int cardCount;
  final int eventCount;
  final int pendingSyncCount;
  final int snapshotCount;
  final int? latestSnapshotVersion;

  VaultStats({
    required this.cardCount,
    required this.eventCount,
    required this.pendingSyncCount,
    required this.snapshotCount,
    this.latestSnapshotVersion,
  });

  @override
  String toString() {
    return 'VaultStats(cards: $cardCount, events: $eventCount, pending: $pendingSyncCount, snapshots: $snapshotCount)';
  }
}
