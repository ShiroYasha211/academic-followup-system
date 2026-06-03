part of '../student_content_screens.dart';

Future<void> _showEditStudyItem(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> item,
  String tab,
) async {
  final id = number(item, 'id').toInt();
  final title = TextEditingController(
    text: text(item, 'custom_title', fallback: text(item, 'title')),
  );
  DateTime? selectedDate = DateTime.tryParse(text(item, 'scheduled_date'));
  final note = TextEditingController(text: text(item, 'note'));
  final formKey = GlobalKey<FormState>();
  String priority = ['high', 'medium', 'low'].contains(text(item, 'priority'))
      ? text(item, 'priority')
      : 'medium';
  String status =
      [
        'pending',
        'in_progress',
        'completed',
        'overdue',
      ].contains(text(item, 'status'))
      ? text(item, 'status')
      : 'pending';
  final reminderDraft = _ReminderScheduleDraft.fromItem(item);

  final ok = await showMoeenBottomSheet<bool>(
    context: context,
    title: 'تعديل عنصر الدراسة',
    icon: Icons.edit_note_rounded,
    color: _studyTabColor(tab),
    child: StatefulBuilder(
      builder: (sheetContext, setDialogState) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: title,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'اكتب عنوان العنصر.'
                  : null,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setDialogState(() => selectedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: AppColors.slate400,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate == null
                          ? 'اختر التاريخ'
                          : dateOnly(selectedDate.toString()),
                      style: TextStyle(
                        color: selectedDate == null
                            ? AppColors.slate400
                            : AppColors.midnight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'الأولوية'),
                    items: const [
                      DropdownMenuItem(value: 'high', child: Text('عالية')),
                      DropdownMenuItem(value: 'medium', child: Text('متوسطة')),
                      DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => priority = value ?? 'medium'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'الحالة'),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('قيد الانتظار'),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('قيد التنفيذ'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('مكتمل'),
                      ),
                      DropdownMenuItem(value: 'overdue', child: Text('متأخر')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => status = value ?? 'pending'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ReminderScheduleFields(
              draft: reminderDraft,
              color: _studyTabColor(tab),
              selectedDate: selectedDate,
              setDialogState: setDialogState,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: note,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(sheetContext, true);
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'حفظ التعديلات الآن',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _studyTabColor(tab),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (ok != true) return;
  try {
    final message = await ref
        .read(studentContentRepositoryProvider)
        .updateStudyItem(id, {
          'title': title.text.trim(),
          'scheduled_date': selectedDate?.toIso8601String().substring(0, 10),
          'note': note.text.trim(),
          'priority': priority,
          'status': status,
          ...reminderDraft.toPayload(selectedDate),
        });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
      ref.invalidate(_studyProvider(tab));
    }
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

Future<void> _deleteStudyItem(
  BuildContext context,
  WidgetRef ref,
  int id,
  String tab,
) async {
  final ok = await showMoeenConfirmDialog(
    context: context,
    title: 'حذف العنصر',
    message:
        'هل تريد حذف هذا العنصر من مركز الدراسة؟ لا يمكن التراجع عن العملية.',
    confirmLabel: 'حذف',
    icon: Icons.delete_forever_rounded,
    danger: true,
  );
  if (!ok) return;
  try {
    await ref.read(studentContentRepositoryProvider).deleteStudyItem(id);
    ref.invalidate(_studyProvider(tab));
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _ReminderScheduleDraft {
  _ReminderScheduleDraft({
    this.type = 'none',
    TimeOfDay? time,
    Set<int>? weekdays,
    List<DateTime>? dates,
  }) : time = time ?? const TimeOfDay(hour: 8, minute: 0),
       weekdays = weekdays ?? <int>{},
       dates = dates ?? <DateTime>[];

  factory _ReminderScheduleDraft.fromItem(Map<String, dynamic> item) {
    final schedule = asMap(item['reminder_schedule']);
    var type = text(schedule, 'type', fallback: 'none');
    var time = _parseReminderTime(text(schedule, 'time'));
    final weekdays = asList(schedule['weekdays'])
        .map((day) => int.tryParse(day.toString()))
        .whereType<int>()
        .where((day) => day >= 0 && day <= 6)
        .toSet();
    final dates = asList(schedule['dates'])
        .map((date) => DateTime.tryParse(date.toString()))
        .whereType<DateTime>()
        .toList();

    final legacyReminderAt = DateTime.tryParse(text(item, 'reminder_at'));
    if ((type.isEmpty || type == 'none') && legacyReminderAt != null) {
      type = 'dates';
      time = TimeOfDay(
        hour: legacyReminderAt.hour,
        minute: legacyReminderAt.minute,
      );
      dates.add(legacyReminderAt);
    }

    return _ReminderScheduleDraft(
      type: ['none', 'daily', 'weekly', 'weekdays', 'dates'].contains(type)
          ? type
          : 'none',
      time: time,
      weekdays: weekdays,
      dates: dates,
    );
  }

  String type;
  TimeOfDay time;
  Set<int> weekdays;
  List<DateTime> dates;

  Map<String, dynamic> toPayload(DateTime? selectedDate) {
    final payload = <String, dynamic>{
      'reminder_schedule_type': type,
      'reminder_time': _formatReminderTime(time),
    };

    if (type == 'weekly') {
      payload['reminder_weekdays'] = [
        _apiWeekdayFromDate(selectedDate ?? DateTime.now()),
      ];
    } else if (type == 'weekdays') {
      payload['reminder_weekdays'] = weekdays.toList()..sort();
    } else if (type == 'dates') {
      final chosenDates = dates.isEmpty && selectedDate != null
          ? [selectedDate]
          : dates;
      payload['reminder_dates'] =
          chosenDates
              .map((date) => date.toIso8601String().substring(0, 10))
              .toSet()
              .toList()
            ..sort();
    }

    return payload;
  }
}

class _ReminderScheduleFields extends StatelessWidget {
  const _ReminderScheduleFields({
    required this.draft,
    required this.color,
    required this.selectedDate,
    required this.setDialogState,
  });

  final _ReminderScheduleDraft draft;
  final Color color;
  final DateTime? selectedDate;
  final StateSetter setDialogState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: color),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'جدولة التذكير',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: draft.type,
            decoration: const InputDecoration(
              labelText: 'متى يتكرر الإشعار؟',
              prefixIcon: Icon(Icons.repeat_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('بدون تذكير')),
              DropdownMenuItem(value: 'daily', child: Text('يوميًا')),
              DropdownMenuItem(value: 'weekly', child: Text('أسبوعيًا')),
              DropdownMenuItem(
                value: 'weekdays',
                child: Text('أيام محددة في الأسبوع'),
              ),
              DropdownMenuItem(
                value: 'dates',
                child: Text('تواريخ محددة من التقويم'),
              ),
            ],
            onChanged: (value) =>
                setDialogState(() => draft.type = value ?? 'none'),
          ),
          if (draft.type != 'none') ...[
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: draft.time,
                );
                if (picked != null) {
                  setDialogState(() => draft.time = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: color),
                    const SizedBox(width: 10),
                    Text(
                      'وقت وصول الإشعار: ${_formatTimeOfDayLabel(draft.time)}',
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (draft.type == 'weekly') ...[
            const SizedBox(height: 10),
            Text(
              'سيصل أسبوعيًا في يوم ${_weekdayName(_apiWeekdayFromDate(selectedDate ?? DateTime.now()))} حسب تاريخ العنصر.',
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (draft.type == 'weekdays') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weekdayOptions.map((entry) {
                final selected = draft.weekdays.contains(entry.$1);
                return FilterChip(
                  label: Text(entry.$2),
                  selected: selected,
                  selectedColor: color.withValues(alpha: 0.18),
                  checkmarkColor: color,
                  onSelected: (value) {
                    setDialogState(() {
                      if (value) {
                        draft.weekdays.add(entry.$1);
                      } else {
                        draft.weekdays.remove(entry.$1);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          if (draft.type == 'dates') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (date == null) return;
                setDialogState(() {
                  final exists = draft.dates.any(
                    (item) =>
                        item.year == date.year &&
                        item.month == date.month &&
                        item.day == date.day,
                  );
                  if (!exists) draft.dates.add(date);
                  draft.dates.sort();
                });
              },
              icon: const Icon(Icons.event_available_rounded),
              label: const Text(
                'إضافة تاريخ من التقويم',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (draft.dates.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: draft.dates.map((date) {
                  return InputChip(
                    label: Text(dateOnly(date.toString())),
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    onDeleted: () =>
                        setDialogState(() => draft.dates.remove(date)),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

const List<(int, String)> _weekdayOptions = [
  (0, 'الأحد'),
  (1, 'الاثنين'),
  (2, 'الثلاثاء'),
  (3, 'الأربعاء'),
  (4, 'الخميس'),
  (5, 'الجمعة'),
  (6, 'السبت'),
];

int _apiWeekdayFromDate(DateTime date) => date.weekday % 7;

String _weekdayName(int day) {
  return _weekdayOptions
      .firstWhere((entry) => entry.$1 == day, orElse: () => _weekdayOptions[0])
      .$2;
}

String _formatReminderTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatTimeOfDayLabel(TimeOfDay time) {
  final hour = time.hour;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'م' : 'ص';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$hour12:$minute $period';
}

TimeOfDay _parseReminderTime(String value) {
  final parts = value.split(':');
  if (parts.length >= 2) {
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    }
  }

  return const TimeOfDay(hour: 8, minute: 0);
}

String _gradeLabel(Map<String, dynamic> grade) {
  if (grade.isEmpty) return '-';
  return '${text(grade, 'score', fallback: '0')}/${text(grade, 'max_score', fallback: '0')}';
}

String _assignmentStatus(String status) {
  return switch (status) {
    'submitted' => 'تم التسليم',
    'missing' => 'متأخر',
    _ => 'متاح',
  };
}

String _attendanceLabel(String status) {
  final cleanStatus = status.trim().toLowerCase();
  return switch (cleanStatus) {
    'present' => 'حاضر',
    'absent' => 'غائب',
    'late' => 'متأخر',
    'excused' => 'معذور',
    'permitted' => 'مسموح',
    'exempted' => 'معفى',
    _ => status.isEmpty ? '-' : status,
  };
}

IconData _attendanceIcon(String status) {
  final cleanStatus = status.trim().toLowerCase();
  return switch (cleanStatus) {
    'present' => Icons.check_circle_rounded,
    'absent' => Icons.cancel_rounded,
    'late' => Icons.timer_rounded,
    'excused' || 'permitted' || 'exempted' => Icons.verified_user_rounded,
    _ => Icons.help_rounded,
  };
}

Color _attendanceColor(String status) {
  final cleanStatus = status.trim().toLowerCase();
  return switch (cleanStatus) {
    'present' => AppColors.success,
    'absent' => AppColors.danger,
    'late' => AppColors.warning,
    'excused' || 'permitted' || 'exempted' => AppColors.info,
    _ => AppColors.slate400,
  };
}

String _studyTabTitle(String tab) {
  return switch (tab) {
    'reminders' => 'التذكيرات',
    'resources' => 'الموارد المحفوظة',
    'assignments' => 'التكليفات المتابعة',
    _ => 'مهام الدراسة',
  };
}

IconData _studyTabIcon(String tab) {
  return switch (tab) {
    'reminders' => Icons.notifications_active_rounded,
    'resources' => Icons.folder_copy_rounded,
    'assignments' => Icons.assignment_rounded,
    _ => Icons.local_library_rounded,
  };
}

Color _studyTabColor(String tab) {
  return switch (tab) {
    'reminders' => AppColors.warning,
    'resources' => const Color(0xFF7C3AED),
    'assignments' => const Color(0xFFEA580C),
    _ => const Color(0xFF0F766E),
  };
}

String _priorityLabel(String value) {
  return switch (value) {
    'high' => 'عالية',
    'low' => 'منخفضة',
    _ => 'متوسطة',
  };
}

Color _priorityColor(String value) {
  return switch (value) {
    'high' => AppColors.danger,
    'low' => AppColors.info,
    _ => AppColors.warning,
  };
}

String _sourceLabel(String source) {
  return switch (source) {
    'administration' => 'الإدارة',
    'doctor' => 'الدكتور',
    'delegate' => 'المندوب',
    _ => 'عام',
  };
}

Color _sourceColor(String source) {
  return switch (source) {
    'administration' => AppColors.primary,
    'doctor' => AppColors.info,
    'delegate' => AppColors.success,
    _ => AppColors.slate500,
  };
}

String starTypeLabel(String type) {
  return switch (type) {
    'quiz_reward' => 'مكافأة كويز',
    'doctor_gift' => 'هدية من الدكتور',
    'admin_grant' => 'منحة من الإدارة',
    'competition_prize' => 'جائزة مسابقة',
    'attendance_bonus' => 'مكافأة حضور',
    'honor_board' => 'لوحة الشرف',
    'penalty' => 'خصم',
    'gifted' => 'هدية مرسلة',
    'received_gift' => 'هدية مستلمة',
    _ => type.isEmpty ? 'حركة نجوم' : type,
  };
}

String _notificationTypeLabel(String type) {
  return switch (type) {
    'announcement' => 'إعلان',
    'exam' => 'اختبار',
    'assignment' => 'تكليف',
    'grade_delegation' => 'تفويض درجات',
    'attendance' => 'حضور',
    'poll' => 'استطلاع',
    'flashcard_assignment' => 'بطاقات One Line Shot',
    'tree_farm' => 'مزرعة الأشجار',
    'excuse' => 'أعذار الغياب',
    'absence_warning' => 'إنذار غياب',
    'lecture_report' => 'تسجيل حضور',
    'message' => 'محادثة',
    'resource' => 'ملف دراسي',
    'study_reminder' => 'تذكير بالمذاكرة',
    _ => 'تنبيه',
  };
}

IconData _notificationIcon(String type) {
  return switch (type) {
    'exam' => Icons.fact_check_rounded,
    'assignment' => Icons.assignment_rounded,
    'grade_delegation' => Icons.assignment_ind_rounded,
    'attendance' => Icons.how_to_reg_rounded,
    'poll' => Icons.poll_rounded,
    'announcement' => Icons.campaign_rounded,
    'flashcard_assignment' => Icons.bolt_rounded,
    'tree_farm' => Icons.park_rounded,
    'excuse' => Icons.verified_user_rounded,
    'absence_warning' => Icons.warning_amber_rounded,
    'lecture_report' => Icons.co_present_rounded,
    'message' => Icons.chat_bubble_outline_rounded,
    'resource' => Icons.folder_copy_rounded,
    'study_reminder' => Icons.alarm_on_rounded,
    _ => Icons.notifications_rounded,
  };
}

Color _notificationColor(String type) {
  return switch (type) {
    'exam' => const Color(0xFF7C3AED),
    'assignment' => AppColors.orange,
    'grade_delegation' => AppColors.royalBlue,
    'attendance' => AppColors.success,
    'poll' => AppColors.info,
    'announcement' => AppColors.royalBlue,
    'flashcard_assignment' => const Color(0xFF4F46E5),
    'tree_farm' => const Color(0xFF10B981),
    'excuse' => AppColors.info,
    'absence_warning' => AppColors.danger,
    'lecture_report' => AppColors.success,
    'message' => AppColors.royalBlue,
    'resource' => const Color(0xFF7C3AED),
    'study_reminder' => AppColors.warning,
    _ => AppColors.goldDeep,
  };
}

const _categoryOptions = {
  'all': 'الكل',
  'lectures': 'محاضرات',
  'references': 'مراجع',
  'summaries': 'ملخصات',
  'exams': 'اختبارات',
  'quizzes': 'كويزات',
  'other': 'أخرى',
};

const _uploadCategoryOptions = {
  'lectures': 'محاضرات',
  'summaries': 'ملخصات',
  'quizzes': 'كويزات',
  'exams': 'اختبارات',
  'other': 'أخرى',
};

// ignore: unused_element
String _categoryLabel(String value) => _categoryOptions[value] ?? 'أخرى';

// ignore: unused_element
Color _categoryColor(String value) {
  return switch (value) {
    'lectures' => AppColors.royalBlue,
    'references' => const Color(0xFF7C3AED),
    'summaries' => AppColors.success,
    'exams' => AppColors.rose,
    'quizzes' => AppColors.orange,
    _ => AppColors.goldDeep,
  };
}

String _safeFileName(Map<String, dynamic> item) {
  final title = text(
    item,
    'title',
    fallback: 'resource',
  ).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  final type = text(item, 'file_type', fallback: 'pdf').replaceAll('.', '');
  return '${title.isEmpty ? 'resource' : title}.$type';
}

Future<void> _runSnack(
  BuildContext context,
  Future<String> Function() action, {
  VoidCallback? onDone,
}) async {
  try {
    final message = await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
    onDone?.call();
  } on ApiException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
    );
  }
}

Future<void> _downloadUrlToFile(
  BuildContext context,
  String url,
  String title, {
  String section = 'StudentFiles',
}) async {
  try {
    final fileName = _downloadFileName(url, title);
    final savedPath = await DownloadService.downloadUrlToMoeenFolder(
      url: url,
      fileName: fileName,
      section: section,
    );
    if (!context.mounted || savedPath == null) return;
    await _showDownloadCompletedDialog(context, savedPath, fileName);
  } on ApiException catch (error) {
    if (!context.mounted) return;
    await showMoeenInfoDialog(
      context: context,
      title: 'تعذر تحميل الملف',
      message: error.message,
      icon: Icons.error_rounded,
      color: AppColors.danger,
    );
  }
}

String _downloadFileName(String url, String title) {
  final cleanUrl = url.split('?').first;
  String uriPath;
  try {
    uriPath = Uri.tryParse(cleanUrl)?.path ?? cleanUrl;
  } catch (_) {
    uriPath = cleanUrl;
  }
  final rawExtension = uriPath.contains('.') ? uriPath.split('.').last : '';
  final extension = rawExtension.isEmpty || rawExtension.length > 8
      ? 'file'
      : rawExtension.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
  final safe = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return '${safe.isEmpty ? 'resource' : safe}.$extension';
}

Future<void> _showDownloadCompletedDialog(
  BuildContext context,
  String savedPath,
  String fileName,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('تم تحميل الملف'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('اسم الملف: $fileName'),
          const SizedBox(height: 8),
          Text('المسار: $savedPath'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('إغلاق'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(dialogContext);
            DownloadService.openPath(savedPath);
          },
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('فتح الملف'),
        ),
      ],
    ),
  );
}

String humanKey(String key) {
  return switch (key) {
    'score' => 'الدرجة',
    'status' => 'الحالة',
    'submitted_at' => 'وقت التسليم',
    'created_at' => 'تاريخ الإنشاء',
    'updated_at' => 'آخر تحديث',
    'id' => 'المعرف',
    _ => key.replaceAll('_', ' '),
  };
}

String _dayLabel(String key) {
  return switch (key.toLowerCase()) {
    '7' || 'sunday' => 'الأحد',
    '1' || 'monday' => 'الإثنين',
    '2' || 'tuesday' => 'الثلاثاء',
    '3' || 'wednesday' => 'الأربعاء',
    '4' || 'thursday' => 'الخميس',
    '5' || 'friday' => 'الجمعة',
    '6' || 'saturday' => 'السبت',
    _ => key,
  };
}

Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<dynamic> asList(Object? value) {
  if (value is List) return value;
  if (value is Map<String, dynamic> && value['data'] is List) {
    return value['data'] as List;
  }
  if (value is Map && value['data'] is List) {
    return value['data'] as List;
  }
  return const [];
}

String text(Map<String, dynamic> map, String key, {String fallback = ''}) {
  final value = map[key];
  if (value == null) return fallback;
  return value.toString();
}

num number(Map<String, dynamic> map, String key, {num fallback = 0}) {
  final value = map[key];
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

bool boolValue(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString() == 'true' || value?.toString() == '1';
}

String dateOnly(String value) {
  if (value.contains('T')) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date != null) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    }
  }
  if (value.length >= 10) return value.substring(0, 10);
  return value.isEmpty ? '-' : value;
}

String dateTime(String value) {
  if (value.isEmpty) return '-';
  return '${dateOnly(value)} ${timeOnly(value)}';
}

String prettyDate(String value) {
  if (value.isEmpty) return '-';
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  final months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String timeAgo(String value) {
  if (value.isEmpty) return '';
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
  return dateOnly(value);
}

String timeOnly(String value) {
  if (value.isEmpty) return '-';

  // Try parsing as full DateTime first
  final date = DateTime.tryParse(value)?.toLocal();
  if (date != null) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
  }

  // Handle time-only strings (HH:mm or HH:mm:ss) from API
  if (value.contains(':') && value.length <= 8) {
    final parts = value.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        final period = hour >= 12 ? 'م' : 'ص';
        final hour12 = hour % 12 == 0 ? 12 : hour % 12;
        return '$hour12:${minute.toString().padLeft(2, '0')} $period';
      }
    }
  }

  // Fallbacks
  if (value.length >= 16) return value.substring(11, 16);
  if (value.length >= 5) return value.substring(0, 5);
  return value;
}

bool isImageUrl(String url) {
  final clean = url.split('?').first.toLowerCase();
  return clean.endsWith('.png') ||
      clean.endsWith('.jpg') ||
      clean.endsWith('.jpeg') ||
      clean.endsWith('.webp') ||
      clean.endsWith('.gif');
}

String absoluteUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
    return trimmed;
  final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  if (trimmed.startsWith('/')) return '$base$trimmed';
  return '$base/$trimmed';
}

bool isTimeInRange(String startStr, String endStr) {
  if (startStr.isEmpty || endStr.isEmpty) return false;
  try {
    final now = DateTime.now();
    final today = dateOnly(now.toString());
    final start = DateTime.parse(
      '$today ${startStr.length == 5 ? "$startStr:00" : startStr}',
    );
    final end = DateTime.parse(
      '$today ${endStr.length == 5 ? "$endStr:00" : endStr}',
    );
    return now.isAfter(start) && now.isBefore(end);
  } catch (_) {
    return false;
  }
}
