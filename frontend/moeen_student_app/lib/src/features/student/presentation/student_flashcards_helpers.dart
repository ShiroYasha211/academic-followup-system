// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

Future<int> _syncFlashcardPendingProgress(WidgetRef ref) async {
  final isOnline = await ref.read(connectivityServiceProvider).isOnline();
  if (!isOnline) return 0;
  final store = ref.read(flashcardLocalStoreProvider);
  final state = await store.load();
  if (state.pendingProgress.isEmpty) return 0;

  final repo = ref.read(studentContentRepositoryProvider);
  final completed = <String>{};
  String identity(Map<String, dynamic> entry) =>
      entry['client_event_id']?.toString() ??
      '${entry['item_id']}:${entry['recorded_at']}';
  var synced = 0;

  for (final entry in state.pendingProgress) {
    final itemId = int.tryParse(entry['item_id']?.toString() ?? '');
    final level = entry['response_level']?.toString();
    if (itemId == null || level == null || level.isEmpty) continue;
    try {
      await repo.recordFlashcardProgress(
        itemId: itemId,
        responseLevel: level,
        clientEventId: entry['client_event_id']?.toString(),
      );
      synced++;
      completed.add(identity(entry));
    } catch (_) {
      // Keep failed entries and any answers added while this request was in flight.
    }
  }

  await store.updateState(
    (latest) => latest.copyWith(
      pendingProgress: latest.pendingProgress
          .where((entry) => !completed.contains(identity(entry)))
          .toList(),
    ),
  );
  return synced;
}

Color _modeColor(String mode) {
  return switch (mode) {
    'flash_card' => AppColors.royalBlue,
    'qa' => AppColors.success,
    'mcq' => AppColors.goldDeep,
    _ => AppColors.midnight,
  };
}

IconData _modeIcon(String mode) {
  return switch (mode) {
    'flash_card' => Icons.flip_rounded,
    'qa' => Icons.question_answer_rounded,
    'mcq' => Icons.checklist_rounded,
    _ => Icons.article_rounded,
  };
}

String _flashcardPriorityLabel(String priority) {
  return switch (priority) {
    'critical' => 'أولوية حرجة',
    'high' => 'أولوية عالية',
    _ => 'عادي',
  };
}

String _upcomingDateLabel(Map<String, dynamic> item) {
  final date = text(item, 'next_review_date');
  final time = text(
    item,
    'next_review_time_label',
    fallback: text(item, 'next_review_time', fallback: '--:--'),
  );
  if (date.isEmpty) return time;
  return '$date · $time';
}

String _historyDateLabel(Map<String, dynamic> item) {
  final date = text(item, 'last_shown_date');
  final time = text(
    item,
    'last_shown_time_label',
    fallback: text(item, 'last_shown_time', fallback: '--:--'),
  );
  if (date.isEmpty) return time;
  return '$date · $time';
}

Color _responseColor(String response) {
  return switch (response) {
    'easy' => AppColors.success,
    'medium' => AppColors.goldDeep,
    'hard' => AppColors.rose,
    _ => AppColors.slate500,
  };
}

String _flashModeLabel(String mode) {
  return switch (mode) {
    'flash_card' => 'Flash Card',
    'qa' => 'سؤال وجواب',
    'mcq' => 'اختيار من متعدد',
    _ => 'One Line',
  };
}

String _typeLabel(String mode) {
  return switch (mode) {
    'flash_card' => 'اقلب الكرت',
    'qa' => 'سؤال وجواب',
    'mcq' => 'اختيارات',
    _ => 'قراءة سريعة',
  };
}

String _itemType(Map<String, dynamic> item) {
  final direct = text(item, 'item_type');
  if (direct.isNotEmpty) return direct;
  final resolved = text(item, 'resolved_item_type');
  if (resolved.isNotEmpty) return resolved;
  return text(asMap(item['pack']), 'display_mode', fallback: 'one_line');
}

int _flashcardItemId(Map<String, dynamic> item) {
  final direct = number(item, 'id').toInt();
  if (direct > 0) return direct;
  return number(item, 'item_id').toInt();
}

bool _isOneLineShotItem(Map<String, dynamic> item) {
  return _itemType(item) == 'one_line';
}

List<Map<String, dynamic>> _oneLineShotNotificationItems(
  Map<String, dynamic> data, {
  bool scheduledOnly = false,
}) {
  final settings = asMap(data['settings']);
  final rawItems = data.containsKey('items') ? data['items'] : data['queue'];
  return asList(rawItems)
      .map(asMap)
      .map((item) => _withRuntimeAvailability(item, settings))
      .where(_isOneLineShotItem)
      .where((item) {
        if (!scheduledOnly) return true;
        final scheduledAt = _parseFlashcardDateTime(text(item, 'scheduled_at'));
        if (scheduledAt == null) return false;
        final now = DateTime.now();
        return scheduledAt.isAfter(now) ||
            now.difference(scheduledAt) <= const Duration(minutes: 5);
      })
      .toList();
}

Future<void> _smartReviewSyncTail = Future<void>.value();

Future<void> _scheduleNextSmartReviewNotification(WidgetRef ref) {
  final store = ref.read(flashcardLocalStoreProvider);
  final repository = ref.read(studentContentRepositoryProvider);
  final operation = _smartReviewSyncTail.then(
    (_) => _syncSmartReviewQueue(store, repository),
  );
  _smartReviewSyncTail = operation.catchError((Object error, StackTrace stack) {
    debugPrint('Smart review synchronization deferred: $error');
  });
  return _smartReviewSyncTail;
}

Future<void> _syncSmartReviewQueue(
  FlashcardLocalStore store,
  StudentContentRepository repository,
) async {
  await PushNotificationService.cancelFlashcardSmartReview(legacyOnly: true);

  Map<String, dynamic>? data;
  try {
    data = await repository.flashcardDailyQueue();
    await store.cacheDailyQueue(data);
  } on ApiException catch (error) {
    if (!error.isOffline) return;
    data = await store.loadDailyQueue();
  } catch (_) {
    data = await store.loadDailyQueue();
  }
  if (data == null) return;
  await FloatingReview.updateQueue(store.accountKey, data);
  final floating = await FloatingReview.status();
  final state = await store.load();
  final queue = _todayPendingReviewItems(
    data,
    state,
  ).where((item) => !floating.running || _itemType(item) != 'mcq').toList();
  await PushNotificationService.syncFlashcardReviewNotifications(queue);
}

Future<void> scheduleStudentFlashcardSmartReviewNotification(WidgetRef ref) {
  return _scheduleNextSmartReviewNotification(ref);
}

int? _minutesFromTime(String value) {
  if (value.length < 5) return null;
  final hour = int.tryParse(value.substring(0, 2));
  final minute = int.tryParse(value.substring(3, 5));
  if (hour == null || minute == null) return null;
  return (hour * 60) + minute;
}

List<Map<String, dynamic>> _todayPendingReviewItems(
  Map<String, dynamic> data,
  FlashcardLocalState state, {
  bool availableOnly = false,
}) {
  return SmartReviewQueue.pending(data, state, availableOnly: availableOnly)
      .map((item) => _withRuntimeAvailability(item, asMap(data['settings'])))
      .toList();
}

Map<String, dynamic> _withRuntimeAvailability(
  Map<String, dynamic> item,
  Map<String, dynamic> settings,
) {
  final scheduledAt = _parseFlashcardDateTime(text(item, 'scheduled_at'));
  if (scheduledAt == null) return item;

  return {
    ...item,
    'available_now':
        !scheduledAt.isAfter(DateTime.now()) &&
        _flashcardSettingsAllowNow(settings),
    'scheduled_time': _formatFlashcardTime24(scheduledAt),
    'scheduled_time_label': _formatFlashcardTime12(scheduledAt),
  };
}

bool _flashcardSettingsAllowNow(Map<String, dynamic> settings) {
  if (settings.isEmpty) return true;
  final now = DateTime.now();
  final currentMinute = (now.hour * 60) + now.minute;
  final activeStart = _minutesFromTime(text(settings, 'active_from_time'));
  final activeEnd = _minutesFromTime(text(settings, 'active_to_time'));
  if ((activeStart != null || activeEnd != null) &&
      !_minuteInWindow(currentMinute, activeStart ?? 0, activeEnd ?? 1439)) {
    return false;
  }

  final quietStart = _minutesFromTime(text(settings, 'quiet_start'));
  final quietEnd = _minutesFromTime(text(settings, 'quiet_end'));
  return !(quietStart != null &&
      quietEnd != null &&
      _minuteInWindow(currentMinute, quietStart, quietEnd));
}

bool _minuteInWindow(int minute, int start, int end) {
  if (start == end) return true;
  if (start < end) return minute >= start && minute <= end;
  return minute >= start || minute <= end;
}

List<Map<String, dynamic>> _todayReviewedItems(Map<String, dynamic> data) {
  return asList(data['reviewed_today']).map(asMap).toList();
}

String _formatFlashcardTime24(DateTime value) {
  final localValue = value.toLocal();
  return '${localValue.hour.toString().padLeft(2, '0')}:'
      '${localValue.minute.toString().padLeft(2, '0')}';
}

String _formatFlashcardTime12(DateTime value) {
  final localValue = value.toLocal();
  final suffix = localValue.hour >= 12 ? 'م' : 'ص';
  final hour = localValue.hour % 12 == 0 ? 12 : localValue.hour % 12;
  return '${hour.toString()}:${localValue.minute.toString().padLeft(2, '0')} $suffix';
}

DateTime? _parseFlashcardDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  return parsed?.toLocal();
}

List<Map<String, dynamic>> _sortedOneLineSchedule(
  List<Map<String, dynamic>> items,
) {
  final sorted = [...items];
  sorted.sort((first, second) {
    final firstDate = _parseFlashcardDateTime(text(first, 'scheduled_at'));
    final secondDate = _parseFlashcardDateTime(text(second, 'scheduled_at'));
    if (firstDate == null && secondDate == null) return 0;
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;
    return firstDate.compareTo(secondDate);
  });
  return sorted;
}

Map<String, dynamic>? _nextOneLineScheduleItem(
  List<Map<String, dynamic>> items,
) {
  final now = DateTime.now();
  for (final item in items) {
    final scheduledAt = _parseFlashcardDateTime(text(item, 'scheduled_at'));
    if (scheduledAt == null) continue;
    if (!scheduledAt.isBefore(now.subtract(const Duration(minutes: 1)))) {
      return item;
    }
  }
  return null;
}

String _oneLineExactScheduleLabel(Map<String, dynamic> item) {
  final scheduledAt = _parseFlashcardDateTime(text(item, 'scheduled_at'));
  if (scheduledAt == null) {
    return text(item, 'scheduled_time_label', fallback: 'وقت غير محدد');
  }
  final date =
      '${scheduledAt.year.toString().padLeft(4, '0')}-'
      '${scheduledAt.month.toString().padLeft(2, '0')}-'
      '${scheduledAt.day.toString().padLeft(2, '0')}';
  final precision = item['precision'] == 'approximate' ? ' • موعد تقريبي' : '';
  return '$date • ${_formatFlashcardTime12(scheduledAt)}$precision';
}

String _oneLineScheduleStatus(Map<String, dynamic> item) {
  if (item['schedule_status'] == 'blocked') return 'الإشعارات غير مسموحة';
  if (item['schedule_status'] == 'failed') return 'تعذرت الجدولة';
  if (item['schedule_status'] != 'scheduled') return 'غير متحقق';
  final scheduledAt = _parseFlashcardDateTime(text(item, 'scheduled_at'));
  if (scheduledAt == null) return 'غير محدد';
  final now = DateTime.now();
  final diff = scheduledAt.difference(now);
  if (diff.inSeconds.abs() <= 60) return 'حان الموعد';
  if (scheduledAt.isBefore(now)) return 'مر الموعد';
  return 'قادم';
}

Color _oneLineScheduleStatusColor(String status) {
  return switch (status) {
    'قادم' => AppColors.info,
    'حان الموعد' => AppColors.success,
    'مر الموعد' => AppColors.slate500,
    _ => AppColors.warning,
  };
}

String _todayKey() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _mergeLocalSmartReviewSettings(
  Map<String, dynamic> data,
  FlashcardLocalState local,
) {
  final serverSettings = asMap(data['settings']);
  if (local.smartReviewSettingsUpdatedAt == null) {
    return {...data, 'settings': serverSettings};
  }

  final settings = {
    ...serverSettings,
    'smart_review_enabled': local.smartReviewEnabled,
    'daily_card_limit': local.smartReviewDailyLimit,
    'smart_review_frequency_minutes': local.smartReviewSnoozeMinutes,
    'auto_restart_enabled': local.smartReviewAutoRestart,
  };
  return {...data, 'settings': settings};
}

String _responseLabel(String response) {
  return switch (response) {
    'easy' => 'سهل - تقليل الظهور',
    'medium' => 'متوسط - عادي',
    'hard' => 'صعب - زيادة الظهور',
    _ => 'لم تراجع',
  };
}

List<String> _flashcardOptions(Map<String, dynamic> item) {
  final raw = item['options'];
  if (raw is List) {
    return raw
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toList();
  }
  return const [];
}

int _correctOptionIndex(Map<String, dynamic> item) {
  final parsed = int.tryParse(item['correct_option']?.toString() ?? '') ?? 0;
  return parsed < 0 ? 0 : parsed;
}

int _parseHex(String input) {
  final clean = input.replaceAll('#', '');
  return int.tryParse('FF$clean', radix: 16) ?? 0xFF4338CA;
}

class _TypeSelectorCard extends StatelessWidget {
  const _TypeSelectorCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.royalBlue : AppColors.slate50,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.slate500,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.slate700,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrioritySelectorChip extends StatelessWidget {
  const _PrioritySelectorChip({
    required this.label,
    required this.value,
    required this.badgeColor,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Color badgeColor;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Expanded(
      child: Material(
        color: isSelected ? badgeColor : AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.slate700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
