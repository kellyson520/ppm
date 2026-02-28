import '../models/models.dart';

/// CRDT Merger for ZTD Password Manager
///
/// Implements CRDT semantics:
/// - Add-Wins Set: For card creation (duplicates tolerated)
/// - LWW-Register: For card updates (last write wins)
/// - Tombstone: For card deletion (permanent marker)
///
/// Uses HLC for conflict resolution with deterministic tie-breaking
class CrdtMerger {
  /// Merge two password cards using LWW-Register semantics
  ///
  /// Returns the card with the higher HLC timestamp
  /// If HLCs are equal, uses device ID for deterministic tie-breaking
  static PasswordCard mergeCards(PasswordCard local, PasswordCard remote) {
    final comparison = local.updatedAt.compareTo(remote.updatedAt);

    if (comparison > 0) {
      // Local is newer
      return local;
    } else if (comparison < 0) {
      // Remote is newer
      return remote;
    } else {
      // Equal timestamps - use device ID for tie-breaking
      // This is deterministic across all devices
      return local.updatedAt.deviceId.compareTo(remote.updatedAt.deviceId) >= 0
          ? local
          : remote;
    }
  }

  /// Merge multiple cards
  /// Returns the latest version according to LWW semantics
  static PasswordCard? mergeCardList(List<PasswordCard> cards) {
    if (cards.isEmpty) return null;
    if (cards.length == 1) return cards.first;

    return cards.reduce((a, b) => mergeCards(a, b));
  }

  /// Merge two events
  /// Uses HLC comparison for ordering
  static PasswordEvent mergeEvents(PasswordEvent local, PasswordEvent remote) {
    final comparison = local.hlc.compareTo(remote.hlc);

    if (comparison >= 0) {
      return local;
    } else {
      return remote;
    }
  }

  /// Apply event to card state
  /// Returns the new card state after applying the event
  static PasswordCard? applyEvent(
    PasswordCard? currentState,
    PasswordEvent event,
  ) {
    switch (event.type) {
      case EventType.cardCreated:
        if (currentState != null) {
          // Card already exists - this is a duplicate creation
          // Keep existing state (Add-Wins Set semantics)
          return currentState;
        }
        // Create new card from event
        return PasswordCard(
          cardId: event.cardId,
          encryptedPayload: event.payload.ciphertext,
          blindIndexes: const [], // Will be populated separately
          createdAt: event.hlc,
          updatedAt: event.hlc,
          currentEventId: event.eventId,
          isDeleted: false,
        );

      case EventType.cardUpdated:
        if (currentState == null) {
          // Update for non-existent card - create it
          return PasswordCard(
            cardId: event.cardId,
            encryptedPayload: event.payload.ciphertext,
            blindIndexes: const [],
            createdAt: event.hlc,
            updatedAt: event.hlc,
            currentEventId: event.eventId,
            isDeleted: false,
          );
        }
        // Apply update if event is newer
        if (event.hlc.compareTo(currentState.updatedAt) > 0) {
          return currentState.copyWith(
            encryptedPayload: event.payload.ciphertext,
            updatedAt: event.hlc,
            currentEventId: event.eventId,
          );
        }
        return currentState;

      case EventType.cardDeleted:
        if (currentState == null) {
          // Delete for non-existent card - create tombstone
          return PasswordCard(
            cardId: event.cardId,
            encryptedPayload: '',
            blindIndexes: const [],
            createdAt: event.hlc,
            updatedAt: event.hlc,
            currentEventId: event.eventId,
            isDeleted: true,
          );
        }
        // Apply tombstone if event is newer
        if (event.hlc.compareTo(currentState.updatedAt) >= 0) {
          return currentState.markDeleted(event.hlc.deviceId, event.eventId);
        }
        return currentState;

      case EventType.snapshotCreated:
        // Snapshots don't affect card state directly
        return currentState;
    }
  }

  /// Merge two sets of events
  /// Returns a sorted list of all unique events
  static List<PasswordEvent> mergeEventSets(
    List<PasswordEvent> local,
    List<PasswordEvent> remote,
  ) {
    // Create a map for deduplication (keyed by event ID)
    final eventMap = <String, PasswordEvent>{};

    // Add all local events
    for (final event in local) {
      eventMap[event.eventId] = event;
    }

    // Merge remote events
    for (final event in remote) {
      if (eventMap.containsKey(event.eventId)) {
        // Same event ID - merge using HLC
        eventMap[event.eventId] = mergeEvents(eventMap[event.eventId]!, event);
      } else {
        eventMap[event.eventId] = event;
      }
    }

    // Convert to list and sort by HLC
    final merged = eventMap.values.toList();
    merged.sort((a, b) => a.hlc.compareTo(b.hlc));

    return merged;
  }

  /// Build card state from event history
  /// Applies all events in causal order to reconstruct state
  static Map<String, PasswordCard> buildStateFromEvents(
    List<PasswordEvent> events,
  ) {
    // Sort events by HLC
    final sortedEvents = List<PasswordEvent>.from(events)
      ..sort((a, b) => a.hlc.compareTo(b.hlc));

    final state = <String, PasswordCard>{};

    for (final event in sortedEvents) {
      final currentState = state[event.cardId];
      final newState = applyEvent(currentState, event);
      if (newState != null) {
        state[event.cardId] = newState;
      }
    }

    return state;
  }

  /// Detect conflicts between two event sets
  /// Returns pairs of conflicting events (same card, concurrent updates)
  static List<Conflict> detectConflicts(
    List<PasswordEvent> local,
    List<PasswordEvent> remote,
  ) {
    final conflicts = <Conflict>[];

    // Group events by card ID
    final localByCard = _groupByCardId(local);
    final remoteByCard = _groupByCardId(remote);

    // Find cards with events in both sets
    final commonCards = localByCard.keys.where(
      (id) => remoteByCard.containsKey(id),
    );

    for (final cardId in commonCards) {
      final localEvents = localByCard[cardId]!;
      final remoteEvents = remoteByCard[cardId]!;

      // Find latest events from each side
      final latestLocal = _getLatestEvent(localEvents);
      final latestRemote = _getLatestEvent(remoteEvents);

      // Check if they are concurrent (neither happened before the other)
      if (latestLocal != null &&
          latestRemote != null &&
          latestLocal.hlc.isConcurrent(latestRemote.hlc)) {
        conflicts.add(Conflict(
          cardId: cardId,
          localEvent: latestLocal,
          remoteEvent: latestRemote,
        ));
      }
    }

    return conflicts;
  }

  /// Resolve conflicts using LWW semantics
  /// Returns the winning event for each conflict
  static Map<String, PasswordEvent> resolveConflicts(
    List<Conflict> conflicts,
  ) {
    final resolutions = <String, PasswordEvent>{};

    for (final conflict in conflicts) {
      resolutions[conflict.cardId] = mergeEvents(
        conflict.localEvent,
        conflict.remoteEvent,
      );
    }

    return resolutions;
  }

  /// Group events by card ID
  static Map<String, List<PasswordEvent>> _groupByCardId(
    List<PasswordEvent> events,
  ) {
    final result = <String, List<PasswordEvent>>{};
    for (final event in events) {
      result.putIfAbsent(event.cardId, () => []).add(event);
    }
    return result;
  }

  /// Get the latest event from a list
  static PasswordEvent? _getLatestEvent(List<PasswordEvent> events) {
    if (events.isEmpty) return null;
    return events.reduce((a, b) => a.hlc.compareTo(b.hlc) >= 0 ? a : b);
  }

  /// Compact event history
  /// Removes intermediate states, keeping only the final state for each card
  static List<PasswordEvent> compactEvents(
    List<PasswordEvent> events,
    Map<String, PasswordCard> currentState,
  ) {
    final compacted = <PasswordEvent>[];
    final latestEventByCard = <String, PasswordEvent>{};

    // Find latest event for each card
    for (final event in events) {
      final existing = latestEventByCard[event.cardId];
      if (existing == null || event.hlc.compareTo(existing.hlc) > 0) {
        latestEventByCard[event.cardId] = event;
      }
    }

    // Keep only events that represent the current state
    for (final entry in latestEventByCard.entries) {
      final cardId = entry.key;
      final event = entry.value;
      final card = currentState[cardId];

      // Keep if event matches current state
      if (card != null &&
          card.currentEventId == event.eventId &&
          !card.isDeleted) {
        compacted.add(event);
      }
    }

    // Sort by HLC
    compacted.sort((a, b) => a.hlc.compareTo(b.hlc));

    return compacted;
  }
}

/// Conflict representation
class Conflict {
  final String cardId;
  final PasswordEvent localEvent;
  final PasswordEvent remoteEvent;

  const Conflict({
    required this.cardId,
    required this.localEvent,
    required this.remoteEvent,
  });

  @override
  String toString() =>
      'Conflict(cardId: $cardId, local: ${localEvent.hlc}, remote: ${remoteEvent.hlc})';
}

/// CRDT State container
class CrdtState {
  final Map<String, PasswordCard> cards;
  final List<PasswordEvent> events;
  final HLC latestHlc;

  const CrdtState({
    required this.cards,
    required this.events,
    required this.latestHlc,
  });

  factory CrdtState.empty(String deviceId) {
    return CrdtState(
      cards: {},
      events: [],
      latestHlc: HLC.now(deviceId),
    );
  }

  /// Get non-deleted cards
  List<PasswordCard> get activeCards =>
      cards.values.where((c) => !c.isDeleted).toList();

  /// Get deleted cards
  List<PasswordCard> get deletedCards =>
      cards.values.where((c) => c.isDeleted).toList();

  /// Get card by ID
  PasswordCard? getCard(String cardId) => cards[cardId];

  /// Check if card exists and is not deleted
  bool hasCard(String cardId) {
    final card = cards[cardId];
    return card != null && !card.isDeleted;
  }
}
