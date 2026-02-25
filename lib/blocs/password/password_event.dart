part of 'password_bloc.dart';

abstract class PasswordEvent extends Equatable {
  const PasswordEvent();

  @override
  List<Object?> get props => [];
}

class PasswordLoadRequested extends PasswordEvent {}

class PasswordSearchRequested extends PasswordEvent {
  final String query;
  const PasswordSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

class PasswordAddRequested extends PasswordEvent {
  final PasswordPayload payload;
  const PasswordAddRequested(this.payload);

  @override
  List<Object?> get props => [payload];
}

class PasswordUpdateRequested extends PasswordEvent {
  final String cardId;
  final PasswordPayload payload;
  const PasswordUpdateRequested(this.cardId, this.payload);

  @override
  List<Object?> get props => [cardId, payload];
}

class PasswordDeleteRequested extends PasswordEvent {
  final String cardId;
  const PasswordDeleteRequested(this.cardId);

  @override
  List<Object?> get props => [cardId];
}
