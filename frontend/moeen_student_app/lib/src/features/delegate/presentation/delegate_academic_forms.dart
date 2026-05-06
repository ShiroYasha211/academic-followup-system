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

  final formKey = GlobalKey<FormState>();

  await showMoeenBottomSheet(
    context: context,
    title: item == null ? 'رفع مصدر مقرر' : 'تعديل بيانات المصدر',
    icon: Icons.cloud_upload_rounded,
    color: const Color(0xFF0D9488),
    child: StatefulBuilder(
      builder: (ctx, setState) => Form(
        key: formKey,
        child: Column(
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
            validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال العنوان' : null,
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
                    if (formKey.currentState?.validate() != true) return;
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
      TextFormField(
        controller: title,
        decoration: const InputDecoration(labelText: 'العنوان', hintText: 'مثلاً: اختبار الجراحة'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال العنوان' : null,
      ),
      TextFormField(
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
      TextFormField(
        controller: eventDate,
        readOnly: true,
        onTap: () async {
          await _pickDateTime(context, eventDate);
        },
        decoration: const InputDecoration(
          labelText: 'وقت الحدث',
          prefixIcon: Icon(Icons.calendar_today_rounded),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'يرجى تحديد وقت الحدث' : null,
      ),
      TextFormField(
        controller: notifyAt,
        readOnly: true,
        onTap: () async {
          await _pickDateTime(context, notifyAt);
        },
        decoration: const InputDecoration(
          labelText: 'وقت التنبيه',
          prefixIcon: Icon(Icons.notifications_active_rounded),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'يرجى تحديد وقت التنبيه' : null,
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
  var isPinned = boolVal(item?['is_pinned']);
  File? attachment;
  var existingAttachment = text(item, 'attachment_path');
  var removeExisting = false;
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item == null ? 'نشر إعلان جديد' : 'تعديل الإعلان',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.midnight),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('عنوان الإعلان'),
                    TextFormField(
                      controller: title,
                      decoration: _formInputDecoration('أدخل عنواناً جذاباً...'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال العنوان' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildFieldLabel('محتوى الخبر'),
                    TextFormField(
                      controller: content,
                      maxLines: 6,
                      decoration: _formInputDecoration('اكتب تفاصيل الإعلان هنا...'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال المحتوى' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildFieldLabel('تصنيف الإعلان'),
                    Row(
                      children: [
                        _CategorySelectChip(
                          label: 'عام',
                          isSelected: category == 'general',
                          onSelected: (v) => setState(() => category = 'general'),
                        ),
                        const SizedBox(width: 8),
                        _CategorySelectChip(
                          label: 'أكاديمي',
                          isSelected: category == 'academic',
                          onSelected: (v) => setState(() => category = 'academic'),
                        ),
                        const SizedBox(width: 8),
                        _CategorySelectChip(
                          label: 'عاجل 🔥',
                          isSelected: category == 'urgent',
                          onSelected: (v) => setState(() => category = 'urgent'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      value: isPinned,
                      onChanged: (v) => setState(() => isPinned = v),
                      title: const Text('تثبيت الإعلان في الأعلى',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      secondary: Icon(Icons.push_pin_rounded,
                          color: isPinned ? AppColors.royalBlue : AppColors.slate400),
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.royalBlue,
                    ),
                    const SizedBox(height: 24),
                    _buildFieldLabel('المرفقات (صور أو مستندات)'),
                    if (attachment != null)
                      _SelectedFileCard(
                        name: attachment!.path.split('/').last,
                        onRemove: () => setState(() => attachment = null),
                      )
                    else if (existingAttachment.isNotEmpty && !removeExisting)
                      _SelectedFileCard(
                        name: 'مرفق حالي',
                        isExisting: true,
                        onRemove: () => setState(() => removeExisting = true),
                      )
                    else
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles();
                          if (result != null && result.files.single.path != null) {
                            setState(() {
                              attachment = File(result.files.single.path!);
                              removeExisting = true;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.slate200, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  color: AppColors.royalBlue.withValues(alpha: 0.5), size: 32),
                              const SizedBox(height: 8),
                              const Text('اضغط لاختيار صورة أو ملف',
                                  style: TextStyle(
                                      color: AppColors.slate500, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) return;
                  
                  final data = {
                    'title': title.text.trim(),
                    'content': content.text.trim(),
                    'category': category,
                    'is_pinned': isPinned ? 1 : 0,
                    if (attachment != null)
                      'attachment': await MultipartFile.fromFile(attachment!.path),
                    if (removeExisting) 'remove_attachment': 1,
                  };

                  try {
                    await ref.read(delegateRepositoryProvider).saveAnnouncement(
                          id: item == null ? null : number(item, 'id').toInt(),
                          data: data,
                        );
                    ref.invalidate(_delegateAnnouncementsProvider);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('تأكيد ونشر الآن',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
    ),
    ),
  );
}

class _CategorySelectChip extends StatelessWidget {
  const _CategorySelectChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.orange.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.orange : AppColors.slate600,
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: AppColors.slate100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.orange : Colors.transparent,
        ),
      ),
      showCheckmark: false,
    );
  }
}

class _SelectedFileCard extends StatelessWidget {
  const _SelectedFileCard({
    required this.name,
    required this.onRemove,
    this.isExisting = false,
  });
  final String name;
  final VoidCallback onRemove;
  final bool isExisting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_rounded, color: AppColors.royalBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.cancel_rounded, color: AppColors.rose),
          ),
        ],
      ),
    );
  }
}

Widget _buildFieldLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8, right: 4),
    child: Text(
      label,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate700),
    ),
  );
}

InputDecoration _formInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
    filled: true,
    fillColor: AppColors.slate50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.slate200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.slate200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
