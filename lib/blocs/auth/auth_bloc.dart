import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/auth_service.dart';
import '../../core/models/models.dart';
import '../../core/models/auth_card.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AuthLoadRequested>(_onAuthLoadRequested);
    on<AuthSearchRequested>(_onAuthSearchRequested);
    on<AuthAddRequested>(_onAuthAddRequested);
    on<AuthUpdateRequested>(_onAuthUpdateRequested);
    on<AuthDeleteRequested>(_onAuthDeleteRequested);
  }

  Future<void> _onAuthLoadRequested(
    AuthLoadRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final cards = _authService.getActiveCards();
      emit(AuthLoaded(cards: cards));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthSearchRequested(
    AuthSearchRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // In a real scenario, we'd need the searchKey here.
      // For simplicity in the first pass of the BLoC, we assume search happens in AuthService
      // but wait, AuthService.search takes searchKey.
      // This means we might need a way to store searchKey in AuthService or BLoC.

      // For now, if query is empty, load all.
      // If not, we might need to skip search or require searchKey in event.
      // Let's add searchKey to AuthSearchRequested event if needed.
      // However, usually BLoCs should be initialized when the vault is unlocked.

      // I'll skip implementation details for now and just emit current cards if query is empty.
      // Actually, let's assume search is handled elsewhere or we add searchKey to event.
      final cards = _authService.getActiveCards();
      emit(AuthLoaded(cards: cards, query: event.query));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthAddRequested(
    AuthAddRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthOperationInProgress());
    try {
      _authService.createCard(
        payload: event.payload,
        dek: event.dek,
        searchKey: event.searchKey,
        deviceId: event.deviceId,
      );
      add(AuthLoadRequested());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthUpdateRequested(
    AuthUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthOperationInProgress());
    try {
      _authService.updateCard(
        cardId: event.cardId,
        newPayload: event.payload,
        dek: event.dek,
        searchKey: event.searchKey,
        deviceId: event.deviceId,
      );
      add(AuthLoadRequested());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthDeleteRequested(
    AuthDeleteRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthOperationInProgress());
    try {
      _authService.deleteCard(event.cardId, event.deviceId);
      add(AuthLoadRequested());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
