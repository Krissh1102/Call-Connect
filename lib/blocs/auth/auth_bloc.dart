import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Drives the splash -> login/register -> home flow and holds the
/// currently-authenticated user for the rest of the app.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authService) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<ProfileUpdateRequested>(_onProfileUpdate);
  }

  final AuthService _authService;

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final user = await _authService.restoreSession();
    emit(user != null ? Authenticated(user) : const Unauthenticated());
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.login(emailOrPhone: event.emailOrPhone, password: event.password);
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(const AuthFailure('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.register(name: event.name, email: event.email, password: event.password);
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(const AuthFailure('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    final current = state;
    if (current is Authenticated) {
      await _authService.logout(current.user.id);
    }
    emit(const Unauthenticated());
  }

  Future<void> _onProfileUpdate(ProfileUpdateRequested event, Emitter<AuthState> emit) async {
    final current = state;
    if (current is! Authenticated) return;
    final updated = current.user.copyWith(
      name: event.name,
      avatarColorHex: event.avatarColorHex,
    );
    await _authService.updateProfile(updated);
    emit(Authenticated(updated));
  }
}
