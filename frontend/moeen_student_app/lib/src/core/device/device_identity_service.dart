import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdentityService {
  DeviceIdentityService(this._storage);

  static const _deviceIdKey = 'moeen_student_device_id';

  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>> loginPayload() async {
    final deviceId = await _getOrCreateDeviceId();

    return {
      'device_id': deviceId,
      'platform': _platformLabel(),
      'device_name': _deviceName(),
    };
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final generated = _generateDeviceId();
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    return 'student-${hex.join()}';
  }

  String _platformLabel() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  String _deviceName() {
    if (Platform.isAndroid) return 'Android device';
    if (Platform.isIOS) return 'iOS device';
    if (Platform.isWindows) return 'Windows device';
    if (Platform.isMacOS) return 'macOS device';
    if (Platform.isLinux) return 'Linux device';
    return 'Unknown device';
  }
}
