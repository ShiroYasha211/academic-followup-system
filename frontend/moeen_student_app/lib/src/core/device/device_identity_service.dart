import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class DeviceIdentityService {
  DeviceIdentityService(this._storage);

  static const _deviceIdKey = 'moeen_student_device_id';
  static const _nativeChannel = MethodChannel('moeen/security');

  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>> loginPayload() async {
    final deviceId = await _getOrCreateDeviceId();
    final deviceName = await _getDeviceName();

    return {
      'device_id': deviceId,
      'platform': _platformLabel(),
      'device_name': deviceName,
    };
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    String? nativeId;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        nativeId = await _androidId();
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        nativeId = iosInfo.identifierForVendor; // IDFV
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        nativeId = windowsInfo.deviceId; // Windows Device ID
      }
    } catch (e) {
      // Fail silently and fallback to UUID generation
    }

    final finalId = (nativeId != null && nativeId.trim().isNotEmpty)
        ? 'student-${nativeId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '')}'
        : _generateDeviceId();

    await _storage.write(key: _deviceIdKey, value: finalId);
    return finalId;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    return 'student-${hex.join()}';
  }

  Future<String?> _androidId() async {
    final value = await _nativeChannel.invokeMethod<String>('getAndroidId');
    if (value == null || value.trim().isEmpty) return null;
    return 'android-${value.trim()}';
  }

  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      }
    } catch (e) {
      // Fallback
    }
    return _staticDeviceName();
  }

  String _platformLabel() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  String _staticDeviceName() {
    if (Platform.isAndroid) return 'Android device';
    if (Platform.isIOS) return 'iOS device';
    if (Platform.isWindows) return 'Windows device';
    if (Platform.isMacOS) return 'macOS device';
    if (Platform.isLinux) return 'Linux device';
    return 'Unknown device';
  }
}
