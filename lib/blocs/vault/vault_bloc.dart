import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/vault_service.dart';

part 'vault_event.dart';
part 'vault_state.dart';

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  final VaultService _vaultService;

  VaultBloc({required VaultService vaultService})
      : _vaultService = vaultService,
        super(const VaultState()) {
    on<VaultCheckRequested>(_onVaultCheckRequested);
    on<VaultInitializeRequested>(_onVaultInitializeRequested);
    on<VaultUnlockRequested>(_onVaultUnlockRequested);
    on<VaultLockRequested>(_onVaultLockRequested);
    on<VaultChangePasswordRequested>(_onVaultChangePasswordRequested);
  }

  Future<void> _onVaultCheckRequested(
    VaultCheckRequested event,
    Emitter<VaultState> emit,
  ) async {
    emit(state.copyWith(status: VaultStatus.loading));
    try {
      final isInitialized = await _vaultService.isInitialized();
      if (!isInitialized) {
        emit(state.copyWith(status: VaultStatus.setupRequired));
      } else {
        emit(state.copyWith(status: VaultStatus.locked));
      }
    } catch (e) {
      emit(state.copyWith(
        status: VaultStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onVaultInitializeRequested(
    VaultInitializeRequested event,
    Emitter<VaultState> emit,
  ) async {
    emit(state.copyWith(status: VaultStatus.loading));
    try {
      await _vaultService.initialize(event.masterPassword);
      emit(state.copyWith(status: VaultStatus.unlocked));
    } catch (e) {
      emit(state.copyWith(
        status: VaultStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onVaultUnlockRequested(
    VaultUnlockRequested event,
    Emitter<VaultState> emit,
  ) async {
    emit(state.copyWith(status: VaultStatus.loading));
    try {
      final success = await _vaultService.unlock(event.masterPassword);
      if (success) {
        emit(state.copyWith(status: VaultStatus.unlocked));
      } else {
        emit(state.copyWith(
          status: VaultStatus.locked,
          errorMessage: 'Invalid master password',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: VaultStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onVaultLockRequested(
    VaultLockRequested event,
    Emitter<VaultState> emit,
  ) async {
    await _vaultService.lock();
    emit(state.copyWith(status: VaultStatus.locked));
  }

  Future<void> _onVaultChangePasswordRequested(
    VaultChangePasswordRequested event,
    Emitter<VaultState> emit,
  ) async {
    emit(state.copyWith(status: VaultStatus.loading));
    try {
      final success = await _vaultService.changeMasterPassword(
        event.oldPassword,
        event.newPassword,
      );
      if (success) {
        emit(state.copyWith(status: VaultStatus.unlocked));
      } else {
        emit(state.copyWith(
          status: VaultStatus.unlocked, // Remain unlocked
          errorMessage:
              'Failed to change password. Please verify current password.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: VaultStatus.unlocked,
        errorMessage: e.toString(),
      ));
    }
  }
}
