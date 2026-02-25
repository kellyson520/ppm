import 'dart:async';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/models.dart';
import '../crypto/crypto_service.dart';
import '../events/event_store.dart';

/// Database Service for ZTD Password Manager
/// 
/// Manages SQLCipher-encrypted SQLite database
/// Provides:
/// - Password card storage with blind indexes
/// - Event sourcing storage
/// - Encrypted search capabilities
class DatabaseService {
  static Database? _db;
  final CryptoService _cryptoService;
  EventStore? _eventStore;

  DatabaseService({CryptoService? cryptoService})
      : _cryptoService = cryptoService ?? CryptoService();

  /// Get database instance
  Database get db {
    if (_db == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _db!;
  }

  /// Get event store instance
  EventStore get eventStore {
    if (_eventStore == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _eventStore!;
  }

  /// Initialize database with encryption key
  Future<void> initialize(String encryptionKey) async {
    if (_db != null) return;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'ztd_vault.db');

    _db = await openDatabase(
      path,
      password: encryptionKey,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    _eventStore = EventStore(_db!);
  }

  /// Database creation
  Future<void> _onCreate(Database db, int version) async {
    // Password cards table
    await db.execute('''
      CREATE TABLE password_cards (
        card_id TEXT PRIMARY KEY,
        encrypted_payload TEXT NOT NULL,
        blind_indexes TEXT NOT NULL DEFAULT '',
        created_at_physical INTEGER NOT NULL,
        created_at_logical INTEGER NOT NULL,
        created_at_device TEXT NOT NULL,
        updated_at_physical INTEGER NOT NULL,
        updated_at_logical INTEGER NOT NULL,
        updated_at_device TEXT NOT NULL,
        current_event_id TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Indexes for efficient queries
    await db.execute('''
      CREATE INDEX idx_cards_updated ON password_cards(
        updated_at_physical, updated_at_logical, updated_at_device
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_cards_deleted ON password_cards(is_deleted)
    ''');

    // Blind index search table
    await db.execute('''
      CREATE TABLE blind_index_entries (
        index_hash TEXT NOT NULL,
        card_id TEXT NOT NULL,
        PRIMARY KEY (index_hash, card_id),
        FOREIGN KEY (card_id) REFERENCES password_cards(card_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_blind_index ON blind_index_entries(index_hash)
    ''');

    // Initialize event store tables
    await EventStore.initializeTables(db);
  }

  /// Database upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations
  }

  // ==================== Password Card Operations ====================

  /// Insert or update a password card
  Future<void> saveCard(PasswordCard card) async {
    await db.insert(
      'password_cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update blind index entries
    await _updateBlindIndexes(card);
  }

  /// Get card by ID
  Future<PasswordCard?> getCard(String cardId) async {
    final result = await db.query(
      'password_cards',
      where: 'card_id = ?',
      whereArgs: [cardId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return PasswordCard.fromMap(result.first);
  }

  /// Get all active (non-deleted) cards
  Future<List<PasswordCard>> getAllActiveCards() async {
    final result = await db.query(
      'password_cards',
      where: 'is_deleted = 0',
      orderBy: 'updated_at_physical DESC, updated_at_logical DESC',
    );

    return result.map((r) => PasswordCard.fromMap(r)).toList();
  }

  /// Get cards updated after a specific HLC
  Future<List<PasswordCard>> getCardsUpdatedAfterHlc(HLC hlc) async {
    final result = await db.query(
      'password_cards',
      where: '''
        is_deleted = 0 AND (
          updated_at_physical > ? OR 
          (updated_at_physical = ? AND updated_at_logical > ?) OR
          (updated_at_physical = ? AND updated_at_logical = ? AND updated_at_device > ?)
        )
      ''',
      whereArgs: [
        hlc.physicalTime,
        hlc.physicalTime, hlc.logicalCounter,
        hlc.physicalTime, hlc.logicalCounter, hlc.deviceId,
      ],
      orderBy: 'updated_at_physical DESC, updated_at_logical DESC',
    );

    return result.map((r) => PasswordCard.fromMap(r)).toList();
  }

  /// Delete a card (soft delete with tombstone)
  Future<void> deleteCard(String cardId, String deviceId, String eventId) async {
    final card = await getCard(cardId);
    if (card == null) return;

    final deletedCard = card.markDeleted(deviceId, eventId);
    await saveCard(deletedCard);
  }

  /// Permanently delete a card (hard delete)
  Future<void> permanentlyDeleteCard(String cardId) async {
    await db.delete(
      'blind_index_entries',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );

    await db.delete(
      'password_cards',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
  }

  /// Get card count
  Future<int> getCardCount() async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM password_cards WHERE is_deleted = 0
    ''');
    return (result.first['count'] as int?) ?? 0;
  }

  // ==================== Search Operations ====================

  /// Search cards using blind indexes
  /// 
  /// [searchHashes]: List of HMAC hashes from search query
  /// Returns cards that match any of the search hashes
  Future<List<PasswordCard>> searchByBlindIndexes(
    List<String> searchHashes,
  ) async {
    if (searchHashes.isEmpty) return [];

    // Build IN clause
    final placeholders = List.filled(searchHashes.length, '?').join(',');
    
    // Find matching card IDs
    final indexResult = await db.rawQuery('''
      SELECT DISTINCT card_id FROM blind_index_entries
      WHERE index_hash IN ($placeholders)
    ''', searchHashes);

    final cardIds = indexResult.map((r) => r['card_id'] as String).toList();
    if (cardIds.isEmpty) return [];

    // Fetch the cards
    final cardPlaceholders = List.filled(cardIds.length, '?').join(',');
    final result = await db.query(
      'password_cards',
      where: 'card_id IN ($cardPlaceholders) AND is_deleted = 0',
      whereArgs: cardIds,
    );

    return result.map((r) => PasswordCard.fromMap(r)).toList();
  }

  /// Full text search (requires decryption)
  /// 
  /// This is less efficient but can search decrypted content
  /// Should be used only when necessary
  Future<List<PasswordCard>> searchByDecryptedContent(
    String query,
    Future<String> Function(PasswordCard) decryptFn,
  ) async {
    final allCards = await getAllActiveCards();
    final results = <PasswordCard>[];
    final lowerQuery = query.toLowerCase();

    for (final card in allCards) {
      try {
        final decrypted = await decryptFn(card);
        if (decrypted.toLowerCase().contains(lowerQuery)) {
          results.add(card);
        }
      } catch (e) {
        // Skip cards that can't be decrypted
      }
    }

    return results;
  }

  // ==================== Blind Index Operations ====================

  /// Update blind index entries for a card
  Future<void> _updateBlindIndexes(PasswordCard card) async {
    // Delete existing entries
    await db.delete(
      'blind_index_entries',
      where: 'card_id = ?',
      whereArgs: [card.cardId],
    );

    // Insert new entries
    if (card.blindIndexes.isNotEmpty && !card.isDeleted) {
      final batch = db.batch();
      for (final indexHash in card.blindIndexes) {
        batch.insert(
          'blind_index_entries',
          {
            'index_hash': indexHash,
            'card_id': card.cardId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }
  }

  /// Generate and store blind indexes for a card
  Future<void> generateBlindIndexes(
    String cardId,
    String plaintext,
    Uint8List searchKey,
  ) async {
    final indexes = _cryptoService.generateBlindIndexes(plaintext, searchKey);
    
    final card = await getCard(cardId);
    if (card == null) return;

    final updatedCard = PasswordCard(
      cardId: card.cardId,
      encryptedPayload: card.encryptedPayload,
      blindIndexes: indexes,
      createdAt: card.createdAt,
      updatedAt: card.updatedAt,
      currentEventId: card.currentEventId,
      isDeleted: card.isDeleted,
    );

    await saveCard(updatedCard);
  }

  // ==================== Maintenance Operations ====================

  /// Compact database (VACUUM)
  Future<void> compact() async {
    await db.execute('VACUUM');
  }

  /// Get database size
  Future<int> getDatabaseSize() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'ztd_vault.db');
    final file = await File(path).stat();
    return file.size;
  }

  /// Export database for backup
  Future<String> exportDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'ztd_vault.db');
    
    final backupDir = await getTemporaryDirectory();
    final backupPath = join(backupDir.path, 'ztd_backup_${DateTime.now().millisecondsSinceEpoch}.db');
    
    await db.close();
    
    final dbFile = File(dbPath);
    await dbFile.copy(backupPath);
    
    // Reopen database
    await initialize(await _getEncryptionKey());
    
    return backupPath;
  }

  /// Import database from backup
  Future<void> importDatabase(String backupPath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, 'ztd_vault.db');
    
    await db.close();
    _db = null;
    _eventStore = null;
    
    final backupFile = File(backupPath);
    await backupFile.copy(dbPath);
    
    // Database will be reopened on next access
  }

  /// Clear all data (DANGER)
  Future<void> clearAllData() async {
    await db.delete('blind_index_entries');
    await db.delete('password_cards');
    await db.delete('password_events');
    await db.delete('snapshots');
    await db.delete('sync_state');
  }

  /// Close database
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _eventStore = null;
    }
  }

  // Helper method (should be replaced with actual key retrieval)
  Future<String> _getEncryptionKey() async {
    // This should be implemented based on your key management strategy
    throw UnimplementedError('Encryption key retrieval not implemented');
  }
}

// File class for database operations
class File {
  final String path;
  
  File(this.path);
  
  Future<FileStat> stat() async {
    // Simplified implementation
    return FileStat(size: 0);
  }
  
  Future<void> copy(String newPath) async {
    // Simplified implementation
  }
  
  static Future<File> fromPath(String path) async {
    return File(path);
  }
}

class FileStat {
  final int size;
  
  FileStat({required this.size});
}
