part of 'staff_screens.dart';

extension _DoctorClinicalSetupActions on _DoctorClinicalSectionScreenState {
  Future<void> _openCreate() async {
    await _openForm();
  }

  Future<void> _openEdit(_Json item) async {
    await _openForm(item: item);
  }

  Future<void> _openForm({_Json? item}) async {
    if (widget.section == 'cases') {
      await _openCaseForm(item: item);
      return;
    }
    if (widget.section == 'assignments') {
      await _openAssignmentForm();
      return;
    }
    if (widget.section == 'checklists') {
      await _openChecklistForm(item: item);
      return;
    }
    if (widget.section == 'rare-cases') {
      await _openRareCaseForm();
      return;
    }
    if (widget.section == 'volunteers') {
      await _openVolunteerForm(item: item);
      return;
    }
    if (widget.section == 'centers') {
      await _openTrainingCenterForm(item: item);
      return;
    }
    if (widget.section == 'departments') {
      await _openDepartmentForm(item: item);
      return;
    }
    if (widget.section == 'body-systems') {
      await _openBodySystemForm(item: item);
      return;
    }
    await _openSimpleForm(item: item);
  }

  Future<void> _openSimpleForm({_Json? item}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: _docText(item?['name']));
    final location = TextEditingController(text: _docText(item?['location']));
    final description = TextEditingController(
      text: _docText(item?['description']),
    );
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'إضافة $_title' : 'تعديل $_title',
      icon: _icon,
      color: AppColors.royalBlue,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'الاسم'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'الاسم مطلوب.' : null,
            ),
            if (widget.section == 'centers') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: location,
                decoration: const InputDecoration(labelText: 'الموقع'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: description,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'الوصف'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    final payload = {
      'name': name.text.trim(),
      if (widget.section == 'centers') 'location': location.text.trim(),
      'description': description.text.trim(),
    };
    name.dispose();
    location.dispose();
    description.dispose();
    if (ok != true) return;
    try {
      if (item == null) {
        await ref.read(staffRepositoryProvider).post(_endpoint, payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('$_endpoint/${item['id']}', payload);
      }
      if (!mounted) return;
      if (item == null) {
        _search.clear();
        _status = null;
      }
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _showTrainingCenterDetails(_Json centerItem) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل مركز التدريب',
      icon: Icons.local_hospital_rounded,
      color: AppColors.royalBlue,
      child: _TrainingCenterDetails(centerItem: centerItem),
    );
  }

  Future<void> _openTrainingCenterForm({_Json? item}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: _docText(item?['name']));
    final location = TextEditingController(text: _docText(item?['location']));
    final description = TextEditingController(
      text: _docText(item?['description']),
    );

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'إضافة مركز تدريب جديد' : 'تعديل مركز التدريب',
      icon: Icons.local_hospital_rounded,
      color: AppColors.royalBlue,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        color: AppColors.royalBlue,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'البيانات الأساسية للمركز',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: AppColors.slate100,
                  ),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'اسم مركز التدريب',
                      hintText: 'مثال: مستشفى الملك فهد',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'اسم المركز مطلوب.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: location,
                    decoration: const InputDecoration(
                      labelText: 'الموقع / العنوان',
                      hintText: 'مثال: الرياض - حي السليمانية',
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: AppColors.royalBlue,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'تفاصيل إضافية',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: AppColors.slate100,
                  ),
                  TextFormField(
                    controller: description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'وصف المركز',
                      hintText:
                          'مثال: مركز تدريب متخصص في حالات الطوارئ والباطنية...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'حفظ البيانات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final payload = {
      'name': name.text.trim(),
      'location': location.text.trim(),
      'description': description.text.trim(),
    };
    name.dispose();
    location.dispose();
    description.dispose();

    if (ok != true) return;

    try {
      if (item == null) {
        await ref.read(staffRepositoryProvider).post(_endpoint, payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('$_endpoint/${item['id']}', payload);
      }
      if (!mounted) return;
      if (item == null) {
        _search.clear();
        _status = null;
      }
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _openDepartmentForm({_Json? item}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: _docText(item?['name']));
    final description = TextEditingController(
      text: _docText(item?['description']),
    );

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'إضافة قسم طبي جديد' : 'تعديل القسم الطبي',
      icon: Icons.account_tree_rounded,
      color: AppColors.info,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_tree_rounded,
                        color: AppColors.info,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'البيانات الأساسية للقسم',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: AppColors.slate100,
                  ),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'اسم القسم الطبي',
                      hintText: 'مثال: الباطنة العامة، الجراحة العامة',
                      prefixIcon: Icon(Icons.account_tree_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'اسم القسم مطلوب.'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: AppColors.info,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'تفاصيل إضافية',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: AppColors.slate100,
                  ),
                  TextFormField(
                    controller: description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'وصف القسم',
                      hintText:
                          'مثال: يختص هذا القسم بالحالات السريرية المتعلقة بـ...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'حفظ البيانات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.info,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final payload = {
      'name': name.text.trim(),
      'description': description.text.trim(),
    };
    name.dispose();
    description.dispose();

    if (ok != true) return;

    try {
      if (item == null) {
        await ref.read(staffRepositoryProvider).post(_endpoint, payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('$_endpoint/${item['id']}', payload);
      }
      if (!mounted) return;
      if (item == null) {
        _search.clear();
        _status = null;
      }
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _openBodySystemForm({_Json? item}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: _docText(item?['name']));
    final description = TextEditingController(
      text: _docText(item?['description']),
    );

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'إضافة نظام جسم جديد' : 'تعديل نظام الجسم',
      icon: Icons.biotech_rounded,
      color: AppColors.teal,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.biotech_rounded,
                        color: AppColors.teal,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'البيانات الأساسية للنظام',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: AppColors.slate100,
                  ),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'اسم نظام الجسم السريري',
                      hintText: 'مثال: الجهاز التنفسي، الجهاز الهضمي',
                      prefixIcon: Icon(Icons.biotech_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'اسم النظام مطلوب.'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: AppColors.teal,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'تفاصيل إضافية',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: AppColors.slate100,
                  ),
                  TextFormField(
                    controller: description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'وصف النظام',
                      hintText:
                          'مثال: يختص هذا النظام بالحالات والأعراض المرتبطة بـ...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'حفظ البيانات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final payload = {
      'name': name.text.trim(),
      'description': description.text.trim(),
    };
    name.dispose();
    description.dispose();

    if (ok != true) return;

    try {
      if (item == null) {
        await ref.read(staffRepositoryProvider).post(_endpoint, payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('$_endpoint/${item['id']}', payload);
      }
      if (!mounted) return;
      if (item == null) {
        _search.clear();
        _status = null;
      }
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _showDepartmentDetails(_Json item) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل القسم الطبي',
      icon: Icons.account_tree_rounded,
      color: AppColors.info,
      child: _DepartmentDetails(departmentItem: item),
    );
  }

  Future<void> _showBodySystemDetails(_Json item) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل نظام الجسم',
      icon: Icons.biotech_rounded,
      color: AppColors.teal,
      child: _BodySystemDetails(bodySystemItem: item),
    );
  }
}
