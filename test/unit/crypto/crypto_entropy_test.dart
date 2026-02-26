// 加密层深度校验：熵值与碰撞测试
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/crypto/crypto_service.dart';

void main() {
  final cs = CryptoService();

  group('加密深度校验 — 熵值与碰撞', () {
    test('IV 唯一性测试 — 大规模生成不碰撞', () {
      final key = cs.generateRandomBytes(32);
      final ivs = <String>{};
      const iterations = 1000; // 模拟连续加解密 1000 次

      for (int i = 0; i < iterations; i++) {
        final encrypted = cs.encryptString('test', key);
        final ivHex = cs.bytesToHex(encrypted.iv);

        expect(ivs.contains(ivHex), isFalse,
            reason:
                'IV Collision detected at iteration $i! This is a CRITICAL security failure.');
        ivs.add(ivHex);
      }
    });

    test('随机数熵值估算 (简单频次统计)', () {
      // 生成一个较大的随机块
      final bytes = cs.generateRandomBytes(10240); // 10KB
      final counts = Map<int, int>.fromIterable(
        List.generate(256, (i) => i),
        value: (_) => 0,
      );

      for (var b in bytes) {
        counts[b] = counts[b]! + 1;
      }

      // 理想情况下，每个字节出现的概率应接近 1/256
      // 我们允许一定的统计偏差 (3个标准差左右)
      const expected = 10240 / 256;
      const tolerance = expected * 0.8; // 允许 80% 的偏差波动 (约 5.0 倍标准差，极低误报率)

      for (var count in counts.values) {
        expect(count,
            isWithin(from: expected - tolerance, to: expected + tolerance),
            reason:
                'Entropy distribution test failed! Byte frequency deviation too large.');
      }
    });
  });
}

/// 辅助 Matcher
Matcher isWithin({required double from, required double to}) =>
    _WithinMatcher(from, to);

class _WithinMatcher extends Matcher {
  final double from, to;
  _WithinMatcher(this.from, this.to);
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) =>
      item is num && item >= from && item <= to;
  @override
  Description describe(Description description) =>
      description.add('is between $from and $to');
}
