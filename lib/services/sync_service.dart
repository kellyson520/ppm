import 'dart:async';
import '../core/storage/database_service.dart';
import '../core/sync/sync.dart';
import '../core/crypto/key_manager.dart';
import '../core/diagnostics/crash_report_service.dart';

/// Sync Service - Orchestrates WebDAV synchronization
class SyncService {
  final DatabaseService _database;
  final KeyManager _keyManager;

  WebDavSyncManager? _manager;
  final _syncProgressController = StreamController<SyncProgress>.broadcast();

  SyncService({
    DatabaseService? database,
    KeyManager? keyManager,
  })  : _database = database ?? DatabaseService(),
        _keyManager = keyManager ?? KeyManager();

  /// Sync progress stream
  Stream<SyncProgress> get syncProgress => _syncProgressController.stream;

  /// Initialize the sync manager with nodes from database
  Future<void> initialize() async {
    try {
      final nodes = await _database.getAllWebDavNodes();

      _manager = WebDavSyncManager(
        nodes: nodes,
        eventStore: _database.eventStore,
        keyManager: _keyManager,
      );

      // Forward progress events
      _manager!.syncProgress.listen((progress) {
        _syncProgressController.add(progress);
      });
    } on Exception catch (e, stack) {
      CrashReportService.instance
          .reportError(e, stack, source: 'SyncService.initialize');
    }
  }

  /// Add a new WebDAV node
  Future<void> addNode(WebDavNode node) async {
    await _database.saveWebDavNode(node);
    await initialize(); // Re-initialize to include new node
  }

  /// Remove a WebDAV node
  Future<void> removeNode(String name) async {
    await _database.deleteWebDavNode(name);
    await initialize();
  }

  /// Get all configured nodes
  Future<List<WebDavNode>> getNodes() async {
    return await _database.getAllWebDavNodes();
  }

  /// Perform sync across all nodes
  Future<SyncResult> syncAll() async {
    if (_manager == null) {
      await initialize();
    }

    if (_manager == null || (await getNodes()).isEmpty) {
      return SyncResult.failure(error: 'No WebDAV nodes configured');
    }

    return await _manager!.syncAllNodes();
  }

  /// Dispose
  void dispose() {
    _manager?.dispose();
    _syncProgressController.close();
  }
}
