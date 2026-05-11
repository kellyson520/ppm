import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ztd_password_manager/core/sync/webdav_sync.dart';
import 'package:ztd_password_manager/core/crdt/crdt_merger.dart';
import 'package:ztd_password_manager/core/events/event_store.dart';
import 'package:ztd_password_manager/core/crypto/key_manager.dart';
import 'package:ztd_password_manager/core/models/models.dart';
import '../helpers/test_helpers.dart';
import 'webdav_sync_test.mocks.dart';

void main() {
  late MockEventStore mockEventStore;
  late MockKeyManager mockKeyManager;
  late WebDavSyncManager syncManager;

  setUp(() {
    mockEventStore = MockEventStore();
    mockKeyManager = MockKeyManager();

    when(mockKeyManager.getDeviceId())
        .thenAnswer((_) async => 'test-device-id');

    syncManager = WebDavSyncManager(
      nodes: [],
      eventStore: mockEventStore,
      keyManager: mockKeyManager,
    );
  });

  tearDown(() {
    syncManager.dispose();
  });

  group('WebDavSyncManager - Unit Tests', () {
    test('should return already syncing when sync is in progress', () async {
      when(mockEventStore.getLatestHlc()).thenAnswer((_) async => null);
      when(mockEventStore.getUnsyncedEvents())
          .thenAnswer((_) async => <PasswordEvent>[]);

      final firstSync = syncManager.syncAllNodes();

      await Future.delayed(const Duration(milliseconds: 10));

      final secondSync = syncManager.syncAllNodes();

      final firstResult = await firstSync;
      final secondResult = await secondSync;

      expect(firstResult.success, isFalse);
      expect(secondResult.success, isFalse);
      expect(secondResult.error, equals('Sync already in progress'));
    });

    test('should report isSyncing status correctly', () {
      expect(syncManager.isSyncing, isFalse);
    });

    test('should handle empty nodes list gracefully', () async {
      when(mockEventStore.getLatestHlc()).thenAnswer((_) async => null);
      when(mockEventStore.getUnsyncedEvents())
          .thenAnswer((_) async => <PasswordEvent>[]);
      when(mockEventStore.getAllEvents())
          .thenAnswer((_) async => <PasswordEvent>[]);

      final result = await syncManager.syncAllNodes();

      expect(result.success, isTrue);
      expect(result.nodeResults, isEmpty);
    });
  });

  group('WebDavSyncManager - Node Configuration', () {
    test('should create WebDavNode from JSON', () {
      final json = {
        'name': 'Test Server',
        'url': 'https://example.com/webdav',
        'username': 'testuser',
        'password': 'testpass',
        'priority': 'high',
        'syncStrategy': 'full',
        'supportsSnapshots': true,
      };

      final node = WebDavNode.fromJson(json);

      expect(node.name, equals('Test Server'));
      expect(node.url, equals('https://example.com/webdav'));
      expect(node.username, equals('testuser'));
      expect(node.password, equals('testpass'));
      expect(node.priority, equals(NodePriority.high));
      expect(node.syncStrategy, equals(SyncStrategy.full));
      expect(node.supportsSnapshots, isTrue);
    });

    test('should serialize WebDavNode to JSON', () {
      final node = WebDavNode(
        name: 'Test Node',
        url: 'https://test.com/dav',
        username: 'user',
        password: 'pass',
        priority: NodePriority.normal,
        syncStrategy: SyncStrategy.delayed,
        supportsSnapshots: false,
      );

      final json = node.toJson();

      expect(json['name'], equals('Test Node'));
      expect(json['url'], equals('https://test.com/dav'));
      expect(json['priority'], equals('normal'));
      expect(json['syncStrategy'], equals('delayed'));
      expect(json['supportsSnapshots'], isFalse);
    });

    test('should use default values for optional fields', () {
      final node = WebDavNode(
        name: 'Minimal Node',
        url: 'https://min.com/',
        username: 'u',
        password: 'p',
      );

      expect(node.priority, equals(NodePriority.normal));
      expect(node.syncStrategy, equals(SyncStrategy.full));
      expect(node.supportsSnapshots, isTrue);
    });
  });

  group('SyncManifest', () {
    test('should create from JSON', () {
      final json = {
        'version': 1,
        'lastModified': {
          'physicalTime': 1000000,
          'logicalCounter': 0,
          'deviceId': 'test-device',
        },
        'eventCount': 42,
        'deviceId': 'another-device',
      };

      final manifest = SyncManifest.fromJson(json);

      expect(manifest.version, equals(1));
      expect(manifest.eventCount, equals(42));
      expect(manifest.deviceId, equals('another-device'));
    });

    test('should serialize to JSON', () {
      final manifest = SyncManifest(
        version: 2,
        lastModified: makeHLC(),
        eventCount: 100,
        deviceId: 'device-123',
      );

      final json = manifest.toJson();

      expect(json['version'], equals(2));
      expect(json['eventCount'], equals(100));
      expect(json['deviceId'], equals('device-123'));
      expect(json['lastModified'], isA<Map<String, dynamic>>());
    });
  });

  group('SyncProgress', () {
    test('should track progress correctly', () {
      final progress = SyncProgress(
        status: SyncStatus.inProgress,
        message: 'Syncing with node 1...',
        progress: 50.0,
        currentNode: 'Primary Server',
        downloadedCount: 5,
        uploadedCount: 3,
      );

      expect(progress.status, equals(SyncStatus.inProgress));
      expect(progress.message, equals('Syncing with node 1...'));
      expect(progress.progress, equals(50.0));
      expect(progress.currentNode, equals('Primary Server'));
      expect(progress.downloadedCount, equals(5));
      expect(progress.uploadedCount, equals(3));
      expect(progress.error, isNull);
    });

    test('should handle error state', () {
      final errorProgress = SyncProgress(
        status: SyncStatus.failed,
        message: 'Sync failed',
        progress: 0.0,
        error: 'Network timeout',
      );

      expect(errorProgress.status, equals(SyncStatus.failed));
      expect(errorProgress.error, equals('Network timeout'));
    });
  });

  group('SyncResult', () {
    test('should create success result', () {
      final result = SyncResult.success(
        nodeResults: {
          'primary': NodeSyncResult(
            nodeName: 'primary',
            success: true,
            downloadedCount: 10,
            uploadedCount: 5,
          ),
        },
        totalDownloaded: 10,
        totalUploaded: 5,
        conflicts: [],
      );

      expect(result.success, isTrue);
      expect(result.totalDownloaded, equals(10));
      expect(result.totalUploaded, equals(5));
      expect(result.error, isNull);
    });

    test('should create failure result', () {
      final result = SyncResult.failure(error: 'Connection refused');

      expect(result.success, isFalse);
      expect(result.error, equals('Connection refused'));
    });

    test('should create already syncing result', () {
      final result = SyncResult.alreadySyncing();

      expect(result.success, isFalse);
      expect(result.error, equals('Sync already in progress'));
    });
  });

  group('NodeSyncResult', () {
    test('should have default values', () {
      final result = NodeSyncResult(
        nodeName: 'test-node',
        success: true,
      );

      expect(result.downloadedCount, equals(0));
      expect(result.uploadedCount, equals(0));
      expect(result.conflicts, isEmpty);
      expect(result.error, isNull);
    });

    test('should track conflicts', () {
      final conflict = Conflict(
        cardId: 'card-1',
        localEvent: makePasswordEvent(),
        remoteEvent: makePasswordEvent(),
      );

      final result = NodeSyncResult(
        nodeName: 'conflict-node',
        success: true,
        conflicts: [conflict],
      );

      expect(result.conflicts.length, equals(1));
    });
  });

  group('SyncStatus enum', () {
    test('should have all expected values', () {
      expect(SyncStatus.values, contains(SyncStatus.idle));
      expect(SyncStatus.values, contains(SyncStatus.inProgress));
      expect(SyncStatus.values, contains(SyncStatus.completed));
      expect(SyncStatus.values, contains(SyncStatus.failed));
    });
  });

  group('NodePriority enum', () {
    test('should have all expected values', () {
      expect(NodePriority.values, contains(NodePriority.low));
      expect(NodePriority.values, contains(NodePriority.normal));
      expect(NodePriority.values, contains(NodePriority.high));
    });
  });

  group('SyncStrategy enum', () {
    test('should have all expected values', () {
      expect(SyncStrategy.values, contains(SyncStrategy.full));
      expect(SyncStrategy.values, contains(SyncStrategy.snapshotsOnly));
      expect(SyncStrategy.values, contains(SyncStrategy.delayed));
    });
  });
}
