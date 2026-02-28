/// 模型层序列化契约测试
///
/// 策略：测试所有模型的 "round-trip" (序列化 → 反序列化 = 原始值)
/// 通用性：只要模型保持 fromJson/toJson 或 fromMap/toMap 的契约，
///         即使内部字段增删改，这些测试只需更新 test_fixtures.dart 即可适配。
library;

import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_helpers.dart';
import 'package:ztd_password_manager/core/models/models.dart';

void main() {
  // ==================== HLC ====================

  group('HLC — 序列化契约', () {
    test('toJson/fromJson round-trip', () {
      final hlc = makeHLC(physicalTime: 123456789, logicalCounter: 42);
      expect(hlc, isHlcJsonSerializable);
    });

    test('不同参数组合均可 round-trip', () {
      final cases = [
        makeHLC(physicalTime: 0, logicalCounter: 0, deviceId: 'a'),
        makeHLC(physicalTime: 2147483647, logicalCounter: 999, deviceId: 'z'),
        makeHLC(
            physicalTime: 1000,
            logicalCounter: 1,
            deviceId: 'device-with-dashes'),
      ];
      for (final hlc in cases) {
        expect(hlc, isHlcJsonSerializable, reason: 'Failed for $hlc');
      }
    });
  });

  group('HLC — 排序契约', () {
    test('physicalTime 更大的 HLC 排在后面', () {
      final earlier = makeHLC(physicalTime: 1000);
      final later = makeHLC(physicalTime: 2000);
      expect(earlier.compareTo(later), lessThan(0));
      expect(later.compareTo(earlier), greaterThan(0));
    });

    test('physicalTime 相同时，logicalCounter 决定顺序', () {
      final a = makeHLC(physicalTime: 1000, logicalCounter: 0);
      final b = makeHLC(physicalTime: 1000, logicalCounter: 1);
      expect(a.compareTo(b), lessThan(0));
    });

    test('physicalTime 和 logicalCounter 都相同时，deviceId 决定顺序', () {
      final a = makeHLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'aaa');
      final b = makeHLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'bbb');
      expect(a.compareTo(b), lessThan(0));
    });

    test('因果有序链的验证', () {
      final chain = makeCausalHLCChain(5);
      expect(chain, isCausallyOrdered);
    });

    test('merge 保证因果序', () {
      final local = makeHLC(physicalTime: 1000, deviceId: kTestDeviceA);
      final remote = makeHLC(physicalTime: 900, deviceId: kTestDeviceB);
      final merged = local.merge(remote);
      // merged 的 physicalTime >= max(local, remote)
      expect(merged.physicalTime, greaterThanOrEqualTo(local.physicalTime));
      expect(merged.physicalTime, greaterThanOrEqualTo(remote.physicalTime));
    });

    test('increment 生成更大的逻辑时钟', () {
      final original = makeHLC(logicalCounter: 5);
      final incremented = original.increment();
      expect(incremented.logicalCounter, equals(6));
      expect(incremented.physicalTime, equals(original.physicalTime));
    });
  });

  group('HLC — 并发检测', () {
    test('来自不同设备、相同时间戳的 HLC 识别为并发', () {
      final a =
          makeHLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'dev-a');
      final b =
          makeHLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'dev-b');
      expect(a.isConcurrent(b), isTrue);
    });

    test('不同时间戳的 HLC 不是并发', () {
      final a = makeHLC(physicalTime: 1000, deviceId: 'dev-a');
      final b = makeHLC(physicalTime: 2000, deviceId: 'dev-b');
      expect(a.isConcurrent(b), isFalse);
    });
  });

  // ==================== PasswordPayload ====================

  group('PasswordPayload — 序列化契约', () {
    test('toJson/fromJson round-trip（完整字段）', () {
      final payload = makePasswordPayload(
        notes: 'test notes',
        tags: ['tag1', 'tag2'],
        expiresAt: DateTime(2026, 12, 31),
      );
      expect(payload, isPasswordPayloadSerializable);
    });

    test('toJson/fromJson round-trip（最小字段）', () {
      final payload = makePasswordPayload(url: null, notes: null);
      expect(payload, isPasswordPayloadSerializable);
    });
  });

  // ==================== PasswordCard ====================

  group('PasswordCard — 序列化契约', () {
    test('toMap/fromMap round-trip', () {
      final card = makePasswordCard();
      expect(card, isPasswordCardSerializable);
    });

    test('带不同 blindIndexes 的 card round-trip', () {
      final card = makePasswordCard(blindIndexes: ['a', 'b', 'c', 'd']);
      expect(card, isPasswordCardSerializable);
    });

    test('空 blindIndexes round-trip', () {
      // blindIndexes 序列化为逗号分隔字符串，空列表应安全处理
      final card = makePasswordCard(blindIndexes: []);
      final map = card.toMap();
      final restored = PasswordCard.fromMap(map);
      expect(restored.blindIndexes, isEmpty);
    });

    test('isDeleted 标记正确序列化', () {
      final card = makePasswordCard(isDeleted: true);
      final map = card.toMap();
      expect(map['is_deleted'], equals(1));
      final restored = PasswordCard.fromMap(map);
      expect(restored.isDeleted, isTrue);
    });
  });

  group('PasswordCard — copyWith 契约', () {
    test('copyWith 不修改原始对象', () {
      final original = makePasswordCard();
      final copied = original.copyWith(isDeleted: true);
      expect(original.isDeleted, isFalse);
      expect(copied.isDeleted, isTrue);
      expect(copied.cardId, equals(original.cardId));
    });

    test('markDeleted 创建墓碑', () {
      final card = makePasswordCard();
      final deleted = card.markDeleted('device', 'event-id');
      expect(deleted.isDeleted, isTrue);
      expect(deleted.cardId, equals(card.cardId));
      expect(deleted.currentEventId, equals('event-id'));
    });
  });

  // ==================== PasswordEvent ====================

  group('PasswordEvent — 序列化契约', () {
    test('toMap/fromMap round-trip (核心字段)', () {
      final event = makePasswordEvent();
      expect(event, isPasswordEventSerializable);
    });

    test('toJson/fromJson round-trip (完整)', () {
      final event = makePasswordEvent();
      expect(event, isPasswordEventJsonSerializable);
    });

    test('所有事件类型的序列化', () {
      for (final type in EventType.values) {
        final event = makePasswordEvent(type: type);
        expect(event, isPasswordEventSerializable,
            reason: 'Failed for type $type');
      }
    });
  });

  group('PasswordEvent — hash 链校验', () {
    test('calculateHash 确定性', () {
      final event = makePasswordEvent();
      final hash1 = event.calculateHash();
      final hash2 = event.calculateHash();
      expect(hash1, equals(hash2));
    });

    test('不同事件产生不同 hash', () {
      final e1 = makePasswordEvent(eventId: 'id1');
      final e2 = makePasswordEvent(eventId: 'id2');
      expect(e1.calculateHash(), isNot(equals(e2.calculateHash())));
    });
  });

  // ==================== EncryptedPayload ====================

  group('EncryptedPayload — 序列化契约', () {
    test('serialize/deserialize round-trip', () {
      final payload = makeEncryptedPayload();
      final serialized = payload.serialize();
      final restored = EncryptedPayload.deserialize(serialized);
      expect(restored, equals(payload));
    });

    test('toJson/fromJson round-trip', () {
      final payload = makeEncryptedPayload();
      final json = payload.toJson();
      final restored = EncryptedPayload.fromJson(json);
      expect(restored, equals(payload));
    });
  });

  // ==================== AuthPayload ====================

  group('AuthPayload — 序列化契约', () {
    test('toJson/fromJson round-trip', () {
      final payload = makeAuthPayload(notes: 'some note');
      expect(payload, isAuthPayloadSerializable);
    });

    test('fromOtpAuthUri 解析标准 URI', () {
      const uri =
          'otpauth://totp/GitHub:test@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA1&digits=6&period=30';
      final payload = AuthPayload.fromOtpAuthUri(uri);
      expect(payload.issuer, equals('GitHub'));
      expect(payload.account, equals('test@example.com'));
      expect(payload.secret, equals('JBSWY3DPEHPK3PXP'));
      expect(payload.digits, equals(6));
      expect(payload.period, equals(30));
    });

    test('toOtpAuthUri → fromOtpAuthUri round-trip', () {
      final original = makeAuthPayload();
      final uri = original.toOtpAuthUri();
      final restored = AuthPayload.fromOtpAuthUri(uri);
      // 核心字段应一致
      expect(restored.issuer, equals(original.issuer));
      expect(restored.account, equals(original.account));
      expect(restored.secret, equals(original.secret));
      expect(restored.digits, equals(original.digits));
      expect(restored.period, equals(original.period));
    });
  });

  // ==================== AuthCard ====================

  group('AuthCard — 序列化契约', () {
    test('toMap/fromMap round-trip', () {
      final card = makeAuthCard();
      final map = card.toMap();
      final restored = AuthCard.fromMap(map);
      expect(restored, equals(card));
    });

    test('copyWith 保持不可变性', () {
      final original = makeAuthCard();
      final copied = original.copyWith(isDeleted: true);
      expect(original.isDeleted, isFalse);
      expect(copied.isDeleted, isTrue);
    });

    test('markDeleted 创建墓碑', () {
      final card = makeAuthCard();
      final deleted = card.markDeleted('device-x');
      expect(deleted.isDeleted, isTrue);
      expect(deleted.cardId, equals(card.cardId));
    });
  });

  // ==================== EventUtils ====================

  group('EventUtils — 工具函数契约', () {
    test('sortByHLC 返回因果有序列表', () {
      final events = [
        makePasswordEvent(hlc: makeHLC(physicalTime: 3000), eventId: 'e3'),
        makePasswordEvent(hlc: makeHLC(physicalTime: 1000), eventId: 'e1'),
        makePasswordEvent(hlc: makeHLC(physicalTime: 2000), eventId: 'e2'),
      ];
      final sorted = EventUtils.sortByHLC(events);
      final hlcs = sorted.map((e) => e.hlc).toList();
      expect(hlcs, isCausallyOrdered);
    });

    test('latest 返回 HLC 更大的事件', () {
      final earlier =
          makePasswordEvent(hlc: makeHLC(physicalTime: 1000), eventId: 'e1');
      final later =
          makePasswordEvent(hlc: makeHLC(physicalTime: 2000), eventId: 'e2');
      expect(EventUtils.latest(earlier, later), equals(later));
      expect(EventUtils.latest(later, earlier), equals(later));
    });

    test('filterByCardId 正确过滤', () {
      final events = [
        makePasswordEvent(cardId: 'card-a', eventId: 'e1'),
        makePasswordEvent(cardId: 'card-b', eventId: 'e2'),
        makePasswordEvent(cardId: 'card-a', eventId: 'e3'),
      ];
      final filtered = EventUtils.filterByCardId(events, 'card-a');
      expect(filtered, hasLength(2));
      expect(filtered.every((e) => e.cardId == 'card-a'), isTrue);
    });
  });
}
