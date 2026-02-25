import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// 崩溃信息数据类
class CrashInfo {
  /// 错误对象的字符串表示
  final String errorMessage;

  /// 完整调用堆栈
  final String stackTrace;

  /// 崩溃发生时间（ISO 8601 格式）
  final String timestamp;

  /// 错误来源标签，例如 "FlutterError / Zone / Platform"
  final String source;

  const CrashInfo({
    required this.errorMessage,
    required this.stackTrace,
    required this.timestamp,
    required this.source,
  });

  /// 生成可直接复制的纯文本报告
  String toPlainText() {
    return '''
=== TG ONE 崩溃报告 ===
时间:   $timestamp
来源:   $source

--- 错误信息 ---
$errorMessage

--- 调用堆栈 ---
$stackTrace
===================
''';
  }
}

/// 崩溃回调类型：由 main.dart 注入，负责将崩溃信息路由到 UI
typedef CrashHandler = void Function(CrashInfo info);

/// 崩溃报告服务
///
/// 负责注册三路错误拦截钩子：
/// 1. [FlutterError.onError]   — Flutter 框架同步异常
/// 2. [PlatformDispatcher.onError] — Dart 平台层未捕获异常
/// 3. [runZonedGuarded]        — Zone 内异步异常（由 main.dart 配置）
class CrashReportService {
  CrashReportService._();

  static final CrashReportService instance = CrashReportService._();

  CrashHandler? _handler;

  /// 注入崩溃处理回调 —— 在 main() 初始化完成后调用
  void setHandler(CrashHandler handler) {
    _handler = handler;
  }

  /// 注册 Flutter 框架异常钩子
  void registerFlutterErrorHook() {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Debug 模式下同时打印原始 Flutter 错误堆栈
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      _report(
        error: details.exception,
        stack: details.stack ?? StackTrace.empty,
        source: 'FlutterError',
      );
    };
  }

  /// 注册 Dart 平台层异常钩子（覆盖 Web / Android / iOS 原生未捕获错误）
  void registerPlatformErrorHook() {
    ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _report(error: error, stack: stack, source: 'PlatformDispatcher');
      // 返回 true 表示错误已处理，避免系统层二次崩溃弹窗
      return true;
    };
  }

  /// 由 [runZonedGuarded] 捕获后调用
  void reportZoneError(Object error, StackTrace stack) {
    _report(error: error, stack: stack, source: 'Zone');
  }

  /// 内部统一上报入口
  void _report({
    required Object error,
    required StackTrace stack,
    required String source,
  }) {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final info = CrashInfo(
      errorMessage: error.toString(),
      stackTrace: stack.toString(),
      timestamp: timestamp,
      source: source,
    );

    // 如果 handler 已注入则触发 UI 弹窗；否则仅在调试模式打印
    if (_handler != null) {
      _handler!(info);
    } else {
      if (kDebugMode) {
        debugPrint('[CrashReportService] [$source] $error\n$stack');
      }
    }
  }
}
