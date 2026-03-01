part of 'vault_bloc.dart';

abstract class VaultEvent extends Equatable {
  const VaultEvent();

  @override
  List<Object?> get props => [];
}

class VaultCheckRequested extends VaultEvent {}

class VaultInitializeRequested extends VaultEvent {
  final String masterPassword;
  final Uint8List? entropy;
  const VaultInitializeRequested(this.masterPassword, {this.entropy});

  @override
  List<Object?> get props => [masterPassword, entropy];
}

class VaultUnlockRequested extends VaultEvent {
  final String masterPassword;
  const VaultUnlockRequested(this.masterPassword);

  @override
  List<Object?> get props => [masterPassword];
}

class VaultLockRequested extends VaultEvent {}

class VaultChangePasswordRequested extends VaultEvent {
  final String oldPassword;
  final String newPassword;

  const VaultChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}
