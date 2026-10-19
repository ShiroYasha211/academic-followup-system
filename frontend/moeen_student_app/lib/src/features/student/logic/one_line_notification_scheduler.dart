import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../data/flashcard_local_store.dart';
import '../data/student_repositories.dart';

final oneLineNotificationSchedulerProvider =
    Provider<OneLineNotificationScheduler>((ref) {
      final scheduler = OneLineNotificationScheduler(
        ref.watch(studentContentRepositoryProvider),
        ref.watch(flashcardLocalStoreProvider),
      );
      ref.onDispose(scheduler.dispose);
      return scheduler;
    });

class OneLineNotificationScheduler {
  OneLineNotificationScheduler(
    this._repository,
    this._store, {
    Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
    reconcile,
    Future<void> Function()? cancel,
    DateTime Function()? now,
    Future<bool> Function()? isCurrentSession,
  }) : _reconcile =
           reconcile ??
           ((items) =>
               PushNotificationService.reconcileOneLineShotNotifications(
                 items: items,
               )),
       _cancel =
           cancel ?? PushNotificationService.cancelOneLineShotNotifications,
       _now = now ?? DateTime.now,
       _isCurrentSession = isCurrentSession ?? (() async => true);

  final StudentContentRepository _repository;
  final FlashcardLocalStore _store;
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)
  _reconcile;
  final Future<void> Function() _cancel;
  final DateTime Function() _now;
  final Future<bool> Function() _isCurrentSession;
  static Future<void> _tail = Future.value();
  bool _disposed = false;

  void dispose() => _disposed = true;

  Future<int> sync({Map<String, dynamic>? data, bool force = false}) {
    return runExclusive(
      () => _store.withScheduleLock(() => _sync(data, force)),
    );
  }

  static Future<T> runExclusive<T>(Future<T> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  Future<int> _sync(Map<String, dynamic>? data, bool force) async {
    if (_disposed) return 0;
    var source = force
        ? await _loadNotificationData(force: true)
        : data ?? await _loadNotificationData();
    if (_disposed || source == null || !await _isCurrentSession()) return 0;
    final cached = await _store.loadOneLineNotifications();
    final cachedAt = DateTime.tryParse(
      cached?['generated_at']?.toString() ?? '',
    );
    final sourceAt = DateTime.tryParse(
      source['generated_at']?.toString() ?? '',
    );
    if (cached != null &&
        cachedAt != null &&
        sourceAt != null &&
        cachedAt.isAfter(sourceAt)) {
      source = cached;
    }
    final now = _now();
    final settings = _map(source['settings']);
    final state = await _store.load();
    final enabled =
        settings['one_line_notifications_enabled'] != false &&
        settings['one_line_notifications_enabled'] != 0;
    if (!enabled) {
      await _cancel();
      await _store.cacheOneLineNotifications(source);
      await _store.saveOneLineScheduleState(
        date: _dateKey(now),
        signature: 'disabled',
        items: [],
      );
      return 0;
    }
    final items = <Map<String, dynamic>>[];
    final perDay = <String, int>{};
    for (final item in _maps(source['items'] ?? source['queue'])) {
      final raw = item['scheduled_at']?.toString() ?? '';
      final at = DateTime.tryParse(raw);
      if (at == null || raw.length < 10) continue;
      final day = raw.substring(0, 10);
      final index = perDay.update(day, (value) => value + 1, ifAbsent: () => 0);
      if (index >= 100)
        throw StateError('One Line daily schedule exceeds 100 items');
      if (!at.isAfter(now)) continue;
      final daySlot =
          DateTime.parse('${day}T00:00:00Z').millisecondsSinceEpoch ~/
          Duration.millisecondsPerDay %
          4;
      items.add({...item, 'notification_id': 64100 + daySlot * 100 + index});
    }
    if (_disposed || !await _isCurrentSession()) return 0;
    final accepted = await _reconcile(items);
    if (_disposed) return 0;
    final elapsed = state.oneLineScheduledItems.where((item) {
      final at = DateTime.tryParse(item['scheduled_at']?.toString() ?? '');
      return at != null &&
          !at.isAfter(now) &&
          at.toLocal().year == now.year &&
          at.toLocal().month == now.month &&
          at.toLocal().day == now.day;
    }).toList();
    await _store.cacheOneLineNotifications(source);
    await _store.saveOneLineScheduleState(
      date: _dateKey(now),
      signature: jsonEncode(items),
      items: [...elapsed, ...accepted],
    );
    return accepted
        .where((item) => item['schedule_status'] == 'scheduled')
        .length;
  }

  Future<Map<String, dynamic>?> _loadNotificationData({
    bool force = false,
  }) async {
    try {
      return await _repository.flashcardOneLineNotifications(reschedule: force);
    } on ApiException catch (error) {
      if (!error.isOffline || force) rethrow;
      return _store.loadOneLineNotifications();
    }
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : [];
String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
