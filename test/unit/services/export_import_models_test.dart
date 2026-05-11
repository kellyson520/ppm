import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/models/models.dart';
import 'package:ztd_password_manager/core/events/event.dart';

void main() {
  group('PasswordPayload Serialization', () {
    test('should serialize PasswordPayload to JSON', () {
      final payload = PasswordPayload(
        id: 'test-id-123',
        title: 'Test Account',
        username: 'testuser',
        password: 'testpass',
        url: 'https://example.com',
        notes: 'Test notes',
        favicon: 'icon.png',
        tags: ['work', 'important'],
        customFields: const {
          'key1': 'value1',
          'key2': 'value2',
        },
        folderId: 'folder-1',
        totpSecret: 'JBSWY3DPEHPK3PXP',
        createdAt: DateTime(2024, 1, 1, 12, 0, 0),
        updatedAt: DateTime(2024, 1, 15, 18, 30, 0),
      );

      final json = payload.toJson();

      expect(json['id'], equals('test-id-123'));
      expect(json['title'], equals('Test Account'));
      expect(json['username'], equals('testuser'));
      expect(json['password'], equals('testpass'));
      expect(json['url'], equals('https://example.com'));
      expect(json['notes'], equals('Test notes'));
      expect(json['favicon'], equals('icon.png'));
      expect(json['tags'], contains('work'));
      expect(json['tags'], contains('important'));
      expect(json['customFields']['key1'], equals('value1'));
      expect(json['folderId'], equals('folder-1'));
      expect(json['totpSecret'], equals('JBSWY3DPEHPK3PXP'));
    });

    test('should deserialize JSON to PasswordPayload', () {
      final json = {
        'id': 'id-456',
        'title': 'My Account',
        'username': 'myuser',
        'password': 'mypass',
        'url': 'https://myapp.com',
        'notes': 'My notes',
        'favicon': null,
        'tags': ['personal'],
        'customFields': <String, dynamic>{},
        'folderId': null,
        'totpSecret': null,
        'createdAt': '2024-02-01T10:00:00.000',
        'updatedAt': '2024-02-15T14:30:00.000',
      };

      final payload = PasswordPayload.fromJson(json);

      expect(payload.id, equals('id-456'));
      expect(payload.title, equals('My Account'));
      expect(payload.username, equals('myuser'));
      expect(payload.password, equals('mypass'));
      expect(payload.tags, contains('personal'));
    });

    test('should handle empty optional fields', () {
      final payload = PasswordPayload(
        id: 'minimal-id',
        title: 'Minimal Entry',
        username: '',
        password: '',
        url: null,
        notes: null,
        favicon: null,
        tags: const [],
        customFields: const {},
        folderId: null,
        totpSecret: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = payload.toJson();
      final restored = PasswordPayload.fromJson(json);

      expect(restored.url, isNull);
      expect(restored.notes, isNull);
      expect(restored.favicon, isNull);
      expect(restored.folderId, isNull);
      expect(restored.totpSecret, isNull);
    });

    test('should handle special characters in credentials', () {
      final payload = PasswordPayload(
        id: 'special-id',
        title: 'Special Chars & Co.',
        username: 'user@domain.com',
        password: 'p@ss!word#123\$%^&*()',
        url: 'https://example.com/path?query=value&other=123',
        notes: 'Notes with\nnewlines\nand\ttabs',
        favicon: null,
        tags: ['tag-with-dash', 'tag_with_underscore'],
        customFields: const {},
        folderId: null,
        totpSecret: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = payload.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = PasswordPayload.fromJson(decoded);

      expect(restored.username, equals('user@domain.com'));
      expect(restored.password, equals('p@ss!word#123\$%^&*()'));
      expect(restored.notes, contains('\n'));
    });
  });

  group('PasswordCard Model', () {
    test('should create PasswordCard with encrypted data', () {
      final card = PasswordCard(
        id: 'card-123',
        encryptedData: EncryptedData(
          ciphertext: Uint8List.fromList('encrypted content'.codeUnits),
          iv: Uint8List(12),
          authTag: Uint8List(16),
        ),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        isDeleted: false,
        deletedAt: null,
        deviceId: 'device-1',
      );

      expect(card.id, equals('card-123'));
      expect(card.isDeleted, isFalse);
      expect(card.deletedAt, isNull);
    });

    test('should mark card as deleted', () {
      final card = PasswordCard(
        id: 'card-to-delete',
        encryptedData: EncryptedData(
          ciphertext: Uint8List.fromList('data'.codeUnits),
          iv: Uint8List(12),
          authTag: Uint8List(16),
        ),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 10),
        isDeleted: true,
        deletedAt: DateTime(2024, 1, 10),
        deviceId: 'device-1',
      );

      expect(card.isDeleted, isTrue);
      expect(card.deletedAt, isNotNull);
    });
  });

  group('EncryptedData Model', () {
    test('should serialize EncryptedData', () {
      final encrypted = EncryptedData(
        ciphertext: Uint8List.fromList([1, 2, 3, 4, 5]),
        iv: Uint8List.fromList([10, 20, 30]),
        authTag: Uint8List.fromList([100, 200]),
      );

      final json = encrypted.toJson();

      expect(json['ciphertext'], isA<List>());
      expect(json['iv'], isA<List>());
      expect(json['authTag'], isA<List>());
    });

    test('should create from base64 string', () {
      const base64String = 'data:application/octet-stream;base64,SGVsbG8gV29ybGQ=';

      final encrypted = EncryptedData.fromBase64(base64String);

      expect(encrypted.ciphertext, isNotEmpty);
      expect(encrypted.iv, isNotEmpty);
    });

    test('should serialize to base64 string', () {
      final encrypted = EncryptedData(
        ciphertext: Uint8List.fromList('Hello'.codeUnits),
        iv: Uint8List.fromList([1, 2, 3, 4]),
        authTag: Uint8List.fromList([5, 6, 7, 8]),
      );

      final serialized = encrypted.serialize();

      expect(serialized, startsWith('data:'));
      expect(serialized, contains('application/octet-stream'));
      expect(serialized, contains('base64,'));
    });
  });

  group('VaultStats Model', () {
    test('should create VaultStats with all fields', () {
      final stats = VaultStats(
        cardCount: 42,
        eventCount: 100,
        pendingSyncCount: 5,
        snapshotCount: 3,
        latestSnapshotVersion: 15,
        oldestEventTime: DateTime(2024, 1, 1),
        newestEventTime: DateTime(2024, 6, 1),
      );

      expect(stats.cardCount, equals(42));
      expect(stats.eventCount, equals(100));
      expect(stats.pendingSyncCount, equals(5));
      expect(stats.snapshotCount, equals(3));
      expect(stats.latestSnapshotVersion, equals(15));
    });

    test('should handle null snapshot info', () {
      final stats = VaultStats(
        cardCount: 0,
        eventCount: 0,
        pendingSyncCount: 0,
        snapshotCount: 0,
        latestSnapshotVersion: null,
        oldestEventTime: null,
        newestEventTime: null,
      );

      expect(stats.latestSnapshotVersion, isNull);
      expect(stats.oldestEventTime, isNull);
    });
  });

  group('HLC (Hybrid Logical Clock)', () {
    test('should create HLC with timestamp and counter', () {
      final hlc = HLC(
        physicalTime: 1000000,
        logicalCounter: 5,
        deviceId: 'device-abc',
      );

      expect(hlc.physicalTime, equals(1000000));
      expect(hlc.logicalCounter, equals(5));
      expect(hlc.deviceId, equals('device-abc'));
    });

    test('should compare HLC values', () {
      final hlc1 = HLC(
        physicalTime: 1000,
        logicalCounter: 0,
        deviceId: 'device-1',
      );

      final hlc2 = HLC(
        physicalTime: 1001,
        logicalCounter: 0,
        deviceId: 'device-2',
      );

      expect(hlc1.compareTo(hlc2), lessThan(0));
    });

    test('should serialize and deserialize HLC', () {
      final original = HLC(
        physicalTime: 5000000,
        logicalCounter: 10,
        deviceId: 'test-device',
      );

      final json = original.toJson();
      final restored = HLC.fromJson(json);

      expect(restored.physicalTime, equals(original.physicalTime));
      expect(restored.logicalCounter, equals(original.logicalCounter));
      expect(restored.deviceId, equals(original.deviceId));
    });
  });

  group('PasswordEvent Model', () {
    test('should create event with all fields', () {
      final event = PasswordEvent(
        id: 'event-123',
        type: EventType.create,
        cardId: 'card-456',
        payload: 'encrypted-payload',
        hlc: HLC(
          physicalTime: 1000,
          logicalCounter: 0,
          deviceId: 'device-x',
        ),
        createdAt: DateTime(2024, 1, 15),
      );

      expect(event.id, equals('event-123'));
      expect(event.type, equals(EventType.create));
      expect(event.cardId, equals('card-456'));
      expect(event.payload, equals('encrypted-payload'));
    });

    test('should serialize event to JSON', () {
      final event = PasswordEvent(
        id: 'event-789',
        type: EventType.update,
        cardId: 'card-abc',
        payload: 'payload-data',
        hlc: HLC(
          physicalTime: 2000,
          logicalCounter: 3,
          deviceId: 'device-y',
        ),
        createdAt: DateTime(2024, 3, 1),
      );

      final json = event.toJson();

      expect(json['id'], equals('event-789'));
      expect(json['type'], equals('update'));
      expect(json['cardId'], equals('card-abc'));
    });

    test('should deserialize event from JSON', () {
      final json = {
        'id': 'event-xyz',
        'type': 'delete',
        'cardId': 'card-deleted',
        'payload': 'deleted-payload',
        'hlc': {
          'physicalTime': 3000,
          'logicalCounter': 1,
          'deviceId': 'device-z',
        },
        'createdAt': '2024-05-01T12:00:00.000',
      };

      final event = PasswordEvent.fromJson(json);

      expect(event.id, equals('event-xyz'));
      expect(event.type, equals(EventType.delete));
      expect(event.cardId, equals('card-deleted'));
      expect(event.hlc.physicalTime, equals(3000));
    });
  });

  group('EventType enum', () {
    test('should have all expected event types', () {
      expect(EventType.values, contains(EventType.create));
      expect(EventType.values, contains(EventType.update));
      expect(EventType.values, contains(EventType.delete));
      expect(EventType.values, contains(EventType.restore));
    });

    test('should serialize event type to string', () {
      expect(EventType.create.toString(), contains('create'));
      expect(EventType.update.toString(), contains('update'));
    });
  });

  group('WebDavNode Model', () {
    test('should create node with minimal fields', () {
      final node = WebDavNode(
        name: 'My Server',
        url: 'https://my.server.com/webdav',
        username: 'admin',
        password: 'secret',
      );

      expect(node.name, equals('My Server'));
      expect(node.url, equals('https://my.server.com/webdav'));
    });

    test('should serialize node to JSON with all fields', () {
      final node = WebDavNode(
        name: 'Full Node',
        url: 'https://full.example.com/dav',
        username: 'user',
        password: 'pass',
        priority: NodePriority.high,
        syncStrategy: SyncStrategy.delayed,
        supportsSnapshots: false,
      );

      final json = node.toJson();

      expect(json['name'], equals('Full Node'));
      expect(json['url'], equals('https://full.example.com/dav'));
      expect(json['priority'], equals('high'));
      expect(json['syncStrategy'], equals('delayed'));
      expect(json['supportsSnapshots'], isFalse);
    });
  });

  group('Export Format Validation', () {
    test('should validate JSON array format for plain export', () {
      const validExport = '''
      [
        {
          "id": "entry-1",
          "title": "Test Entry",
          "username": "user",
          "password": "pass",
          "url": null,
          "notes": null,
          "favicon": null,
          "tags": [],
          "customFields": {},
          "folderId": null,
          "totpSecret": null,
          "createdAt": "2024-01-01T00:00:00.000",
          "updatedAt": "2024-01-01T00:00:00.000"
        }
      ]
      ''';

      final decoded = jsonDecode(validExport) as List;

      expect(decoded, isA<List>());
      expect(decoded.length, equals(1));
      expect(decoded[0]['title'], equals('Test Entry'));
    });

    test('should parse multiple entries from export', () {
      const multiExport = '''
      [
        {"id": "1", "title": "Entry 1", "username": "u1", "password": "p1", "url": null, "notes": null, "favicon": null, "tags": [], "customFields": {}, "folderId": null, "totpSecret": null, "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"},
        {"id": "2", "title": "Entry 2", "username": "u2", "password": "p2", "url": null, "notes": null, "favicon": null, "tags": [], "customFields": {}, "folderId": null, "totpSecret": null, "createdAt": "2024-01-02T00:00:00.000", "updatedAt": "2024-01-02T00:00:00.000"}
      ]
      ''';

      final decoded = jsonDecode(multiExport) as List;

      expect(decoded.length, equals(2));
      expect(decoded[0]['id'], equals('1'));
      expect(decoded[1]['id'], equals('2'));
    });

    test('should handle empty export array', () {
      const emptyExport = '[]';

      final decoded = jsonDecode(emptyExport) as List;

      expect(decoded, isEmpty);
    });
  });

  group('Encrypted Export Format', () {
    test('should detect encrypted export format', () {
      const encryptedExport = 'data:application/octet-stream;base64,SGVsbG8gV29ybGQ=';

      expect(encryptedExport, startsWith('data:'));
      expect(encryptedExport, contains('base64,'));
    });

    test('should parse base64 encoded data', () {
      const plainText = 'Hello World';
      final encoded = base64Encode(plainText.codeUnits);
      final decoded = base64Decode(encoded);

      expect(String.fromCharCodes(decoded), equals(plainText));
    });
  });
}
