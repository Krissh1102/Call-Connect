import '../models/user_model.dart';
import 'local_storage_service.dart';

/// Provides the contacts/user directory. Backed by the same local store as
/// [AuthService] — every registered account automatically becomes a
/// callable contact for every other account, which is enough to demo
/// 1-to-1 calling between two devices/emulators without a real backend.
class UserService {
  UserService(this._storage);
  final LocalStorageService _storage;

  Future<List<UserModel>> getContacts({required String excludingUserId}) async {
    final users = await _storage.getAllUsers();
    final contacts = users.where((u) => u.id != excludingUserId).toList()
      ..sort((a, b) {
        if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    return contacts;
  }

  Future<List<UserModel>> search(String query, {required String excludingUserId}) async {
    final contacts = await getContacts(excludingUserId: excludingUserId);
    if (query.trim().isEmpty) return contacts;
    final q = query.trim().toLowerCase();
    return contacts.where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
  }

  Future<UserModel?> getById(String id) async {
    final users = await _storage.getAllUsers();
    try {
      return users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}
