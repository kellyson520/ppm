/// 通用 Matcher 集合 —— 行为契约驱动的断言工具
///
/// 这些 Matcher 测试的是"行为契约"而非"实现细节"。
/// 当内部实现变化（如换加密算法）时，只要契约不变，测试就不会断裂。
///
/// 使用方式：
///   expect(result, `isSerializable<PasswordCard>(PasswordCard.fromMap, PasswordCard.toMap)`);
///   expect(encrypted, isValidEncryptedData);
///   expect(hlcList, isCausallyOrdered);
library;

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ztd_password_manager/core/models/models.dart';
import 'package:ztd_password_manager/core/crypto/crypto_service.dart';
import 'package:ztd_password_manager/core/crdt/crdt_merger.dart';

// ==================== Encryption Matchers ====================

/// 验证 EncryptedData 结构完整性（ciphertext/iv/authTag 均非空）
const Matcher isValidEncryptedData = _ValidEncryptedDataMatcher();

class _ValidEncryptedDataMatcher extends Matcher {
  const _ValidEncryptedDataMatcher();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! EncryptedData) return false;
    return item.ciphertext.isNotEmpty &&
        item.iv.isNotEmpty &&
        item.authTag.isNotEmpty;
  }

  @override
  Description describe(Description description) => description
      .add('is valid EncryptedData with non-empty ciphertext, iv, authTag');
}

/// 验证 EncryptedData 可序列化并反序列化回相同值
const Matcher isSerializableEncryptedData = _SerializableEncryptedDataMatcher();

class _SerializableEncryptedDataMatcher extends Matcher {
  const _SerializableEncryptedDataMatcher();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! EncryptedData) return false;
    try {
      final serialized = item.serialize();
      final deserialized = EncryptedData.deserialize(serialized);
      return _uint8ListEquals(item.ciphertext, deserialized.ciphertext) &&
          _uint8ListEquals(item.iv, deserialized.iv) &&
          _uint8ListEquals(item.authTag, deserialized.authTag);
    } on Object catch (_) {
      return false;
    }
  }

  @override
  Description describe(Description description) => description
      .add('EncryptedData that survives serialize→deserialize round-trip');
}

// ==================== Encryption Round-Trip Matcher ====================

/// 验证一段明文可以被加密后解密回原始值
class EncryptionRoundTripMatcher extends Matcher {
  final Uint8List key;
  final CryptoService cryptoService;

  const EncryptionRoundTripMatcher(this.key, this.cryptoService);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! String) return false;
    try {
      final encrypted = cryptoService.encryptString(item, key);
      final decrypted = cryptoService.decryptString(encrypted, key);
      return decrypted == item;
    } on Object catch (e) {
      matchState['error'] = e;
      return false;
    }
  }

  @override
  Description describe(Description description) =>
      description.add('string that survives encrypt→decrypt round-trip');

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map<dynamic, dynamic> matchState, bool verbose) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add('threw ${matchState['error']}');
    }
    return mismatchDescription.add('did not survive round-trip');
  }
}

/// 便捷构造函数
Matcher encryptsAndDecrypts(Uint8List key, CryptoService cs) =>
    EncryptionRoundTripMatcher(key, cs);

// ==================== HLC Matchers ====================

/// 验证 HLC 列表符合因果序（每个后续 HLC >= 前一个）
const Matcher isCausallyOrdered = _CausallyOrderedMatcher();

class _CausallyOrderedMatcher extends Matcher {
  const _CausallyOrderedMatcher();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! List<HLC>) return false;
    for (int i = 1; i < item.length; i++) {
      if (item[i].compareTo(item[i - 1]) < 0) {
        matchState['breakIndex'] = i;
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('is causally ordered HLC list');

  @override
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map<dynamic, dynamic> matchState, bool verbose) {
    if (matchState.containsKey('breakIndex')) {
      final i = matchState['breakIndex'] as int;
      return mismatchDescription.add('causal order broken at index $i');
    }
    return mismatchDescription;
  }
}

/// 验证 HLC 的 JSON round-trip
const Matcher isHlcJsonSerializable = _HlcJsonRoundTripMatcher();

class _HlcJsonRoundTripMatcher extends Matcher {
  const _HlcJsonRoundTripMatcher();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! HLC) return false;
    final json = item.toJson();
    final restored = HLC.fromJson(json);
    return item == restored;
  }

  @override
  Description describe(Description description) =>
      description.add('HLC survives toJson→fromJson round-trip');
}

// ==================== Model Serialization Matchers ====================

/// 验证 PasswordCard 的 toMap/fromMap round-trip
const Matcher isPasswordCardSerializable = _PasswordCardSerializableMatcher();

class _PasswordCardSerializableMatcher extends Matcher {
  const _PasswordCardSerializableMatcher();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! PasswordCard) return false;
    try {
      final map = item.toMap();
      final restored = PasswordCard.fromMap(map);
      return item == restored;
    } on Object catch (e) {
      matchState['error'] = e;
      return false;
    }
  }

  @override
  Description describe(Description description) =>
      description.add('PasswordCard survives toMap→fromMap round-trip');
}

/// 验证 PasswordPayload 的 toJson/fromJson round-trip
const Matcher isPasswordPayloadSerializable =
    _PasswordPayloadSerializableMatcher();

class _PasswordPayloadSerializableMatcher extends Matcher {
  const _PasswordPayloadSerializableMatcher();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! PasswordPayload) return false;
    try {
      final json = item.toJson();
      final restored = PasswordPayload.fromJson(json);
      return item == restored;
    } on Object catch (e) {
      matchState['error'] = e;
      return false;
    }
  }

  @override
  Description describe(Description description) =>
      description.add('PasswordPayload survives toJson→fromJson round-trip');
}

/// 验证 PasswordEvent 的 toMap/fromMap round-trip
const Matcher isPasswordEventSerializable = _PasswordEventSerializableMatcher();

class _PasswordEventSerializableMatcher extends Matcher {
  const _PasswordEventSerializableMatcher();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! PasswordEvent) return false;
    try {
      final map = item.toMap();
      final restored = PasswordEvent.fromMap(map);
      // fromMap 不会完整恢复 created_at 等，但核心字段应匹配
      return item.eventId == restored.eventId &&
          item.cardId == restored.cardId &&
          item.type == restored.type &&
          item.deviceId == restored.deviceId;
    } on Object catch (e) {
      matchState['error'] = e;
      return false;
    }
  }

  @override
  Description describe(Description description) => description
      .add('PasswordEvent survives toMap→fromMap round-trip (core fields)');
}

/// 验证 PasswordEvent 的 toJson/fromJson round-trip
const Matcher isPasswordEventJsonSerializable =
    _PasswordEventJsonSerializableMatcher();

class _PasswordEventJsonSerializableMatcher extends Matcher {
  const _PasswordEventJsonSerializableMatcher();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! PasswordEvent) return false;
    try {
      final json = item.toJson();
      final restored = PasswordEvent.fromJson(json);
      return item == restored;
    } on Object catch (e) {
      matchState['error'] = e;
      return false;
    }
  }

  @override
  Description describe(Description description) =>
      description.add('PasswordEvent survives toJson→fromJson round-trip');
}

/// 验证 AuthPayload 的 toJson/fromJson round-trip
const Matcher isAuthPayloadSerializable = _AuthPayloadSerializableMatcher();

class _AuthPayloadSerializableMatcher extends Matcher {
  const _AuthPayloadSerializableMatcher();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! AuthPayload) return false;
    try {
      final json = item.toJson();
      final restored = AuthPayload.fromJson(json);
      return item == restored;
    } on Object catch (e) {
      matchState['error'] = e;
      return false;
    }
  }

  @override
  Description describe(Description description) =>
      description.add('AuthPayload survives toJson→fromJson round-trip');
}

// ==================== CRDT Matchers ====================

/// 验证 CRDT 合并的幂等性：merge(a, a) == a
class CrdtIdempotentMatcher extends Matcher {
  const CrdtIdempotentMatcher();

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! PasswordCard) return false;
    try {
      final merged = CrdtMerger.mergeCards(item, item);
      return merged == item;
    } on Object catch (e) {
      matchState['error'] = e;
      return false;
    }
  }

  @override
  Description describe(Description description) =>
      description.add('CRDT merge is idempotent (merge(x,x) == x)');
}

const Matcher isCrdtIdempotent = CrdtIdempotentMatcher();

/// 验证 CRDT 合并的交换律：merge(a, b) == merge(b, a)
class CrdtCommutativeMatcher extends Matcher {
  final PasswordCard other;
  const CrdtCommutativeMatcher(this.other);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! PasswordCard) return false;
    try {
      final ab = CrdtMerger.mergeCards(item, other);
      final ba = CrdtMerger.mergeCards(other, item);
      return ab == ba;
    } on Object catch (e) {
      matchState['error'] = e;
      return false;
    }
  }

  @override
  Description describe(Description description) =>
      description.add('CRDT merge is commutative (merge(a,b) == merge(b,a))');
}

Matcher isCrdtCommutativeWith(PasswordCard other) =>
    CrdtCommutativeMatcher(other);

// ==================== Utility ====================

bool _uint8ListEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
