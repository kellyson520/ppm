import 'package:equatable/equatable.dart';
import '../../core/sync/sync.dart';
export '../../core/sync/sync.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class SyncNodesRequested extends SyncEvent {}

class SyncStarted extends SyncEvent {}

class SyncNodeAdded extends SyncEvent {
  final WebDavNode node;
  const SyncNodeAdded(this.node);
  @override
  List<Object?> get props => [node];
}

class SyncNodeRemoved extends SyncEvent {
  final String nodeName;
  const SyncNodeRemoved(this.nodeName);
  @override
  List<Object?> get props => [nodeName];
}

class SyncProgressUpdated extends SyncEvent {
  final SyncProgress progress;
  const SyncProgressUpdated(this.progress);
  @override
  List<Object?> get props => [progress];
}

class SyncState extends Equatable {
  final List<WebDavNode> nodes;
  final SyncProgress? currentProgress;
  final bool isLoading;
  final String? error;

  const SyncState({
    this.nodes = const [],
    this.currentProgress,
    this.isLoading = false,
    this.error,
  });

  SyncState copyWith({
    List<WebDavNode>? nodes,
    SyncProgress? currentProgress,
    bool? isLoading,
    String? error,
  }) {
    return SyncState(
      nodes: nodes ?? this.nodes,
      currentProgress: currentProgress ?? this.currentProgress,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [nodes, currentProgress, isLoading, error];
}
