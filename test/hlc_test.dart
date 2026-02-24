import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/models/models.dart';

void main() {
  group('HLC Tests', () {
    test('HLC creation', () {
      final hlc = HLC.now('device1');
      
      expect(hlc.physicalTime, isNotNull);
      expect(hlc.logicalCounter, equals(0));
      expect(hlc.deviceId, equals('device1'));
    });

    test('HLC comparison - happened before', () {
      final hlc1 = HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'A');
      final hlc2 = HLC(physicalTime: 2000, logicalCounter: 0, deviceId: 'B');
      
      expect(hlc1.happenedBefore(hlc2), isTrue);
      expect(hlc2.happenedBefore(hlc1), isFalse);
    });

    test('HLC comparison - same physical time', () {
      final hlc1 = HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'A');
      final hlc2 = HLC(physicalTime: 1000, logicalCounter: 1, deviceId: 'B');
      
      expect(hlc1.compareTo(hlc2), lessThan(0));
      expect(hlc2.compareTo(hlc1), greaterThan(0));
    });

    test('HLC merge', () {
      final local = HLC(physicalTime: 1000, logicalCounter: 5, deviceId: 'A');
      final remote = HLC(physicalTime: 2000, logicalCounter: 3, deviceId: 'B');
      
      final merged = local.merge(remote);
      
      expect(merged.physicalTime, greaterThanOrEqualTo(remote.physicalTime));
      expect(merged.deviceId, equals('A'));
    });

    test('HLC increment', () {
      final hlc = HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'A');
      final incremented = hlc.increment();
      
      expect(incremented.physicalTime, equals(hlc.physicalTime));
      expect(incremented.logicalCounter, equals(1));
      expect(incremented.deviceId, equals(hlc.deviceId));
    });

    test('HLC JSON serialization', () {
      final hlc = HLC(physicalTime: 1000, logicalCounter: 5, deviceId: 'A');
      final json = hlc.toJson();
      final restored = HLC.fromJson(json);
      
      expect(restored.physicalTime, equals(hlc.physicalTime));
      expect(restored.logicalCounter, equals(hlc.logicalCounter));
      expect(restored.deviceId, equals(hlc.deviceId));
    });
  });

  group('HLCUtils Tests', () {
    test('max returns latest HLC', () {
      final hlc1 = HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'A');
      final hlc2 = HLC(physicalTime: 2000, logicalCounter: 0, deviceId: 'B');
      
      final max = HLCUtils.max(hlc1, hlc2);
      
      expect(max, equals(hlc2));
    });

    test('isCausallyOrdered returns true for ordered list', () {
      final hlcs = [
        HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'A'),
        HLC(physicalTime: 2000, logicalCounter: 0, deviceId: 'B'),
        HLC(physicalTime: 3000, logicalCounter: 0, deviceId: 'C'),
      ];
      
      expect(HLCUtils.isCausallyOrdered(hlcs), isTrue);
    });

    test('isCausallyOrdered returns false for unordered list', () {
      final hlcs = [
        HLC(physicalTime: 2000, logicalCounter: 0, deviceId: 'A'),
        HLC(physicalTime: 1000, logicalCounter: 0, deviceId: 'B'),
        HLC(physicalTime: 3000, logicalCounter: 0, deviceId: 'C'),
      ];
      
      expect(HLCUtils.isCausallyOrdered(hlcs), isFalse);
    });
  });
}
