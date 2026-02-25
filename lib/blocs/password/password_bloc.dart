import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/vault_service.dart';
import '../../core/models/models.dart';

part 'password_event.dart';
part 'password_state.dart';

class PasswordBloc extends Bloc<PasswordEvent, PasswordState> {
  final VaultService _vaultService;

  PasswordBloc({required VaultService vaultService})
      : _vaultService = vaultService,
        super(PasswordInitial()) {
    on<PasswordLoadRequested>(_onPasswordLoadRequested);
    on<PasswordSearchRequested>(_onPasswordSearchRequested);
    on<PasswordAddRequested>(_onPasswordAddRequested);
    on<PasswordUpdateRequested>(_onPasswordUpdateRequested);
    on<PasswordDeleteRequested>(_onPasswordDeleteRequested);
  }

  Future<void> _onPasswordLoadRequested(
    PasswordLoadRequested event,
    Emitter<PasswordState> emit,
  ) async {
    emit(PasswordLoading());
    try {
      final cards = await _vaultService.getAllCards();
      emit(PasswordLoaded(cards: cards));
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }

  Future<void> _onPasswordSearchRequested(
    PasswordSearchRequested event,
    Emitter<PasswordState> emit,
  ) async {
    // If we are already loaded, we can filter or re-fetch
    // Usually it's better to re-fetch if searching via blind indexes
    emit(PasswordLoading());
    try {
      final cards = await _vaultService.search(event.query);
      emit(PasswordLoaded(cards: cards, query: event.query));
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }

  Future<void> _onPasswordAddRequested(
    PasswordAddRequested event,
    Emitter<PasswordState> emit,
  ) async {
    emit(PasswordOperationInProgress());
    try {
      await _vaultService.createCard(event.payload);
      add(PasswordLoadRequested()); // Reload list
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }

  Future<void> _onPasswordUpdateRequested(
    PasswordUpdateRequested event,
    Emitter<PasswordState> emit,
  ) async {
    emit(PasswordOperationInProgress());
    try {
      await _vaultService.updateCard(event.cardId, event.payload);
      add(PasswordLoadRequested()); // Reload list
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }

  Future<void> _onPasswordDeleteRequested(
    PasswordDeleteRequested event,
    Emitter<PasswordState> emit,
  ) async {
    emit(PasswordOperationInProgress());
    try {
      await _vaultService.deleteCard(event.cardId);
      add(PasswordLoadRequested()); // Reload list
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }
}
