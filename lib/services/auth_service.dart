import 'dart:convert';
import 'dart:typed_data';
import '../core/models/models.dart';
import '../core/crypto/crypto_service.dart';
import '../core/crypto/totp_generator.dart';
import '../core/models/auth_card.dart';

/// Authenticator Service - 身份验证器业务逻辑
/// 
/// 加密架构与 VaultService 完全一致：
/// - 每张卡片独立用 DEK 进行 AES-256-GCM 加密
/// - 卡片名称/发行方通过盲索引支持搜索
/// - 按需解密：只有用户点击卡片时才解密
/// 
/// 依赖外部注入的 DEK 和 SearchKey（由 VaultService 统一管理）
class AuthService {
  final CryptoService _cryptoService;
  
  // 内存中缓存的卡片列表（加密状态）
  List<AuthCard> _cards = [];
  
  AuthService({CryptoService? cryptoService})
      : _cryptoService = cryptoService ?? CryptoService();

  /// 获取所有卡片
  List<AuthCard> get cards => List.unmodifiable(_cards);
  
  /// 卡片数量
  int get cardCount => _cards.where((c) => !c.isDeleted).length;

  // ==================== CRUD Operations ====================

  /// 创建新的 Authenticator 卡片
  AuthCard createCard({
    required AuthPayload payload,
    required Uint8List dek,
    required Uint8List searchKey,
    required String deviceId,
  }) {
    // 加密 payload
    final encryptedPayload = _encryptPayload(payload, dek);
    
    // 生成盲索引（用于搜索发行方和账号名）
    final searchableText = '${payload.issuer} ${payload.account}';
    final blindIndexes = _cryptoService.generateBlindIndexes(
      searchableText,
      searchKey,
    );
    
    final now = HLC.now(deviceId);
    final card = AuthCard(
      cardId: _generateId(),
      encryptedPayload: encryptedPayload,
      blindIndexes: blindIndexes,
      createdAt: now,
      updatedAt: now,
    );
    
    _cards.add(card);
    return card;
  }

  /// 更新卡片
  AuthCard? updateCard({
    required String cardId,
    required AuthPayload newPayload,
    required Uint8List dek,
    required Uint8List searchKey,
    required String deviceId,
  }) {
    final index = _cards.indexWhere((c) => c.cardId == cardId);
    if (index < 0) return null;
    
    final encryptedPayload = _encryptPayload(newPayload, dek);
    final searchableText = '${newPayload.issuer} ${newPayload.account}';
    final blindIndexes = _cryptoService.generateBlindIndexes(
      searchableText,
      searchKey,
    );
    
    final updated = _cards[index].copyWith(
      encryptedPayload: encryptedPayload,
      blindIndexes: blindIndexes,
      updatedAt: HLC.now(deviceId),
    );
    
    _cards[index] = updated;
    return updated;
  }

  /// 删除卡片（软删除）
  bool deleteCard(String cardId, String deviceId) {
    final index = _cards.indexWhere((c) => c.cardId == cardId);
    if (index < 0) return false;
    
    _cards[index] = _cards[index].markDeleted(deviceId);
    return true;
  }

  /// 永久删除
  bool permanentlyDeleteCard(String cardId) {
    return _cards.removeWhere((c) => c.cardId == cardId) == null || true;
  }

  /// 获取活跃卡片
  List<AuthCard> getActiveCards() {
    return _cards.where((c) => !c.isDeleted).toList();
  }

  /// 获取单张卡片
  AuthCard? getCard(String cardId) {
    try {
      return _cards.firstWhere((c) => c.cardId == cardId && !c.isDeleted);
    } catch (_) {
      return null;
    }
  }

  // ==================== Decryption (On-demand) ====================

  /// 按需解密卡片 - 只在用户点击时调用
  AuthPayload? decryptCard(AuthCard card, Uint8List dek) {
    try {
      final encryptedData = EncryptedData(
        ciphertext: base64Decode(card.encryptedPayload),
        iv: Uint8List(12),
        authTag: Uint8List(16),
      );
      
      final decrypted = _cryptoService.decryptString(
        EncryptedData(
          ciphertext: encryptedData.ciphertext,
          iv: encryptedData.iv,
          authTag: encryptedData.authTag,
        ),
        dek,
      );
      
      return AuthPayload.fromJson(
        jsonDecode(decrypted) as Map<String, dynamic>,
      );
    } on Exception {
      return null;
    }
  }

  // ==================== TOTP Generation ====================

  /// 生成 TOTP 验证码
  String generateTOTP(AuthPayload payload) {
    return TOTPGenerator.generateCode(
      payload.secret,
      algorithm: payload.algorithm,
      digits: payload.digits,
      period: payload.period,
    );
  }

  /// 获取剩余秒数
  int getRemainingSeconds({int period = 30}) {
    return TOTPGenerator.getRemainingSeconds(period: period);
  }

  /// 获取进度
  double getProgress({int period = 30}) {
    return TOTPGenerator.getProgress(period: period);
  }

  // ==================== Import / Export ====================

  /// 从 otpauth:// URI 导入
  AuthCard? importFromUri(
    String uri,
    Uint8List dek,
    Uint8List searchKey,
    String deviceId,
  ) {
    try {
      final payload = AuthPayload.fromOtpAuthUri(uri);
      return createCard(
        payload: payload,
        dek: dek,
        searchKey: searchKey,
        deviceId: deviceId,
      );
    } on Exception {
      return null;
    }
  }

  /// 批量导入（从文本中解析多个 otpauth:// URI）
  List<AuthCard> importFromText(
    String text,
    Uint8List dek,
    Uint8List searchKey,
    String deviceId,
  ) {
    final imported = <AuthCard>[];
    
    // 匹配所有 otpauth:// URI
    final regex = RegExp(r'otpauth://[^\s]+');
    final matches = regex.allMatches(text);
    
    for (final match in matches) {
      final uri = match.group(0)!;
      final card = importFromUri(uri, dek, searchKey, deviceId);
      if (card != null) {
        imported.add(card);
      }
    }
    
    return imported;
  }

  /// 导出单张卡片为 otpauth:// URI
  String? exportAsUri(AuthCard card, Uint8List dek) {
    final payload = decryptCard(card, dek);
    if (payload == null) return null;
    return payload.toOtpAuthUri();
  }

  /// 导出所有卡片为文本（每行一个 otpauth:// URI）
  String exportAllAsText(Uint8List dek) {
    final uris = <String>[];
    
    for (final card in getActiveCards()) {
      final uri = exportAsUri(card, dek);
      if (uri != null) {
        uris.add(uri);
      }
    }
    
    return uris.join('\n');
  }

  /// 导出所有卡片为 JSON（可用于备份）
  String exportAsJson(Uint8List dek) {
    final items = <Map<String, dynamic>>[];
    
    for (final card in getActiveCards()) {
      final payload = decryptCard(card, dek);
      if (payload != null) {
        items.add({
          'type': 'totp',
          'uuid': card.cardId,
          'name': payload.issuer,
          'issuer': payload.issuer,
          'info': payload.toJson(),
        });
      }
    }
    
    return jsonEncode({
      'version': 1,
      'header': {
        'slots': null,
        'params': null,
      },
      'db': {
        'version': 1,
        'entries': items,
      },
    });
  }

  // ==================== Search ====================

  /// 搜索卡片（通过盲索引）
  List<AuthCard> search(String query, Uint8List searchKey) {
    if (query.isEmpty) return getActiveCards();
    
    final searchHashes = _cryptoService.generateBlindIndexes(
      query.toLowerCase(),
      searchKey,
    );
    
    return getActiveCards().where((card) {
      return card.blindIndexes.any((idx) => searchHashes.contains(idx));
    }).toList();
  }

  // ==================== Private ====================

  String _encryptPayload(AuthPayload payload, Uint8List dek) {
    final jsonPayload = jsonEncode(payload.toJson());
    final encrypted = _cryptoService.encryptString(jsonPayload, dek);
    return base64Encode(encrypted.ciphertext);
  }

  String _generateId() {
    final random = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    return 'auth-$random-${random.substring(0, 4)}-4${random.substring(4, 8)}';
  }

  /// 清理内存
  void dispose() {
    _cards.clear();
  }
}
