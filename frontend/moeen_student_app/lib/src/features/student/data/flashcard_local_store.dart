import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import '../../auth/logic/auth_controller.dart';
import '../../auth/data/auth_session.dart';

final flashcardLocalStoreProvider = Provider<FlashcardLocalStore>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;
  return FlashcardLocalStore(
    accountKey: session == null
        ? 'signed_out'
        : FlashcardLocalStore.keyFor(session),
  );
});

class FlashcardLocalStore {
  const FlashcardLocalStore({this.accountKey = 'signed_out'});

  final String accountKey;
  static String keyFor(AuthSession session) => session.userId != null
      ? 'user_${session.userId}'
      : sha256.convert(utf8.encode(session.token)).toString();

  Future<T> withScheduleLock<T>(Future<T> Function() operation) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/moeen_flashcards/schedule.lock');
    await file.parent.create(recursive: true);
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.lock(FileLock.blockingExclusive);
      return await operation();
    } finally {
      await handle.close();
    }
  }

  Future<FlashcardLocalState> load() async {
    final file = await _file();
    if (!await file.exists()) {
      return _withPersistedOneLineSchedule(const FlashcardLocalState());
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return _withPersistedOneLineSchedule(const FlashcardLocalState());
      }
      final state = FlashcardLocalState.fromJson(decoded);
      return _withPersistedOneLineSchedule(state);
    } catch (_) {
      return _withPersistedOneLineSchedule(const FlashcardLocalState());
    }
  }

  Future<void> save(FlashcardLocalState state) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state.toJson()), flush: true);
  }

  Future<void> addPendingProgress({
    required int itemId,
    required String responseLevel,
  }) async {
    final state = await load();
    final today = _dateKey(DateTime.now());
    final pending = [
      ...state.pendingProgress,
      {
        'item_id': itemId,
        'response_level': responseLevel,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      },
    ];
    final seenIds = state.smartReviewSeenDate == today
        ? {...state.smartReviewSeenItemIds}
        : <int>{};
    seenIds.add(itemId);
    await save(
      state.copyWith(
        pendingProgress: pending,
        smartReviewSeenDate: today,
        smartReviewSeenItemIds: seenIds.toList(),
      ),
    );
  }

  Future<void> markSmartReviewItemCompletedToday(int itemId) async {
    final state = await load();
    final today = _dateKey(DateTime.now());
    final seenIds = state.smartReviewSeenDate == today
        ? {...state.smartReviewSeenItemIds}
        : <int>{};
    seenIds.add(itemId);
    await save(
      state.copyWith(
        smartReviewSeenDate: today,
        smartReviewSeenItemIds: seenIds.toList(),
      ),
    );
  }

  Future<bool> canShowSmartReview() async {
    final state = await load();
    if (!state.smartReviewEnabled) return false;

    final now = DateTime.now();
    final snoozeUntil = DateTime.tryParse(state.smartReviewSnoozeUntil ?? '');
    if (snoozeUntil != null && snoozeUntil.isAfter(now)) return false;

    return true;
  }

  Future<void> markSmartReviewShown() async {
    final state = await load();
    final today = _dateKey(DateTime.now());
    final count = state.smartReviewShownDate == today
        ? state.smartReviewShownCount + 1
        : 1;
    await save(
      state.copyWith(smartReviewShownDate: today, smartReviewShownCount: count),
    );
  }

  Future<void> snoozeSmartReview() async {
    final state = await load();
    final snoozeUntil = DateTime.now()
        .add(Duration(minutes: state.smartReviewSnoozeMinutes))
        .toIso8601String();
    await save(state.copyWith(smartReviewSnoozeUntil: snoozeUntil));
  }

  Future<void> updateSmartReviewSettings({
    bool? enabled,
    int? dailyLimit,
    int? snoozeMinutes,
    bool? autoRestart,
    bool markTouched = true,
    bool clearSnooze = false,
  }) async {
    final state = await load();
    final touched =
        enabled != null ||
        dailyLimit != null ||
        snoozeMinutes != null ||
        autoRestart != null;
    await save(
      state.copyWith(
        smartReviewEnabled: enabled,
        smartReviewDailyLimit: dailyLimit,
        smartReviewSnoozeMinutes: snoozeMinutes,
        smartReviewAutoRestart: autoRestart,
        smartReviewSettingsUpdatedAt: markTouched && touched
            ? DateTime.now().toUtc().toIso8601String()
            : null,
        clearSmartReviewSettingsUpdatedAt: !markTouched,
        clearSmartReviewSnoozeUntil: clearSnooze || (markTouched && touched),
      ),
    );
  }

  Future<void> applyServerSmartReviewSettings(
    Map<String, dynamic> data, {
    bool clearSnooze = false,
  }) async {
    final settings = _mapOrNull(data['settings']);
    if (settings == null) return;

    await updateSmartReviewSettings(
      enabled: _boolValue(settings['smart_review_enabled'], fallback: true),
      dailyLimit: _intValue(settings['daily_card_limit'], fallback: 5),
      snoozeMinutes: _intValue(
        settings['smart_review_frequency_minutes'],
        fallback: 30,
      ),
      autoRestart: _boolValue(settings['auto_restart_enabled']),
      markTouched: false,
      clearSnooze: clearSnooze,
    );
  }

  Future<Set<int>> smartReviewSeenItemIdsToday() async {
    final state = await load();
    if (state.smartReviewSeenDate != _dateKey(DateTime.now())) return {};
    return state.smartReviewSeenItemIds.toSet();
  }

  Future<void> restartTodayReview() async {
    final state = await load();
    final now = DateTime.now();
    await save(
      state.copyWith(
        dailyReviewRestartDate: _dateKey(now),
        dailyReviewRestartStartedAt: now.toIso8601String(),
        smartReviewSeenDate: _dateKey(now),
        smartReviewSeenItemIds: const [],
        smartReviewSnoozeUntil: now.toIso8601String(),
      ),
    );
  }

  bool isDailyReviewRestartActive(FlashcardLocalState state) {
    return state.smartReviewAutoRestart ||
        state.dailyReviewRestartDate == _dateKey(DateTime.now());
  }

  Future<void> cacheHome(Map<String, dynamic> data) async {
    final state = await load();
    await save(state.copyWith(home: _offlineSnapshot(data)));
  }

  Future<Map<String, dynamic>?> loadHome() async {
    final data = (await load()).home;
    if (data == null) return null;
    return _markOffline(data);
  }

  Future<void> cacheDailyQueue(Map<String, dynamic> data) async {
    final state = await load();
    await save(state.copyWith(dailyQueue: _offlineSnapshot(data)));
  }

  Future<Map<String, dynamic>?> loadDailyQueue() async {
    final data = (await load()).dailyQueue;
    if (data == null) return null;
    return _markOffline(data);
  }

  Future<void> cacheOneLineNotifications(Map<String, dynamic> data) async {
    final current = await loadOneLineNotifications();
    final oldTime = DateTime.tryParse(
      current?['generated_at']?.toString() ?? '',
    );
    final newTime = DateTime.tryParse(data['generated_at']?.toString() ?? '');
    if (oldTime != null && newTime != null && oldTime.isAfter(newTime)) return;
    final dir = await getApplicationDocumentsDirectory();
    await _writeJsonAtomically(
      File('${dir.path}/moeen_flashcards/$accountKey/one_line_source.json'),
      _offlineSnapshot(data),
    );
  }

  Future<Map<String, dynamic>?> loadOneLineNotifications() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/moeen_flashcards/$accountKey/one_line_source.json',
    );
    if (!await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString());
      return data is Map<String, dynamic> ? _markOffline(data) : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> saveOneLineScheduleState({
    required String date,
    required String signature,
    required List<Map<String, dynamic>> items,
  }) async {
    await _saveOneLineScheduleSnapshot(
      date: date,
      signature: signature,
      items: items,
    );
  }

  Future<void> cacheUpcoming(Map<String, dynamic> data) async {
    final state = await load();
    await save(state.copyWith(upcoming: _offlineSnapshot(data)));
  }

  Future<Map<String, dynamic>?> loadUpcoming() async {
    final data = (await load()).upcoming;
    if (data == null) return null;
    return _markOffline(data);
  }

  Future<void> cacheHistory(Map<String, dynamic> data) async {
    final state = await load();
    await save(state.copyWith(history: _offlineSnapshot(data)));
  }

  Future<Map<String, dynamic>?> loadHistory() async {
    final data = (await load()).history;
    if (data == null) return null;
    return _markOffline(data);
  }

  Future<void> cacheDifficulty(Map<String, dynamic> data) async {
    final state = await load();
    await save(state.copyWith(difficulty: _offlineSnapshot(data)));
  }

  Future<Map<String, dynamic>?> loadDifficulty() async {
    final data = (await load()).difficulty;
    if (data == null) return null;
    return _markOffline(data);
  }

  Future<void> cacheAnalytics(Map<String, dynamic> data) async {
    final state = await load();
    await save(state.copyWith(analytics: _offlineSnapshot(data)));
  }

  Future<Map<String, dynamic>?> loadAnalytics() async {
    final data = (await load()).analytics;
    if (data == null) return null;
    return _markOffline(data);
  }

  Future<void> cacheSettings(Map<String, dynamic> data) async {
    final state = await load();
    await save(state.copyWith(settings: _offlineSnapshot(data)));
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    final data = (await load()).settings;
    if (data == null) return null;
    return _markOffline(data);
  }

  Future<void> cachePackDetails(int packId, Map<String, dynamic> data) async {
    final state = await load();
    await save(
      state.copyWith(
        packDetails: {
          ...state.packDetails,
          packId.toString(): _offlineSnapshot(data),
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> loadPackDetails(int packId) async {
    final data = (await load()).packDetails[packId.toString()];
    if (data == null) return null;
    return _markOffline(data);
  }

  Future<void> cachePackReview(int packId, Map<String, dynamic> data) async {
    final state = await load();
    await save(
      state.copyWith(
        packReviews: {
          ...state.packReviews,
          packId.toString(): _offlineSnapshot(data),
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> loadPackReview(int packId) async {
    final data = (await load()).packReviews[packId.toString()];
    if (data == null) return null;
    return _markOffline(data);
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/moeen_flashcards/$accountKey/state.json');
  }

  Future<File> _oneLineScheduleFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(
      '${dir.path}/moeen_flashcards/$accountKey/one_line_schedule.json',
    );
  }

  Future<void> _saveOneLineScheduleSnapshot({
    required String date,
    required String signature,
    required List<Map<String, dynamic>> items,
  }) async {
    final file = await _oneLineScheduleFile();
    await _writeJsonAtomically(file, {
      'date': date,
      'signature': signature,
      'synced_at': DateTime.now().toUtc().toIso8601String(),
      'items': items,
    });
  }

  Future<void> _writeJsonAtomically(
    File file,
    Map<String, dynamic> data,
  ) async {
    await file.parent.create(recursive: true);
    final temporary = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await temporary.writeAsString(jsonEncode(data), flush: true);
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<FlashcardLocalState> _withPersistedOneLineSchedule(
    FlashcardLocalState state,
  ) async {
    final file = await _oneLineScheduleFile();
    if (!await file.exists()) return state;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return state;
      final date = decoded['date']?.toString();
      final signature = decoded['signature']?.toString();
      final items = _mapList(decoded['items']);
      if (date == null || signature == null) return state;
      return state.copyWith(
        oneLineScheduleDate: date,
        oneLineScheduleSignature: signature,
        oneLineScheduleSyncedAt: decoded['synced_at']?.toString(),
        oneLineScheduledItems: items,
      );
    } catch (_) {
      return state;
    }
  }
}

class FlashcardLocalState {
  const FlashcardLocalState({
    this.pendingProgress = const [],
    this.home,
    this.dailyQueue,
    this.oneLineNotifications,
    this.upcoming,
    this.history,
    this.difficulty,
    this.analytics,
    this.settings,
    this.oneLineScheduleDate,
    this.oneLineScheduleSignature,
    this.oneLineScheduleSyncedAt,
    this.oneLineScheduledItems = const [],
    this.packDetails = const {},
    this.packReviews = const {},
    this.smartReviewEnabled = true,
    this.smartReviewDailyLimit = 3,
    this.smartReviewSnoozeMinutes = 30,
    this.smartReviewSnoozeUntil,
    this.smartReviewShownDate,
    this.smartReviewShownCount = 0,
    this.smartReviewAutoRestart = false,
    this.smartReviewSettingsUpdatedAt,
    this.dailyReviewRestartDate,
    this.dailyReviewRestartStartedAt,
    this.smartReviewSeenDate,
    this.smartReviewSeenItemIds = const [],
  });

  final List<Map<String, dynamic>> pendingProgress;
  final Map<String, dynamic>? home;
  final Map<String, dynamic>? dailyQueue;
  final Map<String, dynamic>? oneLineNotifications;
  final Map<String, dynamic>? upcoming;
  final Map<String, dynamic>? history;
  final Map<String, dynamic>? difficulty;
  final Map<String, dynamic>? analytics;
  final Map<String, dynamic>? settings;
  final String? oneLineScheduleDate;
  final String? oneLineScheduleSignature;
  final String? oneLineScheduleSyncedAt;
  final List<Map<String, dynamic>> oneLineScheduledItems;
  final Map<String, Map<String, dynamic>> packDetails;
  final Map<String, Map<String, dynamic>> packReviews;
  final bool smartReviewEnabled;
  final int smartReviewDailyLimit;
  final int smartReviewSnoozeMinutes;
  final String? smartReviewSnoozeUntil;
  final String? smartReviewShownDate;
  final int smartReviewShownCount;
  final bool smartReviewAutoRestart;
  final String? smartReviewSettingsUpdatedAt;
  final String? dailyReviewRestartDate;
  final String? dailyReviewRestartStartedAt;
  final String? smartReviewSeenDate;
  final List<int> smartReviewSeenItemIds;

  factory FlashcardLocalState.fromJson(Map<String, dynamic> json) {
    return FlashcardLocalState(
      pendingProgress: _mapList(json['pending_progress']),
      home: _mapOrNull(json['home']),
      dailyQueue: _mapOrNull(json['daily_queue']),
      oneLineNotifications: _mapOrNull(json['one_line_notifications']),
      upcoming: _mapOrNull(json['upcoming']),
      history: _mapOrNull(json['history']),
      difficulty: _mapOrNull(json['difficulty']),
      analytics: _mapOrNull(json['analytics']),
      settings: _mapOrNull(json['settings']),
      oneLineScheduleDate: json['one_line_schedule_date']?.toString(),
      oneLineScheduleSignature: json['one_line_schedule_signature']?.toString(),
      oneLineScheduleSyncedAt: json['one_line_schedule_synced_at']?.toString(),
      oneLineScheduledItems: _mapList(json['one_line_scheduled_items']),
      packDetails: _nestedMap(json['pack_details']),
      packReviews: _nestedMap(json['pack_reviews']),
      smartReviewEnabled: json['smart_review_enabled'] != false,
      smartReviewDailyLimit: _intValue(
        json['smart_review_daily_limit'],
        fallback: 3,
      ),
      smartReviewSnoozeMinutes: _intValue(
        json['smart_review_snooze_minutes'],
        fallback: 30,
      ),
      smartReviewSnoozeUntil: json['smart_review_snooze_until']?.toString(),
      smartReviewShownDate: json['smart_review_shown_date']?.toString(),
      smartReviewShownCount: _intValue(json['smart_review_shown_count']),
      smartReviewAutoRestart: json['smart_review_auto_restart'] == true,
      smartReviewSettingsUpdatedAt: json['smart_review_settings_updated_at']
          ?.toString(),
      dailyReviewRestartDate: json['daily_review_restart_date']?.toString(),
      dailyReviewRestartStartedAt: json['daily_review_restart_started_at']
          ?.toString(),
      smartReviewSeenDate: json['smart_review_seen_date']?.toString(),
      smartReviewSeenItemIds: _intList(json['smart_review_seen_item_ids']),
    );
  }

  FlashcardLocalState copyWith({
    List<Map<String, dynamic>>? pendingProgress,
    Map<String, dynamic>? home,
    Map<String, dynamic>? dailyQueue,
    Map<String, dynamic>? oneLineNotifications,
    Map<String, dynamic>? upcoming,
    Map<String, dynamic>? history,
    Map<String, dynamic>? difficulty,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? settings,
    String? oneLineScheduleDate,
    String? oneLineScheduleSignature,
    String? oneLineScheduleSyncedAt,
    List<Map<String, dynamic>>? oneLineScheduledItems,
    Map<String, Map<String, dynamic>>? packDetails,
    Map<String, Map<String, dynamic>>? packReviews,
    bool? smartReviewEnabled,
    int? smartReviewDailyLimit,
    int? smartReviewSnoozeMinutes,
    String? smartReviewSnoozeUntil,
    String? smartReviewShownDate,
    int? smartReviewShownCount,
    bool? smartReviewAutoRestart,
    String? smartReviewSettingsUpdatedAt,
    String? dailyReviewRestartDate,
    String? dailyReviewRestartStartedAt,
    String? smartReviewSeenDate,
    List<int>? smartReviewSeenItemIds,
    bool clearSmartReviewSnoozeUntil = false,
    bool clearSmartReviewSettingsUpdatedAt = false,
    bool clearDailyReviewRestart = false,
  }) {
    return FlashcardLocalState(
      pendingProgress: pendingProgress ?? this.pendingProgress,
      home: home ?? this.home,
      dailyQueue: dailyQueue ?? this.dailyQueue,
      oneLineNotifications: oneLineNotifications ?? this.oneLineNotifications,
      upcoming: upcoming ?? this.upcoming,
      history: history ?? this.history,
      difficulty: difficulty ?? this.difficulty,
      analytics: analytics ?? this.analytics,
      settings: settings ?? this.settings,
      oneLineScheduleDate: oneLineScheduleDate ?? this.oneLineScheduleDate,
      oneLineScheduleSignature:
          oneLineScheduleSignature ?? this.oneLineScheduleSignature,
      oneLineScheduleSyncedAt:
          oneLineScheduleSyncedAt ?? this.oneLineScheduleSyncedAt,
      oneLineScheduledItems:
          oneLineScheduledItems ?? this.oneLineScheduledItems,
      packDetails: packDetails ?? this.packDetails,
      packReviews: packReviews ?? this.packReviews,
      smartReviewEnabled: smartReviewEnabled ?? this.smartReviewEnabled,
      smartReviewDailyLimit:
          smartReviewDailyLimit ?? this.smartReviewDailyLimit,
      smartReviewSnoozeMinutes:
          smartReviewSnoozeMinutes ?? this.smartReviewSnoozeMinutes,
      smartReviewSnoozeUntil: clearSmartReviewSnoozeUntil
          ? null
          : smartReviewSnoozeUntil ?? this.smartReviewSnoozeUntil,
      smartReviewShownDate: smartReviewShownDate ?? this.smartReviewShownDate,
      smartReviewShownCount:
          smartReviewShownCount ?? this.smartReviewShownCount,
      smartReviewAutoRestart:
          smartReviewAutoRestart ?? this.smartReviewAutoRestart,
      smartReviewSettingsUpdatedAt: clearSmartReviewSettingsUpdatedAt
          ? null
          : smartReviewSettingsUpdatedAt ?? this.smartReviewSettingsUpdatedAt,
      dailyReviewRestartDate: clearDailyReviewRestart
          ? null
          : dailyReviewRestartDate ?? this.dailyReviewRestartDate,
      dailyReviewRestartStartedAt: clearDailyReviewRestart
          ? null
          : dailyReviewRestartStartedAt ?? this.dailyReviewRestartStartedAt,
      smartReviewSeenDate: smartReviewSeenDate ?? this.smartReviewSeenDate,
      smartReviewSeenItemIds:
          smartReviewSeenItemIds ?? this.smartReviewSeenItemIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pending_progress': pendingProgress,
      if (home != null) 'home': home,
      if (dailyQueue != null) 'daily_queue': dailyQueue,
      if (oneLineNotifications != null)
        'one_line_notifications': oneLineNotifications,
      if (upcoming != null) 'upcoming': upcoming,
      if (history != null) 'history': history,
      if (difficulty != null) 'difficulty': difficulty,
      if (analytics != null) 'analytics': analytics,
      if (settings != null) 'settings': settings,
      if (oneLineScheduleDate != null)
        'one_line_schedule_date': oneLineScheduleDate,
      if (oneLineScheduleSignature != null)
        'one_line_schedule_signature': oneLineScheduleSignature,
      if (oneLineScheduleSyncedAt != null)
        'one_line_schedule_synced_at': oneLineScheduleSyncedAt,
      'one_line_scheduled_items': oneLineScheduledItems,
      'pack_details': packDetails,
      'pack_reviews': packReviews,
      'smart_review_enabled': smartReviewEnabled,
      'smart_review_daily_limit': smartReviewDailyLimit,
      'smart_review_snooze_minutes': smartReviewSnoozeMinutes,
      if (smartReviewSnoozeUntil != null)
        'smart_review_snooze_until': smartReviewSnoozeUntil,
      if (smartReviewShownDate != null)
        'smart_review_shown_date': smartReviewShownDate,
      'smart_review_shown_count': smartReviewShownCount,
      'smart_review_auto_restart': smartReviewAutoRestart,
      if (smartReviewSettingsUpdatedAt != null)
        'smart_review_settings_updated_at': smartReviewSettingsUpdatedAt,
      if (dailyReviewRestartDate != null)
        'daily_review_restart_date': dailyReviewRestartDate,
      if (dailyReviewRestartStartedAt != null)
        'daily_review_restart_started_at': dailyReviewRestartStartedAt,
      if (smartReviewSeenDate != null)
        'smart_review_seen_date': smartReviewSeenDate,
      'smart_review_seen_item_ids': smartReviewSeenItemIds,
    };
  }
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolValue(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().toLowerCase().trim();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

List<int> _intList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item is num ? item.toInt() : int.tryParse('$item'))
      .whereType<int>()
      .toList();
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((item) {
    return item.map((key, value) => MapEntry(key.toString(), value));
  }).toList();
}

Map<String, dynamic>? _mapOrNull(Object? value) {
  if (value is! Map) return null;
  return value.map((key, value) => MapEntry(key.toString(), value));
}

Map<String, Map<String, dynamic>> _nestedMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, value) {
    return MapEntry(key.toString(), _mapOrNull(value) ?? const {});
  });
}

Map<String, dynamic> _offlineSnapshot(Map<String, dynamic> data) {
  return {...data, '_cached_at': DateTime.now().toUtc().toIso8601String()};
}

Map<String, dynamic> _markOffline(Map<String, dynamic> data) {
  return {...data, '_offline': true};
}
