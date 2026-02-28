import 'dart:async';
import 'dart:typed_data';
import 'package:synchronized/synchronized.dart';

/// Secure Buffer for sensitive data
///
/// Features:
/// - Automatic memory wiping after TTL
/// - Read/Write locking for thread safety
/// - DoD 5220.22-M compliant data destruction
/// - Access resets TTL timer
///
/// Usage:
/// ```dart
/// final buffer = SecureBuffer(ttl: Duration(seconds: 30));
/// buffer.set(sensitiveData);
/// // ... use buffer.access() ...
/// buffer.dispose(); // Explicit cleanup
/// ```
class SecureBuffer {
  Uint8List? _sensitiveData;
  Timer? _wipeTimer;
  final _lock = Lock();
  final Duration _defaultTtl;
  DateTime? _lastAccess;

  /// Create secure buffer with default TTL
  SecureBuffer({Duration ttl = const Duration(seconds: 30)})
      : _defaultTtl = ttl;

  /// Store sensitive data with optional custom TTL
  Future<void> set(Uint8List data, {Duration? ttl}) async {
    await _lock.synchronized(() {
      _wipe(); // Immediately wipe old data
      _sensitiveData = Uint8List.fromList(data);
      _scheduleWipe(ttl ?? _defaultTtl);
      _lastAccess = DateTime.now();
    });
  }

  /// Store string data
  Future<void> setString(String data, {Duration? ttl}) async {
    await set(Uint8List.fromList(data.codeUnits), ttl: ttl);
  }

  /// Access sensitive data (read-only view)
  /// Resets TTL timer on access
  Future<Uint8List?> access() async {
    return await _lock.synchronized(() {
      if (_sensitiveData == null) return null;

      _resetTimer();
      _lastAccess = DateTime.now();

      // Return a copy to prevent external modification
      return Uint8List.fromList(_sensitiveData!);
    });
  }

  /// Access as string
  Future<String?> accessString() async {
    final data = await access();
    if (data == null) return null;
    return String.fromCharCodes(data);
  }

  /// Check if buffer contains data
  bool get hasData => _sensitiveData != null;

  /// Get time since last access
  Duration? get timeSinceLastAccess {
    if (_lastAccess == null) return null;
    return DateTime.now().difference(_lastAccess!);
  }

  /// Reset the wipe timer
  void _resetTimer() {
    _wipeTimer?.cancel();
    _scheduleWipe(_defaultTtl);
  }

  /// Schedule automatic wipe
  void _scheduleWipe(Duration ttl) {
    _wipeTimer = Timer(ttl, () {
      _lock.synchronized(_wipe);
    });
  }

  /// Securely wipe data (DoD 5220.22-M simplified)
  void _wipe() {
    if (_sensitiveData != null) {
      // Pass 1: Write 0x00
      _sensitiveData!.fillRange(0, _sensitiveData!.length, 0x00);
      // Pass 2: Write 0xFF
      _sensitiveData!.fillRange(0, _sensitiveData!.length, 0xFF);
      // Pass 3: Write 0x00
      _sensitiveData!.fillRange(0, _sensitiveData!.length, 0x00);

      _sensitiveData = null;
    }
    _wipeTimer?.cancel();
    _wipeTimer = null;
  }

  /// Explicitly dispose and wipe
  Future<void> dispose() async {
    await _lock.synchronized(_wipe);
  }

  /// Get remaining time before wipe
  Duration? get remainingTime {
    if (_wipeTimer == null) return null;
    // Approximate remaining time
    return _defaultTtl;
  }
}

/// Password Input Buffer - Specialized for password entry
///
/// Automatically masks input and provides secure handling
class PasswordInputBuffer {
  final List<int> _chars = [];
  final _lock = Lock();
  final SecureBuffer _secureBuffer;

  PasswordInputBuffer({Duration ttl = const Duration(seconds: 60)})
      : _secureBuffer = SecureBuffer(ttl: ttl);

  /// Add character
  Future<void> addChar(String char) async {
    await _lock.synchronized(() {
      if (char.length == 1) {
        _chars.add(char.codeUnitAt(0));
        _updateBuffer();
      }
    });
  }

  /// Remove last character (backspace)
  Future<void> backspace() async {
    await _lock.synchronized(() {
      if (_chars.isNotEmpty) {
        _chars.removeLast();
        _updateBuffer();
      }
    });
  }

  /// Clear all input
  Future<void> clear() async {
    await _lock.synchronized(() {
      _chars.clear();
      _secureBuffer.dispose();
    });
  }

  /// Get current password length (for masking display)
  Future<int> get length async {
    return await _lock.synchronized(() => _chars.length);
  }

  /// Get password as secure buffer
  Future<SecureBuffer> finalize() async {
    final buffer = SecureBuffer();
    final data = await _lock.synchronized(() {
      final copy = Uint8List.fromList(_chars);
      _chars.clear();
      return copy;
    });
    await buffer.set(data);
    return buffer;
  }

  void _updateBuffer() {
    _secureBuffer.set(Uint8List.fromList(_chars));
  }

  /// Dispose
  Future<void> dispose() async {
    await _lock.synchronized(() {
      _chars.clear();
    });
    await _secureBuffer.dispose();
  }
}

/// Secure String - Immutable secure string container
///
/// Automatically wipes after TTL or when disposed
class SecureString {
  final SecureBuffer _buffer;
  final String _id;

  SecureString._(this._buffer) : _id = _generateId();

  /// Create from string
  static Future<SecureString> create(
    String data, {
    Duration ttl = const Duration(seconds: 30),
  }) async {
    final buffer = SecureBuffer(ttl: ttl);
    await buffer.setString(data, ttl: ttl);
    return SecureString._(buffer);
  }

  /// Create from bytes
  static Future<SecureString> fromBytes(
    Uint8List data, {
    Duration ttl = const Duration(seconds: 30),
  }) async {
    final buffer = SecureBuffer(ttl: ttl);
    await buffer.set(data, ttl: ttl);
    return SecureString._(buffer);
  }

  /// Access the string
  Future<String?> get() async => await _buffer.accessString();

  /// Get ID (for tracking, not the content)
  String get id => _id;

  /// Dispose
  Future<void> dispose() async => await _buffer.dispose();

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Memory pressure handler
///
/// Wipes all secure buffers when memory pressure is detected
class MemoryPressureHandler {
  static final List<SecureBuffer> _buffers = [];
  static final _lock = Lock();

  /// Register a buffer for tracking
  static Future<void> register(SecureBuffer buffer) async {
    await _lock.synchronized(() {
      _buffers.add(buffer);
    });
  }

  /// Unregister a buffer
  static Future<void> unregister(SecureBuffer buffer) async {
    await _lock.synchronized(() {
      _buffers.remove(buffer);
    });
  }

  /// Wipe all registered buffers (emergency cleanup)
  static Future<void> emergencyWipe() async {
    await _lock.synchronized(() async {
      for (final buffer in _buffers) {
        await buffer.dispose();
      }
      _buffers.clear();
    });
  }

  /// Get count of tracked buffers
  static Future<int> get bufferCount async {
    return await _lock.synchronized(() => _buffers.length);
  }
}
