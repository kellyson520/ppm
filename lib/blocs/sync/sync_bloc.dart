import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/sync_service.dart';
import 'sync_event_state.dart';

export 'sync_event_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _syncService;
  StreamSubscription<SyncProgress>? _progressSubscription;

  SyncBloc({required SyncService syncService})
      : _syncService = syncService,
        super(const SyncState()) {
    on<SyncNodesRequested>(_onSyncNodesRequested);
    on<SyncStarted>(_onSyncStarted);
    on<SyncNodeAdded>(_onSyncNodeAdded);
    on<SyncNodeRemoved>(_onSyncNodeRemoved);
    on<SyncProgressUpdated>(_onSyncProgressUpdated);

    // Listen for progress
    _progressSubscription = _syncService.syncProgress.listen(
      (progress) => add(SyncProgressUpdated(progress)),
    );
  }

  Future<void> _onSyncNodesRequested(
    SyncNodesRequested event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final nodes = await _syncService.getNodes();
      emit(state.copyWith(nodes: nodes, isLoading: false));
    } on Exception catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onSyncStarted(
    SyncStarted event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final result = await _syncService.syncAll();
      if (result.success) {
        emit(state.copyWith(isLoading: false));
      } else {
        emit(state.copyWith(error: result.error, isLoading: false));
      }
    } on Exception catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onSyncNodeAdded(
    SyncNodeAdded event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _syncService.addNode(event.node);
      final nodes = await _syncService.getNodes();
      emit(state.copyWith(nodes: nodes, isLoading: false));
    } on Exception catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onSyncNodeRemoved(
    SyncNodeRemoved event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _syncService.removeNode(event.nodeName);
      final nodes = await _syncService.getNodes();
      emit(state.copyWith(nodes: nodes, isLoading: false));
    } on Exception catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  void _onSyncProgressUpdated(
    SyncProgressUpdated event,
    Emitter<SyncState> emit,
  ) {
    emit(state.copyWith(currentProgress: event.progress));
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    _syncService.dispose();
    return super.close();
  }
}
