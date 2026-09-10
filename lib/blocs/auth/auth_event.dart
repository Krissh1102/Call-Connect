part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginRequested extends AuthEvent {
  final String emailOrPhone;
  final String password;
  const LoginRequested({required this.emailOrPhone, required this.password});
  @override
  List<Object?> get props => [emailOrPhone, password];
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const RegisterRequested({required this.name, required this.email, required this.password});
  @override
  List<Object?> get props => [name, email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ProfileUpdateRequested extends AuthEvent {
  final String name;
  final String? avatarColorHex;
  const ProfileUpdateRequested({required this.name, this.avatarColorHex});
  @override
  List<Object?> get props => [name, avatarColorHex];
}
