import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_variant.dart';
import '../../auth/data/auth_session.dart';
import '../data/flashcard_local_store.dart';
import '../data/student_repositories.dart';

enum ReviewDisplayMode { inApp, floating, notificationOnly }

class FloatingReviewStatus {
  const FloatingReviewStatus({
    this.supported = false,
    this.permission = false,
    this.notificationsAllowed,
    this.running = false,
    this.autoStart = false,
    this.mode = ReviewDisplayMode.inApp,
    this.pending = 0,
    this.message = '',
    this.seenIds = const [],
    this.seenKeys = const [],
  });

  final bool supported;
  final bool permission;
  final bool? notificationsAllowed;
  final bool running;
  final bool autoStart;
  final ReviewDisplayMode mode;
  final int pending;
  final String message;
  final List<int> seenIds;
  final List<String> seenKeys;

  factory FloatingReviewStatus.fromMap(Map<dynamic, dynamic> data) {
    final mode = ReviewDisplayMode.values.firstWhere(
      (value) => value.name == data['mode'],
      orElse: () => ReviewDisplayMode.inApp,
    );
    return FloatingReviewStatus(
      supported: data['supported'] == true,
      permission: data['permission'] == true,
      notificationsAllowed: data['notifications_allowed'] as bool?,
      running: data['running'] == true,
      autoStart: data['auto_start'] == true,
      mode: mode,
      pending: (data['pending'] as num?)?.toInt() ?? 0,
      message: data['message']?.toString() ?? '',
      seenIds: (data['seen_ids'] as List? ?? const [])
          .whereType<num>()
          .map((id) => id.toInt())
          .toList(),
      seenKeys: (data['seen_keys'] as List? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class FloatingReview {
  static const _channel = MethodChannel('moeen/review_overlay');
  static bool get supportedPlatform =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      StudentFeatureFlags.showOneLineShot;

  static Future<FloatingReviewStatus> status() async {
    if (!supportedPlatform) return const FloatingReviewStatus();
    try {
      final data = await _channel.invokeMapMethod<dynamic, dynamic>('status');
      return FloatingReviewStatus.fromMap(data ?? const {});
    } on MissingPluginException {
      return const FloatingReviewStatus();
    }
  }

  static Future<void> configure(AuthSession session) async {
    if (!supportedPlatform) return;
    if (session.isDelegate) return stop();
    await _channel.invokeMethod<void>('configure', {
      'account': FlashcardLocalStore.keyFor(session),
      'token': session.token,
      'base_url': AppConfig.apiBaseUrl,
    });
  }

  static Future<void> setMode(ReviewDisplayMode mode) async {
    if (supportedPlatform)
      await _channel.invokeMethod<void>('setMode', mode.name);
  }

  static Future<void> requestPermission() async {
    if (supportedPlatform) await _channel.invokeMethod<void>('permission');
  }

  static Future<void> openNotificationSettings() async {
    if (supportedPlatform)
      await _channel.invokeMethod<void>('notificationSettings');
  }

  static Future<void> start() async {
    if (supportedPlatform) await _channel.invokeMethod<void>('start');
  }

  static Future<void> setAutoStart(bool enabled) async {
    if (supportedPlatform)
      await _channel.invokeMethod<void>('setAutoStart', enabled);
  }

  static Future<void> stop() async {
    if (!supportedPlatform) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (error) {
      debugPrint('Cannot stop floating review: ${error.code}');
    } on MissingPluginException {
      debugPrint('Floating review requires a full app restart after updating.');
    }
  }

  static Future<void> endSession() async {
    if (supportedPlatform) await _channel.invokeMethod<void>('endSession');
  }

  static Future<String?> beginInApp({bool force = false}) async {
    if (!supportedPlatform) return 'local';
    try {
      return await _channel.invokeMethod<String>('beginInApp', {
        'force': force,
      });
    } on MissingPluginException {
      return 'local';
    }
  }

  static Future<void> endInApp(String lease) async {
    if (!supportedPlatform) return;
    try {
      await _channel.invokeMethod<void>('endInApp', lease);
    } on MissingPluginException {
      debugPrint('Floating review is not installed in this build.');
    }
  }

  static Future<void> completed(int itemId, {String? reviewKey}) async {
    if (!supportedPlatform) return;
    try {
      await _channel.invokeMethod<void>('completed', {
        'item_id': itemId,
        if (reviewKey != null) 'review_key': reviewKey,
      });
    } on MissingPluginException {
      debugPrint('Floating review is not installed in this build.');
    }
  }

  static Future<void> snooze() async {
    if (supportedPlatform) await _channel.invokeMethod<void>('snooze');
  }

  static Future<void> updateQueue(
    String account,
    Map<String, dynamic> data,
  ) async {
    if (!supportedPlatform) return;
    await _channel.invokeMethod<void>('updateQueue', {
      'account': account,
      'data': data,
    });
  }

  static Future<void> synchronize(
    AuthSession session,
    StudentContentRepository repository,
  ) async {
    if (!supportedPlatform) return;
    final account = FlashcardLocalStore.keyFor(session);
    final pending = await _channel.invokeListMethod<dynamic>('answers', {
      'account': account,
    });
    for (final entry in pending ?? const []) {
      final answer = Map<String, dynamic>.from(entry as Map);
      await repository.recordFlashcardProgress(
        itemId: (answer['item_id'] as num).toInt(),
        responseLevel: answer['response_level'] as String,
        clientEventId: answer['client_event_id'] as String,
      );
      await _channel.invokeMethod<void>('acknowledge', {
        'account': account,
        'event_id': answer['client_event_id'],
      });
    }
  }

  static String eventId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
