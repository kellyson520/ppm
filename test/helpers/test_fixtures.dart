/// 通用测试数据工厂 (Test Fixtures)
///
/// 所有测试用例共享的模型构建器。
/// 当模型字段变更时，只需修改此文件，所有引用它的测试自动适配。
///
/// 设计原则：
/// - 每个工厂方法提供合理默认值，允许按需覆盖
/// - 使用 Builder 模式支持链式调用
/// - 固定种子数据保证测试可重复性
import 'dart:convert';
import 'dart:typed_data';
import 'package:ztd_password_manager/core/models/models.dart';
import 'package:ztd_password_manager/core/crypto/crypto_service.dart';

// ==================== 常量 ====================

/// 固定测试设备 ID（保证 HLC 确定性）
const String kTestDeviceA = 'test-device-aaa';
const String kTestDeviceB = 'test-device-bbb';

/// 固定测试 cardId
const String kTestCardId1 = '11111111-1111-1111-1111-111111111111';
const String kTestCardId2 = '22222222-2222-2222-2222-222222222222';
const String kTestCardId3 = '33333333-3333-3333-3333-333333333333';

/// 固定测试 eventId
const String kTestEventId1 = 'eeeeeeee-1111-1111-1111-111111111111';
const String kTestEventId2 = 'eeeeeeee-2222-2222-2222-222222222222';
const String kTestEventId3 = 'eeeeeeee-3333-3333-3333-333333333333';

// ==================== HLC 工厂 ====================

/// 创建测试用 HLC
///
/// [physicalTime] 物理时间（毫秒），默认 1000000
/// [logicalCounter] 逻辑计数器，默认 0
/// [deviceId] 设备 ID，默认 kTestDeviceA
HLC makeHLC({
  int physicalTime = 1000000,
  int logicalCounter = 0,
  String deviceId = kTestDeviceA,
}) {
  return HLC(
    physicalTime: physicalTime,
    logicalCounter: logicalCounter,
    deviceId: deviceId,
  );
}

/// 创建一系列因果有序的 HLC（用于事件链测试）
List<HLC> makeCausalHLCChain(int count, {String deviceId = kTestDeviceA}) {
  return List.generate(
    count,
    (i) => HLC(
      physicalTime: 1000000 + i * 1000,
      logicalCounter: 0,
      deviceId: deviceId,
    ),
  );
}

// ==================== PasswordPayload 工厂 ====================

/// 创建测试用密码载荷
PasswordPayload makePasswordPayload({
  String title = 'Test Title',
  String username = 'testuser',
  String password = 'P@ssw0rd!2024',
  String? url = 'https://example.com',
  String? notes,
  List<String> tags = const [],
  DateTime? expiresAt,
}) {
  return PasswordPayload(
    title: title,
    username: username,
    password: password,
    url: url,
    notes: notes,
    tags: tags,
    expiresAt: expiresAt,
  );
}

/// 创建 N 个不同的 PasswordPayload
List<PasswordPayload> makePasswordPayloads(int count) {
  return List.generate(
    count,
    (i) => makePasswordPayload(
      title: 'Entry $i',
      username: 'user$i',
      password: 'Pass$i!@#',
      url: 'https://site$i.com',
    ),
  );
}

// ==================== PasswordCard 工厂 ====================

/// 创建测试用密码卡片
///
/// 提供合理默认值，关键字段可按需覆盖
PasswordCard makePasswordCard({
  String? cardId,
  String encryptedPayload = 'encrypted-test-payload',
  List<String> blindIndexes = const ['idx1', 'idx2'],
  HLC? createdAt,
  HLC? updatedAt,
  String? currentEventId,
  bool isDeleted = false,
}) {
  final hlc = createdAt ?? makeHLC();
  return PasswordCard(
    cardId: cardId ?? kTestCardId1,
    encryptedPayload: encryptedPayload,
    blindIndexes: blindIndexes,
    createdAt: hlc,
    updatedAt: updatedAt ?? hlc,
    currentEventId: currentEventId ?? kTestEventId1,
    isDeleted: isDeleted,
  );
}

/// 创建一个"真实加密"的密码卡片（ciphertext 可解密）
///
/// 使用 CryptoService 做真实加密，适用于端到端集成测试
PasswordCard makeEncryptedPasswordCard({
  String? cardId,
  PasswordPayload? payload,
  Uint8List? dek,
  CryptoService? cryptoService,
}) {
  final cs = cryptoService ?? CryptoService();
  final key = dek ?? cs.generateRandomBytes(32);
  final pl = payload ?? makePasswordPayload();
  final encrypted = cs.encryptString(jsonEncode(pl.toJson()), key);
  final serialized = encrypted.serialize();

  final hlc = makeHLC();
  return PasswordCard(
    cardId: cardId ?? kTestCardId1,
    encryptedPayload: serialized,
    blindIndexes: const ['real-idx'],
    createdAt: hlc,
    updatedAt: hlc,
    currentEventId: kTestEventId1,
  );
}

// ==================== EncryptedPayload 工厂 ====================

/// 创建测试用加密载荷容器
EncryptedPayload makeEncryptedPayload({
  String ciphertext = 'dGVzdC1jaXBoZXJ0ZXh0', // base64 of "test-ciphertext"
  String iv = 'dGVzdC1pdg==', // base64 of "test-iv"
  String authTag = 'dGVzdC1hdXRoLXRhZw==', // base64 of "test-auth-tag"
}) {
  return EncryptedPayload(
    ciphertext: ciphertext,
    iv: iv,
    authTag: authTag,
  );
}

// ==================== EncryptedData 工厂 ====================

/// 创建测试用加密数据容器 (Uint8List 版本)
EncryptedData makeEncryptedData({
  Uint8List? ciphertext,
  Uint8List? iv,
  Uint8List? authTag,
}) {
  return EncryptedData(
    ciphertext: ciphertext ?? Uint8List.fromList([1, 2, 3, 4]),
    iv: iv ?? Uint8List.fromList(List.filled(12, 0)),
    authTag: authTag ?? Uint8List.fromList(List.filled(16, 0)),
  );
}

// ==================== PasswordEvent 工厂 ====================

/// 创建测试用密码事件
PasswordEvent makePasswordEvent({
  HLC? hlc,
  String? eventId,
  String deviceId = kTestDeviceA,
  EventType type = EventType.cardCreated,
  String? cardId,
  EncryptedPayload? payload,
  String? prevEventHash,
  String? signature,
}) {
  return PasswordEvent(
    hlc: hlc ?? makeHLC(),
    eventId: eventId ?? kTestEventId1,
    deviceId: deviceId,
    type: type,
    cardId: cardId ?? kTestCardId1,
    payload: payload ?? makeEncryptedPayload(),
    prevEventHash: prevEventHash,
    signature: signature,
  );
}

/// 创建一条卡片创建事件链：create -> update -> delete
List<PasswordEvent> makeEventLifecycle({
  String? cardId,
  String deviceId = kTestDeviceA,
}) {
  final cid = cardId ?? kTestCardId1;
  final hlcs = makeCausalHLCChain(3, deviceId: deviceId);

  return [
    makePasswordEvent(
      hlc: hlcs[0],
      eventId: 'lifecycle-create-$cid',
      deviceId: deviceId,
      type: EventType.cardCreated,
      cardId: cid,
    ),
    makePasswordEvent(
      hlc: hlcs[1],
      eventId: 'lifecycle-update-$cid',
      deviceId: deviceId,
      type: EventType.cardUpdated,
      cardId: cid,
      prevEventHash: 'lifecycle-create-$cid',
    ),
    makePasswordEvent(
      hlc: hlcs[2],
      eventId: 'lifecycle-delete-$cid',
      deviceId: deviceId,
      type: EventType.cardDeleted,
      cardId: cid,
      payload: const EncryptedPayload(ciphertext: '', iv: '', authTag: ''),
      prevEventHash: 'lifecycle-update-$cid',
    ),
  ];
}

// ==================== AuthCard / AuthPayload 工厂 ====================

/// 创建测试用认证器载荷
AuthPayload makeAuthPayload({
  String issuer = 'GitHub',
  String account = 'test@example.com',
  String secret = 'JBSWY3DPEHPK3PXP', // 标准 TOTP 测试密钥
  String algorithm = 'SHA1',
  int digits = 6,
  int period = 30,
  String? otpauthUri,
  String? notes,
}) {
  return AuthPayload(
    issuer: issuer,
    account: account,
    secret: secret,
    algorithm: algorithm,
    digits: digits,
    period: period,
    otpauthUri: otpauthUri,
    notes: notes,
  );
}

/// 创建测试用认证器卡片
AuthCard makeAuthCard({
  String cardId = 'auth-card-11111111',
  String encryptedPayload = 'encrypted-auth-payload',
  List<String> blindIndexes = const ['auth-idx1'],
  HLC? createdAt,
  HLC? updatedAt,
  bool isDeleted = false,
}) {
  final hlc = createdAt ?? makeHLC();
  return AuthCard(
    cardId: cardId,
    encryptedPayload: encryptedPayload,
    blindIndexes: blindIndexes,
    createdAt: hlc,
    updatedAt: updatedAt ?? hlc,
    isDeleted: isDeleted,
  );
}

// ==================== Map (DB row) 工厂 ====================

/// 创建模拟数据库行的 Map（PasswordCard）
Map<String, dynamic> makePasswordCardMap({
  String? cardId,
  String encryptedPayload = 'encrypted-payload',
  String blindIndexes = 'idx1,idx2',
  int createdAtPhysical = 1000000,
  int createdAtLogical = 0,
  String createdAtDevice = kTestDeviceA,
  int updatedAtPhysical = 1000000,
  int updatedAtLogical = 0,
  String updatedAtDevice = kTestDeviceA,
  String currentEventId = kTestEventId1,
  int isDeleted = 0,
}) {
  return {
    'card_id': cardId ?? kTestCardId1,
    'encrypted_payload': encryptedPayload,
    'blind_indexes': blindIndexes,
    'created_at_physical': createdAtPhysical,
    'created_at_logical': createdAtLogical,
    'created_at_device': createdAtDevice,
    'updated_at_physical': updatedAtPhysical,
    'updated_at_logical': updatedAtLogical,
    'updated_at_device': updatedAtDevice,
    'current_event_id': currentEventId,
    'is_deleted': isDeleted,
  };
}

/// 创建模拟数据库行的 Map（PasswordEvent）
Map<String, dynamic> makePasswordEventMap({
  String? eventId,
  int hlcPhysical = 1000000,
  int hlcLogical = 0,
  String hlcDevice = kTestDeviceA,
  String deviceId = kTestDeviceA,
  String type = 'cardCreated',
  String? cardId,
  String payloadCiphertext = 'ciphertext',
  String payloadIv = 'iv',
  String payloadAuthTag = 'authTag',
  String? prevEventHash,
  String? signature,
}) {
  return {
    'event_id': eventId ?? kTestEventId1,
    'hlc_physical': hlcPhysical,
    'hlc_logical': hlcLogical,
    'hlc_device': hlcDevice,
    'device_id': deviceId,
    'type': type,
    'card_id': cardId ?? kTestCardId1,
    'payload_ciphertext': payloadCiphertext,
    'payload_iv': payloadIv,
    'payload_auth_tag': payloadAuthTag,
    'prev_event_hash': prevEventHash,
    'signature': signature,
  };
}
