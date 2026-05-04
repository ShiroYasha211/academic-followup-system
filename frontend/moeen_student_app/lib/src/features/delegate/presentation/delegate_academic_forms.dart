part of 'delegate_screens.dart';

Future<void> _subjectSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final repo = ref.read(delegateRepositoryProvider);
  final results = await Future.wait([repo.eligibleDoctors(), repo.terms()]);
  if (!context.mounted) return;
  final doctors = results[0];
  final terms = results[1];
  final name = TextEditingController(text: text(item, 'name'));
  final code = TextEditingController(text: text(item, 'code'));
  var doctorId = number(
    item,
    'doctor_id',
    fallback: number(asMap(item?['doctor']), 'id'),
  ).toInt();
  var termId = number(
    item,
    'term_id',
    fallback: number(asMap(item?['term']), 'id'),
  ).toInt();
  doctorId = doctorId == 0 && doctors.isNotEmpty
      ? number(doctors.first, 'id').toInt()
      : doctorId;
  termId = termId == 0 && terms.isNotEmpty
      ? number(terms.first, 'id').toInt()
      : termId;

  await _formSheet(
    context,
    title: item == null ? 'إضافة مادة' : 'تعديل مادة',
    fields: [
      TextFormField(
        controller: name,
        decoration: const InputDecoration(labelText: 'اسم المادة'),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'يرجى إدخال اسم المادة' : null,
      ),
      TextFormField(
        controller: code,
        decoration: const InputDecoration(labelText: 'الكود (اختياري)'),
      ),
      DropdownButtonFormField<int>(
        value: doctorId == 0 ? null : doctorId,
        items: doctors
            .map(
              (doctor) => DropdownMenuItem(
                value: number(doctor, 'id').toInt(),
                child: Text(text(doctor, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => doctorId = value ?? 0,
        decoration: const InputDecoration(labelText: 'الدكتور'),
        validator: (v) => v == null ? 'يرجى اختيار الدكتور' : null,
      ),
      DropdownButtonFormField<int>(
        value: termId == 0 ? null : termId,
        items: terms
            .map(
              (term) => DropdownMenuItem(
                value: number(term, 'id').toInt(),
                child: Text(text(term, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => termId = value ?? 0,
        decoration: const InputDecoration(labelText: 'الترم'),
        validator: (v) => v == null ? 'يرجى اختيار الترم الدراسي' : null,
      ),
    ],
    onSave: () => repo.saveSubject(
      id: item == null ? null : number(item, 'id').toInt(),
      data: {
        'name': name.text.trim(),
        'code': code.text.trim(),
        'doctor_id': doctorId,
        'term_id': termId,
      },
    ),
    after: () => ref.invalidate(_delegateSubjectsProvider),
  );
}

Future<void> _scheduleSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final repo = ref.read(delegateRepositoryProvider);
  final results = await Future.wait([repo.subjects(), repo.eligibleDoctors()]);
  if (!context.mounted) return;
  final subjects = results[0];
  final doctors = results[1];

  var subjectId = number(item, 'subject_id').toInt();
  var doctorId = number(item, 'doctor_id').toInt();
  var day = number(item, 'day', fallback: 1).toInt();
  final start = TextEditingController(text: text(item, 'start_time'));
  final end = TextEditingController(text: text(item, 'end_time'));
  final hall = TextEditingController(text: text(item, 'hall'));

  await _formSheet(
    context,
    title: item == null ? 'إضافة محاضرة' : 'تعديل محاضرة',
    fields: [
      DropdownButtonFormField<int>(
        value: subjectId == 0 ? null : subjectId,
        items: subjects
            .map(
              (s) => DropdownMenuItem(
                value: number(s, 'id').toInt(),
                child: Text(text(s, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => subjectId = value ?? 0,
        decoration: const InputDecoration(labelText: 'المادة'),
        validator: (v) => v == null ? 'يرجى اختيار المادة' : null,
      ),
      DropdownButtonFormField<int>(
        value: doctorId == 0 ? null : doctorId,
        items: doctors
            .map(
              (doc) => DropdownMenuItem(
                value: number(doc, 'id').toInt(),
                child: Text(text(doc, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => doctorId = value ?? 0,
        decoration: const InputDecoration(labelText: 'الدكتور (اختياري)'),
      ),
      DropdownButtonFormField<int>(
        value: day,
        items: [
          DropdownMenuItem(value: 6, child: Text('السبت')),
          DropdownMenuItem(value: 7, child: Text('الأحد')),
          DropdownMenuItem(value: 1, child: Text('الاثنين')),
          DropdownMenuItem(value: 2, child: Text('الثلاثاء')),
          DropdownMenuItem(value: 3, child: Text('الأربعاء')),
          DropdownMenuItem(value: 4, child: Text('الخميس')),
          DropdownMenuItem(value: 5, child: Text('الجمعة')),
        ],
        onChanged: (value) => day = value ?? 1,
        decoration: const InputDecoration(labelText: 'اليوم'),
        validator: (v) => v == null ? 'يرجى اختيار اليوم' : null,
      ),
      StatefulBuilder(
        builder: (context, setState) => Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: start,
                readOnly: true,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    start.text = _formatReminderTime(picked);
                    setState(() {});
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'بداية المحاضرة',
                  prefixIcon: Icon(Icons.schedule_rounded),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'يرجى اختيار وقت البدء' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: end,
                readOnly: true,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    end.text = _formatReminderTime(picked);
                    setState(() {});
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'نهاية المحاضرة',
                  prefixIcon: Icon(Icons.update_rounded),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'يرجى اختيار وقت الانتهاء' : null,
              ),
            ),
          ],
        ),
      ),
      TextFormField(
        controller: hall,
        decoration: const InputDecoration(
          labelText: 'القاعة الدراسية',
          prefixIcon: Icon(Icons.room_rounded),
        ),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'يرجى إدخال اسم القاعة' : null,
      ),
    ],
    onSave: () => repo.saveSchedule(
      id: item == null ? null : number(item, 'id').toInt(),
      data: {
        'subject_id': subjectId,
        'doctor_id': doctorId == 0 ? null : doctorId,
        'day': day,
        'start_time': start.text.trim(),
        'end_time': end.text.trim(),
        'hall': hall.text.trim(),
      },
    ),
    after: () => ref.invalidate(_delegateSchedulesProvider),
  );
}

Future<void> _assignmentSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;

  var subjectId = number(item, 'subject_id').toInt();
  final title = TextEditingController(text: text(item, 'title'));
  final description = TextEditingController(text: text(item, 'description'));
  final due = TextEditingController(text: dateOnly(text(item, 'due_date')));
  var requiresSubmission = boolValue(item, 'requires_submission');

  await _formSheet(
    context,
    title: item == null ? 'نشر تكليف جديد' : 'تعديل التكليف',
    fields: [
      DropdownButtonFormField<int>(
        value: subjectId == 0 ? null : subjectId,
        items: subjects
            .map(
              (s) => DropdownMenuItem(
                value: number(s, 'id').toInt(),
                child: Text(text(s, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => subjectId = value ?? 0,
        decoration: const InputDecoration(
            labelText: 'المادة', prefixIcon: Icon(Icons.book_rounded)),
        validator: (v) => v == null ? 'يرجى اختيار المادة' : null,
      ),
      TextFormField(
        controller: title,
        decoration: const InputDecoration(
            labelText: 'عنوان التكليف', prefixIcon: Icon(Icons.title_rounded)),
        validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال العنوان' : null,
      ),
      TextFormField(
        controller: description,
        maxLines: 5,
        decoration: const InputDecoration(
            labelText: 'تعليمات التكليف / الوصف',
            prefixIcon: Icon(Icons.description_rounded)),
        validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال الوصف' : null,
      ),
      StatefulBuilder(
        builder: (ctx, setState) => TextFormField(
          controller: due,
          readOnly: true,
          onTap: () async {
            await pickDate(ctx, due);
            setState(() {});
          },
          decoration: const InputDecoration(
              labelText: 'تاريخ التسليم النهائي',
              prefixIcon: Icon(Icons.event_available_rounded)),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'يرجى اختيار التاريخ' : null,
        ),
      ),
      const SizedBox(height: 8),
      StatefulBuilder(
        builder: (ctx, setState) => SwitchListTile(
          value: requiresSubmission,
          onChanged: (value) => setState(() => requiresSubmission = value),
          title: const Text('يتطلب تسليم ملف من الطالب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          secondary:
              const Icon(Icons.upload_file_rounded, color: AppColors.primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.slate200)),
        ),
      ),
    ],
    onSave: () => ref.read(delegateRepositoryProvider).saveAssignment(
          id: item == null ? null : number(item, 'id').toInt(),
          data: {
            'subject_id': subjectId,
            'title': title.text.trim(),
            'description': description.text.trim(),
            'due_date': due.text.trim(),
            'requires_submission': requiresSubmission ? 1 : 0,
          },
        ),
    after: () => ref.invalidate(_delegateAssignmentsProvider),
  );
}

Future<void> _examSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;

  final title = TextEditingController(text: text(item, 'title'));
  final description = TextEditingController(text: text(item, 'description'));
  final List<_ExamFormItem> formItems = [];

  if (item != null && item['items'] != null) {
    for (var sub in asList(item['items'])) {
      formItems.add(_ExamFormItem.fromMap(asMap(sub)));
    }
  }

  if (formItems.isEmpty) {
    formItems.add(_ExamFormItem.empty(subjects));
  }

  await _formSheet(
    context,
    title: item == null ? 'إضافة جدول اختبارات' : 'تعديل جدول اختبارات',
    fields: [
      TextFormField(
        controller: title,
        decoration: const InputDecoration(
            labelText: 'عنوان الجدول (مثلاً: امتحانات نصفية)',
            prefixIcon: Icon(Icons.title_rounded)),
        validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال العنوان' : null,
      ),
      TextFormField(
        controller: description,
        decoration: const InputDecoration(
            labelText: 'الوصف أو ملاحظات عامة',
            prefixIcon: Icon(Icons.description_rounded)),
      ),
      const SizedBox(height: 24),
      StatefulBuilder(
        builder: (ctx, setState) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المواد والمواعيد',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.midnight)),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => formItems.add(_ExamFormItem.empty(subjects))),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('إضافة مادة'),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...formItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final fItem = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primary,
                          child: Text('${idx + 1}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                            child: Text('تفاصيل المادة',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13))),
                        if (formItems.length > 1)
                          IconButton(
                            onPressed: () =>
                                setState(() => formItems.removeAt(idx)),
                            icon: const Icon(Icons.remove_circle_outline_rounded,
                                color: Colors.redAccent, size: 20),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    DropdownButtonFormField<int>(
                      value: fItem.subjectId == 0 ? null : fItem.subjectId,
                      items: subjects
                          .map((s) => DropdownMenuItem(
                              value: number(s, 'id').toInt(),
                              child: Text(text(s, 'name'))))
                          .toList(),
                      onChanged: (value) => fItem.subjectId = value ?? 0,
                      decoration: const InputDecoration(
                          labelText: 'المادة',
                          prefixIcon: Icon(Icons.book_rounded)),
                      validator: (v) => v == null ? 'اختر المادة' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: fItem.date,
                      readOnly: true,
                      onTap: () async {
                        await pickDate(ctx, fItem.date);
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                          labelText: 'التاريخ',
                          prefixIcon: Icon(Icons.event_rounded)),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'اختر التاريخ' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: fItem.start,
                            readOnly: true,
                            onTap: () async {
                              await pickTime(ctx, fItem.start);
                              setState(() {});
                            },
                            decoration: const InputDecoration(
                                labelText: 'البداية',
                                prefixIcon: Icon(Icons.schedule_rounded)),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'وقت البدء' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: fItem.end,
                            readOnly: true,
                            onTap: () async {
                              await pickTime(ctx, fItem.end);
                              setState(() {});
                            },
                            decoration: const InputDecoration(
                                labelText: 'النهاية',
                                prefixIcon: Icon(Icons.update_rounded)),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'وقت الانتهاء' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: fItem.location,
                      decoration: const InputDecoration(
                          labelText: 'المكان',
                          prefixIcon: Icon(Icons.room_rounded)),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'ادخل المكان' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: fItem.examType,
                      items: const [
                        DropdownMenuItem(value: 'midterm', child: Text('نصفي')),
                        DropdownMenuItem(value: 'final', child: Text('نهائي')),
                        DropdownMenuItem(value: 'practical', child: Text('عملي')),
                        DropdownMenuItem(value: 'quiz', child: Text('كويز')),
                        DropdownMenuItem(value: 'other', child: Text('آخر')),
                      ],
                      onChanged: (value) => fItem.examType = value ?? 'midterm',
                      decoration: const InputDecoration(
                          labelText: 'النوع',
                          prefixIcon: Icon(Icons.category_rounded)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ],
    onSave: () => ref.read(delegateRepositoryProvider).saveExamSchedule(
          id: item == null ? null : number(item, 'id').toInt(),
          data: {
            'title': title.text.trim(),
            'description': description.text.trim(),
            'items': formItems
                .map((fi) => {
                      'subject_id': fi.subjectId,
                      'date': fi.date.text,
                      'start_time': fi.start.text,
                      'end_time': fi.end.text,
                      'location': fi.location.text,
                      'type': fi.examType,
                    })
                .toList(),
          },
        ),
    after: () => ref.invalidate(_delegateExamsProvider),
  );
}

class _ExamFormItem {
  int subjectId;
  final TextEditingController date;
  final TextEditingController start;
  final TextEditingController end;
  final TextEditingController location;
  String examType;

  _ExamFormItem({
    required this.subjectId,
    required this.date,
    required this.start,
    required this.end,
    required this.location,
    required this.examType,
  });

  factory _ExamFormItem.empty(List<dynamic> subjects) => _ExamFormItem(
        subjectId: subjects.isNotEmpty ? number(subjects.first, 'id').toInt() : 0,
        date: TextEditingController(),
        start: TextEditingController(),
        end: TextEditingController(),
        location: TextEditingController(),
        examType: 'midterm',
      );

  factory _ExamFormItem.fromMap(Map<String, dynamic> map) => _ExamFormItem(
        subjectId: number(map, 'subject_id').toInt(),
        date: TextEditingController(text: text(map, 'date')),
        start: TextEditingController(text: text(map, 'start_time')),
        end: TextEditingController(text: text(map, 'end_time')),
        location: TextEditingController(text: text(map, 'location')),
        examType: text(map, 'type', fallback: 'midterm'),
      );
}

Future<void> _resourceSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;

  var subjectId = number(item, 'subject_id').toInt();
  if (subjectId == 0 && subjects.isNotEmpty) {
    subjectId = number(subjects.first, 'id').toInt();
  }
  final title = TextEditingController(text: text(item, 'title'));
  var category = text(item, 'category', fallback: 'lectures');
  final description = TextEditingController(text: text(item, 'description'));
  PlatformFile? selected;

  await showMoeenBottomSheet(
    context: context,
    title: item == null ? 'رفع مصدر مقرر' : 'تعديل بيانات المصدر',
    icon: Icons.cloud_upload_rounded,
    color: const Color(0xFF0D9488),
    child: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            value: subjectId == 0 ? null : subjectId,
            items: subjects
                .map((s) => DropdownMenuItem(
                    value: number(s, 'id').toInt(), child: Text(text(s, 'name'))))
                .toList(),
            onChanged: (v) => subjectId = v ?? 0,
            decoration: const InputDecoration(
                labelText: 'المادة', prefixIcon: Icon(Icons.book_rounded)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: title,
            decoration: const InputDecoration(
                labelText: 'العنوان', prefixIcon: Icon(Icons.title_rounded)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: category,
            items: const [
              DropdownMenuItem(value: 'lectures', child: Text('محاضرات')),
              DropdownMenuItem(value: 'references', child: Text('مراجع')),
              DropdownMenuItem(value: 'summaries', child: Text('ملخصات')),
              DropdownMenuItem(value: 'exams', child: Text('اختبارات')),
              DropdownMenuItem(value: 'quizzes', child: Text('كويزات')),
              DropdownMenuItem(value: 'other', child: Text('أخرى')),
            ],
            onChanged: (v) => category = v ?? 'lectures',
            decoration: const InputDecoration(
                labelText: 'التصنيف', prefixIcon: Icon(Icons.category_rounded)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: description,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'وصف إضافي (اختياري)',
                prefixIcon: Icon(Icons.description_rounded)),
          ),
          const SizedBox(height: 16),
          if (item == null) ...[
            OutlinedButton.icon(
              onPressed: () async {
                final res = await FilePicker.platform.pickFiles();
                if (res != null) {
                  setState(() => selected = res.files.first);
                }
              },
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(selected?.name ?? 'اختيار ملف'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
          ElevatedButton(
            onPressed: (item == null && selected?.path == null)
                ? null
                : () async {
                    await _run(
                      ctx,
                      () => item == null
                          ? ref.read(delegateRepositoryProvider).uploadResource(
                                subjectId: subjectId,
                                title: title.text.trim(),
                                category: category,
                                filePath: selected!.path!,
                                fileName: selected!.name,
                                description: description.text.trim(),
                              )
                          : ref.read(delegateRepositoryProvider).updateResource(
                                id: number(item, 'id').toInt(),
                                subjectId: subjectId,
                                title: title.text.trim(),
                                category: category,
                                description: description.text.trim(),
                              ),
                      after: () => ref.invalidate(_delegateResourcesProvider),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(item == null ? 'رفع الملف الآن' : 'حفظ التعديلات'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _reminderSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final title = TextEditingController(text: text(item, 'title'));
  final description = TextEditingController(text: text(item, 'description'));
  final eventDate = TextEditingController(text: text(item, 'event_date'));
  final notifyAt = TextEditingController(text: text(item, 'notify_at'));
  String priority = text(item, 'priority', fallback: 'medium');

  await _formSheet(
    context,
    title: item == null ? 'إضافة تذكير' : 'تعديل تذكير',
    fields: [
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'العنوان', hintText: 'مثلاً: اختبار الجراحة'),
      ),
      TextField(
        controller: description,
        decoration: const InputDecoration(labelText: 'الوصف الإضافي (اختياري)'),
      ),
      const SizedBox(height: 12),
      StatefulBuilder(
        builder: (context, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مستوى الأولوية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _PriorityChip(
                  label: 'عاجل',
                  color: AppColors.danger,
                  selected: priority == 'high',
                  onTap: () => setState(() => priority = 'high'),
                ),
                const SizedBox(width: 8),
                _PriorityChip(
                  label: 'مهم',
                  color: AppColors.orange,
                  selected: priority == 'medium',
                  onTap: () => setState(() => priority = 'medium'),
                ),
                const SizedBox(width: 8),
                _PriorityChip(
                  label: 'عادي',
                  color: AppColors.success,
                  selected: priority == 'low',
                  onTap: () => setState(() => priority = 'low'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: eventDate,
        readOnly: true,
        onTap: () async {
          await _pickDateTime(context, eventDate);
        },
        decoration: const InputDecoration(
          labelText: 'وقت الحدث',
          prefixIcon: Icon(Icons.calendar_today_rounded),
        ),
      ),
      TextField(
        controller: notifyAt,
        readOnly: true,
        onTap: () async {
          await _pickDateTime(context, notifyAt);
        },
        decoration: const InputDecoration(
          labelText: 'وقت التنبيه',
          prefixIcon: Icon(Icons.notifications_active_rounded),
        ),
      ),
    ],
    onSave: () => ref.read(delegateRepositoryProvider).saveReminder(
      id: item == null ? null : number(item, 'id').toInt(),
      data: {
        'title': title.text.trim(),
        'description': description.text.trim(),
        'event_date': eventDate.text.trim(),
        'notify_at': notifyAt.text.trim(),
        'priority': priority,
      },
    ),
    after: () => ref.invalidate(_delegateRemindersProvider('all')),
  );
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

Future<void> _newsSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final title = TextEditingController(text: text(item, 'title'));
  final content = TextEditingController(text: text(item, 'content'));
  var category = text(item, 'category', fallback: 'general');
  await _formSheet(
    context,
    title: item == null ? 'نشر إعلان' : 'تعديل إعلان',
    fields: [
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'العنوان'),
      ),
      TextField(
        controller: content,
        maxLines: 7,
        decoration: const InputDecoration(labelText: 'المحتوى'),
      ),
      DropdownButtonFormField<String>(
        value: category,
        items: const [
          DropdownMenuItem(value: 'general', child: Text('عام')),
          DropdownMenuItem(value: 'academic', child: Text('أكاديمي')),
          DropdownMenuItem(value: 'urgent', child: Text('عاجل')),
        ],
        onChanged: (value) => category = value ?? 'general',
        decoration: const InputDecoration(labelText: 'النوع'),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .saveAnnouncement(id: item == null ? null : number(item, 'id').toInt(), data: {
      'title': title.text.trim(),
      'content': content.text.trim(),
      'category': category,
    }),
    after: () => ref.invalidate(_delegateAnnouncementsProvider),
  );
}
