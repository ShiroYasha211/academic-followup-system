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
  static const _clinicalKey = 'has_clinical';
  static const _permissionsKey = 'permissions';
  static const _deviceTypeKey = 'device_type';
  static const _isPrimaryDeviceKey = 'is_primary_device';

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
      _storage.write(key: _clinicalKey, value: session.hasClinical ? '1' : '0'),
      _storage.write(
        key: _permissionsKey,
        value: session.permissions.join(','),
      ),
      _storage.write(key: _deviceTypeKey, value: session.deviceType),
      _storage.write(
        key: _isPrimaryDeviceKey,
        value: session.isPrimaryDevice == null
            ? null
            : (session.isPrimaryDevice! ? '1' : '0'),
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
    final hasClinical = await _storage.read(key: _clinicalKey);
    final permissionsStr = await _storage.read(key: _permissionsKey);
    final deviceType = await _storage.read(key: _deviceTypeKey);
    final isPrimaryDevice = await _storage.read(key: _isPrimaryDeviceKey);

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
      hasClinical: hasClinical == '1',
      permissions:
          permissionsStr?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      deviceType: deviceType,
      isPrimaryDevice: isPrimaryDevice == null ? null : isPrimaryDevice == '1',
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _workspaceKey),
      _storage.delete(key: _roleKey),
      _storage.delete(key: _nameKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _practicalKey),
      _storage.delete(key: _clinicalKey),
      _storage.delete(key: _permissionsKey),
      _storage.delete(key: _deviceTypeKey),
      _storage.delete(key: _isPrimaryDeviceKey),
    ]);
  }
}
