// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

Future<void> _showCreatePackSheet(BuildContext context, WidgetRef ref) async {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  String scheduleMode = 'daily';
  String color = '#4338ca';
  bool notifications = true;
  String packPriority = 'medium';
  String restartMode = 'none';
  final scheduleWeekdays = <int>{};

  final ok = await showMoeenBottomSheet<bool>(
    context: context,
    title: 'حزمة جديدة',
    icon: Icons.bolt_rounded,
    color: AppColors.royalBlue,
    child: StatefulBuilder(
      builder: (sheetContext, setLocal) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: title,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'اكتب اسم الحزمة.'
                  : null,
              decoration: const InputDecoration(labelText: 'اسم الحزمة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'وصف مختصر'),
            ),
            const SizedBox(height: 12),
            if (false)
              DropdownButtonFormField<String>(
                value: 'one_line',
                decoration: const InputDecoration(labelText: 'نوع البطاقات'),
                items: const [
                  DropdownMenuItem(
                    value: 'one_line',
                    child: Text('One Line Shot'),
                  ),
                  DropdownMenuItem(
                    value: 'flash_card',
                    child: Text('بطاقة أمام/خلف'),
                  ),
                  DropdownMenuItem(value: 'qa', child: Text('سؤال وجواب')),
                  DropdownMenuItem(
                    value: 'mcq',
                    child: Text('اختيار من متعدد'),
                  ),
                ],
                onChanged: null,
              ),
            const SizedBox(height: 16),
            _ColorPickerRow(
              selectedColor: color,
              onChanged: (value) => setLocal(() => color = value),
            ),
            const SizedBox(height: 12),
            _PackScheduleSection(
              smartReviewEnabled: notifications,
              scheduleMode: scheduleMode,
              scheduleWeekdays: scheduleWeekdays,
              packPriority: packPriority,
              restartMode: restartMode,
              onSmartChanged: (value) => setLocal(() => notifications = value),
              onScheduleModeChanged: (value) =>
                  setLocal(() => scheduleMode = value),
              onWeekdayToggle: (day) => setLocal(() {
                scheduleWeekdays.contains(day)
                    ? scheduleWeekdays.remove(day)
                    : scheduleWeekdays.add(day);
              }),
              onPriorityChanged: (value) =>
                  setLocal(() => packPriority = value),
              onRestartModeChanged: (value) =>
                  setLocal(() => restartMode = value),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(sheetContext, true);
              },
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    ),
  );
  if (ok != true || title.text.trim().isEmpty) return;
  if (!context.mounted) return;
  await _runSnack(
    context,
    () => ref.read(studentContentRepositoryProvider).createFlashcardPack({
      'title': title.text.trim(),
      'description': description.text.trim(),
      'color': color,
      'display_mode': 'one_line',
      'notifications_enabled': notifications,
      ..._packSchedulePayload(
        scheduleMode: scheduleMode,
        scheduleWeekdays: scheduleWeekdays,
        packPriority: packPriority,
        smartReviewEnabled: notifications,
        restartMode: restartMode,
      ),
    }),
    onDone: () => ref.invalidate(_flashcardsProvider),
  );
}

Future<void> _showEditPack(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> pack, {
  VoidCallback? onDone,
}) async {
  final formKey = GlobalKey<FormState>();
  final id = number(pack, 'id').toInt();
  final title = TextEditingController(text: text(pack, 'title'));
  final description = TextEditingController(text: text(pack, 'description'));
  String scheduleMode = text(
    pack,
    'schedule_mode',
    fallback: _scheduleModeFromRepeatCycle(text(pack, 'repeat_cycle')),
  );
  String color = text(pack, 'color', fallback: '#4338ca');
  bool notifications = _boolValueFallback(
    pack,
    'smart_review_enabled',
    boolValue(pack, 'notifications_enabled'),
  );
  String packPriority = text(pack, 'pack_priority', fallback: 'medium');
  String restartMode = text(pack, 'restart_mode', fallback: 'none');
  final scheduleWeekdays = asList(
    pack['schedule_weekdays'],
  ).map((day) => int.tryParse('$day')).whereType<int>().toSet();

  final ok = await showMoeenBottomSheet<bool>(
    context: context,
    title: 'تعديل الحزمة',
    icon: Icons.edit_rounded,
    color: Color(_parseHex(color)),
    child: StatefulBuilder(
      builder: (sheetContext, setLocal) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: title,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'اكتب اسم الحزمة.'
                  : null,
              decoration: const InputDecoration(labelText: 'اسم الحزمة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'وصف مختصر'),
            ),
            const SizedBox(height: 12),
            if (false)
              DropdownButtonFormField<String>(
                value: 'one_line',
                decoration: const InputDecoration(labelText: 'نوع البطاقات'),
                items: const [
                  DropdownMenuItem(
                    value: 'one_line',
                    child: Text('One Line Shot'),
                  ),
                  DropdownMenuItem(
                    value: 'flash_card',
                    child: Text('بطاقة أمام/خلف'),
                  ),
                  DropdownMenuItem(value: 'qa', child: Text('سؤال وجواب')),
                  DropdownMenuItem(
                    value: 'mcq',
                    child: Text('اختيار من متعدد'),
                  ),
                ],
                onChanged: null,
              ),
            const SizedBox(height: 16),
            _ColorPickerRow(
              selectedColor: color,
              onChanged: (value) => setLocal(() => color = value),
            ),
            const SizedBox(height: 12),
            _PackScheduleSection(
              smartReviewEnabled: notifications,
              scheduleMode: scheduleMode,
              scheduleWeekdays: scheduleWeekdays,
              packPriority: packPriority,
              restartMode: restartMode,
              onSmartChanged: (value) => setLocal(() => notifications = value),
              onScheduleModeChanged: (value) =>
                  setLocal(() => scheduleMode = value),
              onWeekdayToggle: (day) => setLocal(() {
                scheduleWeekdays.contains(day)
                    ? scheduleWeekdays.remove(day)
                    : scheduleWeekdays.add(day);
              }),
              onPriorityChanged: (value) =>
                  setLocal(() => packPriority = value),
              onRestartModeChanged: (value) =>
                  setLocal(() => restartMode = value),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(sheetContext, true);
              },
              child: const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    ),
  );

  if (ok != true || title.text.trim().isEmpty) return;
  if (!context.mounted) return;

  await _runSnack(
    context,
    () => ref.read(studentContentRepositoryProvider).updateFlashcardPack(id, {
      'title': title.text.trim(),
      'description': description.text.trim(),
      'color': color,
      'display_mode': text(pack, 'display_mode', fallback: 'one_line'),
      'notifications_enabled': notifications,
      ..._packSchedulePayload(
        scheduleMode: scheduleMode,
        scheduleWeekdays: scheduleWeekdays,
        packPriority: packPriority,
        smartReviewEnabled: notifications,
        restartMode: restartMode,
      ),
    }),
    onDone: () {
      ref.invalidate(_flashcardsProvider);
      if (onDone != null) onDone();
    },
  );
}

class _PackScheduleSection extends StatelessWidget {
  const _PackScheduleSection({
    required this.smartReviewEnabled,
    required this.scheduleMode,
    required this.scheduleWeekdays,
    this.activeFromTime,
    this.activeToTime,
    this.quietStart,
    this.quietEnd,
    this.dailyLimit,
    required this.packPriority,
    this.frequency,
    required this.restartMode,
    required this.onSmartChanged,
    required this.onScheduleModeChanged,
    required this.onWeekdayToggle,
    this.onActiveFromChanged,
    this.onActiveToChanged,
    this.onQuietStartChanged,
    this.onQuietEndChanged,
    required this.onPriorityChanged,
    required this.onRestartModeChanged,
  });

  final bool smartReviewEnabled;
  final String scheduleMode;
  final Set<int> scheduleWeekdays;
  final String? activeFromTime;
  final String? activeToTime;
  final String? quietStart;
  final String? quietEnd;
  final TextEditingController? dailyLimit;
  final String packPriority;
  final TextEditingController? frequency;
  final String restartMode;
  final ValueChanged<bool> onSmartChanged;
  final ValueChanged<String> onScheduleModeChanged;
  final ValueChanged<int> onWeekdayToggle;
  final ValueChanged<String?>? onActiveFromChanged;
  final ValueChanged<String?>? onActiveToChanged;
  final ValueChanged<String?>? onQuietStartChanged;
  final ValueChanged<String?>? onQuietEndChanged;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<String> onRestartModeChanged;

  static const _weekdays = [
    (6, 'السبت'),
    (0, 'الأحد'),
    (1, 'الاثنين'),
    (2, 'الثلاثاء'),
    (3, 'الأربعاء'),
    (4, 'الخميس'),
    (5, 'الجمعة'),
  ];

  @override
  Widget build(BuildContext context) {
    final showDays = scheduleMode == 'weekdays' || scheduleMode == 'weekly';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.royalBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'جدولة الظهور',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(
                value: smartReviewEnabled,
                activeColor: AppColors.royalBlue,
                onChanged: onSmartChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: scheduleMode,
            decoration: const InputDecoration(labelText: 'نمط الجدولة'),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('يوميًا')),
              DropdownMenuItem(value: 'weekdays', child: Text('أيام محددة')),
              DropdownMenuItem(value: 'weekly', child: Text('أسبوعيًا')),
              DropdownMenuItem(value: 'monthly', child: Text('شهريًا')),
              DropdownMenuItem(value: 'manual', child: Text('يدوي فقط')),
            ],
            onChanged: (value) => onScheduleModeChanged(value ?? 'daily'),
          ),
          if (showDays) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weekdays.map((entry) {
                final selected = scheduleWeekdays.contains(entry.$1);
                return FilterChip(
                  selected: selected,
                  label: Text(entry.$2),
                  onSelected: (_) => onWeekdayToggle(entry.$1),
                  selectedColor: AppColors.royalBlue.withValues(alpha: 0.16),
                  checkmarkColor: AppColors.royalBlue,
                );
              }).toList(),
            ),
          ],
          if (false) const SizedBox(height: 12),
          if (false)
            Row(
              children: [
                Expanded(
                  child: _ScheduleTimeField(
                    label: 'من وقت',
                    value: activeFromTime,
                    onChanged: onActiveFromChanged ?? (_) {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScheduleTimeField(
                    label: 'إلى وقت',
                    value: activeToTime,
                    onChanged: onActiveToChanged ?? (_) {},
                  ),
                ),
              ],
            ),
          if (false) const SizedBox(height: 12),
          if (false)
            Row(
              children: [
                Expanded(
                  child: _ScheduleTimeField(
                    label: 'بداية الهدوء',
                    value: quietStart,
                    onChanged: onQuietStartChanged ?? (_) {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScheduleTimeField(
                    label: 'نهاية الهدوء',
                    value: quietEnd,
                    onChanged: onQuietEndChanged ?? (_) {},
                  ),
                ),
              ],
            ),
          if (false) const SizedBox(height: 12),
          if (false)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: dailyLimit,
                    keyboardType: TextInputType.number,
                    validator: _positiveNumberValidator,
                    decoration: const InputDecoration(
                      labelText: 'كروت اليوم',
                      suffixText: 'كرت',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: frequency,
                    keyboardType: TextInputType.number,
                    validator: _positiveNumberValidator,
                    decoration: const InputDecoration(
                      labelText: 'تكرار الظهور',
                      suffixText: 'دقيقة',
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: packPriority,
            decoration: const InputDecoration(labelText: 'أولوية الحزمة'),
            items: const [
              DropdownMenuItem(value: 'high', child: Text('عالية')),
              DropdownMenuItem(value: 'medium', child: Text('متوسطة')),
              DropdownMenuItem(value: 'low', child: Text('منخفضة')),
            ],
            onChanged: (value) => onPriorityChanged(value ?? 'medium'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: restartMode,
            decoration: const InputDecoration(labelText: 'عند انتهاء اليوم'),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('لا تعيد الكروت')),
              DropdownMenuItem(value: 'all', child: Text('أعد كل الكروت')),
              DropdownMenuItem(
                value: 'hard_only',
                child: Text('أعد الصعبة فقط'),
              ),
              DropdownMenuItem(
                value: 'wrong_only',
                child: Text('أعد الخاطئة فقط'),
              ),
            ],
            onChanged: (value) => onRestartModeChanged(value ?? 'none'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTimeField extends StatelessWidget {
  const _ScheduleTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: _formatScheduleTime12(value)),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null && value!.isNotEmpty)
              IconButton(
                tooltip: 'مسح',
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close_rounded),
              ),
            const Icon(Icons.schedule_rounded),
            const SizedBox(width: 8),
          ],
        ),
      ),
      onTap: () async {
        final parts = (value ?? '').split(':');
        final initial = parts.length >= 2
            ? TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 8,
                minute: int.tryParse(parts[1]) ?? 0,
              )
            : const TimeOfDay(hour: 8, minute: 0);
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: false),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
        if (picked == null) return;
        onChanged(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
        );
      },
    );
  }
}

String _formatScheduleTime12(String? value) {
  final clean = _cleanTime(value ?? '');
  if (clean == null || clean.isEmpty) return '';
  final parts = clean.split(':');
  if (parts.length < 2) return clean;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return clean;
  final suffix = hour >= 12 ? 'م' : 'ص';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '${hour12.toString()}:${minute.toString().padLeft(2, '0')} $suffix';
}

String? _positiveNumberValidator(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed <= 0) return 'اكتب رقمًا صحيحًا.';
  return null;
}

Map<String, dynamic> _packSchedulePayload({
  required String scheduleMode,
  required Set<int> scheduleWeekdays,
  required String packPriority,
  required bool smartReviewEnabled,
  required String restartMode,
}) {
  return {
    'schedule_mode': scheduleMode,
    'schedule_weekdays': scheduleWeekdays.toList()..sort(),
    'pack_priority': packPriority,
    'smart_review_enabled': smartReviewEnabled,
    'restart_mode': restartMode,
    'repeat_cycle': _repeatCycleFromScheduleMode(scheduleMode),
  };
}

String _scheduleModeFromRepeatCycle(String value) {
  return switch (value) {
    'weekly' => 'weekly',
    'monthly' => 'monthly',
    _ => 'daily',
  };
}

String _repeatCycleFromScheduleMode(String value) {
  return switch (value) {
    'weekly' => 'weekly',
    'monthly' => 'monthly',
    _ => 'daily',
  };
}

String? _cleanTime(String value) {
  if (value.isEmpty) return null;
  return value.length >= 5 ? value.substring(0, 5) : value;
}

String _packScheduleSummary(Map<String, dynamic> pack) {
  final mode = text(
    pack,
    'schedule_mode',
    fallback: _scheduleModeFromRepeatCycle(text(pack, 'repeat_cycle')),
  );
  final priority = text(pack, 'pack_priority', fallback: 'medium');
  final enabled = _boolValueFallback(
    pack,
    'smart_review_enabled',
    boolValue(pack, 'notifications_enabled'),
  );
  final from = _cleanTime(text(pack, 'active_from_time'));
  final to = _cleanTime(text(pack, 'active_to_time'));
  final limit = number(
    pack,
    'daily_card_limit',
    fallback: number(pack, 'daily_notification_count', fallback: 5),
  ).toInt();
  final frequency = number(
    pack,
    'smart_review_frequency_minutes',
    fallback: 30,
  ).toInt();
  final window = from != null && to != null ? ' من $from إلى $to' : '';
  return '${_scheduleModeLabel(mode)}$window • $limit كروت • كل $frequency دقيقة';
}

String _scheduleModeLabel(String value) {
  return switch (value) {
    'weekdays' => 'أيام محددة',
    'weekly' => 'أسبوعيًا',
    'monthly' => 'شهريًا',
    'manual' => 'يدوي فقط',
    _ => 'يوميًا',
  };
}

String _packPriorityLabel(String value) {
  return switch (value) {
    'high' => 'أولوية عالية',
    'low' => 'أولوية منخفضة',
    _ => 'أولوية متوسطة',
  };
}

bool _boolValueFallback(Map<String, dynamic> map, String key, bool fallback) {
  if (!map.containsKey(key) || map[key] == null) return fallback;
  return boolValue(map, key);
}
