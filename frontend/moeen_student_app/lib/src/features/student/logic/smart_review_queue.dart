import '../data/flashcard_local_store.dart';

class SmartReviewQueue {
  static List<Map<String, dynamic>> pending(
    Map<String, dynamic> data,
    FlashcardLocalState state, {
    bool availableOnly = false,
    DateTime? now,
  }) {
    now ??= DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    if (data['date'] != null && data['date'] != today) return [];
    final settings = Map<String, dynamic>.from(data['settings'] as Map? ?? {});
    if (settings['smart_review_enabled'] == false ||
        !state.smartReviewEnabled) {
      return [];
    }
    final seen = state.smartReviewSeenDate == today
        ? state.smartReviewSeenItemIds.toSet()
        : <int>{};
    final completed = state.smartReviewSeenDate == today
        ? state.smartReviewCompletedKeys.toSet()
        : <String>{};
    final result = <Map<String, dynamic>>[];
    for (final raw in data['queue'] as List? ?? []) {
      final item = Map<String, dynamic>.from(raw as Map);
      final type = item['item_type'] ?? item['resolved_item_type'];
      final id = (item['item_id'] ?? item['id'])?.toString();
      final key = item['review_key']?.toString() ?? '';
      if (type == 'one_line' ||
          state.pendingProgress.any(
            (entry) =>
                entry['item_id']?.toString() == id &&
                (entry['review_key'] == null || entry['review_key'] == key),
          ) ||
          (key.isEmpty
              ? seen.contains(int.tryParse(id ?? ''))
              : completed.contains(key))) {
        continue;
      }
      final at = DateTime.tryParse(item['scheduled_at']?.toString() ?? '');
      final available =
          at != null && !at.isAfter(now) && allowed(settings, now);
      if (availableOnly && !available) continue;
      result.add({...item, 'available_now': available});
    }
    result.sort(
      (a, b) => (a['scheduled_at']?.toString() ?? '').compareTo(
        b['scheduled_at']?.toString() ?? '',
      ),
    );
    return result;
  }

  static bool allowed(Map<String, dynamic> settings, DateTime now) {
    int? minute(dynamic value) {
      final parts = value?.toString().split(':') ?? [];
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]);
      final min = int.tryParse(parts[1]);
      if (hour == null || min == null) return null;
      return hour * 60 + min;
    }

    bool within(int value, int start, int end) =>
        start == end ||
        (start < end
            ? value >= start && value <= end
            : value >= start || value <= end);
    final current = now.hour * 60 + now.minute;
    final start = minute(settings['active_from_time']);
    final end = minute(settings['active_to_time']);
    if ((start != null || end != null) &&
        !within(current, start ?? 0, end ?? 1439)) {
      return false;
    }
    final quietStart = minute(settings['quiet_start']);
    final quietEnd = minute(settings['quiet_end']);
    return quietStart == null ||
        quietEnd == null ||
        !within(current, quietStart, quietEnd);
  }
}
