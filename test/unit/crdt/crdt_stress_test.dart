/// CRDT 冲突压力测试
///
/// 模拟 A、B 两台设备在几乎同一时刻对同一份数据进行不同修改。
/// 验证：合并结果是否满足强一致性（Strong Eventual Consistency）。
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/crdt/crdt_merger.dart';
import 'package:ztd_password_manager/core/models/models.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('CRDT 压力测试 — 极限并发冲突', () {
    test('同步时钟冲突 (Physical Time Identical)', () {
      const cardId = 'conflict-card-1';
      final baseCreatedHlc = makeHLC(physicalTime: 1000);

      // 设备 A 在 2000ms 更新标题
      final cardA = makePasswordCard(
        cardId: cardId,
        createdAt: baseCreatedHlc,
        updatedAt: makeHLC(physicalTime: 2000, deviceId: 'device-A'),
        encryptedPayload: 'payload-A',
      );

      // 设备 B 也在 2000ms 更新密码 (假设物理时钟完全同步)
      final cardB = makePasswordCard(
        cardId: cardId,
        createdAt: baseCreatedHlc,
        updatedAt: makeHLC(physicalTime: 2000, deviceId: 'device-B'),
        encryptedPayload: 'payload-B',
      );

      // 合并结果
      final merge1 = CrdtMerger.mergeCards(cardA, cardB);
      final merge2 = CrdtMerger.mergeCards(cardB, cardA);

      // [1] SEC 验证：合并结果必须与顺序无关
      expect(merge1, equals(merge2),
          reason: 'SEC Failure: Merged state depends on order.');

      // [2] Tie-breaking 验证：应该根据 deviceId 决定胜负
      // 'device-B' > 'device-A'，所以 payload-B 应获胜
      expect(merge1.encryptedPayload, equals('payload-B'));
    });

    test('多级更新冲突链', () {
      final h1 = makeHLC(physicalTime: 1000, deviceId: 'A');
      final h2 = makeHLC(physicalTime: 2000, deviceId: 'B');
      final h3 = makeHLC(physicalTime: 3000, deviceId: 'A');

      final v1 = makePasswordCard(updatedAt: h1, encryptedPayload: 'v1');
      final v2 = makePasswordCard(updatedAt: h2, encryptedPayload: 'v2');
      final v3 = makePasswordCard(updatedAt: h3, encryptedPayload: 'v3');

      // 路径 1: (v1 merge v2) merge v3
      final merge_12_3 =
          CrdtMerger.mergeCards(CrdtMerger.mergeCards(v1, v2), v3);
      // 路径 2: v1 merge (v2 merge v3)
      final merge_1_23 =
          CrdtMerger.mergeCards(v1, CrdtMerger.mergeCards(v2, v3));

      expect(merge_12_3.encryptedPayload, equals('v3'));
      expect(merge_1_23.encryptedPayload, equals('v3'));
      expect(merge_12_3, equals(merge_1_23));
    });
  });
}
