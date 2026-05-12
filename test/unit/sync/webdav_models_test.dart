import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/sync/webdav_sync.dart';

void main() {
  group('WebDavSyncManager - Model Tests', () {
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

    test('should serialize and deserialize WebDavNode roundtrip', () {
      final original = WebDavNode(
        name: 'Roundtrip Test',
        url: 'https://roundtrip.com/webdav',
        username: 'testuser',
        password: 'secret123',
        priority: NodePriority.low,
        syncStrategy: SyncStrategy.snapshotsOnly,
        supportsSnapshots: true,
      );

      final json = original.toJson();
      final restored = WebDavNode.fromJson(json);

      expect(restored.name, equals(original.name));
      expect(restored.url, equals(original.url));
      expect(restored.username, equals(original.username));
      expect(restored.password, equals(original.password));
      expect(restored.priority, equals(original.priority));
      expect(restored.syncStrategy, equals(original.syncStrategy));
      expect(restored.supportsSnapshots, equals(original.supportsSnapshots));
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

    test('should handle completed state', () {
      final completedProgress = SyncProgress(
        status: SyncStatus.completed,
        message: 'Sync completed successfully',
        progress: 100.0,
        downloadedCount: 10,
        uploadedCount: 5,
      );

      expect(completedProgress.status, equals(SyncStatus.completed));
      expect(completedProgress.progress, equals(100.0));
      expect(completedProgress.downloadedCount, equals(10));
      expect(completedProgress.uploadedCount, equals(5));
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

    test('should track upload and download counts', () {
      final result = NodeSyncResult(
        nodeName: 'count-test-node',
        success: true,
        downloadedCount: 15,
        uploadedCount: 8,
      );

      expect(result.downloadedCount, equals(15));
      expect(result.uploadedCount, equals(8));
      expect(result.success, isTrue);
    });

    test('should track error state', () {
      final result = NodeSyncResult(
        nodeName: 'error-node',
        success: false,
        error: 'Connection timeout',
      );

      expect(result.success, isFalse);
      expect(result.error, equals('Connection timeout'));
    });
  });

  group('SyncStatus enum', () {
    test('should have all expected values', () {
      expect(SyncStatus.values, contains(SyncStatus.idle));
      expect(SyncStatus.values, contains(SyncStatus.inProgress));
      expect(SyncStatus.values, contains(SyncStatus.completed));
      expect(SyncStatus.values, contains(SyncStatus.failed));
    });

    test('should have 4 status values', () {
      expect(SyncStatus.values.length, equals(4));
    });
  });

  group('NodePriority enum', () {
    test('should have all expected values', () {
      expect(NodePriority.values, contains(NodePriority.low));
      expect(NodePriority.values, contains(NodePriority.normal));
      expect(NodePriority.values, contains(NodePriority.high));
    });

    test('should have 3 priority values', () {
      expect(NodePriority.values.length, equals(3));
    });
  });

  group('SyncStrategy enum', () {
    test('should have all expected values', () {
      expect(SyncStrategy.values, contains(SyncStrategy.full));
      expect(SyncStrategy.values, contains(SyncStrategy.snapshotsOnly));
      expect(SyncStrategy.values, contains(SyncStrategy.delayed));
    });

    test('should have 3 strategy values', () {
      expect(SyncStrategy.values.length, equals(3));
    });
  });

  group('WebDavNode validation', () {
    test('should handle empty URL gracefully', () {
      final node = WebDavNode(
        name: 'Empty URL Node',
        url: '',
        username: 'user',
        password: 'pass',
      );

      expect(node.url, equals(''));
      expect(node.name, equals('Empty URL Node'));
    });

    test('should handle special characters in credentials', () {
      final node = WebDavNode(
        name: 'Special Chars',
        url: 'https://example.com/webdav',
        username: 'user@domain.com',
        password: 'p@ss!word#123',
      );

      final json = node.toJson();
      final restored = WebDavNode.fromJson(json);

      expect(restored.username, equals('user@domain.com'));
      expect(restored.password, equals('p@ss!word#123'));
    });
  });
}
