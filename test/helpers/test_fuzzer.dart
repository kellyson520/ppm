/// 极端数据模糊生成器 (Fuzzer)
///
/// 目标：生成能够触发解析崩溃、越界或溢出的边界数据。
library;

import 'dart:math';
import 'dart:typed_data';

class TestFuzzer {
  static final Random _random = Random();

  /// 生成各种奇葩字符串
  static String randomString({int? length}) {
    final len = length ?? _random.nextInt(1000); // 随机 0-1000 长度
    final types = [
      () => _simpleString(len),
      () => _unicodeString(len),
      () => _injectedString(len),
      () => _longString(5000), // 超长字符串
    ];
    return types[_random.nextInt(types.length)]();
  }

  static String _simpleString(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(len, (i) => chars[_random.nextInt(chars.length)]).join();
  }

  static String _unicodeString(int len) {
    const emojis = '😀😃😄😁😆😅😂🤣😇😉😊😋😌😍🥰😘';
    const cjk = '你好我是测试数据密码管理器こんにちはनमस्ते';
    const all = emojis + cjk;
    return List.generate(len, (i) => all[_random.nextInt(all.length)]).join();
  }

  static String _injectedString(int len) {
    const payloads = [
      '\' OR 1=1 --', // SQL 注入
      '<script>alert(1)</script>', // XSS
      '../../etc/passwd', // 路径穿越
      '%s%s%s%s%s', // 格式化字符串
      '\x00\xFF\x01', // 二进制/截断
    ];
    return payloads[_random.nextInt(payloads.length)];
  }

  static String _longString(int len) => 'A' * len;

  /// 生成随机字节块
  static Uint8List randomBytes(int len) {
    return Uint8List.fromList(List.generate(len, (_) => _random.nextInt(256)));
  }
}
