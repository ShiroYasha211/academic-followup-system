import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/auth_session.dart';

class SessionStorage {
  const SessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _workspaceKey = 'workspace';
  static const _roleKey = 'role';
  static const _nameKey = 'name';
  static const _emailKey = 'email';
  static const _practicalKey = 'is_practical_delegate';

  Future<void> save(AuthSession session) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: session.token),
      _storage.write(key: _workspaceKey, value: session.workspace.name),
      _storage.write(key: _roleKey, value: session.role),
      _storage.write(key: _nameKey, value: session.name),
      _storage.write(key: _emailKey, value: session.email),
      _storage.write(
        key: _practicalKey,
        value: session.isPracticalDelegate ? '1' : '0',
      ),
    ]);
  }

  Future<AuthSession?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final workspace = await _storage.read(key: _workspaceKey);
    final role = await _storage.read(key: _roleKey);
    final name = await _storage.read(key: _nameKey);
    final email = await _storage.read(key: _emailKey);
    final isPractical = await _storage.read(key: _practicalKey);

    if ([
      token,
      workspace,
      role,
      name,
    ].any((value) => value == null || value.isEmpty)) {
      return null;
    }

    return AuthSession(
      token: token!,
      workspace: AuthWorkspace.values.firstWhere(
        (item) => item.name == workspace,
        orElse: () => AuthWorkspace.student,
      ),
      role: role!,
      name: name!,
      email: email,
      isPracticalDelegate: isPractical == '1',
    );
  }

  Future<void> clear() => _storage.deleteAll();
}
