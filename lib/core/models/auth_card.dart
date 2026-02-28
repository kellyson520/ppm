import 'package:equatable/equatable.dart';
import 'hlc.dart';

/// Authenticator Card Entity
///
/// 与 PasswordCard 加密架构完全一致：
/// - 每张卡片的 payload 独立用 DEK 进行 AES-256-GCM 加密
/// - 卡片名称通过 blindIndexes 实现盲索引搜索
/// - 只有点击卡片时才按需解密
class AuthCard extends Equatable {
  final String cardId; // UUID v4
  final String encryptedPayload; // AES-GCM encrypted JSON (AuthPayload)
  final List<String> blindIndexes; // HMAC-SHA256 indexes for search
  final HLC createdAt;
  final HLC updatedAt;
  final bool isDeleted; // Tombstone marker

  const AuthCard({
    required this.cardId,
    required this.encryptedPayload,
    required this.blindIndexes,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  /// Create from database row
  factory AuthCard.fromMap(Map<String, dynamic> map) {
    return AuthCard(
      cardId: map['card_id'] as String,
      encryptedPayload: map['encrypted_payload'] as String,
      blindIndexes: (map['blind_indexes'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      createdAt: HLC.fromJson({
        'physicalTime': map['created_at_physical'] as int,
        'logicalCounter': map['created_at_logical'] as int,
        'deviceId': map['created_at_device'] as String,
      }),
      updatedAt: HLC.fromJson({
        'physicalTime': map['updated_at_physical'] as int,
        'logicalCounter': map['updated_at_logical'] as int,
        'deviceId': map['updated_at_device'] as String,
      }),
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }

  /// Convert to database row
  Map<String, dynamic> toMap() => {
        'card_id': cardId,
        'encrypted_payload': encryptedPayload,
        'blind_indexes': blindIndexes.join(','),
        'created_at_physical': createdAt.physicalTime,
        'created_at_logical': createdAt.logicalCounter,
        'created_at_device': createdAt.deviceId,
        'updated_at_physical': updatedAt.physicalTime,
        'updated_at_logical': updatedAt.logicalCounter,
        'updated_at_device': updatedAt.deviceId,
        'is_deleted': isDeleted ? 1 : 0,
      };

  /// Create a copy with updated values
  AuthCard copyWith({
    String? encryptedPayload,
    List<String>? blindIndexes,
    HLC? updatedAt,
    bool? isDeleted,
  }) =>
      AuthCard(
        cardId: cardId,
        encryptedPayload: encryptedPayload ?? this.encryptedPayload,
        blindIndexes: blindIndexes ?? this.blindIndexes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  /// Mark as deleted (tombstone)
  AuthCard markDeleted(String deviceId) => copyWith(
        isDeleted: true,
        updatedAt: HLC.now(deviceId),
      );

  @override
  List<Object?> get props =>
      [cardId, encryptedPayload, blindIndexes, createdAt, updatedAt, isDeleted];
}

/// Decrypted authenticator payload (in memory only, never stored)
///
/// 存储完整的 otpauth:// URI 以保证可迁移性
/// 解密后在内存中计算 TOTP 验证码，用完即清
class AuthPayload extends Equatable {
  final String issuer; // 发行方, e.g. "GitHub", "Google"
  final String account; // 账号, e.g. "user@example.com"
  final String secret; // Base32 编码的密钥
  final String algorithm; // 哈希算法: SHA1, SHA256, SHA512
  final int digits; // 验证码位数: 6 或 8
  final int period; // 刷新周期(秒): 通常 30
  final String? otpauthUri; // 完整的 otpauth:// URI (用于导出)
  final String? notes; // 备注

  const AuthPayload({
    required this.issuer,
    required this.account,
    required this.secret,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
    this.otpauthUri,
    this.notes,
  });

  /// 从 otpauth:// URI 解析
  /// 格式: otpauth://totp/Issuer:Account?secret=XXX&issuer=Issuer&algorithm=SHA1&digits=6&period=30
  factory AuthPayload.fromOtpAuthUri(String uri) {
    final parsed = Uri.parse(uri);

    // 解析 path 中的 label (issuer:account)
    final String rawLabel = Uri.decodeComponent(
        parsed.path.replaceFirst('/totp/', '').replaceFirst('/hotp/', ''));
    String issuer = '';
    String account = rawLabel;

    if (rawLabel.contains(':')) {
      final parts = rawLabel.split(':');
      issuer = parts[0].trim();
      account = parts.sublist(1).join(':').trim();
    }

    // 从 query 参数获取
    final params = parsed.queryParameters;
    issuer = params['issuer'] ?? issuer;
    final secret = params['secret'] ?? '';
    final algorithm = params['algorithm'] ?? 'SHA1';
    final digits = int.tryParse(params['digits'] ?? '6') ?? 6;
    final period = int.tryParse(params['period'] ?? '30') ?? 30;

    return AuthPayload(
      issuer: issuer,
      account: account,
      secret: secret.toUpperCase(),
      algorithm: algorithm.toUpperCase(),
      digits: digits,
      period: period,
      otpauthUri: uri,
    );
  }

  /// 生成 otpauth:// URI
  String toOtpAuthUri() {
    if (otpauthUri != null && otpauthUri!.isNotEmpty) {
      return otpauthUri!;
    }

    final label = issuer.isNotEmpty
        ? '${Uri.encodeComponent(issuer)}:${Uri.encodeComponent(account)}'
        : Uri.encodeComponent(account);

    final params = <String, String>{
      'secret': secret,
      'algorithm': algorithm,
      'digits': digits.toString(),
      'period': period.toString(),
    };
    if (issuer.isNotEmpty) {
      params['issuer'] = issuer;
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'otpauth://totp/$label?$queryString';
  }

  factory AuthPayload.fromJson(Map<String, dynamic> json) {
    return AuthPayload(
      issuer: json['issuer'] as String? ?? '',
      account: json['account'] as String? ?? '',
      secret: json['secret'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? 'SHA1',
      digits: json['digits'] as int? ?? 6,
      period: json['period'] as int? ?? 30,
      otpauthUri: json['otpauthUri'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'issuer': issuer,
        'account': account,
        'secret': secret,
        'algorithm': algorithm,
        'digits': digits,
        'period': period,
        if (otpauthUri != null) 'otpauthUri': otpauthUri,
        if (notes != null) 'notes': notes,
      };

  AuthPayload copyWith({
    String? issuer,
    String? account,
    String? secret,
    String? algorithm,
    int? digits,
    int? period,
    String? otpauthUri,
    String? notes,
  }) =>
      AuthPayload(
        issuer: issuer ?? this.issuer,
        account: account ?? this.account,
        secret: secret ?? this.secret,
        algorithm: algorithm ?? this.algorithm,
        digits: digits ?? this.digits,
        period: period ?? this.period,
        otpauthUri: otpauthUri ?? this.otpauthUri,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props =>
      [issuer, account, secret, algorithm, digits, period, otpauthUri, notes];
}
