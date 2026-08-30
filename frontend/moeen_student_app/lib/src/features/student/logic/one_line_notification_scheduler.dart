import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../data/flashcard_local_store.dart';
import '../data/student_repositories.dart';

final oneLineNotificationSchedulerProvider =
    Provider<OneLineNotificationScheduler>((ref) {
      return OneLineNotificationScheduler(
        ref.watch(studentContentRepositoryProvider),
        ref.watch(flashcardLocalStoreProvider),
      );
    });

class OneLineNotificationScheduler {
  OneLineNotificationScheduler(this._repository, this._store);

  final StudentContentRepository _repository;
  final FlashcardLocalStore _store;
  bool _running = false;

  Future<int> sync({Map<String, dynamic>? data, bool force = false}) async {
    if (_running) return 0;
    _running = true;
    try {
      final currentState = await _store.load();
      final today = _dateKey(DateTime.now());
      if (!force &&
          currentState.oneLineScheduleDate == today &&
          currentState.oneLineScheduleSignature != null) {
        return currentState.oneLineScheduledItems.length;
      }

      final source = data ?? await _loadNotificationData();
      if (source == null) return 0;

      await _store.cacheOneLineNotifications(source);

      final date = source['date']?.toString() ?? today;
      final settings = _map(source['settings']);
      final enabled = _boolValue(
        settings['one_line_notifications_enabled'],
        fallback: true,
      );
      final items = _scheduledItems(source);
      final signature = _scheduleSignature(settings, items);
      final state = await _store.load();

      if (!force &&
          state.oneLineScheduleDate == date &&
          state.oneLineScheduleSignature != null) {
        return state.oneLineScheduledItems.length;
      }

      if (!enabled) {
        if (force ||
            state.oneLineScheduleDate != date ||
            state.oneLineScheduleSignature != signature ||
            state.oneLineScheduledItems.isNotEmpty) {
          await PushNotificationService.cancelOneLineShotNotifications();
          await _store.saveOneLineScheduleState(
            date: date,
            signature: signature,
            items: const [],
          );
        }
        return 0;
      }

      if (!force &&
          state.oneLineScheduleDate == date &&
          state.oneLineScheduleSignature == signature) {
        return state.oneLineScheduledItems.length;
      }

      if (items.isEmpty) {
        await PushNotificationService.cancelOneLineShotNotifications();
        await _store.saveOneLineScheduleState(
          date: date,
          signature: signature,
          items: const [],
        );
        return 0;
      }

      final scheduledCount =
          await PushNotificationService.scheduleOneLineShotNotifications(
            items: items,
          );
      await _store.saveOneLineScheduleState(
        date: date,
        signature: signature,
        items: items,
      );
      return scheduledCount;
    } finally {
      _running = false;
    }
  }

  Future<Map<String, dynamic>?> _loadNotificationData() async {
    try {
      return await _repository.flashcardOneLineNotifications();
    } on ApiException catch (error) {
      if (!error.isOffline) rethrow;
      return _store.loadOneLineNotifications();
    } catch (_) {
      return _store.loadOneLineNotifications();
    }
  }
}

List<Map<String, dynamic>> _scheduledItems(Map<String, dynamic> data) {
  final rawItems = data.containsKey('items') ? data['items'] : data['queue'];
  final now = DateTime.now();
  return _list(rawItems).map(_map).where((item) {
    final scheduledAt = DateTime.tryParse(
      item['scheduled_at']?.toString() ?? '',
    )?.toLocal();
    if (scheduledAt == null) return false;
    if (scheduledAt.isBefore(now.subtract(const Duration(minutes: 5)))) {
      return false;
    }
    final body = (item['notification_body'] ?? item['front_content'] ?? '')
        .toString()
        .trim();
    return body.isNotEmpty;
  }).toList();
}

String _scheduleSignature(
  Map<String, dynamic> settings,
  List<Map<String, dynamic>> items,
) {
  final relevantSettings = {
    'enabled': _boolValue(
      settings['one_line_notifications_enabled'],
      fallback: true,
    ),
    'limit': settings['one_line_daily_limit'] ?? settings['daily_card_limit'],
    'frequency':
        settings['one_line_frequency_minutes'] ??
        settings['smart_review_frequency_minutes'],
    'active_from':
        settings['one_line_active_from_time'] ?? settings['active_from_time'],
    'active_to':
        settings['one_line_active_to_time'] ?? settings['active_to_time'],
    'quiet_start': settings['one_line_quiet_start'] ?? settings['quiet_start'],
    'quiet_end': settings['one_line_quiet_end'] ?? settings['quiet_end'],
  };

  final stableItems = items.map((item) {
    return {
      'item_id': item['item_id'] ?? item['id'],
      'pack_id': item['pack_id'],
      'title':
          item['notification_title'] ??
          item['notification_subtitle'] ??
          item['pack_title'],
      'body': item['notification_body'] ?? item['front_content'],
    };
  }).toList();

  return jsonEncode({'settings': relevantSettings, 'items': stableItems});
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<Object?> _list(Object? value) {
  if (value is List) return value;
  return const [];
}

bool _boolValue(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().toLowerCase().trim();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
