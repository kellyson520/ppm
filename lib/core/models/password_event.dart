import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'hlc.dart';

/// Event types for password operations
enum EventType {
  cardCreated, // Add-Wins Set semantics
  cardUpdated, // LWW-Register semantics
  cardDeleted, // Tombstone semantics
  snapshotCreated, // System event for compaction
}

/// Encrypted payload container
class EncryptedPayload extends Equatable {
  final String ciphertext; // Base64 encoded encrypted data
  final String iv; // Base64 encoded initialization vector
  final String authTag; // Base64 encoded authentication tag

  const EncryptedPayload({
    required this.ciphertext,
    required this.iv,
    required this.authTag,
  });

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) {
    return EncryptedPayload(
      ciphertext: json['ciphertext'] as String,
      iv: json['iv'] as String,
      authTag: json['authTag'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertext,
        'iv': iv,
        'authTag': authTag,
      };

  /// Combine all components for storage/transmission
  String serialize() => base64Encode(utf8.encode(jsonEncode(toJson())));

  factory EncryptedPayload.deserialize(String data) {
    final json =
        jsonDecode(utf8.decode(base64Decode(data))) as Map<String, dynamic>;
    return EncryptedPayload.fromJson(json);
  }

  @override
  List<Object?> get props => [ciphertext, iv, authTag];
}

/// Password Event - Immutable event for Event Sourcing
/// CRDT-compatible structure with HLC timestamps
class PasswordEvent extends Equatable {
  // Hybrid Logical Clock for causal ordering
  final HLC hlc;

  // Event metadata
  final String eventId; // UUID v4, globally unique
  final String deviceId; // Device fingerprint
  final EventType type; // Event type

  // Business payload
  final String cardId; // Business entity identifier
  final EncryptedPayload payload; // AES-GCM encrypted content

  // Integrity protection
  final String? prevEventHash; // Previous event SHA256 hash (chain validation)
  final String? signature; // Device private key signature

  const PasswordEvent({
    required this.hlc,
    required this.eventId,
    required this.deviceId,
    required this.type,
    required this.cardId,
    required this.payload,
    this.prevEventHash,
    this.signature,
  });

  /// Create a new event
  factory PasswordEvent.create({
    required EventType type,
    required String cardId,
    required EncryptedPayload payload,
    required String deviceId,
    String? prevEventHash,
  }) {
    return PasswordEvent(
      hlc: HLC.now(deviceId),
      eventId: const Uuid().v4(),
      deviceId: deviceId,
      type: type,
      cardId: cardId,
      payload: payload,
      prevEventHash: prevEventHash,
    );
  }

  /// Create from database row
  factory PasswordEvent.fromMap(Map<String, dynamic> map) {
    return PasswordEvent(
      hlc: HLC.fromJson({
        'physicalTime': map['hlc_physical'] as int,
        'logicalCounter': map['hlc_logical'] as int,
        'deviceId': map['hlc_device'] as String,
      }),
      eventId: map['event_id'] as String,
      deviceId: map['device_id'] as String,
      type: EventType.values.byName(map['type'] as String),
      cardId: map['card_id'] as String,
      payload: EncryptedPayload.fromJson({
        'ciphertext': map['payload_ciphertext'] as String,
        'iv': map['payload_iv'] as String,
        'authTag': map['payload_auth_tag'] as String,
      }),
      prevEventHash: map['prev_event_hash'] as String?,
      signature: map['signature'] as String?,
    );
  }

  /// Convert to database row
  Map<String, dynamic> toMap() => {
        'event_id': eventId,
        'hlc_physical': hlc.physicalTime,
        'hlc_logical': hlc.logicalCounter,
        'hlc_device': hlc.deviceId,
        'device_id': deviceId,
        'type': type.name,
        'card_id': cardId,
        'payload_ciphertext': payload.ciphertext,
        'payload_iv': payload.iv,
        'payload_auth_tag': payload.authTag,
        'prev_event_hash': prevEventHash,
        'signature': signature,
        'created_at': DateTime.now().toIso8601String(),
      };

  /// Convert to JSON for sync
  Map<String, dynamic> toJson() => {
        'hlc': hlc.toJson(),
        'eventId': eventId,
        'deviceId': deviceId,
        'type': type.name,
        'cardId': cardId,
        'payload': payload.toJson(),
        'prevEventHash': prevEventHash,
        'signature': signature,
      };

  factory PasswordEvent.fromJson(Map<String, dynamic> json) {
    return PasswordEvent(
      hlc: HLC.fromJson(json['hlc'] as Map<String, dynamic>),
      eventId: json['eventId'] as String,
      deviceId: json['deviceId'] as String,
      type: EventType.values.byName(json['type'] as String),
      cardId: json['cardId'] as String,
      payload:
          EncryptedPayload.fromJson(json['payload'] as Map<String, dynamic>),
      prevEventHash: json['prevEventHash'] as String?,
      signature: json['signature'] as String?,
    );
  }

  /// Calculate hash of this event for chain validation
  String calculateHash() {
    final data = utf8.encode(jsonEncode({
      'hlc': hlc.toJson(),
      'eventId': eventId,
      'deviceId': deviceId,
      'type': type.name,
      'cardId': cardId,
      'payload': payload.toJson(),
      'prevEventHash': prevEventHash,
    }));
    return sha256.convert(data).toString();
  }

  /// Create a copy with signature
  PasswordEvent withSignature(String signature) => PasswordEvent(
        hlc: hlc,
        eventId: eventId,
        deviceId: deviceId,
        type: type,
        cardId: cardId,
        payload: payload,
        prevEventHash: prevEventHash,
        signature: signature,
      );

  @override
  List<Object?> get props =>
      [hlc, eventId, deviceId, type, cardId, payload, prevEventHash, signature];
}

/// Event comparison utilities
class EventUtils {
  /// Compare two events by HLC (for sorting)
  static int compareByHLC(PasswordEvent a, PasswordEvent b) =>
      a.hlc.compareTo(b.hlc);

  /// Get the latest event (LWW semantics)
  static PasswordEvent latest(PasswordEvent a, PasswordEvent b) =>
      a.hlc.compareTo(b.hlc) >= 0 ? a : b;

  /// Filter events by card ID
  static List<PasswordEvent> filterByCardId(
          List<PasswordEvent> events, String cardId) =>
      events.where((e) => e.cardId == cardId).toList();

  /// Get events sorted by HLC
  static List<PasswordEvent> sortByHLC(List<PasswordEvent> events) {
    final sorted = List<PasswordEvent>.from(events);
    sorted.sort(compareByHLC);
    return sorted;
  }

  /// Validate event chain integrity
  static bool validateChain(List<PasswordEvent> events) {
    if (events.isEmpty) return true;

    final sorted = sortByHLC(events);
    for (int i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final previous = sorted[i - 1];

      if (current.prevEventHash != null &&
          current.prevEventHash != previous.calculateHash()) {
        return false;
      }
    }
    return true;
  }
}
