// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class _FlashcardSmartReviewSettingsCard extends ConsumerStatefulWidget {
  const _FlashcardSmartReviewSettingsCard();

  @override
  ConsumerState<_FlashcardSmartReviewSettingsCard> createState() =>
      _FlashcardSmartReviewSettingsCardState();
}

class _FlashcardSmartReviewSettingsCardState
    extends ConsumerState<_FlashcardSmartReviewSettingsCard> {
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
        final settings = asMap(effectiveData?['settings']);
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
                onChanged: (value) => _update(enabled: value),
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
    final payload = <String, dynamic>{
      if (enabled != null) 'smart_review_enabled': enabled,
      if (dailyLimit != null) 'daily_card_limit': dailyLimit,
      if (snoozeMinutes != null)
        'smart_review_frequency_minutes': snoozeMinutes,
      if (autoRestart != null) 'auto_restart_enabled': autoRestart,
    };
    final data = await ref
        .read(studentContentRepositoryProvider)
        .updateFlashcardSettings(payload);
    await ref.read(flashcardLocalStoreProvider).cacheSettings(data);
    await ref
        .read(flashcardLocalStoreProvider)
        .applyServerSmartReviewSettings(data, clearSnooze: true);
    if (enabled == false) {
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
        final settings = asMap(effectiveData?['settings']);
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
                            'ميزة ذكية تعرض لك كرت مراجعة واحد تلقائياً في الواجهة عند فتح التطبيق أو العودة إليه لمساعدتك على الاستمرار.',
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
                        value: dailyLimit,
                        suffix: 'مرات',
                        onChangedValue: (value) => _dailyLimitDraft = value,
                        onSubmitted: (value) => _update(dailyLimit: value),
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
                        value: frequency,
                        suffix: 'دقيقة',
                        onChangedValue: (value) => _frequencyDraft = value,
                        onSubmitted: (value) => _update(snoozeMinutes: value),
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
                onPressed: () async {
                  await _update(
                    dailyLimit: _dailyLimitDraft,
                    snoozeMinutes: _frequencyDraft,
                  );
                  if (context.mounted) Navigator.of(context).pop();
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

  Future<void> _update({
    bool? enabled,
    int? dailyLimit,
    int? snoozeMinutes,
    bool? autoRestart,
    String? activeFromTime,
    String? activeToTime,
    String? quietStart,
    String? quietEnd,
  }) async {
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
    if (payload.isEmpty) return;
    final data = await ref
        .read(studentContentRepositoryProvider)
        .updateFlashcardSettings(payload);
    await ref.read(flashcardLocalStoreProvider).cacheSettings(data);
    await ref
        .read(flashcardLocalStoreProvider)
        .applyServerSmartReviewSettings(data, clearSnooze: true);
    if (enabled == false) {
      await PushNotificationService.cancelFlashcardSmartReview();
    } else if (enabled == true ||
        snoozeMinutes != null ||
        activeFromTime != null ||
        activeToTime != null ||
        quietStart != null ||
        quietEnd != null) {
      await _scheduleNextSmartReviewNotification(ref);
    }
    if (!mounted) return;
    setState(() {
      _sheetFuture = _loadSettings();
    });
    ref.invalidate(_flashcardSettingsProvider);
    ref.invalidate(_flashcardDailyQueueProvider);
    ref.invalidate(_flashcardsProvider);
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
    _submit();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSubmit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed != null && parsed > 0) widget.onChangedValue?.call(parsed);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _submit);
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed <= 0 || parsed == _lastSubmitted) return;
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
