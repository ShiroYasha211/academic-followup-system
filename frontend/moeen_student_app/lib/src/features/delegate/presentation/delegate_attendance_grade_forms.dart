part of 'delegate_screens.dart';

Future<void> _attendanceSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> subject,
) async {
  final title = TextEditingController(
    text: 'محاضرة ${DateTime.now().toIso8601String().split('T').first}',
  );
  final date = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  final data = await ref
      .read(delegateRepositoryProvider)
      .attendanceCreate(
        subjectId: number(subject, 'id').toInt(),
        date: date.text,
      );
  if (!context.mounted) return;
  final students = asList(data['students']);
  final statuses = <int, String>{
    for (final raw in students) number(raw, 'id').toInt(): 'present',
  };
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text('رصد حضور ${text(subject, 'name')}', style: _titleStyle),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'عنوان المحاضرة'),
            ),
            TextField(
              controller: date,
              decoration: const InputDecoration(labelText: 'التاريخ'),
            ),
            const SizedBox(height: 14),
            for (final raw in students)
              _GlassCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text(raw, 'name'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    DropdownButton<String>(
                      value: statuses[number(raw, 'id').toInt()],
                      items: const [
                        DropdownMenuItem(value: 'present', child: Text('حاضر')),
                        DropdownMenuItem(value: 'absent', child: Text('غائب')),
                        DropdownMenuItem(value: 'late', child: Text('متأخر')),
                        DropdownMenuItem(value: 'excused', child: Text('بعذر')),
                      ],
                      onChanged: (value) => setState(
                        () => statuses[number(raw, 'id').toInt()] =
                            value ?? 'present',
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                await _run(
                  context,
                  () => ref.read(delegateRepositoryProvider).saveAttendance({
                    'subject_id': number(subject, 'id').toInt(),
                    'title': title.text.trim(),
                    'date': date.text.trim(),
                    'students': statuses.entries
                        .map(
                          (entry) => {'id': entry.key, 'status': entry.value},
                        )
                        .toList(),
                  }),
                  after: () => ref.invalidate(_delegateAttendanceProvider),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ الحضور'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _startQrSession(
  BuildContext context,
  WidgetRef ref, {
  required ValueChanged<Map<String, dynamic>> onStarted,
}) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;
  var subjectId = subjects.isNotEmpty
      ? number(subjects.first, 'id').toInt()
      : 0;
  final title = TextEditingController(text: 'جلسة حضور QR');
  final date = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  await _formSheet(
    context,
    title: 'بدء جلسة QR',
    fields: [
      DropdownButtonFormField<int>(
        value: subjectId == 0 ? null : subjectId,
        items: subjects
            .where(
              (subject) => asMap(subject)['allow_delegate_attendance'] == true,
            )
            .map(
              (subject) => DropdownMenuItem(
                value: number(subject, 'id').toInt(),
                child: Text(text(subject, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => subjectId = value ?? 0,
        decoration: const InputDecoration(labelText: 'المادة'),
      ),
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'عنوان الجلسة'),
      ),
      TextField(
        controller: date,
        decoration: const InputDecoration(labelText: 'التاريخ'),
      ),
    ],
    onSave: () async {
      final session = await ref
          .read(delegateRepositoryProvider)
          .startQrAttendance({
            'subject_id': subjectId,
            'title': title.text.trim(),
            'date': date.text.trim(),
          });
      onStarted(session);
      return 'تم بدء الجلسة.';
    },
    after: () {},
  );
}

Future<void> _gradesEntrySheet(
  BuildContext context,
  WidgetRef ref,
  int categoryId,
) async {
  final data = await ref
      .read(delegateRepositoryProvider)
      .authorizedGradeDetails(categoryId);
  if (!context.mounted) return;
  final students = asList(data['students']);
  final controllers = <int, TextEditingController>{};
  for (final raw in students) {
    final id = number(raw, 'id').toInt();
    final current = asMap(raw)['current_grade'];
    controllers[id] = TextEditingController(text: text(current, 'score'));
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          const Text('رصد الدرجات', style: _titleStyle),
          const SizedBox(height: 12),
          for (final raw in students)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: controllers[number(raw, 'id').toInt()],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      '${text(raw, 'name')} - ${text(raw, 'student_number', fallback: '-')}',
                ),
              ),
            ),
          ElevatedButton(
            onPressed: () async {
              final grades = controllers.entries
                  .where((entry) => entry.value.text.trim().isNotEmpty)
                  .map(
                    (entry) => {
                      'student_id': entry.key,
                      'score': entry.value.text.trim(),
                    },
                  )
                  .toList();
              await _run(
                context,
                () => ref
                    .read(delegateRepositoryProvider)
                    .saveAuthorizedGrades(
                      categoryId: categoryId,
                      grades: grades,
                    ),
                after: () => ref.invalidate(_delegateAuthorizedGradesProvider),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('إرسال للمراجعة'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _helperDelegationSheet(BuildContext context, WidgetRef ref) async {
  final grades = await ref.read(delegateRepositoryProvider).authorizedGrades();
  final categories = asList(grades['direct_delegations']);
  if (!context.mounted || categories.isEmpty) {
    if (context.mounted)
      _toast(context, 'لا توجد تصنيفات مفوضة لإنشاء تفويض مساعد.');
    return;
  }
  var categoryId = number(categories.first, 'id').toInt();
  final title = TextEditingController(text: 'مهمة رصد درجات');
  final notes = TextEditingController();
  var helperId = 0;
  var delegationType = 'full';
  List<dynamic> students = const [];
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          8,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تفويض مساعد رصد', style: _titleStyle),
              DropdownButtonFormField<int>(
                value: categoryId,
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: number(category, 'id').toInt(),
                        child: Text(text(category, 'name')),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  categoryId = value ?? categoryId;
                  final data = await ref
                      .read(delegateRepositoryProvider)
                      .helperDelegationStudents(categoryId);
                  setState(() {
                    students = asList(data['eligible_students']);
                    helperId = students.isNotEmpty
                        ? number(students.first, 'id').toInt()
                        : 0;
                  });
                },
                decoration: const InputDecoration(labelText: 'التصنيف'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final data = await ref
                      .read(delegateRepositoryProvider)
                      .helperDelegationStudents(categoryId);
                  setState(() {
                    students = asList(data['eligible_students']);
                    helperId = students.isNotEmpty
                        ? number(students.first, 'id').toInt()
                        : 0;
                  });
                },
                icon: const Icon(Icons.people_rounded),
                label: const Text('تحميل الطلاب المتاحين'),
              ),
              if (students.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: helperId == 0 ? null : helperId,
                  items: students
                      .map(
                        (student) => DropdownMenuItem(
                          value: number(student, 'id').toInt(),
                          child: Text(
                            '${text(student, 'name')} - ${text(student, 'role')}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => helperId = value ?? 0,
                  decoration: const InputDecoration(labelText: 'المساعد'),
                ),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'عنوان المهمة'),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
              DropdownButtonFormField<String>(
                value: delegationType,
                items: const [
                  DropdownMenuItem(value: 'full', child: Text('كل الطلاب')),
                  DropdownMenuItem(value: 'partial', child: Text('تفويض جزئي')),
                ],
                onChanged: (value) => delegationType = value ?? 'full',
                decoration: const InputDecoration(labelText: 'نطاق التفويض'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: helperId == 0
                    ? null
                    : () async {
                        await _run(
                          context,
                          () => ref
                              .read(delegateRepositoryProvider)
                              .createHelperDelegation({
                                'category_id': categoryId,
                                'helper_user_id': helperId,
                                'delegation_type': delegationType,
                                'title': title.text.trim(),
                                'notes': notes.text.trim(),
                                if (delegationType == 'partial')
                                  'student_ids': students
                                      .map(
                                        (student) =>
                                            number(student, 'id').toInt(),
                                      )
                                      .take(1)
                                      .toList(),
                              }),
                          after: () =>
                              ref.invalidate(_delegateHelperTasksProvider),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                child: const Text('إنشاء التفويض'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
