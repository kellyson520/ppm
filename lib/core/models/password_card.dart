import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'hlc.dart';

/// Password Card Entity
/// Represents an encrypted password entry in the vault
class PasswordCard extends Equatable {
  final String cardId;           // UUID v4
  final String encryptedPayload; // AES-GCM encrypted JSON
  final List<String> blindIndexes; // HMAC-SHA256 indexes for search
  final HLC createdAt;
  final HLC updatedAt;
  final String currentEventId;   // Points to latest event
  final bool isDeleted;          // Tombstone marker

  const PasswordCard({
    required this.cardId,
    required this.encryptedPayload,
    required this.blindIndexes,
    required this.createdAt,
    required this.updatedAt,
    required this.currentEventId,
    this.isDeleted = false,
  });

  /// Create a new password card
  factory PasswordCard.create({
    required String encryptedPayload,
    required List<String> blindIndexes,
    required String deviceId,
    required String eventId,
  }) {
    final now = HLC.now(deviceId);
    return PasswordCard(
      cardId: const Uuid().v4(),
      encryptedPayload: encryptedPayload,
      blindIndexes: blindIndexes,
      createdAt: now,
      updatedAt: now,
      currentEventId: eventId,
      isDeleted: false,
    );
  }

  /// Create from database row
  factory PasswordCard.fromMap(Map<String, dynamic> map) {
    return PasswordCard(
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
      currentEventId: map['current_event_id'] as String,
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
    'current_event_id': currentEventId,
    'is_deleted': isDeleted ? 1 : 0,
  };

  /// Create a copy with updated values
  PasswordCard copyWith({
    String? encryptedPayload,
    List<String>? blindIndexes,
    HLC? updatedAt,
    String? currentEventId,
    bool? isDeleted,
  }) => PasswordCard(
    cardId: cardId,
    encryptedPayload: encryptedPayload ?? this.encryptedPayload,
    blindIndexes: blindIndexes ?? this.blindIndexes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    currentEventId: currentEventId ?? this.currentEventId,
    isDeleted: isDeleted ?? this.isDeleted,
  );

  /// Mark as deleted (tombstone)
  PasswordCard markDeleted(String deviceId, String eventId) => copyWith(
    isDeleted: true,
    updatedAt: HLC.now(deviceId),
    currentEventId: eventId,
  );

  @override
  List<Object?> get props => [
    cardId, 
    encryptedPayload, 
    blindIndexes, 
    createdAt, 
    updatedAt, 
    currentEventId, 
    isDeleted
  ];
}

/// Decrypted password payload (in memory only, never stored)
class PasswordPayload extends Equatable {
  final String title;
  final String username;
  final String password;
  final String? url;
  final String? notes;
  final List<String> tags;
  final DateTime? expiresAt;

  const PasswordPayload({
    required this.title,
    required this.username,
    required this.password,
    this.url,
    this.notes,
    this.tags = const [],
    this.expiresAt,
  });

  factory PasswordPayload.fromJson(Map<String, dynamic> json) {
    return PasswordPayload(
      title: json['title'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      url: json['url'] as String?,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'username': username,
    'password': password,
    if (url != null) 'url': url,
    if (notes != null) 'notes': notes,
    if (tags.isNotEmpty) 'tags': tags,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
  };

  PasswordPayload copyWith({
    String? title,
    String? username,
    String? password,
    String? url,
    String? notes,
    List<String>? tags,
    DateTime? expiresAt,
  }) => PasswordPayload(
    title: title ?? this.title,
    username: username ?? this.username,
    password: password ?? this.password,
    url: url ?? this.url,
    notes: notes ?? this.notes,
    tags: tags ?? this.tags,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  @override
  List<Object?> get props => [title, username, password, url, notes, tags, expiresAt];
}
