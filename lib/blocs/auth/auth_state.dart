part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthLoaded extends AuthState {
  final List<AuthCard> cards;
  final String query;

  const AuthLoaded({
    required this.cards,
    this.query = '',
  });

  @override
  List<Object?> get props => [cards, query];
}

class AuthOperationInProgress extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
