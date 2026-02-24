import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

/// Hybrid Logical Clock (HLC) implementation
/// Based on the paper: "Logical Physical Clocks and Consistent Snapshots in Distributed Systems"
/// 
/// HLC combines physical timestamps with logical counters to provide:
/// - Causal ordering of events
/// - Conflict resolution in distributed systems
/// - Deterministic tie-breaking using device ID
class HLC extends Equatable implements Comparable<HLC> {
  final int physicalTime;  // Physical timestamp in milliseconds (NTP-synced)
  final int logicalCounter; // Logical counter for concurrent events
  final String deviceId;    // Device unique identifier (dictionary order tie-breaker)

  const HLC({
    required this.physicalTime,
    required this.logicalCounter,
    required this.deviceId,
  });

  /// Create HLC from current time
  factory HLC.now(String deviceId) {
    return HLC(
      physicalTime: DateTime.now().millisecondsSinceEpoch,
      logicalCounter: 0,
      deviceId: deviceId,
    );
  }

  /// Create HLC from JSON
  factory HLC.fromJson(Map<String, dynamic> json) {
    return HLC(
      physicalTime: json['physicalTime'] as int,
      logicalCounter: json['logicalCounter'] as int,
      deviceId: json['deviceId'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'physicalTime': physicalTime,
    'logicalCounter': logicalCounter,
    'deviceId': deviceId,
  };

  /// Compare two HLCs for partial ordering
  /// Returns: negative if this < other, positive if this > other, 0 if equal
  @override
  int compareTo(HLC other) {
    if (physicalTime != other.physicalTime) {
      return physicalTime.compareTo(other.physicalTime);
    }
    if (logicalCounter != other.logicalCounter) {
      return logicalCounter.compareTo(other.logicalCounter);
    }
    return deviceId.compareTo(other.deviceId); // Deterministic tie-breaker
  }

  /// Check if this HLC happened before another (causal ordering)
  bool happenedBefore(HLC other) => compareTo(other) < 0;

  /// Check if this HLC is concurrent with another
  bool isConcurrent(HLC other) => 
    physicalTime == other.physicalTime && 
    logicalCounter == other.logicalCounter &&
    deviceId != other.deviceId;

  /// Merge with remote HLC (HLC algorithm)
  HLC merge(HLC remote) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final newPhysical = [physicalTime, remote.physicalTime, now].reduce((a, b) => a > b ? a : b);
    
    int newLogical;
    if (newPhysical == physicalTime && newPhysical == remote.physicalTime) {
      // Both at same physical time, increment max logical counter
      newLogical = logicalCounter > remote.logicalCounter ? logicalCounter : remote.logicalCounter;
      newLogical++;
    } else if (newPhysical == physicalTime) {
      // Local event is latest, increment local counter
      newLogical = logicalCounter + 1;
    } else if (newPhysical == remote.physicalTime) {
      // Remote event is latest, adopt remote counter + 1
      newLogical = remote.logicalCounter + 1;
    } else {
      // New physical time, reset logical counter
      newLogical = 0;
    }

    return HLC(
      physicalTime: newPhysical,
      logicalCounter: newLogical,
      deviceId: deviceId,
    );
  }

  /// Increment logical counter for local events
  HLC increment() => HLC(
    physicalTime: physicalTime,
    logicalCounter: logicalCounter + 1,
    deviceId: deviceId,
  );

  /// Create a copy with updated values
  HLC copyWith({
    int? physicalTime,
    int? logicalCounter,
    String? deviceId,
  }) => HLC(
    physicalTime: physicalTime ?? this.physicalTime,
    logicalCounter: logicalCounter ?? this.logicalCounter,
    deviceId: deviceId ?? this.deviceId,
  );

  /// String representation for debugging
  @override
  String toString() => 'HLC($physicalTime, $logicalCounter, $deviceId)';

  @override
  List<Object?> get props => [physicalTime, logicalCounter, deviceId];
}

/// HLC utilities
class HLCUtils {
  /// Generate a unique device ID based on device fingerprint
  static String generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final input = '$timestamp$random${DateTime.now().hashCode}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Compare two HLCs and return the maximum (latest)
  static HLC max(HLC a, HLC b) => a.compareTo(b) >= 0 ? a : b;

  /// Check if a list of HLCs are all causally ordered
  static bool isCausallyOrdered(List<HLC> hlcs) {
    for (int i = 1; i < hlcs.length; i++) {
      if (hlcs[i].happenedBefore(hlcs[i - 1])) {
        return false;
      }
    }
    return true;
  }
}
