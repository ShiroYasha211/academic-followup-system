part of 'staff_screens.dart';

class DoctorClinicalScreen extends ConsumerStatefulWidget {
  const DoctorClinicalScreen({super.key});

  static const route = '/doctor/clinical';

  @override
  ConsumerState<DoctorClinicalScreen> createState() =>
      _DoctorClinicalScreenState();
}

class _DoctorClinicalScreenState extends ConsumerState<DoctorClinicalScreen> {
  late Future<_ClinicalBundle> _future = _fetch();

  Future<_ClinicalBundle> _fetch() async {
    final overview = await ref
        .read(staffRepositoryProvider)
        .get('/doctor/clinical/overview');
    return _ClinicalBundle(overview: _docMap(_docData(overview)));
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'القسم العملي',
      currentRoute: DoctorClinicalScreen.route,
      child: FutureBuilder<_ClinicalBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final bundle = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'القسم العملي والسريري',
                  subtitle:
                      'متابعة الحالات العملية، إعلان الحالات النادرة، وإدارة سجل المتطوعين.',
                  icon: Icons.medical_services_rounded,
                ),
                const SizedBox(height: 16),
                _buildOverview(bundle),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverview(_ClinicalBundle bundle) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DocMetric(
              label: 'الحالات',
              value: _docText(bundle.overview['total_cases'], '0'),
              color: AppColors.royalBlue,
              icon: Icons.medical_information_rounded,
            ),
            _DocMetric(
              label: 'نشطة',
              value: _docText(bundle.overview['active_cases'], '0'),
              color: AppColors.success,
              icon: Icons.play_circle_rounded,
            ),
            _DocMetric(
              label: 'حالات نادرة',
              value: _docText(bundle.overview['rare_cases'], '0'),
              color: AppColors.warning,
              icon: Icons.campaign_rounded,
            ),
            _DocMetric(
              label: 'متطوعون',
              value: _docText(bundle.overview['volunteers'], '0'),
              color: AppColors.teal,
              icon: Icons.groups_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ClinicalActionCard(
          title: 'إعلان حالة نادرة',
          subtitle:
              'انشر حالة سريرية مهمة للطلاب مع تفاصيل المستشفى والقسم والمرفق.',
          icon: Icons.campaign_rounded,
          color: AppColors.warning,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('rare-cases')),
        ),
        _ClinicalActionCard(
          title: 'سجل المتطوعين',
          subtitle:
              'أضف متطوعين للحالات العملية وتابع حالة توفرهم ومعلومات التواصل.',
          icon: Icons.groups_rounded,
          color: AppColors.teal,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('volunteers')),
        ),
        _ClinicalActionCard(
          title: 'مراكز التدريب',
          subtitle: 'إدارة المستشفيات والمراكز التي يتم فيها التدريب السريري.',
          icon: Icons.local_hospital_rounded,
          color: AppColors.royalBlue,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('centers')),
        ),
        _ClinicalActionCard(
          title: 'الأقسام السريرية',
          subtitle:
              'إدارة الأقسام، الإضافة والتعديل والإخفاء واستعادة الافتراضي.',
          icon: Icons.account_tree_rounded,
          color: AppColors.info,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('departments')),
        ),
        _ClinicalActionCard(
          title: 'أنظمة الجسم',
          subtitle: 'إدارة أنظمة الجسم المرتبطة بالحالات والتقييمات السريرية.',
          icon: Icons.biotech_rounded,
          color: AppColors.teal,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('body-systems')),
        ),
        _ClinicalActionCard(
          title: 'الحالات السريرية',
          subtitle:
              'إضافة الحالات، تصفيتها، تحديث حالتها، وربطها بالمركز والقسم والجهاز.',
          icon: Icons.medical_information_rounded,
          color: AppColors.success,
          onTap: () => context.push(DoctorClinicalSectionScreen.path('cases')),
        ),
        _ClinicalActionCard(
          title: 'تكليف الحالات',
          subtitle: 'تكليف الطلاب بحالات سريرية ومراجعة طلبات الاعتماد.',
          icon: Icons.assignment_ind_rounded,
          color: AppColors.warning,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('assignments')),
        ),
        _ClinicalActionCard(
          title: 'السجل العملي وQR',
          subtitle: 'مسح QR، مراجعة سجلات الطلاب، وتسجيل حضور يدوي عند الحاجة.',
          icon: Icons.qr_code_scanner_rounded,
          color: AppColors.teal,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('records')),
        ),
        _ClinicalActionCard(
          title: 'تقييمات OSCE',
          subtitle: 'قوائم التقييم، بدء تقييم طالب، ومراجعة النتائج.',
          icon: Icons.fact_check_rounded,
          color: AppColors.danger,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('checklists')),
        ),
      ],
    );
  }

  // Kept for the older inline clinical tab layout; the clinical hub now opens
  // rare cases as a dedicated section page.
  // ignore: unused_element
  Widget _buildRareCases(List<_Json> cases) {
    if (cases.isEmpty) {
      return Column(
        children: [
          const _DocEmpty('لا توجد حالات نادرة منشورة بعد.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showRareCaseForm(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إعلان حالة نادرة'),
          ),
        ],
      );
    }
    return Column(
      children: cases
          .map(
            (rareCase) => _RareCaseCard(
              rareCase: rareCase,
              onTap: () => _showRareCaseDetails(rareCase),
              onToggle: () => _toggleRareCase(rareCase),
              onDelete: () => _deleteRareCase(rareCase),
            ),
          )
          .toList(),
    );
  }

  // Kept for the older inline clinical tab layout; volunteers now open as a
  // dedicated section page.
  // ignore: unused_element
  Widget _buildVolunteers(List<_Json> volunteers) {
    if (volunteers.isEmpty) {
      return Column(
        children: [
          const _DocEmpty('لا يوجد متطوعون في السجل بعد.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showVolunteerForm(),
            icon: const Icon(Icons.person_add_alt_rounded),
            label: const Text('إضافة متطوع'),
          ),
        ],
      );
    }
    return Column(
      children: volunteers
          .map(
            (volunteer) => _VolunteerCard(
              volunteer: volunteer,
              onTap: () => _showVolunteerDetails(volunteer),
              onEdit: () => _showVolunteerForm(volunteer: volunteer),
              onToggle: () => _toggleVolunteer(volunteer),
              onDelete: () => _deleteVolunteer(volunteer),
            ),
          )
          .toList(),
    );
  }

  Future<void> _showRareCaseDetails(_Json rareCase) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الحالة النادرة',
      icon: Icons.campaign_rounded,
      color: _docBool(rareCase['is_active'])
          ? AppColors.success
          : AppColors.slate500,
      child: _RareCaseDetails(
        rareCase: rareCase,
        onDownload: () => _downloadRareCaseAttachment(rareCase),
      ),
    );
  }

  Future<void> _showRareCaseForm() async {
    final formKey = GlobalKey<FormState>();
    final patientName = TextEditingController();
    final hospital = TextEditingController();
    final department = TextEditingController();
    final room = TextEditingController();
    final diagnosis = TextEditingController();
    final signs = TextEditingController();
    PlatformFile? attachment;

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'إعلان حالة نادرة',
      icon: Icons.campaign_rounded,
      color: AppColors.warning,
      fullScreen: true,
      child: StatefulBuilder(
        builder: (context, setLocal) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: diagnosis,
                  decoration: const InputDecoration(labelText: 'التشخيص'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'التشخيص مطلوب.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hospital,
                  decoration: const InputDecoration(
                    labelText: 'المستشفى / المركز',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'المستشفى مطلوب.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: department,
                  decoration: const InputDecoration(labelText: 'القسم'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'القسم مطلوب.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: room,
                  decoration: const InputDecoration(labelText: 'رقم الغرفة'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: patientName,
                  decoration: const InputDecoration(
                    labelText: 'اسم المريض (اختياري)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: signs,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'العلامات السريرية',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                    );
                    if (result?.files.single != null) {
                      setLocal(() => attachment = result!.files.single);
                    }
                  },
                  icon: const Icon(Icons.image_rounded),
                  label: Text(attachment?.name ?? 'إضافة صورة مرفقة'),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('نشر الحالة'),
                ),
              ],
            ),
          );
        },
      ),
    );

    final payload = ok == true
        ? <String, dynamic>{
            'patient_name': patientName.text.trim(),
            'hospital': hospital.text.trim(),
            'department': department.text.trim(),
            'room_number': room.text.trim(),
            'diagnosis': diagnosis.text.trim(),
            'clinical_signs': signs.text.trim(),
          }
        : null;

    patientName.dispose();
    hospital.dispose();
    department.dispose();
    room.dispose();
    diagnosis.dispose();
    signs.dispose();

    if (ok != true || payload == null) return;
    try {
      if (attachment?.path != null) {
        payload['attachment'] = await MultipartFile.fromFile(
          attachment!.path!,
          filename: attachment!.name,
        );
      }
      await ref
          .read(staffRepositoryProvider)
          .upload('/doctor/clinical/rare-cases', payload);
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم نشر الحالة النادرة.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _toggleRareCase(_Json rareCase) async {
    try {
      await ref
          .read(staffRepositoryProvider)
          .patch(
            '/doctor/clinical/rare-cases/${rareCase['id']}/toggle',
            const {},
          );
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _deleteRareCase(_Json rareCase) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف الحالة النادرة',
      message: 'هل تريد حذف هذا الإعلان؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/clinical/rare-cases/${rareCase['id']}');
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حذف الحالة.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _downloadRareCaseAttachment(_Json rareCase) async {
    final url = _docText(rareCase['attachment_url']);
    if (url.isEmpty) return;
    try {
      final result = await DownloadService.downloadUrlToMoeenFolder(
        url: url,
        fileName: 'rare_case_${rareCase['id']}.jpg',
        section: 'RareCases',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم التحميل',
        message: 'تم حفظ المرفق في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _showVolunteerDetails(_Json volunteer) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'بيانات المتطوع',
      icon: Icons.person_rounded,
      color: _docBool(volunteer['is_available'])
          ? AppColors.success
          : AppColors.slate500,
      child: _VolunteerDetails(volunteer: volunteer),
    );
  }

  Future<void> _showVolunteerForm({_Json? volunteer}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: _docText(volunteer?['name']));
    final contact = TextEditingController(
      text: _docText(volunteer?['contact_info']),
    );
    final secondary = TextEditingController(
      text: _docText(volunteer?['phone_secondary']),
    );
    final email = TextEditingController(text: _docText(volunteer?['email']));
    final diagnosis = TextEditingController(
      text: _docText(volunteer?['diagnosis']),
    );
    final signs = TextEditingController(
      text: _docText(volunteer?['clinical_signs']),
    );

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: volunteer == null ? 'إضافة متطوع' : 'تعديل متطوع',
      icon: Icons.person_add_alt_rounded,
      color: AppColors.teal,
      fullScreen: true,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'اسم المتطوع'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'اسم المتطوع مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contact,
              decoration: const InputDecoration(
                labelText: 'رقم التواصل / واتساب',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'رقم التواصل مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: secondary,
              decoration: const InputDecoration(labelText: 'رقم إضافي'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: diagnosis,
              decoration: const InputDecoration(labelText: 'التشخيص'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'التشخيص مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: signs,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'العلامات السريرية'),
            ),
            const SizedBox(height: 18),
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

    final payload = ok == true
        ? {
            'name': name.text.trim(),
            'contact_info': contact.text.trim(),
            'phone_secondary': secondary.text.trim(),
            'email': email.text.trim(),
            'diagnosis': diagnosis.text.trim(),
            'clinical_signs': signs.text.trim(),
          }
        : null;

    name.dispose();
    contact.dispose();
    secondary.dispose();
    email.dispose();
    diagnosis.dispose();
    signs.dispose();

    if (ok != true || payload == null) return;
    try {
      if (volunteer == null) {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/clinical/volunteers', payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('/doctor/clinical/volunteers/${volunteer['id']}', payload);
      }
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حفظ بيانات المتطوع.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _toggleVolunteer(_Json volunteer) async {
    try {
      await ref
          .read(staffRepositoryProvider)
          .patch(
            '/doctor/clinical/volunteers/${volunteer['id']}/toggle',
            const {},
          );
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _deleteVolunteer(_Json volunteer) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف المتطوع',
      message: 'هل تريد حذف هذا المتطوع من السجل؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/clinical/volunteers/${volunteer['id']}');
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حذف المتطوع.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class DoctorClinicalSectionScreen extends ConsumerStatefulWidget {
  const DoctorClinicalSectionScreen({super.key, required this.section});

  static const route = '/doctor/clinical/:section';

  final String section;

  static String path(String section) => '/doctor/clinical/$section';

  @override
  ConsumerState<DoctorClinicalSectionScreen> createState() =>
      _DoctorClinicalSectionScreenState();
}

class _DoctorClinicalSectionScreenState
    extends ConsumerState<DoctorClinicalSectionScreen> {
  final _search = TextEditingController();
  String? _status;
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _processingQr = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _endpoint => switch (widget.section) {
    'centers' => '/doctor/clinical/training-centers',
    'departments' => '/doctor/clinical/departments',
    'body-systems' => '/doctor/clinical/body-systems',
    'cases' => '/doctor/clinical/cases',
    'assignments' => '/doctor/clinical/assignments',
    'records' => '/doctor/clinical/logbook/records',
    'checklists' => '/doctor/clinical/evaluations/checklists',
    'evaluation-start' => '/doctor/clinical/evaluations/start-data',
    'results' => '/doctor/clinical/evaluations/results',
    'rare-cases' => '/doctor/clinical/rare-cases',
    'volunteers' => '/doctor/clinical/volunteers',
    _ => '/doctor/clinical/overview',
  };

  String get _title => switch (widget.section) {
    'centers' => 'مراكز التدريب',
    'departments' => 'الأقسام السريرية',
    'body-systems' => 'أنظمة الجسم',
    'cases' => 'الحالات السريرية',
    'assignments' => 'تكليف الحالات',
    'scanner' => 'ماسح QR للسجل العملي',
    'records' => 'سجلات الطلاب العملية',
    'manual' => 'تسجيل حضور عملي يدوي',
    'checklists' => 'قوائم تقييم OSCE',
    'evaluation-start' => 'بدء تقييم OSCE',
    'results' => 'نتائج تقييم OSCE',
    'rare-cases' => 'إعلان حالات نادرة',
    'volunteers' => 'سجل المتطوعين',
    _ => 'القسم السريري',
  };

  IconData get _icon => switch (widget.section) {
    'centers' => Icons.local_hospital_rounded,
    'departments' => Icons.account_tree_rounded,
    'body-systems' => Icons.biotech_rounded,
    'cases' => Icons.medical_information_rounded,
    'assignments' => Icons.assignment_ind_rounded,
    'scanner' => Icons.qr_code_scanner_rounded,
    'records' => Icons.library_books_rounded,
    'manual' => Icons.edit_calendar_rounded,
    'checklists' => Icons.fact_check_rounded,
    'evaluation-start' => Icons.play_circle_rounded,
    'results' => Icons.analytics_rounded,
    'rare-cases' => Icons.campaign_rounded,
    'volunteers' => Icons.groups_rounded,
    _ => Icons.medical_services_rounded,
  };

  bool get _canAdd => {
    'centers',
    'departments',
    'body-systems',
    'cases',
    'assignments',
    'checklists',
    'rare-cases',
    'volunteers',
  }.contains(widget.section);

  Future<Map<String, dynamic>> _fetch() {
    if (widget.section == 'scanner' || widget.section == 'manual') {
      return ref
          .read(staffRepositoryProvider)
          .get('/doctor/clinical/evaluations/start-data');
    }
    return ref
        .read(staffRepositoryProvider)
        .get(
          _endpoint,
          query: {
            if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
            if (_status != null && _status!.isNotEmpty) 'status': _status,
          },
        );
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: _title,
      currentRoute: DoctorClinicalScreen.route,
      floatingActionButton: _canAdd
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة'),
            )
          : null,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final data = _docMap(_docData(snapshot.data ?? const {}));
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: _title,
                  subtitle:
                      'إدارة هذا الجزء بنفس منطق الويب مع واجهة مناسبة للتطبيق.',
                  icon: _icon,
                ),
                const SizedBox(height: 14),
                _buildSectionShortcuts(),
                const SizedBox(height: 14),
                if (_showsFilters) _buildFilters(),
                if (_showsFilters) const SizedBox(height: 14),
                ..._buildBody(data),
              ],
            ),
          );
        },
      ),
    );
  }

  bool get _showsFilters =>
      !{'scanner', 'manual', 'evaluation-start'}.contains(widget.section);

  Widget _buildSectionShortcuts() {
    if (widget.section == 'checklists') {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: () => context.push(
              DoctorClinicalSectionScreen.path('evaluation-start'),
            ),
            icon: const Icon(Icons.play_circle_rounded),
            label: const Text('بدء تقييم'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                context.push(DoctorClinicalSectionScreen.path('results')),
            icon: const Icon(Icons.analytics_rounded),
            label: const Text('نتائج التقييم'),
          ),
        ],
      );
    }
    if (widget.section == 'records') {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: () =>
                context.push(DoctorClinicalSectionScreen.path('scanner')),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('مسح QR'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                context.push(DoctorClinicalSectionScreen.path('manual')),
            icon: const Icon(Icons.edit_calendar_rounded),
            label: const Text('حضور يدوي'),
          ),
        ],
      );
    }
    if (widget.section == 'departments') {
      return OutlinedButton.icon(
        onPressed: () =>
            _restoreDefaults('/doctor/clinical/departments/restore'),
        icon: const Icon(Icons.restore_rounded),
        label: const Text('استعادة الأقسام الافتراضية'),
      );
    }
    if (widget.section == 'body-systems') {
      return OutlinedButton.icon(
        onPressed: () =>
            _restoreDefaults('/doctor/clinical/body-systems/restore'),
        icon: const Icon(Icons.restore_rounded),
        label: const Text('استعادة الأنظمة الافتراضية'),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFilters() {
    return _DocFilterPanel(
      title: 'بحث وتصفية',
      icon: Icons.tune_rounded,
      children: [
        TextField(
          controller: _search,
          onSubmitted: (_) => _reload(),
          decoration: InputDecoration(
            hintText: 'بحث...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ),
        if ({
          'cases',
          'assignments',
          'records',
          'results',
        }.contains(widget.section)) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'الحالة'),
            items: const [
              DropdownMenuItem(value: null, child: Text('الكل')),
              DropdownMenuItem(value: 'active', child: Text('نشط')),
              DropdownMenuItem(value: 'pending', child: Text('بانتظار')),
              DropdownMenuItem(value: 'confirmed', child: Text('معتمد')),
              DropdownMenuItem(
                value: 'partially_confirmed',
                child: Text('اعتماد جزئي'),
              ),
              DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
              DropdownMenuItem(value: 'assigned', child: Text('مكلف')),
              DropdownMenuItem(
                value: 'submitted_for_review',
                child: Text('بانتظار المراجعة'),
              ),
              DropdownMenuItem(value: 'approved', child: Text('مقبول')),
            ],
            onChanged: (value) {
              _status = value;
              _reload();
            },
          ),
        ],
      ],
    );
  }

  List<Widget> _buildBody(_Json data) {
    return switch (widget.section) {
      'scanner' => [_buildScanner()],
      'manual' => [_buildManualAttendance(data)],
      'evaluation-start' => [_buildEvaluationStart(data)],
      'results' => _buildResults(data),
      'checklists' => _buildChecklists(data),
      'assignments' => _buildAssignments(data),
      'records' => _buildRecords(data),
      _ => _buildGenericItems(data),
    };
  }

  List<_Json> _itemsFrom(_Json data) {
    if (data.containsKey('checklists')) return _docList(data['checklists']);
    final nestedData = _docMap(data['data']);
    if (nestedData['data'] is List) return _docList(nestedData['data']);
    return _docList(data['data'] ?? data['items'] ?? data);
  }

  List<Widget> _buildGenericItems(_Json data) {
    final items = _itemsFrom(data);
    if (items.isEmpty) return [const _DocEmpty('لا توجد بيانات حالية.')];
    return items
        .map(
          (item) => _ClinicalListCard(
            title: _genericTitle(item),
            subtitle: _genericSubtitle(item),
            icon: _icon,
            color: _docStatusColor(_docText(item['status'], 'active')),
            status: _docText(item['status_label'], _docText(item['status'])),
            onTap: () => _showGenericDetails(item),
            onEdit: _canAdd ? () => _openEdit(item) : null,
            onDelete: _canAdd ? () => _deleteItem(item) : null,
          ),
        )
        .toList();
  }

  String _genericTitle(_Json item) {
    return _docText(
      item['name'] ??
          item['title'] ??
          item['patient_name'] ??
          item['diagnosis'] ??
          item['student_name'],
      'عنصر',
    );
  }

  String _genericSubtitle(_Json item) {
    final parts = [
      _docText(item['description']),
      _docText(item['location']),
      _docText(item['diagnosis_or_description']),
      _docText(item['hospital']),
      _docText(item['department']),
      _docText(_docMap(item['training_center'])['name']),
      _docText(_docMap(item['clinical_department'])['name']),
      _docText(_docMap(item['body_system'])['name']),
      _docDate(item['created_at']),
    ].where((value) => value.isNotEmpty && value != '-').take(3).join(' • ');
    return parts.isEmpty ? 'اضغط لعرض التفاصيل' : parts;
  }

  List<Widget> _buildAssignments(_Json data) {
    final items = _itemsFrom(data);
    if (items.isEmpty) return [const _DocEmpty('لا توجد تكليفات حالات.')];
    return items.map((item) {
      final status = _docText(item['status']);
      return _ClinicalListCard(
        title: _docText(_docMap(item['student'])['name'], 'طالب'),
        subtitle:
            '${_docText(item['task_type'], 'مهمة')} • ${_docText(_docMap(item['clinical_case'])['patient_name'], 'حالة')}',
        icon: Icons.assignment_ind_rounded,
        color: _docStatusColor(status),
        status: _docText(item['status_label'], status),
        onTap: () => _showGenericDetails(item),
        onEdit: status == 'submitted_for_review'
            ? () => _reviewAssignment(item)
            : null,
        editLabel: status == 'submitted_for_review' ? 'مراجعة' : null,
      );
    }).toList();
  }

  List<Widget> _buildRecords(_Json data) {
    final items = _itemsFrom(data);
    if (items.isEmpty) return [const _DocEmpty('لا توجد سجلات عملية.')];
    return items.map((item) {
      final status = _docText(item['status']);
      return _ClinicalListCard(
        title: _docText(
          _docMap(item['student'])['name'],
          _docText(item['student_name'], 'طالب'),
        ),
        subtitle:
            '${_docText(item['training_center'], _docText(_docMap(item['training_center'])['name']))} • ${_docText(item['department'], _docText(_docMap(item['department'])['name']))} • ${_docDate(item['log_date'])}',
        icon: Icons.library_books_rounded,
        color: _docStatusColor(status),
        status: _docText(item['status_label'], status),
        onTap: () => _showLogDetails(item),
        onEdit: status == 'pending' || status == 'partially_confirmed'
            ? () => _showLogDetails(item)
            : null,
        editLabel: 'مراجعة',
      );
    }).toList();
  }

  List<Widget> _buildChecklists(_Json data) {
    final items = _itemsFrom(data);
    if (items.isEmpty) return [const _DocEmpty('لا توجد قوائم تقييم.')];
    return items.map((item) {
      return _ClinicalListCard(
        title: _docText(item['title'], 'قائمة تقييم'),
        subtitle:
            '${_docText(item['skill_type'], '-')} • ${_docText(item['total_marks'], '0')} درجة',
        icon: Icons.fact_check_rounded,
        color: AppColors.royalBlue,
        status: _docBool(item['is_standard']) ? 'افتراضية' : 'مخصصة',
        onTap: () => _showGenericDetails(item),
        onEdit: () => _openEdit(item),
        onDelete: () => _deleteItem(item),
      );
    }).toList();
  }

  List<Widget> _buildResults(_Json data) {
    final items = _itemsFrom(data);
    if (items.isEmpty) return [const _DocEmpty('لا توجد نتائج تقييم.')];
    return items.map((item) {
      return _ClinicalListCard(
        title: _docText(_docMap(item['student'])['name'], 'طالب'),
        subtitle:
            '${_docText(_docMap(item['checklist'])['title'], 'تقييم')} • ${_docText(item['percentage'], '0')}%',
        icon: Icons.analytics_rounded,
        color: _docStatusColor(_docText(item['grade'])),
        status: _docText(item['grade']),
        onTap: () => _showEvaluationResult(item),
      );
    }).toList();
  }

  Widget _buildScanner() {
    return Container(
      height: 420,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.black,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              onDetect: (capture) {
                if (_processingQr) return;
                final code = capture.barcodes
                    .map((item) => item.rawValue ?? '')
                    .firstWhere((value) => value.isNotEmpty, orElse: () => '');
                if (code.isNotEmpty) _processLogQr(code);
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _processingQr
                    ? 'جاري قراءة السجل...'
                    : 'وجّه الكاميرا إلى QR السجل العملي للطالب',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualAttendance(_Json data) {
    return _ClinicalManualAttendanceForm(
      data: data,
      onSubmit: (payload) async {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/clinical/logbook/manual', payload);
        if (!mounted) return;
        await showMoeenInfoDialog(
          context: context,
          title: 'تم تسجيل الحضور',
          message: 'تم تسجيل الحضور العملي يدويًا.',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        );
      },
    );
  }

  Widget _buildEvaluationStart(_Json data) {
    return _ClinicalEvaluationForm(
      data: data,
      onSubmit: (payload) async {
        final response = await ref
            .read(staffRepositoryProvider)
            .post('/doctor/clinical/evaluations/submit', payload);
        if (!mounted) return;
        await showMoeenInfoDialog(
          context: context,
          title: 'تم حفظ التقييم',
          message: _docText(response['message'], 'تم حفظ نتيجة التقييم بنجاح.'),
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        );
      },
    );
  }

  Future<void> _processLogQr(String token) async {
    setState(() => _processingQr = true);
    try {
      final response = await ref.read(staffRepositoryProvider).post(
        '/doctor/clinical/logbook/scan',
        {'qr_token': token},
      );
      if (!mounted) return;
      await _showLogDetails(_docMap(_docData(response)));
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _processingQr = false);
    }
  }

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
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _openCaseForm({_Json? item}) async {
    final options = await Future.wait([
      ref
          .read(staffRepositoryProvider)
          .get('/doctor/clinical/training-centers'),
      ref.read(staffRepositoryProvider).get('/doctor/clinical/departments'),
      ref.read(staffRepositoryProvider).get('/doctor/clinical/body-systems'),
    ]);
    if (!mounted) return;
    final centers = _clinicalPagedItems(options[0]);
    final departments = _clinicalPagedItems(options[1]);
    final systems = _clinicalPagedItems(options[2]);
    final formKey = GlobalKey<FormState>();
    final patient = TextEditingController(
      text: _docText(item?['patient_name']),
    );
    final age = TextEditingController(text: _docText(item?['age']));
    final diagnosis = TextEditingController(
      text: _docText(item?['diagnosis_or_description']),
    );
    int? centerId = _docInt(item?['training_center_id'], 0) == 0
        ? null
        : _docInt(item?['training_center_id']);
    int? departmentId = _docInt(item?['clinical_department_id'], 0) == 0
        ? null
        : _docInt(item?['clinical_department_id']);
    int? systemId = _docInt(item?['body_system_id'], 0) == 0
        ? null
        : _docInt(item?['body_system_id']);
    String gender = _docText(item?['gender'], 'male');
    String status = _docText(item?['status'], 'active');
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'إضافة حالة سريرية' : 'تعديل حالة سريرية',
      icon: Icons.medical_information_rounded,
      color: AppColors.success,
      fullScreen: true,
      child: StatefulBuilder(
        builder: (context, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            TextFormField(
              controller: patient,
              decoration: const InputDecoration(labelText: 'اسم المريض'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'اسم المريض مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'العمر'),
              validator: (value) =>
                  int.tryParse(value?.trim() ?? '') == null ? 'العمر مطلوب كرقم.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: gender,
              decoration: const InputDecoration(labelText: 'الجنس'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('ذكر')),
                DropdownMenuItem(value: 'female', child: Text('أنثى')),
              ],
              onChanged: (v) => setLocal(() => gender = v ?? gender),
            ),
            const SizedBox(height: 12),
            _clinicalDropdown(
              'المركز',
              centers,
              centerId,
              (v) => setLocal(() => centerId = v),
              validator: (value) => value == null ? 'اختر المركز.' : null,
            ),
            const SizedBox(height: 12),
            _clinicalDropdown(
              'القسم',
              departments,
              departmentId,
              (v) => setLocal(() => departmentId = v),
              validator: (value) => value == null ? 'اختر القسم.' : null,
            ),
            const SizedBox(height: 12),
            _clinicalDropdown(
              'نظام الجسم',
              systems,
              systemId,
              (v) => setLocal(() => systemId = v),
              validator: (value) => value == null ? 'اختر نظام الجسم.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'الحالة'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('نشط')),
                DropdownMenuItem(value: 'discharged', child: Text('خروج')),
                DropdownMenuItem(value: 'transferred', child: Text('تحويل')),
              ],
              onChanged: (v) => setLocal(() => status = v ?? status),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: diagnosis,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'التشخيص / الوصف'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'التشخيص أو الوصف مطلوب.'
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ الحالة'),
            ),
          ],
          ),
        ),
      ),
    );
    final payload = {
      'patient_name': patient.text.trim(),
      'age': int.tryParse(age.text.trim()),
      'gender': gender,
      'training_center_id': centerId,
      'clinical_department_id': departmentId,
      'body_system_id': systemId,
      'diagnosis_or_description': diagnosis.text.trim(),
      'status': status,
    };
    patient.dispose();
    age.dispose();
    diagnosis.dispose();
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
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _openAssignmentForm() async {
    final results = await Future.wait([
      ref.read(staffRepositoryProvider).get('/doctor/clinical/cases'),
      ref
          .read(staffRepositoryProvider)
          .get('/doctor/clinical/evaluations/start-data'),
    ]);
    if (!mounted) return;
    final cases = _clinicalPagedItems(results[0]);
    final startData = _docMap(_docData(results[1]));
    final students = _docList(startData['students']);
    final formKey = GlobalKey<FormState>();
    int? studentId;
    int? caseId;
    String task = 'history_taking';
    final instructions = TextEditingController();
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تكليف حالة لطالب',
      icon: Icons.assignment_ind_rounded,
      color: AppColors.warning,
      child: StatefulBuilder(
        builder: (context, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _clinicalDropdown(
              'الطالب',
              students,
              studentId,
              (v) => setLocal(() => studentId = v),
              validator: (value) => value == null ? 'اختر الطالب.' : null,
            ),
            const SizedBox(height: 12),
            _clinicalDropdown(
              'الحالة',
              cases,
              caseId,
              (v) => setLocal(() => caseId = v),
              titleKey: 'patient_name',
              validator: (value) => value == null ? 'اختر الحالة.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: task,
              decoration: const InputDecoration(labelText: 'نوع المهمة'),
              items: const [
                DropdownMenuItem(
                  value: 'history_taking',
                  child: Text('أخذ التاريخ المرضي'),
                ),
                DropdownMenuItem(
                  value: 'clinical_examination',
                  child: Text('الفحص السريري'),
                ),
                DropdownMenuItem(value: 'follow_up', child: Text('متابعة')),
              ],
              onChanged: (v) => setLocal(() => task = v ?? task),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: instructions,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'تعليمات'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('إرسال التكليف'),
            ),
          ],
          ),
        ),
      ),
    );
    final payload = {
      'student_id': studentId,
      'clinical_case_id': caseId,
      'task_type': task,
      'instructions': instructions.text.trim(),
    };
    instructions.dispose();
    if (ok != true) return;
    try {
      await ref.read(staffRepositoryProvider).post(_endpoint, payload);
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _openChecklistForm({_Json? item}) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: _docText(item?['title']));
    final description = TextEditingController(
      text: _docText(item?['description']),
    );
    final minutes = TextEditingController(
      text: _docText(item?['time_limit_minutes']),
    );
    String skill = _docText(item?['skill_type'], 'history_taking');
    bool practice = _docBool(item?['is_practice_allowed']);
    final items = _docList(item?['items']).isEmpty
        ? [
            {
              'description': TextEditingController(),
              'marks': TextEditingController(text: '1'),
            },
          ]
        : _docList(item?['items'])
              .where(
                (entry) =>
                    _docText(entry['parent_id']).isEmpty ||
                    _docText(entry['parent_id']) == '0',
              )
              .map(
                (entry) => {
                  'description': TextEditingController(
                    text: _docText(entry['description']),
                  ),
                  'marks': TextEditingController(
                    text: _docText(entry['marks'], '1'),
                  ),
                },
              )
              .toList();
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'إضافة قائمة تقييم' : 'تعديل قائمة تقييم',
      icon: Icons.fact_check_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: StatefulBuilder(
        builder: (context, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'العنوان'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'العنوان مطلوب.' : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'الوصف'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: skill,
              decoration: const InputDecoration(labelText: 'نوع المهارة'),
              items: const [
                DropdownMenuItem(
                  value: 'history_taking',
                  child: Text('أخذ التاريخ'),
                ),
                DropdownMenuItem(
                  value: 'clinical_examination',
                  child: Text('الفحص السريري'),
                ),
                DropdownMenuItem(value: 'procedure', child: Text('إجراء عملي')),
                DropdownMenuItem(
                  value: 'communication',
                  child: Text('التواصل'),
                ),
              ],
              onChanged: (v) => setLocal(() => skill = v ?? skill),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الوقت بالدقائق'),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                return int.tryParse(text) == null ? 'اكتب الوقت كرقم.' : null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: practice,
              onChanged: (v) => setLocal(() => practice = v),
              title: const Text('السماح بالتدريب للطلاب'),
            ),
            const SizedBox(height: 10),
            ...items.asMap().entries.map((entry) {
              final itemMap = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller:
                          itemMap['description'] as TextEditingController,
                      decoration: InputDecoration(
                        labelText: 'بند ${entry.key + 1}',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'وصف البند مطلوب.'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: itemMap['marks'] as TextEditingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الدرجة'),
                      validator: (value) =>
                          int.tryParse(value?.trim() ?? '') == null
                          ? 'الدرجة مطلوبة كرقم.'
                          : null,
                    ),
                    if (items.length > 1)
                      TextButton.icon(
                        onPressed: () =>
                            setLocal(() => items.removeAt(entry.key)),
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('حذف البند'),
                      ),
                  ],
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: () => setLocal(() {
                items.add({
                  'description': TextEditingController(),
                  'marks': TextEditingController(text: '1'),
                });
              }),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة بند'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ القائمة'),
            ),
          ],
          ),
        ),
      ),
    );
    final payload = {
      'title': title.text.trim(),
      'description': description.text.trim(),
      'skill_type': skill,
      'time_limit_minutes': int.tryParse(minutes.text.trim()),
      'is_practice_allowed': practice,
      'items': items
          .map(
            (entry) => {
              'description': (entry['description'] as TextEditingController)
                  .text
                  .trim(),
              'marks':
                  int.tryParse(
                    (entry['marks'] as TextEditingController).text.trim(),
                  ) ??
                  1,
            },
          )
          .toList(),
    };
    title.dispose();
    description.dispose();
    minutes.dispose();
    for (final entry in items) {
      (entry['description'] as TextEditingController).dispose();
      (entry['marks'] as TextEditingController).dispose();
    }
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
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _openRareCaseForm() async {
    final formKey = GlobalKey<FormState>();
    final diagnosis = TextEditingController();
    final hospital = TextEditingController();
    final department = TextEditingController();
    final room = TextEditingController();
    final signs = TextEditingController();
    final payload = await showMoeenBottomSheet<Map<String, dynamic>>(
      context: context,
      title: 'إعلان حالة نادرة',
      icon: Icons.campaign_rounded,
      color: AppColors.warning,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: diagnosis,
              decoration: const InputDecoration(labelText: 'التشخيص'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'التشخيص مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: hospital,
              decoration: const InputDecoration(labelText: 'المستشفى / المركز'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'المستشفى أو المركز مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: department,
              decoration: const InputDecoration(labelText: 'القسم'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'القسم مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: room,
              decoration: const InputDecoration(labelText: 'رقم الغرفة'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: signs,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'العلامات السريرية'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, {
                  'diagnosis': diagnosis.text.trim(),
                  'hospital': hospital.text.trim(),
                  'department': department.text.trim(),
                  'room_number': room.text.trim(),
                  'clinical_signs': signs.text.trim(),
                });
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('نشر'),
            ),
          ],
        ),
      ),
    );
    if (payload == null) return;
    try {
      await ref.read(staffRepositoryProvider).post(_endpoint, payload);
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _openVolunteerForm({_Json? item}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: _docText(item?['name']));
    final contact = TextEditingController(
      text: _docText(item?['contact_info']),
    );
    final email = TextEditingController(text: _docText(item?['email']));
    final diagnosis = TextEditingController(text: _docText(item?['diagnosis']));
    final signs = TextEditingController(
      text: _docText(item?['clinical_signs']),
    );
    final payload = await showMoeenBottomSheet<Map<String, dynamic>>(
      context: context,
      title: item == null ? 'إضافة متطوع' : 'تعديل متطوع',
      icon: Icons.person_add_alt_rounded,
      color: AppColors.teal,
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
            const SizedBox(height: 12),
            TextFormField(
              controller: contact,
              decoration: const InputDecoration(labelText: 'رقم التواصل'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'رقم التواصل مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                return text.contains('@') ? null : 'البريد الإلكتروني غير صحيح.';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: diagnosis,
              decoration: const InputDecoration(labelText: 'التشخيص'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'التشخيص مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: signs,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'العلامات السريرية'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, {
                  'name': name.text.trim(),
                  'contact_info': contact.text.trim(),
                  'email': email.text.trim(),
                  'diagnosis': diagnosis.text.trim(),
                  'clinical_signs': signs.text.trim(),
                });
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (payload == null) return;
    try {
      if (item == null) {
        await ref.read(staffRepositoryProvider).post(_endpoint, payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('$_endpoint/${item['id']}', payload);
      }
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  DropdownButtonFormField<int> _clinicalDropdown(
    String label,
    List<_Json> items,
    int? value,
    ValueChanged<int?> onChanged, {
    String titleKey = 'name',
    FormFieldValidator<int>? validator,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: _docInt(item['id']),
              child: Text(
                _docText(item[titleKey], _docText(item['name'], '-')),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Future<void> _showGenericDetails(_Json item) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: _genericTitle(item),
      icon: _icon,
      color: AppColors.royalBlue,
      child: _JsonDetailsView(item: item),
    );
  }

  Future<void> _showEvaluationResult(_Json item) async {
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .get('/doctor/clinical/evaluations/results/${item['id']}');
      if (!mounted) return;
      await showMoeenBottomSheet<void>(
        context: context,
        title: 'تفاصيل نتيجة التقييم',
        icon: Icons.analytics_rounded,
        color: AppColors.royalBlue,
        child: _JsonDetailsView(item: _docMap(_docData(response))),
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _showLogDetails(_Json rawLog) async {
    final log = rawLog.containsKey('log') ? _docMap(rawLog['log']) : rawLog;
    final groups = _docList(log['groups']);
    final confirmations = <String, bool>{
      for (final group in groups)
        _docText(group['key']): _docBool(group['confirmed']),
    };
    final notes = TextEditingController(text: _docText(log['doctor_notes']));
    final action = await showMoeenBottomSheet<String>(
      context: context,
      title: 'مراجعة السجل العملي',
      icon: Icons.library_books_rounded,
      color: _docStatusColor(_docText(log['status'])),
      fullScreen: true,
      child: StatefulBuilder(
        builder: (context, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _JsonDetailsView(item: log),
            const SizedBox(height: 12),
            if (groups.isNotEmpty)
              ...groups.map((group) {
                final key = _docText(group['key']);
                return CheckboxListTile(
                  value: confirmations[key] ?? false,
                  onChanged: (v) =>
                      setLocal(() => confirmations[key] = v ?? false),
                  title: Text(_docText(group['label'], key)),
                  subtitle: Text('${_docText(group['count'], '0')} عناصر'),
                );
              }),
            TextField(
              controller: notes,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'ملاحظات الدكتور'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'reject'),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, 'confirm'),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('اعتماد'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/clinical/logbook/confirm',
        {
          'log_id': log['log_id'] ?? log['id'],
          'action': action,
          'doctor_notes': notes.text.trim(),
          'confirmations': {
            for (final entry in confirmations.entries)
              entry.key: {'confirm': entry.value},
          },
        },
      );
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      notes.dispose();
    }
  }

  Future<void> _reviewAssignment(_Json assignment) async {
    final notes = TextEditingController();
    final action = await showMoeenBottomSheet<String>(
      context: context,
      title: 'مراجعة التكليف',
      icon: Icons.assignment_turned_in_rounded,
      color: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _JsonDetailsView(item: assignment),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'ملاحظات المراجعة'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'reject'),
                  child: const Text('رفض'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, 'approve'),
                  child: const Text('اعتماد'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (action == null) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/clinical/assignments/${assignment['id']}/review',
        {'action': action, 'review_notes': notes.text.trim()},
      );
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      notes.dispose();
    }
  }

  Future<void> _deleteItem(_Json item) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل تريد حذف هذا العنصر؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('$_endpoint/${item['id']}');
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _restoreDefaults(String endpoint) async {
    try {
      await ref.read(staffRepositoryProvider).post(endpoint, const {});
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _ClinicalListCard extends StatelessWidget {
  const _ClinicalListCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.status,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.editLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? status;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? editLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_docText(status).isNotEmpty)
                        _DocPill(status!, color, icon: Icons.circle_rounded),
                      if (onEdit != null)
                        ActionChip(
                          onPressed: onEdit,
                          avatar: const Icon(Icons.edit_rounded, size: 16),
                          label: Text(editLabel ?? 'تعديل'),
                        ),
                      if (onDelete != null)
                        ActionChip(
                          onPressed: onDelete,
                          avatar: const Icon(
                            Icons.delete_rounded,
                            size: 16,
                            color: AppColors.danger,
                          ),
                          label: const Text('حذف'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JsonDetailsView extends StatelessWidget {
  const _JsonDetailsView({required this.item});

  final _Json item;

  @override
  Widget build(BuildContext context) {
    final rows = _flatten(
      item,
    ).entries.where((entry) => entry.value.isNotEmpty).take(28).toList();
    if (rows.isEmpty) return const _DocEmpty('لا توجد تفاصيل إضافية.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows
          .map((entry) => _DetailRow(_label(entry.key), entry.value))
          .toList(),
    );
  }

  Map<String, String> _flatten(
    Map<String, dynamic> source, [
    String prefix = '',
  ]) {
    final result = <String, String>{};
    for (final entry in source.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      final value = entry.value;
      if (value == null) continue;
      if (value is Map) {
        result.addAll(_flatten(Map<String, dynamic>.from(value), key));
      } else if (value is List) {
        if (value.isNotEmpty) result[key] = '${value.length} عناصر';
      } else {
        final text = value.toString();
        if (text.isNotEmpty) result[key] = text;
      }
    }
    return result;
  }

  String _label(String key) {
    return switch (key) {
      'id' => 'المعرف',
      'name' => 'الاسم',
      'title' => 'العنوان',
      'description' => 'الوصف',
      'patient_name' => 'اسم المريض',
      'student.name' => 'الطالب',
      'student.student_number' => 'رقم القيد',
      'status' => 'الحالة',
      'status_label' => 'وصف الحالة',
      'created_at' => 'تاريخ الإنشاء',
      'updated_at' => 'آخر تحديث',
      'diagnosis' => 'التشخيص',
      'diagnosis_or_description' => 'التشخيص / الوصف',
      'clinical_signs' => 'العلامات السريرية',
      'doctor_notes' => 'ملاحظات الدكتور',
      _ => key.replaceAll('_', ' '),
    };
  }
}

class _ClinicalManualAttendanceForm extends StatefulWidget {
  const _ClinicalManualAttendanceForm({
    required this.data,
    required this.onSubmit,
  });

  final _Json data;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_ClinicalManualAttendanceForm> createState() =>
      _ClinicalManualAttendanceFormState();
}

class _ClinicalManualAttendanceFormState
    extends State<_ClinicalManualAttendanceForm> {
  int? _studentId;
  int? _centerId;
  int? _departmentId;
  bool _saving = false;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final students = _docList(widget.data['students']);
    final centers = _docList(
      widget.data['training_centers'] ?? widget.data['centers'],
    );
    final departments = _docList(widget.data['departments']);
    return _DocFilterPanel(
      title: 'تسجيل حضور يدوي',
      icon: Icons.edit_calendar_rounded,
      children: [
        _dropdown(
          'الطالب',
          students,
          _studentId,
          (v) => setState(() => _studentId = v),
        ),
        const SizedBox(height: 12),
        _dropdown(
          'المركز',
          centers,
          _centerId,
          (v) => setState(() => _centerId = v),
        ),
        const SizedBox(height: 12),
        _dropdown(
          'القسم',
          departments,
          _departmentId,
          (v) => setState(() => _departmentId = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'ملاحظات'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('تسجيل الحضور'),
        ),
      ],
    );
  }

  DropdownButtonFormField<int> _dropdown(
    String label,
    List<_Json> items,
    int? value,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: _docInt(item['id']),
              child: Text(
                _docText(item['name'], _docText(item['student_number'], '-')),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        'student_id': _studentId,
        'training_center_id': _centerId,
        'department_id': _departmentId,
        'doctor_notes': _notes.text.trim(),
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ClinicalEvaluationForm extends StatefulWidget {
  const _ClinicalEvaluationForm({required this.data, required this.onSubmit});

  final _Json data;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_ClinicalEvaluationForm> createState() =>
      _ClinicalEvaluationFormState();
}

class _ClinicalEvaluationFormState extends State<_ClinicalEvaluationForm> {
  int? _studentId;
  int? _checklistId;
  int? _bodySystemId;
  String _timerType = 'fixed';
  final _feedback = TextEditingController();
  final Map<int, String> _scores = {};
  bool _saving = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  _Json? get _selectedChecklist {
    return _docList(widget.data['checklists'])
        .where((item) => _docInt(item['id']) == _checklistId)
        .cast<_Json?>()
        .firstWhere((item) => item != null, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    final students = _docList(widget.data['students']);
    final checklists = _docList(widget.data['checklists']);
    final systems = _docList(widget.data['body_systems']);
    final checklist = _selectedChecklist;
    final items = _docList(checklist?['items'])
        .where(
          (item) =>
              _docText(item['parent_id']).isEmpty ||
              _docText(item['parent_id']) == '0',
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocFilterPanel(
          title: 'بيانات التقييم',
          icon: Icons.play_circle_rounded,
          children: [
            _dropdown(
              'الطالب',
              students,
              _studentId,
              (v) => setState(() => _studentId = v),
            ),
            const SizedBox(height: 12),
            _dropdown('قائمة التقييم', checklists, _checklistId, (v) {
              setState(() {
                _checklistId = v;
                _scores.clear();
              });
            }, titleKey: 'title'),
            const SizedBox(height: 12),
            _dropdown(
              'نظام الجسم',
              systems,
              _bodySystemId,
              (v) => setState(() => _bodySystemId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _timerType,
              decoration: const InputDecoration(labelText: 'نوع المؤقت'),
              items: const [
                DropdownMenuItem(value: 'fixed', child: Text('رسمي / ثابت')),
                DropdownMenuItem(value: 'open', child: Text('مفتوح')),
              ],
              onChanged: (v) => setState(() => _timerType = v ?? _timerType),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const _DocEmpty('اختر قائمة تقييم لعرض البنود.')
        else
          ...items.map((item) {
            final id = _docInt(item['id']);
            final score = _scores[id] ?? 'not_done';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _docText(item['description']),
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    selected: {score},
                    segments: const [
                      ButtonSegment(value: 'done', label: Text('تم')),
                      ButtonSegment(value: 'partial', label: Text('جزئي')),
                      ButtonSegment(value: 'not_done', label: Text('لم يتم')),
                    ],
                    onSelectionChanged: (value) =>
                        setState(() => _scores[id] = value.first),
                  ),
                ],
              ),
            );
          }),
        TextField(
          controller: _feedback,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'ملاحظات التقييم'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving || items.isEmpty ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('حفظ التقييم'),
        ),
      ],
    );
  }

  DropdownButtonFormField<int> _dropdown(
    String label,
    List<_Json> items,
    int? value,
    ValueChanged<int?> onChanged, {
    String titleKey = 'name',
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: _docInt(item['id']),
              child: Text(
                _docText(item[titleKey], _docText(item['name'], '-')),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final checklist = _selectedChecklist;
      final items = _docList(checklist?['items'])
          .where(
            (item) =>
                _docText(item['parent_id']).isEmpty ||
                _docText(item['parent_id']) == '0',
          )
          .toList();
      await widget.onSubmit({
        'checklist_id': _checklistId,
        'student_id': _studentId,
        'body_system_id': _bodySystemId,
        'timer_type': _timerType,
        'time_taken_seconds': 0,
        'doctor_feedback': _feedback.text.trim(),
        'scores': {
          for (final item in items)
            '${_docInt(item['id'])}': {
              'score': _scores[_docInt(item['id'])] ?? 'not_done',
            },
        },
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ClinicalBundle {
  const _ClinicalBundle({
    required this.overview,
  });

  final _Json overview;
}

List<_Json> _clinicalPagedItems(Map<String, dynamic> response) {
  final payload = _docData(response);
  if (payload is List) return _docList(payload);
  final map = _docMap(payload);
  return _docList(map['data'] ?? map['items'] ?? map);
}

_Json _clinicalDataMap(Map<String, dynamic> response) {
  final payload = _docData(response);
  if (payload is List) return {'data': payload};
  final map = _docMap(payload);
  if (map['data'] is List) return map;
  if (_docMap(map['data'])['data'] is List) return _docMap(map['data']);
  return map;
}

class _ClinicalActionCard extends StatelessWidget {
  const _ClinicalActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}

class _RareCaseCard extends StatelessWidget {
  const _RareCaseCard({
    required this.rareCase,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final _Json rareCase;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = _docBool(rareCase['is_active']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _docText(rareCase['diagnosis'], 'حالة نادرة'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _DocPill(
                  active ? 'منشورة' : 'مخفية',
                  active ? AppColors.success : AppColors.slate500,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docText(rareCase['hospital'], '-'),
                  AppColors.royalBlue,
                  icon: Icons.local_hospital_rounded,
                ),
                _DocPill(
                  _docText(rareCase['department'], '-'),
                  AppColors.teal,
                  icon: Icons.account_tree_rounded,
                ),
                if (_docText(rareCase['room_number']).isNotEmpty)
                  _DocPill(
                    'غرفة ${_docText(rareCase['room_number'])}',
                    AppColors.slate500,
                    icon: Icons.meeting_room_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _docText(
                rareCase['clinical_signs'],
                'لا توجد علامات سريرية مضافة.',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.slate600,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    active
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  label: Text(active ? 'إخفاء' : 'نشر'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RareCaseDetails extends StatelessWidget {
  const _RareCaseDetails({required this.rareCase, required this.onDownload});

  final _Json rareCase;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow('التشخيص', _docText(rareCase['diagnosis'])),
        _DetailRow('المستشفى / المركز', _docText(rareCase['hospital'])),
        _DetailRow('القسم', _docText(rareCase['department'])),
        _DetailRow('رقم الغرفة', _docText(rareCase['room_number'], '-')),
        _DetailRow('اسم المريض', _docText(rareCase['patient_name'], '-')),
        _DetailRow('تاريخ النشر', _docDate(rareCase['created_at'])),
        const SizedBox(height: 12),
        Text(
          'العلامات السريرية',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _docText(rareCase['clinical_signs'], 'لا توجد علامات سريرية.'),
          style: const TextStyle(height: 1.6, fontWeight: FontWeight.w700),
        ),
        if (_docText(rareCase['attachment_url']).isNotEmpty) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.image_rounded),
            label: const Text('تحميل المرفق'),
          ),
        ],
      ],
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({
    required this.volunteer,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final _Json volunteer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final available = _docBool(volunteer['is_available']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_rounded)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(volunteer['name'], 'متطوع'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _docText(volunteer['diagnosis']),
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _DocPill(
                  available ? 'متاح' : 'غير متاح',
                  available ? AppColors.success : AppColors.slate500,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docText(volunteer['contact_info'], '-'),
                  AppColors.royalBlue,
                  icon: Icons.phone_rounded,
                ),
                if (_docText(volunteer['email']).isNotEmpty)
                  _DocPill(
                    _docText(volunteer['email']),
                    AppColors.teal,
                    icon: Icons.email_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('تعديل'),
                ),
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    available
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                  ),
                  label: Text(available ? 'غير متاح' : 'متاح'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VolunteerDetails extends StatelessWidget {
  const _VolunteerDetails({required this.volunteer});

  final _Json volunteer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow('الاسم', _docText(volunteer['name'])),
        _DetailRow('رقم التواصل', _docText(volunteer['contact_info'])),
        _DetailRow('رقم إضافي', _docText(volunteer['phone_secondary'], '-')),
        _DetailRow('البريد الإلكتروني', _docText(volunteer['email'], '-')),
        _DetailRow('التشخيص', _docText(volunteer['diagnosis'])),
        _DetailRow(
          'الحالة',
          _docBool(volunteer['is_available']) ? 'متاح' : 'غير متاح',
        ),
        const SizedBox(height: 12),
        Text(
          'العلامات السريرية',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _docText(volunteer['clinical_signs'], 'لا توجد علامات سريرية.'),
          style: const TextStyle(height: 1.6, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

String _notificationTypeLabel(String type) {
  switch (type) {
    case 'announcement':
      return 'إعلان';
    case 'exam':
      return 'اختبار';
    case 'assignment':
      return 'تكليف';
    case 'attendance':
      return 'حضور';
    case 'poll':
      return 'استبيان';
    case 'resource':
      return 'مورد';
    default:
      return 'إشعار';
  }
}

Color _notificationTypeColor(String type) {
  switch (type) {
    case 'exam':
      return AppColors.danger;
    case 'assignment':
      return AppColors.warning;
    case 'poll':
      return AppColors.teal;
    case 'attendance':
      return AppColors.danger;
    case 'resource':
      return AppColors.royalBlue;
    case 'announcement':
      return AppColors.success;
    default:
      return AppColors.slate500;
  }
}

IconData _notificationTypeIcon(String type) {
  switch (type) {
    case 'exam':
      return Icons.event_available_rounded;
    case 'assignment':
      return Icons.assignment_rounded;
    case 'poll':
      return Icons.poll_rounded;
    case 'attendance':
      return Icons.fact_check_rounded;
    case 'resource':
      return Icons.folder_rounded;
    case 'announcement':
      return Icons.campaign_rounded;
    default:
      return Icons.notifications_rounded;
  }
}
