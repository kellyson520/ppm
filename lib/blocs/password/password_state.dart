part of 'password_bloc.dart';

abstract class PasswordState extends Equatable {
  const PasswordState();

  @override
  List<Object?> get props => [];
}

class PasswordInitial extends PasswordState {}

class PasswordLoading extends PasswordState {}

class PasswordLoaded extends PasswordState {
  final List<PasswordCard> cards;
  final String query;

  const PasswordLoaded({
    required this.cards,
    this.query = '',
  });

  @override
  List<Object?> get props => [cards, query];
}

class PasswordOperationInProgress extends PasswordState {}

class PasswordError extends PasswordState {
  final String message;
  const PasswordError(this.message);

  @override
  List<Object?> get props => [message];
}
