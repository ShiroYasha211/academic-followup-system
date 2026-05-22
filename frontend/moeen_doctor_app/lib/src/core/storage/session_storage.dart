import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/staff_auth_session.dart';

class SessionStorage {
  const SessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'staff_token';
  static const _workspaceKey = 'staff_workspace';
  static const _nameKey = 'staff_name';
  static const _emailKey = 'staff_email';
  static const _roleKey = 'staff_role';
  static const _universityKey = 'staff_university';
  static const _collegeKey = 'staff_college';
  static const _majorKey = 'staff_major';
  static const _workspacesKey = 'staff_available_workspaces';

  Future<void> save(StaffAuthSession session) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: session.token),
      _storage.write(key: _workspaceKey, value: session.workspace.name),
      _storage.write(key: _nameKey, value: session.name),
      _storage.write(key: _emailKey, value: session.email),
      _storage.write(key: _roleKey, value: session.role),
      _storage.write(key: _universityKey, value: session.university),
      _storage.write(key: _collegeKey, value: session.college),
      _storage.write(key: _majorKey, value: session.major),
      _storage.write(
        key: _workspacesKey,
        value: session.availableWorkspaces.map((item) => item.name).join(','),
      ),
    ]);
  }

  Future<StaffAuthSession?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final workspace = await _storage.read(key: _workspaceKey);
    final name = await _storage.read(key: _nameKey);
    final email = await _storage.read(key: _emailKey);
    final role = await _storage.read(key: _roleKey);
    final workspaces = await _storage.read(key: _workspacesKey);

    if ([
      token,
      workspace,
      name,
      email,
      role,
    ].any((value) => value == null || value.isEmpty)) {
      return null;
    }

    return StaffAuthSession(
      token: token!,
      workspace: StaffWorkspace.values.firstWhere(
        (item) => item.name == workspace,
        orElse: () => StaffWorkspace.doctor,
      ),
      availableWorkspaces: _parseWorkspaces(workspaces),
      name: name!,
      email: email!,
      role: role!,
      university: await _storage.read(key: _universityKey),
      college: await _storage.read(key: _collegeKey),
      major: await _storage.read(key: _majorKey),
    );
  }

  List<StaffWorkspace> _parseWorkspaces(String? raw) {
    final parsed =
        raw
            ?.split(',')
            .map(
              (name) => StaffWorkspace.values.firstWhere(
                (item) => item.name == name,
                orElse: () => StaffWorkspace.doctor,
              ),
            )
            .toSet()
            .toList() ??
        const <StaffWorkspace>[];
    return parsed.isEmpty ? const [StaffWorkspace.doctor] : parsed;
  }

  Future<void> clear() => _storage.deleteAll();
}
