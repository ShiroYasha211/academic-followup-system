part of 'delegate_screens.dart';

Future<void> _studentSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? item,
}) async {
  final name = TextEditingController(text: text(item, 'name'));
  final email = TextEditingController(text: text(item, 'email'));
  final numberController = TextEditingController(
    text: text(item, 'student_number'),
  );
  final password = TextEditingController();
  var gender = text(item, 'gender', fallback: 'male');
  final showLegacyCredentials = _showLegacyStudentCredentials();

  await _formSheet(
    context,
    title: item == null ? 'إضافة طالب' : 'تعديل طالب',
    fields: [
      TextFormField(
        controller: name,
        decoration: const InputDecoration(labelText: 'اسم الطالب'),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'يرجى إدخال اسم الطالب' : null,
      ),
      if (showLegacyCredentials) TextFormField(
        controller: email,
        decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
          if (!v.contains('@')) return 'بريد إلكتروني غير صالح';
          return null;
        },
      ),
      TextFormField(
        controller: numberController,
        decoration: const InputDecoration(labelText: 'رقم القيد'),
        keyboardType: TextInputType.number,
        validator: (v) =>
            (v == null || v.isEmpty) ? 'يرجى إدخال رقم القيد' : null,
      ),
      DropdownButtonFormField<String>(
        value: gender,
        items: const [
          DropdownMenuItem(value: 'male', child: Text('ذكر')),
          DropdownMenuItem(value: 'female', child: Text('أنثى')),
        ],
        onChanged: (value) => gender = value ?? 'male',
        decoration: const InputDecoration(labelText: 'الجنس'),
      ),
      if (showLegacyCredentials) TextFormField(
        controller: password,
        obscureText: true,
        decoration: InputDecoration(
          labelText: item == null
              ? 'كلمة المرور'
              : 'كلمة مرور جديدة (اختيارية)',
        ),
        validator: (v) {
          if (item == null && (v == null || v.isEmpty))
            return 'يرجى إدخال كلمة المرور';
          return null;
        },
      ),
    ],
    onSave: () async {
      final data = {
        'name': name.text.trim(),
        'student_number': numberController.text.trim(),
        'gender': gender,
      };
      password.text = numberController.text.trim();
      if (item == null) {
        if (password.text.isEmpty)
          throw const ApiException('يجب إدخال كلمة المرور للطالب الجديد.');
        return ref.read(delegateRepositoryProvider).createStudent(data);
      }
      return ref
          .read(delegateRepositoryProvider)
          .updateStudent(number(item, 'id').toInt(), data);
    },
    after: () => ref.invalidate(delegateStudentsProvider),
  );
}

bool _showLegacyStudentCredentials() => false;

Future<void> _studentPermissionSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> student,
) async {
  final repository = ref.read(delegateRepositoryProvider);
  final id = number(student, 'id').toInt();
  final state = await repository.studentPermissions(id);
  final data = asMap(state);
  var canUpload = data['can_upload_library'] == true;

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slate200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'صلاحيات الطالب',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnight,
                            ),
                          ),
                          Text(
                            text(student, 'name'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.slate400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.slate100),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الرفع للمكتبة المشتركة',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.midnight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'يسمح للطالب برفع الملفات والمحاضرات للجميع.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: canUpload,
                        activeColor: AppColors.success,
                        onChanged: (val) async {
                          setModalState(() => canUpload = val);
                          try {
                            await repository.updateStudentPermissions(
                              id: id,
                              canUploadLibrary: val,
                            );
                            _toast(context, 'تم تحديث الصلاحيات بنجاح');
                          } catch (e) {
                            setModalState(() => canUpload = !val);
                            if (context.mounted) _showError(context, e);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
