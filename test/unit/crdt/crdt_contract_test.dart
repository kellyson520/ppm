/// CRDT Merger 行为契约测试
///
/// CRDT 有严格的数学不变式（幂等、交换、结合），此测试基于这些数学属性。
/// 通用性：只要 CRDT 语义不变，哪怕内部数据结构完全重写，这些测试都不需改动。
///         属性测试风格（Property-Based），比 example-based 更抗重构。
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/crdt/crdt_merger.dart';
import 'package:ztd_password_manager/core/models/models.dart';
import '../../helpers/test_helpers.dart';

void main() {
  // ==================== LWW-Register 数学属性 ====================

  group('CrdtMerger.mergeCards — LWW-Register 属性', () {
    test('幂等性：merge(x, x) == x', () {
      final card = makePasswordCard();
      expect(card, isCrdtIdempotent);
    });

    test('交换律：merge(a, b) == merge(b, a)', () {
      final a = makePasswordCard(
        cardId: kTestCardId1,
        updatedAt: makeHLC(physicalTime: 1000),
      );
      final b = makePasswordCard(
        cardId: kTestCardId1,
        updatedAt: makeHLC(physicalTime: 2000),
      );
      expect(a, isCrdtCommutativeWith(b));
    });

    test('结合律：merge(merge(a,b), c) == merge(a, merge(b,c))', () {
      final a = makePasswordCard(
        cardId: kTestCardId1,
        updatedAt: makeHLC(physicalTime: 1000, deviceId: 'dev-a'),
      );
      final b = makePasswordCard(
        cardId: kTestCardId1,
        updatedAt: makeHLC(physicalTime: 2000, deviceId: 'dev-b'),
      );
      final c = makePasswordCard(
        cardId: kTestCardId1,
        updatedAt: makeHLC(physicalTime: 1500, deviceId: 'dev-c'),
      );
      final abC = CrdtMerger.mergeCards(CrdtMerger.mergeCards(a, b), c);
      final aBc = CrdtMerger.mergeCards(a, CrdtMerger.mergeCards(b, c));
      expect(abC, equals(aBc));
    });

    test('LWW 语义：更新时间更晚的获胜', () {
      final old = makePasswordCard(
        updatedAt: makeHLC(physicalTime: 1000),
        encryptedPayload: 'old-data',
      );
      final newer = makePasswordCard(
        updatedAt: makeHLC(physicalTime: 2000),
        encryptedPayload: 'new-data',
      );
      final winner = CrdtMerger.mergeCards(old, newer);
      expect(winner.encryptedPayload, equals('new-data'));
    });

    test('确定性 tie-breaking：时间戳相同时用 deviceId', () {
      final a = makePasswordCard(
        updatedAt: makeHLC(physicalTime: 1000, deviceId: 'aaa'),
        encryptedPayload: 'data-a',
      );
      final b = makePasswordCard(
        updatedAt: makeHLC(physicalTime: 1000, deviceId: 'bbb'),
        encryptedPayload: 'data-b',
      );
      // deviceId 'bbb' > 'aaa'，所以 b 应获胜
      final winner = CrdtMerger.mergeCards(a, b);
      expect(winner.encryptedPayload, equals('data-b'));
      // 交换顺序仍然 b 获胜
      final winner2 = CrdtMerger.mergeCards(b, a);
      expect(winner2.encryptedPayload, equals('data-b'));
    });
  });

  group('CrdtMerger.mergeCardList — 批量合并', () {
    test('空列表返回 null', () {
      expect(CrdtMerger.mergeCardList([]), isNull);
    });

    test('单元素列表返回该元素', () {
      final card = makePasswordCard();
      expect(CrdtMerger.mergeCardList([card]), equals(card));
    });

    test('多元素列表返回最新的', () {
      final cards = List.generate(
        5,
        (i) => makePasswordCard(
          updatedAt: makeHLC(physicalTime: 1000 + i * 1000),
          encryptedPayload: 'data-$i',
        ),
      );
      final winner = CrdtMerger.mergeCardList(cards)!;
      expect(winner.encryptedPayload, equals('data-4'));
    });
  });

  // ==================== applyEvent 状态机 ====================

  group('CrdtMerger.applyEvent — 事件应用状态机', () {
    test('cardCreated 在空状态上创建新卡片', () {
      final event = makePasswordEvent(type: EventType.cardCreated);
      final result = CrdtMerger.applyEvent(null, event);
      expect(result, isNotNull);
      expect(result!.cardId, equals(event.cardId));
      expect(result.isDeleted, isFalse);
    });

    test('cardCreated 在已存在的卡片上是幂等的（Add-Wins Set）', () {
      final existing = makePasswordCard();
      final event = makePasswordEvent(type: EventType.cardCreated);
      final result = CrdtMerger.applyEvent(existing, event);
      expect(result, equals(existing));
    });

    test('cardUpdated 更新已有卡片', () {
      final existing = makePasswordCard(
        updatedAt: makeHLC(physicalTime: 1000),
      );
      final newPayload = makeEncryptedPayload(ciphertext: 'new-cipher');
      final event = makePasswordEvent(
        type: EventType.cardUpdated,
        hlc: makeHLC(physicalTime: 2000),
        payload: newPayload,
      );
      final result = CrdtMerger.applyEvent(existing, event);
      expect(result, isNotNull);
      expect(result!.encryptedPayload, equals('new-cipher'));
    });

    test('cardUpdated 对更旧的事件无效', () {
      final existing = makePasswordCard(
        updatedAt: makeHLC(physicalTime: 2000),
        encryptedPayload: 'current',
      );
      final event = makePasswordEvent(
        type: EventType.cardUpdated,
        hlc: makeHLC(physicalTime: 1000),
      );
      final result = CrdtMerger.applyEvent(existing, event);
      expect(result!.encryptedPayload, equals('current'));
    });

    test('cardDeleted 标记墓碑', () {
      final existing = makePasswordCard(
        updatedAt: makeHLC(physicalTime: 1000),
      );
      final event = makePasswordEvent(
        type: EventType.cardDeleted,
        hlc: makeHLC(physicalTime: 2000),
      );
      final result = CrdtMerger.applyEvent(existing, event);
      expect(result!.isDeleted, isTrue);
    });

    test('snapshotCreated 不改变卡片状态', () {
      final existing = makePasswordCard();
      final event = makePasswordEvent(type: EventType.snapshotCreated);
      final result = CrdtMerger.applyEvent(existing, event);
      expect(result, equals(existing));
    });
  });

  // ==================== mergeEventSets ====================

  group('CrdtMerger.mergeEventSets — 事件集合合并', () {
    test('合并两个不交集', () {
      final local = [
        makePasswordEvent(eventId: 'e1', hlc: makeHLC(physicalTime: 1000)),
      ];
      final remote = [
        makePasswordEvent(eventId: 'e2', hlc: makeHLC(physicalTime: 2000)),
      ];
      final merged = CrdtMerger.mergeEventSets(local, remote);
      expect(merged, hasLength(2));
      // 应按 HLC 排序
      expect(merged.first.eventId, equals('e1'));
      expect(merged.last.eventId, equals('e2'));
    });

    test('合并有重叠事件 ID 的集合（去重）', () {
      final event = makePasswordEvent(eventId: 'same-id');
      final local = [event];
      final remote = [event];
      final merged = CrdtMerger.mergeEventSets(local, remote);
      expect(merged, hasLength(1));
    });

    test('空集合与非空集合合并', () {
      final events = [makePasswordEvent(eventId: 'e1')];
      expect(CrdtMerger.mergeEventSets(events, []), hasLength(1));
      expect(CrdtMerger.mergeEventSets([], events), hasLength(1));
    });
  });

  // ==================== buildStateFromEvents ====================

  group('CrdtMerger.buildStateFromEvents — 事件重放', () {
    test('创建事件生成卡片', () {
      final events = [
        makePasswordEvent(
          type: EventType.cardCreated,
          cardId: 'card-1',
          eventId: 'e1',
        ),
      ];
      final state = CrdtMerger.buildStateFromEvents(events);
      expect(state.containsKey('card-1'), isTrue);
      expect(state['card-1']!.isDeleted, isFalse);
    });

    test('完整生命周期：create → update → delete', () {
      final lifecycle = makeEventLifecycle(cardId: 'card-1');
      final state = CrdtMerger.buildStateFromEvents(lifecycle);
      expect(state.containsKey('card-1'), isTrue);
      expect(state['card-1']!.isDeleted, isTrue);
    });

    test('多张卡片独立管理', () {
      final events = [
        makePasswordEvent(
          type: EventType.cardCreated,
          cardId: 'card-a',
          eventId: 'e1',
          hlc: makeHLC(physicalTime: 1000),
        ),
        makePasswordEvent(
          type: EventType.cardCreated,
          cardId: 'card-b',
          eventId: 'e2',
          hlc: makeHLC(physicalTime: 2000),
        ),
      ];
      final state = CrdtMerger.buildStateFromEvents(events);
      expect(state.keys, containsAll(['card-a', 'card-b']));
    });
  });

  // ==================== detectConflicts ====================

  group('CrdtMerger.detectConflicts — 冲突检测', () {
    test('无并发事件时无冲突', () {
      final local = [
        makePasswordEvent(
          cardId: 'card-a',
          eventId: 'e1',
          hlc: makeHLC(physicalTime: 1000, deviceId: 'dev-a'),
        ),
      ];
      final remote = [
        makePasswordEvent(
          cardId: 'card-a',
          eventId: 'e2',
          hlc: makeHLC(physicalTime: 2000, deviceId: 'dev-b'),
        ),
      ];
      final conflicts = CrdtMerger.detectConflicts(local, remote);
      expect(conflicts, isEmpty);
    });

    test('并发事件被识别为冲突', () {
      final local = [
        makePasswordEvent(
          cardId: 'card-a',
          eventId: 'e1',
          hlc:
              makeHLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'dev-a'),
        ),
      ];
      final remote = [
        makePasswordEvent(
          cardId: 'card-a',
          eventId: 'e2',
          hlc:
              makeHLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'dev-b'),
        ),
      ];
      final conflicts = CrdtMerger.detectConflicts(local, remote);
      expect(conflicts, hasLength(1));
      expect(conflicts.first.cardId, equals('card-a'));
    });
  });

  // ==================== resolveConflicts ====================

  group('CrdtMerger.resolveConflicts — 冲突解决', () {
    test('使用 LWW 语义解决冲突', () {
      final localEvent = makePasswordEvent(
        eventId: 'e-local',
        hlc: makeHLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'dev-a'),
      );
      final remoteEvent = makePasswordEvent(
        eventId: 'e-remote',
        hlc: makeHLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'dev-b'),
      );
      final conflicts = [
        Conflict(
          cardId: 'card-a',
          localEvent: localEvent,
          remoteEvent: remoteEvent,
        ),
      ];
      final resolutions = CrdtMerger.resolveConflicts(conflicts);
      expect(resolutions, hasLength(1));
      expect(resolutions['card-a'], isNotNull);
    });
  });

  // ==================== compactEvents ====================

  group('CrdtMerger.compactEvents — 事件压缩', () {
    test('只保留当前状态匹配的最新事件', () {
      final event1 = makePasswordEvent(
        eventId: 'e1',
        cardId: 'card-a',
        hlc: makeHLC(physicalTime: 1000),
        type: EventType.cardCreated,
      );
      final event2 = makePasswordEvent(
        eventId: 'e2',
        cardId: 'card-a',
        hlc: makeHLC(physicalTime: 2000),
        type: EventType.cardUpdated,
      );
      final currentState = {
        'card-a': makePasswordCard(
          cardId: 'card-a',
          currentEventId: 'e2',
        ),
      };
      final compacted =
          CrdtMerger.compactEvents([event1, event2], currentState);
      expect(compacted, hasLength(1));
      expect(compacted.first.eventId, equals('e2'));
    });

    test('已删除的卡片不包含在压缩结果中', () {
      final event = makePasswordEvent(
        eventId: 'e1',
        cardId: 'card-deleted',
        type: EventType.cardDeleted,
      );
      final currentState = {
        'card-deleted': makePasswordCard(
          cardId: 'card-deleted',
          currentEventId: 'e1',
          isDeleted: true,
        ),
      };
      final compacted = CrdtMerger.compactEvents([event], currentState);
      expect(compacted, isEmpty);
    });
  });

  // ==================== CrdtState ====================

  group('CrdtState — 容器', () {
    test('activeCards 排除已删除的', () {
      final state = CrdtState(
        cards: {
          'a': makePasswordCard(cardId: 'a', isDeleted: false),
          'b': makePasswordCard(cardId: 'b', isDeleted: true),
          'c': makePasswordCard(cardId: 'c', isDeleted: false),
        },
        events: [],
        latestHlc: makeHLC(),
      );
      expect(state.activeCards, hasLength(2));
      expect(state.deletedCards, hasLength(1));
    });

    test('hasCard 检查活跃卡片', () {
      final state = CrdtState(
        cards: {
          'active': makePasswordCard(cardId: 'active'),
          'deleted': makePasswordCard(cardId: 'deleted', isDeleted: true),
        },
        events: [],
        latestHlc: makeHLC(),
      );
      expect(state.hasCard('active'), isTrue);
      expect(state.hasCard('deleted'), isFalse);
      expect(state.hasCard('nonexistent'), isFalse);
    });

    test('empty 工厂创建空状态', () {
      final state = CrdtState.empty('device1');
      expect(state.cards, isEmpty);
      expect(state.events, isEmpty);
    });
  });
}
