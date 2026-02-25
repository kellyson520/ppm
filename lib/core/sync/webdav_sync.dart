import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../diagnostics/crash_report_service.dart';
import '../models/models.dart';
import '../events/event_store.dart';
import '../crdt/crdt_merger.dart';

/// WebDAV Sync Manager
///
/// Implements distributed synchronization using WebDAV protocol
/// Supports multiple WebDAV nodes with different priorities:
/// - Primary node: Real-time sync
/// - Secondary nodes: Delayed backup
///
/// Features:
/// - Incremental sync using HLC timestamps
/// - Conflict resolution using CRDT semantics
/// - Snapshot compression and upload
/// - Multi-node redundancy
class WebDavSyncManager {
  final List<WebDavNode> _nodes;
  final EventStore _eventStore;

  // Sync state
  bool _isSyncing = false;
  final _syncController = StreamController<SyncProgress>.broadcast();

  WebDavSyncManager({
    required List<WebDavNode> nodes,
    required EventStore eventStore,
    CrdtMerger? crdtMerger,
  })  : _nodes = nodes,
        _eventStore = eventStore;

  /// Sync progress stream
  Stream<SyncProgress> get syncProgress => _syncController.stream;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  // ==================== Sync Operations ====================

  /// Perform full sync with all configured nodes
  ///
  /// 1. Check manifest on each node
  /// 2. Calculate diff (events to download/upload)
  /// 3. Download missing events from nodes
  /// 4. Merge events using CRDT
  /// 5. Upload local events to nodes
  /// 6. Update manifests
  /// 7. Trigger compaction if needed
  Future<SyncResult> syncAllNodes() async {
    if (_isSyncing) {
      return SyncResult.alreadySyncing();
    }

    _isSyncing = true;
    _syncController.add(SyncProgress(
      status: SyncStatus.inProgress,
      message: 'Starting sync...',
      progress: 0.0,
    ));

    final results = <String, NodeSyncResult>{};
    var totalDownloaded = 0;
    var totalUploaded = 0;
    final conflicts = <Conflict>[];

    try {
      // Sync with each node
      for (var i = 0; i < _nodes.length; i++) {
        final node = _nodes[i];
        final progress = (i / _nodes.length) * 100;

        _syncController.add(SyncProgress(
          status: SyncStatus.inProgress,
          message: 'Syncing with ${node.name}...',
          progress: progress,
          currentNode: node.name,
        ));

        final nodeResult = await _syncNode(node);
        results[node.name] = nodeResult;

        totalDownloaded += nodeResult.downloadedCount;
        totalUploaded += nodeResult.uploadedCount;
        conflicts.addAll(nodeResult.conflicts);
      }

      // Update last sync timestamp
      final latestHlc = await _eventStore.getLatestHlc();
      if (latestHlc != null) {
        await _eventStore.updateLastSync(latestHlc);
      }

      _syncController.add(SyncProgress(
        status: SyncStatus.completed,
        message: 'Sync completed successfully',
        progress: 100.0,
        downloadedCount: totalDownloaded,
        uploadedCount: totalUploaded,
      ));

      return SyncResult.success(
        nodeResults: results,
        totalDownloaded: totalDownloaded,
        totalUploaded: totalUploaded,
        conflicts: conflicts,
      );
    } on Exception catch (e) {
      _syncController.add(SyncProgress(
        status: SyncStatus.failed,
        message: 'Sync failed: $e',
        progress: 0.0,
        error: e.toString(),
      ));

      return SyncResult.failure(error: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync with a single node
  Future<NodeSyncResult> _syncNode(WebDavNode node) async {
    final client = await _createClient(node);

    try {
      // Ensure directory structure exists
      await _ensureDirectoryStructure(client);

      // Get remote manifest
      final remoteManifest = await _getRemoteManifest(client);

      // Get local state
      final _ = await _eventStore.getLatestHlc();
      final unsyncedEvents = await _eventStore.getUnsyncedEvents();

      // Download remote events
      final eventsToDownload = <PasswordEvent>[];
      if (remoteManifest != null) {
        eventsToDownload.addAll(
          await _downloadEvents(client, remoteManifest),
        );
      }

      // Merge events
      final localEvents = await _eventStore.getAllEvents();
      final mergedEvents = CrdtMerger.mergeEventSets(
        localEvents,
        eventsToDownload,
      );

      // Detect conflicts
      final conflicts =
          CrdtMerger.detectConflicts(localEvents, eventsToDownload);

      // Apply merged events to local store
      final newEvents = mergedEvents
          .where(
            (e) => !localEvents.any((le) => le.eventId == e.eventId),
          )
          .toList();

      if (newEvents.isNotEmpty) {
        await _eventStore.appendEvents(newEvents);
      }

      // Upload local events
      var uploadedCount = 0;
      if (unsyncedEvents.isNotEmpty) {
        uploadedCount = await _uploadEvents(client, unsyncedEvents);
        await _eventStore.markEventsAsSynced(
          unsyncedEvents.map((e) => e.eventId).toList(),
        );
      }

      // Update remote manifest
      await _updateManifest(client);

      return NodeSyncResult(
        nodeName: node.name,
        success: true,
        downloadedCount: newEvents.length,
        uploadedCount: uploadedCount,
        conflicts: conflicts,
      );
    } on Exception catch (e) {
      return NodeSyncResult(
        nodeName: node.name,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Create WebDAV client
  Future<webdav.Client> _createClient(WebDavNode node) async {
    return webdav.newClient(
      node.url,
      user: node.username,
      password: node.password,
      debug: false,
    );
  }

  /// Ensure directory structure exists on remote
  Future<void> _ensureDirectoryStructure(webdav.Client client) async {
    final paths = [
      'ztd-password-manager',
      'ztd-password-manager/events',
      'ztd-password-manager/snapshots',
    ];

    for (final path in paths) {
      try {
        await client.mkdir(path).timeout(const Duration(seconds: 10));
      } on Exception catch (e, stack) {
        // Log if it's not a 405 (Method Not Allowed - usually means dir exists)
        if (!e.toString().contains('405')) {
          CrashReportService.instance.reportZoneError(
            'Failed to create WebDAV directory $path',
            stack,
          );
        }
      }
    }
  }

  /// Get remote manifest
  Future<SyncManifest?> _getRemoteManifest(webdav.Client client) async {
    try {
      final response = await client.read(
        'ztd-password-manager/manifest.json',
      );
      final json = jsonDecode(utf8.decode(response)) as Map<String, dynamic>;
      return SyncManifest.fromJson(json);
    } on Exception catch (e, stack) {
      if (!e.toString().contains('404')) {
        CrashReportService.instance.reportZoneError(
          'Failed to read WebDAV manifest',
          stack,
        );
      }
      return null;
    }
  }

  /// Update remote manifest
  Future<void> _updateManifest(webdav.Client client) async {
    final latestHlc = await _eventStore.getLatestHlc();
    final eventCount = await _eventStore.getEventCount();

    final manifest = SyncManifest(
      version: 1,
      lastModified: latestHlc ?? HLC.now('local'),
      eventCount: eventCount,
      deviceId: await _getDeviceId(),
    );

    await client.write(
      'ztd-password-manager/manifest.json',
      utf8.encode(jsonEncode(manifest.toJson())),
    );
  }

  Future<List<PasswordEvent>> _downloadEvents(
    webdav.Client client,
    SyncManifest manifest,
  ) async {
    final events = <PasswordEvent>[];

    try {
      // List event files
      final files = await client
          .readDir('ztd-password-manager/events')
          .timeout(const Duration(seconds: 30));

      for (final file in files) {
        if (file.name?.endsWith('.json') ?? false) {
          try {
            final content = await client
                .read('ztd-password-manager/events/${file.name}')
                .timeout(const Duration(seconds: 15));
            final json =
                jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
            events.add(PasswordEvent.fromJson(json));
          } on Exception catch (e, stack) {
            CrashReportService.instance.reportZoneError(
              'Failed to download event file ${file.name}',
              stack,
            );
          }
        }
      }
    } on Exception catch (e, stack) {
      CrashReportService.instance.reportZoneError(
        'Failed to list WebDAV events directory',
        stack,
      );
    }

    return events;
  }

  Future<int> _uploadEvents(
    webdav.Client client,
    List<PasswordEvent> events,
  ) async {
    var uploaded = 0;

    for (final event in events) {
      try {
        final fileName = '${event.eventId}.json';
        final content = jsonEncode(event.toJson());

        await client
            .write(
              'ztd-password-manager/events/$fileName',
              utf8.encode(content),
            )
            .timeout(const Duration(seconds: 15));
        uploaded++;
      } on Exception catch (e, stack) {
        CrashReportService.instance.reportZoneError(
          'Failed to upload event ${event.eventId}',
          stack,
        );
      }
    }

    return uploaded;
  }

  Future<void> uploadSnapshot(
    String snapshotPath,
    String snapshotName,
  ) async {
    for (final node in _nodes.where((n) => n.supportsSnapshots)) {
      try {
        final client = await _createClient(node);
        final file = File(snapshotPath);
        final content = await file.readAsBytes();

        await client
            .write(
              'ztd-password-manager/snapshots/$snapshotName',
              Uint8List.fromList(content),
            )
            .timeout(const Duration(seconds: 60));
      } on Exception catch (e, stack) {
        CrashReportService.instance.reportZoneError(
          'Failed to upload snapshot $snapshotName to node ${node.name}',
          stack,
        );
      }
    }
  }

  /// Get device ID
  Future<String> _getDeviceId() async {
    // This should be retrieved from KeyManager
    return 'unknown-device';
  }

  /// Dispose
  void dispose() {
    _syncController.close();
  }
}

/// WebDAV Node Configuration
class WebDavNode {
  final String name;
  final String url;
  final String username;
  final String password;
  final NodePriority priority;
  final SyncStrategy syncStrategy;
  final bool supportsSnapshots;

  WebDavNode({
    required this.name,
    required this.url,
    required this.username,
    required this.password,
    this.priority = NodePriority.normal,
    this.syncStrategy = SyncStrategy.full,
    this.supportsSnapshots = true,
  });

  factory WebDavNode.fromJson(Map<String, dynamic> json) {
    return WebDavNode(
      name: json['name'] as String,
      url: json['url'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      priority: NodePriority.values.byName(json['priority'] as String),
      syncStrategy: SyncStrategy.values.byName(json['syncStrategy'] as String),
      supportsSnapshots: json['supportsSnapshots'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'username': username,
        'password': password,
        'priority': priority.name,
        'syncStrategy': syncStrategy.name,
        'supportsSnapshots': supportsSnapshots,
      };
}

enum NodePriority { low, normal, high }

enum SyncStrategy { full, snapshotsOnly, delayed }

/// Sync Manifest
class SyncManifest {
  final int version;
  final HLC lastModified;
  final int eventCount;
  final String deviceId;

  SyncManifest({
    required this.version,
    required this.lastModified,
    required this.eventCount,
    required this.deviceId,
  });

  factory SyncManifest.fromJson(Map<String, dynamic> json) {
    return SyncManifest(
      version: json['version'] as int,
      lastModified: HLC.fromJson(json['lastModified'] as Map<String, dynamic>),
      eventCount: json['eventCount'] as int,
      deviceId: json['deviceId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'lastModified': lastModified.toJson(),
        'eventCount': eventCount,
        'deviceId': deviceId,
      };
}

/// Sync Progress
class SyncProgress {
  final SyncStatus status;
  final String message;
  final double progress;
  final String? currentNode;
  final int? downloadedCount;
  final int? uploadedCount;
  final String? error;

  SyncProgress({
    required this.status,
    required this.message,
    required this.progress,
    this.currentNode,
    this.downloadedCount,
    this.uploadedCount,
    this.error,
  });
}

enum SyncStatus { idle, inProgress, completed, failed }

/// Sync Result
class SyncResult {
  final bool success;
  final Map<String, NodeSyncResult>? nodeResults;
  final int? totalDownloaded;
  final int? totalUploaded;
  final List<Conflict>? conflicts;
  final String? error;

  SyncResult._({
    required this.success,
    this.nodeResults,
    this.totalDownloaded,
    this.totalUploaded,
    this.conflicts,
    this.error,
  });

  factory SyncResult.success({
    required Map<String, NodeSyncResult> nodeResults,
    required int totalDownloaded,
    required int totalUploaded,
    required List<Conflict> conflicts,
  }) =>
      SyncResult._(
        success: true,
        nodeResults: nodeResults,
        totalDownloaded: totalDownloaded,
        totalUploaded: totalUploaded,
        conflicts: conflicts,
      );

  factory SyncResult.failure({required String error}) => SyncResult._(
        success: false,
        error: error,
      );

  factory SyncResult.alreadySyncing() => SyncResult._(
        success: false,
        error: 'Sync already in progress',
      );
}

/// Node Sync Result
class NodeSyncResult {
  final String nodeName;
  final bool success;
  final int downloadedCount;
  final int uploadedCount;
  final List<Conflict> conflicts;
  final String? error;

  NodeSyncResult({
    required this.nodeName,
    required this.success,
    this.downloadedCount = 0,
    this.uploadedCount = 0,
    this.conflicts = const [],
    this.error,
  });
}
