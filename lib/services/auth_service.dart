import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'local_storage_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Mock authentication backend. Swap this class out for a
/// FirebaseAuth/Supabase implementation without touching any UI code —
/// every screen only depends on this interface via [AuthBloc].
class AuthService {
  AuthService(this._storage);
  final LocalStorageService _storage;
  static final _uuid = Uuid();

  String _hash(String password) => sha256.convert(utf8.encode(password)).toString();

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = await _storage.getAllUsers();
    final exists = users.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) {
      throw AuthException('An account with this email already exists.');
    }
    if (name.trim().isEmpty) throw AuthException('Name is required.');
    if (!email.contains('@')) throw AuthException('Enter a valid email address.');
    if (password.length < 6) throw AuthException('Password must be at least 6 characters.');

    final user = UserModel(
      id: _uuid.v4(),
      name: name.trim(),
      email: email.trim(),
      passwordHash: _hash(password),
      isOnline: true,
      lastSeen: DateTime.now(),
      avatarColorHex: _colorForId(_uuid.v4()),
    );
    await _storage.upsertUser(user);
    await _storage.saveSessionUserId(user.id);
    return user;
  }

  Future<UserModel> login({required String emailOrPhone, required String password}) async {
    final users = await _storage.getAllUsers();
    final match = users.where(
      (u) => u.email.toLowerCase() == emailOrPhone.trim().toLowerCase() || u.phone == emailOrPhone.trim(),
    );
    if (match.isEmpty) {
      throw AuthException('No account found with that email/phone.');
    }
    final user = match.first;
    if (user.passwordHash != _hash(password)) {
      throw AuthException('Incorrect password.');
    }
    final updated = user.copyWith(isOnline: true, lastSeen: DateTime.now());
    await _storage.upsertUser(updated);
    await _storage.saveSessionUserId(updated.id);
    return updated;
  }

  Future<void> logout(String userId) async {
    final users = await _storage.getAllUsers();
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      users[idx] = users[idx].copyWith(isOnline: false, lastSeen: DateTime.now());
      await _storage.saveAllUsers(users);
    }
    await _storage.clearSession();
  }

  /// Restores a session on app start (used by the Splash screen).
  Future<UserModel?> restoreSession() async {
    final userId = await _storage.getSessionUserId();
    if (userId == null) return null;
    final users = await _storage.getAllUsers();
    try {
      final user = users.firstWhere((u) => u.id == userId);
      final updated = user.copyWith(isOnline: true, lastSeen: DateTime.now());
      await _storage.upsertUser(updated);
      return updated;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> updateProfile(UserModel updated) async {
    await _storage.upsertUser(updated);
    return updated;
  }

  String _colorForId(String id) {
    const palette = ['#4F63F6', '#2ECC71', '#F5A623', '#E74C3C', '#9B59B6', '#1ABC9C'];
    return palette[id.hashCode.abs() % palette.length];
  }
}
