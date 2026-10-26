// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

int? _parseReviewNumber(String value) {
  final normalized = String.fromCharCodes(
    value.trim().runes.map((rune) {
      if (rune >= 0x660 && rune <= 0x669) return rune - 0x660 + 48;
      if (rune >= 0x6f0 && rune <= 0x6f9) return rune - 0x6f0 + 48;
      return rune;
    }),
  );
  return int.tryParse(normalized);
}

Future<Map<String, dynamic>?> _saveFlashcardSettings(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> payload,
) async {
  for (final key in [
    'daily_card_limit',
    'one_line_daily_limit',
    'smart_review_frequency_minutes',
    'one_line_frequency_minutes',
  ]) {
    if (!payload.containsKey(key)) continue;
    final maximum = key.contains('daily_limit') || key == 'daily_card_limit'
        ? 100
        : 1440;
    final value = payload[key] as int;
    if (value < 1 || value > maximum) {
      await showMoeenInfoDialog(
        context: context,
        title: 'قيمة غير صالحة',
        message: 'يجب أن تكون القيمة بين 1 و$maximum.',
        icon: Icons.error_outline_rounded,
        color: AppColors.rose,
      );
      return null;
    }
  }
  final repository = ref.read(studentContentRepositoryProvider);
  final store = ref.read(flashcardLocalStoreProvider);
  try {
    final data = await repository.updateFlashcardSettings(payload);
    if (asMap(data['settings']).isEmpty)
      throw const ApiException('لم يؤكد الخادم حفظ الإعدادات.');
    await store.cacheSettings(data);
    await store.applyServerSmartReviewSettings(
      data,
      clearSnooze: payload.keys.any((key) => !key.startsWith('one_line_')),
    );
    return data;
  } on ApiException catch (error) {
    if (context.mounted)
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذر حفظ الإعدادات',
        message: error.message,
        icon: Icons.error_outline_rounded,
        color: AppColors.rose,
      );
    return null;
  }
}

class _FlashcardSmartReviewSettingsCard extends ConsumerStatefulWidget {
  const _FlashcardSmartReviewSettingsCard();

  @override
  ConsumerState<_FlashcardSmartReviewSettingsCard> createState() =>
      _FlashcardSmartReviewSettingsCardState();
}

class _FlashcardSmartReviewSettingsCardState
    extends ConsumerState<_FlashcardSmartReviewSettingsCard> {
  bool _saving = false;
  late Future<Map<String, dynamic>> _future;
  // Holds the last successfully loaded data to avoid flicker during reload
  Map<String, dynamic>? _lastData;

  @override
  void initState() {
    super.initState();
    _future = _loadSettings();
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    final store = ref.read(flashcardLocalStoreProvider);
    final data = await ref
        .read(studentContentRepositoryProvider)
        .flashcardSettings();
    if (await ref.read(connectivityServiceProvider).isOnline()) {
      await store.applyServerSmartReviewSettings(data);
    }
    final local = await store.load();
    final merged = _mergeLocalSmartReviewSettings(data, local);
    await store.cacheSettings(merged);
    if (mounted) _lastData = merged;
    return merged;
  }

  Future<void> _showSettingsSheet(BuildContext context) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'إعدادات الظهور الذكي',
      icon: Icons.auto_awesome_motion_rounded,
      color: AppColors.royalBlue,
      child: const _SmartReviewSettingsSheet(),
    );
    if (mounted) {
      setState(() {
        _future = _loadSettings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        // Use last cached data while reloading to prevent flicker back to defaults
        final effectiveData = snapshot.data ?? _lastData;
        if (effectiveData == null) {
          if (snapshot.hasError) {
            return _FlashcardsQueueWarning(
              message: 'تعذر تحميل إعدادات المراجعة.',
              onRetry: () => setState(() => _future = _loadSettings()),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final settings = asMap(effectiveData['settings']);
        final enabled = _boolValueFallback(
          settings,
          'smart_review_enabled',
          true,
        );
        final dailyLimit = number(
          settings,
          'daily_card_limit',
          fallback: 5,
        ).toInt();
        final frequency = number(
          settings,
          'smart_review_frequency_minutes',
          fallback: 30,
        ).toInt();
        return _ShotPanel(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_motion_rounded,
                  color: AppColors.royalBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الظهور الذكي',
                      style: TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => _showSettingsSheet(context),
                      child: const Text(
                        'اضغط لتعديل الإعدادات والتكرار اليومي',
                        style: TextStyle(
                          color: AppColors.royalBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      '$dailyLimit كروت يوميًا • كل $frequency دقيقة',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: _saving ? null : (value) => _update(enabled: value),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _update({
    bool? enabled,
    int? dailyLimit,
    int? snoozeMinutes,
    bool? autoRestart,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        if (enabled != null) 'smart_review_enabled': enabled,
        if (dailyLimit != null) 'daily_card_limit': dailyLimit,
        if (snoozeMinutes != null)
          'smart_review_frequency_minutes': snoozeMinutes,
        if (autoRestart != null) 'auto_restart_enabled': autoRestart,
      };
      final data = await _saveFlashcardSettings(context, ref, payload);
      if (data == null || !mounted) return;
      if (enabled == false) {
        await FloatingReview.endSession();
        await PushNotificationService.cancelFlashcardSmartReview();
      } else if (enabled == true || snoozeMinutes != null) {
        await _scheduleNextSmartReviewNotification(ref);
      }
      if (!mounted) return;
      setState(() {
        _future = _loadSettings();
      });
      ref.invalidate(_flashcardSettingsProvider);
      ref.invalidate(_flashcardDailyQueueProvider);
      ref.invalidate(_flashcardsProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SmartReviewSettingsSheet extends ConsumerStatefulWidget {
  const _SmartReviewSettingsSheet();

  @override
  ConsumerState<_SmartReviewSettingsSheet> createState() =>
      _SmartReviewSettingsSheetState();
}

class _SmartReviewSettingsSheetState
    extends ConsumerState<_SmartReviewSettingsSheet> {
  bool _saving = false;
  late Future<Map<String, dynamic>> _sheetFuture;
  // Holds the last successfully loaded data to avoid flicker during reload
  Map<String, dynamic>? _lastData;
  int? _dailyLimitDraft;
  int? _frequencyDraft;

  @override
  void initState() {
    super.initState();
    _sheetFuture = _loadSettings();
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    final store = ref.read(flashcardLocalStoreProvider);
    final data = await ref
        .read(studentContentRepositoryProvider)
        .flashcardSettings();
    if (await ref.read(connectivityServiceProvider).isOnline()) {
      await store.applyServerSmartReviewSettings(data);
    }
    final local = await store.load();
    final merged = _mergeLocalSmartReviewSettings(data, local);
    await store.cacheSettings(merged);
    if (mounted) _lastData = merged;
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _sheetFuture,
      builder: (context, snapshot) {
        // Use last cached data while reloading to prevent flicker back to defaults
        final effectiveData = snapshot.data ?? _lastData;
        if (effectiveData == null) {
          if (snapshot.hasError) {
            return _FlashcardsQueueWarning(
              message: 'تعذر تحميل الإعدادات. لم يتم تغيير القيم المحفوظة.',
              onRetry: () => setState(() => _sheetFuture = _loadSettings()),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final settings = asMap(effectiveData['settings']);
        final enabled = _boolValueFallback(
          settings,
          'smart_review_enabled',
          true,
        );
        final dailyLimit = number(
          settings,
          'daily_card_limit',
          fallback: 5,
        ).toInt();
        final frequency = number(
          settings,
          'smart_review_frequency_minutes',
          fallback: 30,
        ).toInt();
        _dailyLimitDraft ??= dailyLimit;
        _frequencyDraft ??= frequency;
        final autoRestart = _boolValueFallback(
          settings,
          'auto_restart_enabled',
          false,
        );
        final activeFrom = _cleanTime(text(settings, 'active_from_time'));
        final activeTo = _cleanTime(text(settings, 'active_to_time'));
        final quietStart = _cleanTime(text(settings, 'quiet_start'));
        final quietEnd = _cleanTime(text(settings, 'quiet_end'));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _FloatingReviewSettings(),
              const SizedBox(height: 16),
              // Premium Info Panel
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.royalBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_motion_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ما هو الظهور الذكي؟',
                            style: TextStyle(
                              color: AppColors.midnight,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'جدولة الكروت التفاعلية اليومية ومواعيد تذكيرها. المراجعة داخل التطبيق تبدأ باختيارك فقط.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Toggle Panel
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.power_settings_new_rounded,
                      color: AppColors.royalBlue,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'تفعيل الظهور الذكي',
                        style: TextStyle(
                          color: AppColors.midnight,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Switch(
                      value: enabled,
                      activeColor: AppColors.royalBlue,
                      onChanged: (value) => _update(enabled: value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Configuration Selectors Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: _SmartReviewNumberField(
                        label: 'حد المراجعة اليومي',
                        value: _dailyLimitDraft!,
                        suffix: 'مرات',
                        onChangedValue: (value) => _dailyLimitDraft = value,
                        onSubmitted: (value) => _dailyLimitDraft = value,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: _SmartReviewNumberField(
                        label: 'تكرار الظهور',
                        value: _frequencyDraft!,
                        suffix: 'دقيقة',
                        onChangedValue: (value) => _frequencyDraft = value,
                        onSubmitted: (value) => _frequencyDraft = value,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _ScheduleTimeField(
                      label: 'بداية الظهور',
                      value: activeFrom,
                      onChanged: (value) =>
                          _update(activeFromTime: value ?? ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScheduleTimeField(
                      label: 'نهاية الظهور',
                      value: activeTo,
                      onChanged: (value) => _update(activeToTime: value ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ScheduleTimeField(
                      label: 'بداية الهدوء',
                      value: quietStart,
                      onChanged: (value) => _update(quietStart: value ?? ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScheduleTimeField(
                      label: 'نهاية الهدوء',
                      value: quietEnd,
                      onChanged: (value) => _update(quietEnd: value ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Auto Restart Panel
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(Icons.loop_rounded, color: AppColors.success),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تكرار المراجعة تلقائياً',
                            style: TextStyle(
                              color: AppColors.midnight,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'إذا انتهت جميع كروت اليوم، يعاد تفعيل عرض الكروت مجدداً وفق تكرار الظهور الذكي.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: autoRestart,
                      activeColor: AppColors.success,
                      onChanged: (value) => _update(autoRestart: value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action button to save & dismiss
              FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final saved = await _update(
                          dailyLimit: _dailyLimitDraft,
                          snoozeMinutes: _frequencyDraft,
                        );
                        if (saved && context.mounted)
                          Navigator.of(context).pop();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.midnight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'حفظ وإغلاق',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _update({
    bool? enabled,
    int? dailyLimit,
    int? snoozeMinutes,
    bool? autoRestart,
    String? activeFromTime,
    String? activeToTime,
    String? quietStart,
    String? quietEnd,
  }) async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        if (enabled != null) 'smart_review_enabled': enabled,
        if (dailyLimit != null) 'daily_card_limit': dailyLimit,
        if (snoozeMinutes != null)
          'smart_review_frequency_minutes': snoozeMinutes,
        if (autoRestart != null) 'auto_restart_enabled': autoRestart,
        if (activeFromTime != null)
          'active_from_time': activeFromTime.isEmpty ? null : activeFromTime,
        if (activeToTime != null)
          'active_to_time': activeToTime.isEmpty ? null : activeToTime,
        if (quietStart != null)
          'quiet_start': quietStart.isEmpty ? null : quietStart,
        if (quietEnd != null) 'quiet_end': quietEnd.isEmpty ? null : quietEnd,
      };
      if (payload.isEmpty) return true;
      final data = await _saveFlashcardSettings(context, ref, payload);
      if (data == null || !mounted) return false;
      if (enabled == false) {
        await FloatingReview.endSession();
        await PushNotificationService.cancelFlashcardSmartReview();
      } else if (enabled == true ||
          snoozeMinutes != null ||
          activeFromTime != null ||
          activeToTime != null ||
          quietStart != null ||
          quietEnd != null) {
        await _scheduleNextSmartReviewNotification(ref);
      }
      if (!mounted) return true;
      setState(() {
        _sheetFuture = Future.value(data);
      });
      ref.invalidate(_flashcardSettingsProvider);
      ref.invalidate(_flashcardDailyQueueProvider);
      ref.invalidate(_flashcardsProvider);
      return true;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _OneLineShotNotificationPanel extends ConsumerWidget {
  const _OneLineShotNotificationPanel({
    required this.notificationData,
    this.loading = false,
    this.offline = false,
  });

  final Map<String, dynamic> notificationData;
  final bool loading;
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _oneLineShotNotificationItems(notificationData);
    final sourceScheduled = _oneLineShotNotificationItems(
      notificationData,
      scheduledOnly: true,
    );
    final settings = asMap(notificationData['settings']);
    final enabled = _boolValueFallback(
      settings,
      'one_line_notifications_enabled',
      true,
    );
    final dailyLimit = number(
      settings,
      'one_line_daily_limit',
      fallback: number(settings, 'daily_card_limit', fallback: 5),
    ).toInt();
    final frequency = number(
      settings,
      'one_line_frequency_minutes',
      fallback: number(
        settings,
        'smart_review_frequency_minutes',
        fallback: 30,
      ),
    ).toInt();

    return FutureBuilder<FlashcardLocalState>(
      future: ref.read(flashcardLocalStoreProvider).load(),
      builder: (context, snapshot) {
        final localState = snapshot.data ?? const FlashcardLocalState();
        final localScheduled = localState.oneLineScheduleDate == _todayKey()
            ? localState.oneLineScheduledItems
                  .where(
                    (item) =>
                        text(item, 'scheduled_at').startsWith(_todayKey()),
                  )
                  .toList()
            : const <Map<String, dynamic>>[];
        final scheduled = _sortedOneLineSchedule(
          localScheduled.isNotEmpty
              ? localScheduled
              : sourceScheduled
                    .where(
                      (item) =>
                          text(item, 'scheduled_at').startsWith(_todayKey()),
                    )
                    .toList(),
        );
        final next = _nextOneLineScheduleItem(scheduled);

        return _ShotPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ShotSectionHeader(
                title: 'رسائل One Line',
                subtitle:
                    'رسائل قصيرة تظهر كإشعارات تلقائية، ولا تحتاج أزرار صعوبة أو مراجعة داخلية.',
                icon: Icons.notifications_active_rounded,
                color: AppColors.midnight,
                trailing: _ShotDataPill(
                  label: 'اليوم',
                  value: loading ? '...' : scheduled.length.toString(),
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.midnight.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        enabled
                            ? Icons.mark_unread_chat_alt_rounded
                            : Icons.notifications_off_rounded,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            next == null
                                ? enabled
                                      ? 'لا توجد رسائل One Line قادمة الآن'
                                      : 'إشعارات One Line متوقفة'
                                : text(
                                    next,
                                    'notification_body',
                                    fallback: text(next, 'front_content'),
                                  ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.midnight,
                              fontWeight: FontWeight.w900,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            next == null
                                ? scheduled.isNotEmpty && enabled
                                      ? 'انتهت مواعيد رسائل اليوم. راجع الجدول أدناه.'
                                      : text(
                                          asMap(notificationData['summary']),
                                          'message',
                                          fallback: scheduled.isNotEmpty
                                              ? 'انتهت مواعيد رسائل اليوم. راجع الجدول أدناه.'
                                              : 'راجع أيام الحزم وفترة النشاط والهدوء.',
                                        )
                                : '${text(next, 'notification_subtitle', fallback: text(next, 'pack_title'))} • ${_oneLineExactScheduleLabel(next)}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ShotTinyPill('المحفوظة: ${items.length}'),
                  _ShotTinyPill('الحد اليومي: $dailyLimit'),
                  _ShotTinyPill('كل $frequency دقيقة'),
                  if (offline) _ShotTinyPill('من آخر نسخة محفوظة'),
                  _ShotTinyPill(
                    localScheduled.isNotEmpty
                        ? 'حالة الجدولة على الجهاز'
                        : enabled
                        ? 'الجدولة تلقائية'
                        : 'متوقف',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _OneLineScheduleList(items: scheduled, enabled: enabled),
              const SizedBox(height: 14),
              _OneLineManualRescheduleButton(enabled: enabled),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => showMoeenBottomSheet<void>(
                  context: context,
                  title: 'إعدادات رسائل One Line',
                  icon: Icons.notifications_active_rounded,
                  color: AppColors.midnight,
                  child: const _OneLineNotificationSettingsSheet(),
                ),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('تعديل إعدادات One Line'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OneLineManualRescheduleButton extends ConsumerStatefulWidget {
  const _OneLineManualRescheduleButton({required this.enabled});

  final bool enabled;

  @override
  ConsumerState<_OneLineManualRescheduleButton> createState() =>
      _OneLineManualRescheduleButtonState();
}

class _OneLineManualRescheduleButtonState
    extends ConsumerState<_OneLineManualRescheduleButton> {
  bool _rescheduling = false;

  Future<void> _reschedule() async {
    final confirmed = await showMoeenConfirmDialog(
      context: context,
      title: 'إعادة جدولة إشعارات اليوم',
      message:
          'سيتم إلغاء مواعيد One Line الحالية وبناء جدول جديد لليوم حسب آخر إعداداتك.',
      confirmLabel: 'إعادة الجدولة',
      cancelLabel: 'إلغاء',
      icon: Icons.restart_alt_rounded,
      color: AppColors.midnight,
    );
    if (!confirmed || !mounted) return;

    setState(() => _rescheduling = true);
    try {
      await PushNotificationService.requestOneLineNotificationPermissions();
      final count = await ref
          .read(oneLineNotificationSchedulerProvider)
          .sync(force: true);
      final saved = await ref.read(flashcardLocalStoreProvider).load();
      final failed = saved.oneLineScheduledItems
          .where(
            (item) =>
                item['schedule_status'] == 'failed' ||
                item['schedule_status'] == 'blocked',
          )
          .length;
      ref.invalidate(_flashcardOneLineNotificationsProvider);
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'تم التحقق من جدولة $count إشعار قادم.${failed > 0 ? ' تعذرت جدولة $failed إشعارات.' : ''}'
                : failed > 0
                ? 'لم تكتمل الجدولة. تحقق من سماح الإشعارات وأعد المحاولة.'
                : 'تم تحديث الجدول، ولا توجد مواعيد قادمة ضمن الإعدادات الحالية.',
          ),
          backgroundColor: failed > 0 ? AppColors.warning : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذرت إعادة جدولة One Line: $error'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _rescheduling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: widget.enabled && !_rescheduling ? _reschedule : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.midnight,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.slate200,
        disabledForegroundColor: AppColors.slate500,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: _rescheduling
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.restart_alt_rounded),
      label: Text(
        _rescheduling
            ? 'جاري إعادة الجدولة...'
            : widget.enabled
            ? 'إعادة جدولة إشعارات اليوم'
            : 'إشعارات One Line متوقفة',
      ),
    );
  }
}

class _OneLineScheduleList extends StatefulWidget {
  const _OneLineScheduleList({required this.items, required this.enabled});

  final List<Map<String, dynamic>> items;
  final bool enabled;

  @override
  State<_OneLineScheduleList> createState() => _OneLineScheduleListState();
}

class _OneLineScheduleListState extends State<_OneLineScheduleList> {
  static const _pageSize = 10;
  int _visibleCount = _pageSize;

  @override
  void didUpdateWidget(covariant _OneLineScheduleList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.enabled != widget.enabled) {
      _visibleCount = _pageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const _OneLineScheduleEmpty(
        icon: Icons.notifications_off_rounded,
        message: 'إشعارات One Line متوقفة من الإعدادات.',
      );
    }
    if (widget.items.isEmpty) {
      return const _OneLineScheduleEmpty(
        icon: Icons.event_busy_rounded,
        message: 'لا يوجد جدول محفوظ لرسائل اليوم حتى الآن.',
      );
    }

    final visibleItems = widget.items.take(_visibleCount).toList();
    final remainingCount = widget.items.length - visibleItems.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'جدول إشعارات اليوم',
                style: TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '${visibleItems.length} من ${widget.items.length}',
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...visibleItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final status = _oneLineScheduleStatus(item);
          final color = _oneLineScheduleStatusColor(status);
          return Container(
            margin: EdgeInsets.only(top: index == 0 ? 0 : 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _formatFlashcardTime12(
                      _parseFlashcardDateTime(text(item, 'scheduled_at')) ??
                          DateTime.now(),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text(
                          item,
                          'notification_body',
                          fallback: text(item, 'front_content'),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _oneLineExactScheduleLabel(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (remainingCount > 0) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _visibleCount = (_visibleCount + _pageSize).clamp(
                  0,
                  widget.items.length,
                );
              });
            },
            icon: const Icon(Icons.expand_more_rounded),
            label: Text(
              remainingCount > _pageSize
                  ? 'عرض المزيد 10'
                  : 'عرض الباقي ($remainingCount)',
            ),
          ),
        ],
      ],
    );
  }
}

class _OneLineScheduleEmpty extends StatelessWidget {
  const _OneLineScheduleEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.slate500, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OneLineNotificationSettingsSheet extends ConsumerStatefulWidget {
  const _OneLineNotificationSettingsSheet();

  @override
  ConsumerState<_OneLineNotificationSettingsSheet> createState() =>
      _OneLineNotificationSettingsSheetState();
}

class _OneLineNotificationSettingsSheetState
    extends ConsumerState<_OneLineNotificationSettingsSheet> {
  bool _saving = false;
  late Future<Map<String, dynamic>> _future;
  int? _dailyLimitDraft;
  int? _frequencyDraft;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await ref
        .read(studentContentRepositoryProvider)
        .flashcardSettings();
    await ref.read(flashcardLocalStoreProvider).cacheSettings(data);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final settings = asMap(snapshot.data?['settings']);
        if (snapshot.hasError) {
          return _FlashcardsQueueWarning(
            message: 'تعذر تحميل إعدادات رسائل One Line.',
            onRetry: () => setState(() => _future = _load()),
          );
        }
        if (settings.isEmpty &&
            snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final enabled = _boolValueFallback(
          settings,
          'one_line_notifications_enabled',
          true,
        );
        final dailyLimit = number(
          settings,
          'one_line_daily_limit',
          fallback: number(settings, 'daily_card_limit', fallback: 5),
        ).toInt();
        final frequency = number(
          settings,
          'one_line_frequency_minutes',
          fallback: number(
            settings,
            'smart_review_frequency_minutes',
            fallback: 30,
          ),
        ).toInt();
        _dailyLimitDraft ??= dailyLimit;
        _frequencyDraft ??= frequency;

        final activeFrom = _cleanTime(
          text(settings, 'one_line_active_from_time'),
        );
        final activeTo = _cleanTime(text(settings, 'one_line_active_to_time'));
        final quietStart = _cleanTime(text(settings, 'one_line_quiet_start'));
        final quietEnd = _cleanTime(text(settings, 'one_line_quiet_end'));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.midnight.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.midnight.withValues(alpha: 0.12),
                ),
              ),
              child: const Text(
                'هذه الإعدادات تخص رسائل One Line فقط. الكروت التفاعلية تبقى في مراجعة اليوم ولا تتأثر بهذه الإعدادات.',
                style: TextStyle(
                  color: AppColors.slate600,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              value: enabled,
              onChanged: _saving
                  ? null
                  : (value) => _update(oneLineNotificationsEnabled: value),
              title: const Text(
                'تفعيل إشعارات One Line',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('تتم الجدولة تلقائيًا بدون زر إضافي.'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SmartReviewNumberField(
                    label: 'عدد الرسائل يوميًا',
                    value: _dailyLimitDraft!,
                    suffix: 'رسالة',
                    onChangedValue: (value) => _dailyLimitDraft = value,
                    onSubmitted: (value) => _dailyLimitDraft = value,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmartReviewNumberField(
                    label: 'الفاصل الزمني',
                    value: _frequencyDraft!,
                    suffix: 'دقيقة',
                    onChangedValue: (value) => _frequencyDraft = value,
                    onSubmitted: (value) => _frequencyDraft = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ScheduleTimeField(
                    label: 'بداية الإشعارات',
                    value: activeFrom,
                    onChanged: (value) =>
                        _update(oneLineActiveFromTime: value ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScheduleTimeField(
                    label: 'نهاية الإشعارات',
                    value: activeTo,
                    onChanged: (value) =>
                        _update(oneLineActiveToTime: value ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ScheduleTimeField(
                    label: 'بداية الهدوء',
                    value: quietStart,
                    onChanged: (value) =>
                        _update(oneLineQuietStart: value ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScheduleTimeField(
                    label: 'نهاية الهدوء',
                    value: quietEnd,
                    onChanged: (value) => _update(oneLineQuietEnd: value ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      final saved = await _update(
                        oneLineDailyLimit: _dailyLimitDraft,
                        oneLineFrequencyMinutes: _frequencyDraft,
                      );
                      if (saved && context.mounted) Navigator.of(context).pop();
                    },
              icon: const Icon(Icons.check_rounded),
              label: const Text('حفظ الإعدادات'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _update({
    bool? oneLineNotificationsEnabled,
    int? oneLineDailyLimit,
    int? oneLineFrequencyMinutes,
    String? oneLineActiveFromTime,
    String? oneLineActiveToTime,
    String? oneLineQuietStart,
    String? oneLineQuietEnd,
  }) async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        if (oneLineNotificationsEnabled != null)
          'one_line_notifications_enabled': oneLineNotificationsEnabled,
        if (oneLineDailyLimit != null)
          'one_line_daily_limit': oneLineDailyLimit,
        if (oneLineFrequencyMinutes != null)
          'one_line_frequency_minutes': oneLineFrequencyMinutes,
        if (oneLineActiveFromTime != null)
          'one_line_active_from_time': oneLineActiveFromTime.isEmpty
              ? null
              : oneLineActiveFromTime,
        if (oneLineActiveToTime != null)
          'one_line_active_to_time': oneLineActiveToTime.isEmpty
              ? null
              : oneLineActiveToTime,
        if (oneLineQuietStart != null)
          'one_line_quiet_start': oneLineQuietStart.isEmpty
              ? null
              : oneLineQuietStart,
        if (oneLineQuietEnd != null)
          'one_line_quiet_end': oneLineQuietEnd.isEmpty
              ? null
              : oneLineQuietEnd,
      };
      if (payload.isEmpty) return true;
      final data = await _saveFlashcardSettings(context, ref, payload);
      if (data == null || !mounted) return false;
      final scheduler = ref.read(oneLineNotificationSchedulerProvider);
      try {
        await scheduler.sync(force: true);
      } on ApiException catch (error) {
        if (mounted)
          await showMoeenInfoDialog(
            context: context,
            title: 'تم الحفظ وتعذّر تحديث الجدول',
            message: error.message,
            icon: Icons.error_outline_rounded,
            color: AppColors.rose,
          );
        return false;
      } on PlatformException catch (error) {
        if (mounted)
          await showMoeenInfoDialog(
            context: context,
            title: 'تم الحفظ وتعذّر تجهيز الإشعارات',
            message: error.message ?? 'راجع أذونات الإشعارات ثم أعد المحاولة.',
            icon: Icons.notifications_off_outlined,
            color: AppColors.rose,
          );
        return false;
      }
      if (!mounted) return true;
      setState(() {
        _future = Future.value(data);
      });
      ref.invalidate(_flashcardSettingsProvider);
      ref.invalidate(_flashcardOneLineNotificationsProvider);
      ref.invalidate(_flashcardsProvider);
      return true;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SmartReviewNumberField extends StatefulWidget {
  const _SmartReviewNumberField({
    required this.label,
    required this.value,
    required this.suffix,
    this.onChangedValue,
    required this.onSubmitted,
  });

  final String label;
  final int value;
  final String suffix;
  final ValueChanged<int>? onChangedValue;
  final ValueChanged<int> onSubmitted;

  @override
  State<_SmartReviewNumberField> createState() =>
      _SmartReviewNumberFieldState();
}

class _SmartReviewNumberFieldState extends State<_SmartReviewNumberField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  int? _lastSubmitted;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _lastSubmitted = widget.value;
  }

  @override
  void didUpdateWidget(covariant _SmartReviewNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        widget.value != int.tryParse(_controller.text.trim())) {
      _controller.text = widget.value.toString();
      _lastSubmitted = widget.value;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSubmit() {
    final parsed = _parseReviewNumber(_controller.text);
    widget.onChangedValue?.call(parsed ?? 0);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _submit);
  }

  void _submit() {
    final parsed = _parseReviewNumber(_controller.text) ?? 0;
    if (parsed == _lastSubmitted) return;
    _lastSubmitted = parsed;
    widget.onSubmitted(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      onChanged: (_) => _scheduleSubmit(),
      onFieldSubmitted: (value) {
        _debounce?.cancel();
        _submit();
      },
    );
  }
}

class _SmartReviewSelect extends StatelessWidget {
  const _SmartReviewSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> options;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: options
          .map(
            (item) => DropdownMenuItem<int>(
              value: item,
              child: Text('$item $suffix'),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _SmartReviewFrequencySelect extends StatelessWidget {
  const _SmartReviewFrequencySelect({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = switch (value) {
      10 => 'high',
      30 => 'medium',
      45 => 'low',
      60 => 'rare',
      _ => 'custom',
    };
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: 'نسبة التكرار',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        const DropdownMenuItem(value: 'high', child: Text('عالي (10 د)')),
        const DropdownMenuItem(value: 'medium', child: Text('متوسط (30 د)')),
        const DropdownMenuItem(value: 'low', child: Text('منخفض (45 د)')),
        const DropdownMenuItem(value: 'rare', child: Text('نادر (ساعة)')),
        DropdownMenuItem(
          value: 'custom',
          child: Text(selected == 'custom' ? 'مخصص ($value د)' : 'مخصص'),
        ),
      ],
      onChanged: (option) async {
        final minutes = switch (option) {
          'high' => 10,
          'medium' => 30,
          'low' => 45,
          'rare' => 60,
          'custom' => await _askCustomMinutes(context, value),
          _ => null,
        };
        if (minutes != null && minutes > 0) onChanged(minutes);
      },
    );
  }

  Future<int?> _askCustomMinutes(BuildContext context, int current) async {
    final controller = TextEditingController(text: current.toString());
    try {
      return await showMoeenBottomSheet<int>(
        context: context,
        title: 'تكرار مخصص',
        icon: Icons.tune_rounded,
        color: AppColors.royalBlue,
        child: _CustomFrequencyForm(controller: controller),
      );
    } finally {
      controller.dispose();
    }
  }
}

class _CustomFrequencyForm extends StatelessWidget {
  const _CustomFrequencyForm({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'حدد عدد الدقائق بين كل ظهور للكرت الذكي.',
          style: TextStyle(
            color: AppColors.slate600,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'الوقت بالدقائق',
            suffixText: 'دقيقة',
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value == null || value <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('اكتب عدد دقائق صحيح.')),
              );
              return;
            }
            Navigator.of(context).pop(value);
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('اعتماد التكرار'),
        ),
      ],
    );
  }
}
