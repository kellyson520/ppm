part of 'vault_bloc.dart';

enum VaultStatus {
  initial,
  loading,
  setupRequired,
  locked,
  unlocked,
  error,
}

class VaultState extends Equatable {
  final VaultStatus status;
  final String? errorMessage;

  const VaultState({
    this.status = VaultStatus.initial,
    this.errorMessage,
  });

  VaultState copyWith({
    VaultStatus? status,
    String? errorMessage,
  }) {
    return VaultState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
