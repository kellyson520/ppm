part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoadRequested extends AuthEvent {}

class AuthSearchRequested extends AuthEvent {
  final String query;
  const AuthSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

class AuthAddRequested extends AuthEvent {
  final AuthPayload payload;
  final Uint8List dek;
  final Uint8List searchKey;
  final String deviceId;

  const AuthAddRequested({
    required this.payload,
    required this.dek,
    required this.searchKey,
    required this.deviceId,
  });

  @override
  List<Object?> get props => [payload, dek, searchKey, deviceId];
}

class AuthUpdateRequested extends AuthEvent {
  final String cardId;
  final AuthPayload payload;
  final Uint8List dek;
  final Uint8List searchKey;
  final String deviceId;

  const AuthUpdateRequested({
    required this.cardId,
    required this.payload,
    required this.dek,
    required this.searchKey,
    required this.deviceId,
  });

  @override
  List<Object?> get props => [cardId, payload, dek, searchKey, deviceId];
}

class AuthDeleteRequested extends AuthEvent {
  final String cardId;
  final String deviceId;

  const AuthDeleteRequested(this.cardId, this.deviceId);

  @override
  List<Object?> get props => [cardId, deviceId];
}
