import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/call_model.dart';
import '../models/user_model.dart';

/// Thin persistence layer used by the mock backend. Everything lives in
/// SharedPreferences as JSON, which is enough to demonstrate a working
/// end-to-end app without standing up Firebase/Supabase (see README).
class LocalStorageService {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // ---------------- Users ----------------

  Future<List<UserModel>> getAllUsers() async {
    final prefs = await _prefs;
    final raw = prefs.getString(AppConstants.storeUsers);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAllUsers(List<UserModel> users) async {
    final prefs = await _prefs;
    await prefs.setString(
      AppConstants.storeUsers,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  Future<void> upsertUser(UserModel user) async {
    final users = await getAllUsers();
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx >= 0) {
      users[idx] = user;
    } else {
      users.add(user);
    }
    await saveAllUsers(users);
  }

  // ---------------- Session ----------------

  Future<void> saveSessionUserId(String userId) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.storeSession, userId);
  }

  Future<String?> getSessionUserId() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.storeSession);
  }

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(AppConstants.storeSession);
  }

  // ---------------- Call history (per user) ----------------

  Future<List<CallModel>> getHistory(String userId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('${AppConstants.storeCallHistory}$userId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => CallModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addHistoryEntry(String userId, CallModel call) async {
    final history = await getHistory(userId);
    history.insert(0, call);
    final prefs = await _prefs;
    await prefs.setString(
      '${AppConstants.storeCallHistory}$userId',
      jsonEncode(history.map((c) => c.toJson()).toList()),
    );
  }
}
