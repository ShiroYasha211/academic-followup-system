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
                      'متابعة الحالات العملية، السجلات، التقييمات، ومكونات التدريب السريري.',
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.slate800,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(_ClinicalBundle bundle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          ],
        ),
        const SizedBox(height: 8),

        _buildSectionHeader(
          'إدارة الحالات والتدريب السريري',
          Icons.medical_services_rounded,
          AppColors.royalBlue,
        ),
        _ClinicalBentoCard(
          title: 'الحالات السريرية',
          subtitle:
              'إضافة الحالات، تصفيتها، وتحديث حالتها، وربطها بالمركز والقسم والجهاز.',
          icon: Icons.medical_information_rounded,
          color: AppColors.success,
          onTap: () => context.push(DoctorClinicalSectionScreen.path('cases')),
        ),
        const SizedBox(height: 12),
        _ClinicalBentoCard(
          title: 'تكليف الحالات للطلاب',
          subtitle:
              'تكليف الطلاب بحالات سريرية ومراجعة طلبات الاعتماد المقدمة.',
          icon: Icons.assignment_ind_rounded,
          color: AppColors.warning,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('assignments')),
        ),

        _buildSectionHeader(
          'الحضور والسجل العملي اليومي',
          Icons.qr_code_scanner_rounded,
          AppColors.teal,
        ),
        _ClinicalBentoCard(
          title: 'ماسح QR للسجل العملي',
          subtitle: 'مسح سريع لرمز الطالب لتسجيل الحضور وتأكيد النشاط فوراً.',
          icon: Icons.qr_code_scanner_rounded,
          color: AppColors.teal,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('scanner')),
        ),
        const SizedBox(height: 12),
        _ClinicalBentoCard(
          title: 'سجلات الطلاب العملية',
          subtitle: 'مراجعة وتأكيد السجلات والأنشطة العملية اليومية.',
          icon: Icons.library_books_rounded,
          color: AppColors.royalBlue,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('records')),
        ),

        _buildSectionHeader(
          'التقييمات والدرجات السريرية',
          Icons.fact_check_rounded,
          AppColors.danger,
        ),
        Row(
          children: [
            Expanded(
              child: _ClinicalBentoCard(
                title: 'قوائم تقييم OSCE',
                subtitle: 'إدارة وتطبيق قوائم التقييم.',
                icon: Icons.fact_check_rounded,
                color: AppColors.danger,
                isHalfWidth: true,
                onTap: () => context.push(
                  DoctorClinicalSectionScreen.path('checklists'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ClinicalBentoCard(
                title: 'نتائج التقييمات',
                subtitle: 'درجات وتقارير الطلاب.',
                icon: Icons.analytics_rounded,
                color: AppColors.success,
                isHalfWidth: true,
                onTap: () =>
                    context.push(DoctorClinicalSectionScreen.path('results')),
              ),
            ),
          ],
        ),

        _buildSectionHeader(
          'التهيئة والإعدادات الطبية',
          Icons.settings_applications_rounded,
          AppColors.slate500,
        ),
        Row(
          children: [
            Expanded(
              child: _ClinicalBentoCard(
                title: 'مراكز التدريب',
                subtitle: 'المستشفيات والمراكز.',
                icon: Icons.local_hospital_rounded,
                color: AppColors.royalBlue,
                isHalfWidth: true,
                onTap: () =>
                    context.push(DoctorClinicalSectionScreen.path('centers')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ClinicalBentoCard(
                title: 'الأقسام الطبية',
                subtitle: 'الباطنة، الجراحة، إلخ.',
                icon: Icons.account_tree_rounded,
                color: AppColors.info,
                isHalfWidth: true,
                onTap: () => context.push(
                  DoctorClinicalSectionScreen.path('departments'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ClinicalBentoCard(
          title: 'أنظمة وأجهزة الجسم الطبية',
          subtitle:
              'إدارة وتصنيف أنظمة الجسم المرتبطة بالحالات والتقييمات السريرية.',
          icon: Icons.biotech_rounded,
          color: AppColors.teal,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('body-systems')),
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
              onFollowUp: () {},
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
    final diagnosis = TextEditingController();
    final hospital = TextEditingController();
    final department = TextEditingController();
    final room = TextEditingController();
    final patientName = TextEditingController();
    final signs = TextEditingController();
    final internalNotes = TextEditingController();
    var status = 'published';
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
                            Icons.medical_information_rounded,
                            color: AppColors.royalBlue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'البيانات الطبية',
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
                        controller: diagnosis,
                        decoration: InputDecoration(
                          labelText: 'التشخيص الطبي',
                          prefixIcon: const Icon(
                            Icons.medical_services_rounded,
                            color: AppColors.royalBlue,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'التشخيص مطلوب.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: signs,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'العلامات السريرية وأعراض الحالة',
                          prefixIcon: const Icon(
                            Icons.description_rounded,
                            color: AppColors.royalBlue,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                            Icons.local_hospital_rounded,
                            color: AppColors.teal,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'الموقع والمريض',
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
                        controller: hospital,
                        decoration: InputDecoration(
                          labelText: 'المستشفى / المركز',
                          prefixIcon: const Icon(
                            Icons.local_hospital_rounded,
                            color: AppColors.teal,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.teal,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'المستشفى مطلوب.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: department,
                        decoration: InputDecoration(
                          labelText: 'القسم الطبي',
                          prefixIcon: const Icon(
                            Icons.account_tree_rounded,
                            color: AppColors.teal,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.teal,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'القسم مطلوب.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: room,
                              decoration: InputDecoration(
                                labelText: 'رقم الغرفة',
                                prefixIcon: const Icon(
                                  Icons.meeting_room_rounded,
                                  color: AppColors.slate500,
                                ),
                                filled: true,
                                fillColor: AppColors.slate50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate500,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: patientName,
                              decoration: InputDecoration(
                                labelText: 'اسم المريض (اختياري)',
                                prefixIcon: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.slate500,
                                ),
                                filled: true,
                                fillColor: AppColors.slate50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate500,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                            Icons.image_rounded,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'المرفقات والصور',
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
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (result?.files.single != null) {
                            setLocal(() => attachment = result!.files.single);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: attachment == null
                            ? Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.slate300,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_rounded,
                                      color: AppColors.slate400,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'إضافة صورة مرفقة (اختياري)',
                                      style: TextStyle(
                                        color: AppColors.slate600,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'اضغط لتحديد ملف الصورة من المعرض',
                                      style: TextStyle(
                                        color: AppColors.slate400,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.royalBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        File(attachment!.path!),
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: FloatingActionButton.small(
                                          heroTag:
                                              'remove_attachment_rare_case',
                                          onPressed: () {
                                            setLocal(() => attachment = null);
                                          },
                                          backgroundColor: Colors.white,
                                          foregroundColor: AppColors.danger,
                                          child: const Icon(
                                            Icons.delete_rounded,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          child: Text(
                                            attachment!.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                            Icons.tune_rounded,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'إعدادات النشر والمتابعة',
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
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'الحالة'),
                        items: const [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('مسودة'),
                          ),
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('منشورة'),
                          ),
                          DropdownMenuItem(
                            value: 'closed',
                            child: Text('مغلقة'),
                          ),
                          DropdownMenuItem(
                            value: 'archived',
                            child: Text('مؤرشفة'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) status = value;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: internalNotes,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات داخلية لا تظهر للطلاب',
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
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'نشر الحالة الآن',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      fontSize: 14,
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
                const SizedBox(height: 20),
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
            'status': status,
            'internal_notes': internalNotes.text.trim(),
          }
        : null;

    Future.delayed(const Duration(milliseconds: 500), () {
      patientName.dispose();
      hospital.dispose();
      department.dispose();
      room.dispose();
      diagnosis.dispose();
      signs.dispose();
      internalNotes.dispose();
    });

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
      title: volunteer == null ? 'إضافة متطوع جديد' : 'تعديل بيانات المتطوع',
      icon: Icons.person_add_alt_rounded,
      color: AppColors.teal,
      fullScreen: true,
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
                        Icons.badge_rounded,
                        color: AppColors.royalBlue,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'بيانات التعريف والاتصال',
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
                    decoration: InputDecoration(
                      labelText: 'اسم المتطوع كامل',
                      prefixIcon: const Icon(
                        Icons.person_rounded,
                        color: AppColors.royalBlue,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.royalBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'الاسم مطلوب.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: contact,
                          decoration: InputDecoration(
                            labelText: 'رقم التواصل الرئيسي',
                            prefixIcon: const Icon(
                              Icons.phone_rounded,
                              color: AppColors.royalBlue,
                            ),
                            filled: true,
                            fillColor: AppColors.slate50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.royalBlue,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'رقم التواصل مطلوب.'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: secondary,
                          decoration: InputDecoration(
                            labelText: 'رقم هاتف إضافي',
                            prefixIcon: const Icon(
                              Icons.phone_android_rounded,
                              color: AppColors.slate500,
                            ),
                            filled: true,
                            fillColor: AppColors.slate50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.slate500,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني (اختياري)',
                      prefixIcon: const Icon(
                        Icons.email_rounded,
                        color: AppColors.royalBlue,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.royalBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      return text.contains('@')
                          ? null
                          : 'البريد الإلكتروني غير صحيح.';
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                        Icons.medical_information_rounded,
                        color: AppColors.teal,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'بيانات الحالة التشخيصية',
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
                    controller: diagnosis,
                    decoration: InputDecoration(
                      labelText: 'التشخيص الطبي للمتطوع',
                      prefixIcon: const Icon(
                        Icons.medical_services_rounded,
                        color: AppColors.teal,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.teal,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'التشخيص مطلوب.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: signs,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'العلامات السريرية المرافقة',
                      prefixIcon: const Icon(
                        Icons.description_rounded,
                        color: AppColors.teal,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.teal,
                          width: 1.5,
                        ),
                      ),
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
                'حفظ بيانات المتطوع',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                  fontSize: 14,
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

    Future.delayed(const Duration(milliseconds: 500), () {
      name.dispose();
      contact.dispose();
      secondary.dispose();
      email.dispose();
      diagnosis.dispose();
      signs.dispose();
    });

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
  static const rareCasesRoute = '/doctor/rare-cases';
  static const volunteersRoute = '/doctor/volunteers';

  final String section;

  static String path(String section) => '/doctor/clinical/$section';
  static String standalonePath(String section) => switch (section) {
    'rare-cases' => rareCasesRoute,
    'volunteers' => volunteersRoute,
    _ => path(section),
  };

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
  bool _showHiddenChecklists = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    if (widget.section == 'scanner') {
      _scannerController = MobileScannerController();
    }
    _search.addListener(() {
      if (!mounted ||
          !{
            'rare-cases',
            'volunteers',
            'cases',
            'assignments',
            'centers',
            'departments',
            'body-systems',
            'checklists',
            'results',
          }.contains(widget.section)) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  String get _endpoint => switch (widget.section) {
    'centers' => '/doctor/clinical/training-centers',
    'departments' => '/doctor/clinical/departments',
    'body-systems' => '/doctor/clinical/body-systems',
    'cases' => '/doctor/clinical/cases',
    'assignments' => '/doctor/clinical/assignments',
    'records' => '/doctor/clinical/logbook/records',
    'checklists' =>
      _showHiddenChecklists
          ? '/doctor/clinical/evaluations/checklists/hidden'
          : '/doctor/clinical/evaluations/checklists',
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
    'checklists' => 'قوائم تقييم OSCE',
    'evaluation-start' => 'بدء تقييم OSCE',
    'results' => 'نتائج تقييم OSCE',
    'rare-cases' => 'إعلان حالات نادرة',
    'volunteers' => 'سجل المتطوعين',
    _ => 'القسم السريري',
  };

  String get _subtitle => switch (widget.section) {
    'centers' =>
      'استعرض وأشرف على مراكز التدريب السريري وتتبع توزيع الحالات بها.',
    'departments' => 'أدر الأقسام الطبية السريرية ونسب تغطية الحالات المحددة.',
    'body-systems' =>
      'تابع أنظمة وأجهزة الجسم المختلفة وتوزيع المهارات العملية المقترنة بها.',
    'cases' => 'أدر الحالات السريرية المتوفرة وتابع المهام التدريبية للطلاب.',
    'assignments' =>
      'أشرف على تكليفات الحالات السريرية وقم باعتماد المحاولات المكتملة.',
    'scanner' =>
      'امسح رمز QR الخاص بالطلاب لتأكيد حضورهم واعتماد سجلاتهم العملية فورياً.',
    'records' =>
      'استعرض وراجع السجلات والأنشطة العملية اليومية المقدمة من طلابك لاعتمادها.',
    'checklists' =>
      'أدر قوائم تقييم المهارات السريرية (OSCE) للطلاب وتابع أداءهم.',
    'evaluation-start' => 'بدء نموذج تقييم المهارات السريرية (OSCE) للطلاب.',
    'results' => 'استعرض نتائج تقييم المهارات السريرية ومستويات الإنجاز.',
    'rare-cases' =>
      'أعلن وتابع الحالات النادرة المتوفرة في المستشفيات لتوجيه الطلاب إليها.',
    'volunteers' =>
      'سجل وتابع المتطوعين السريريين المتاحين لمرافقة الطلاب في الفحوصات.',
    _ => 'إدارة الأنشطة والمهام السريرية والتدريب العملي لطلاب الكلية.',
  };

  IconData get _icon => switch (widget.section) {
    'centers' => Icons.local_hospital_rounded,
    'departments' => Icons.account_tree_rounded,
    'body-systems' => Icons.biotech_rounded,
    'cases' => Icons.medical_information_rounded,
    'assignments' => Icons.assignment_ind_rounded,
    'scanner' => Icons.qr_code_scanner_rounded,
    'records' => Icons.library_books_rounded,
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

  String get _currentRoute => switch (widget.section) {
    'rare-cases' => DoctorClinicalSectionScreen.rareCasesRoute,
    'volunteers' => DoctorClinicalSectionScreen.volunteersRoute,
    _ => DoctorClinicalScreen.route,
  };

  Future<Map<String, dynamic>> _fetch() {
    if (widget.section == 'scanner') {
      return ref
          .read(staffRepositoryProvider)
          .get('/doctor/clinical/evaluations/start-data');
    }
    return ref
        .read(staffRepositoryProvider)
        .get(
          _endpoint,
          query: {
            if ({
              'rare-cases',
              'volunteers',
              'cases',
              'assignments',
              'centers',
              'departments',
              'body-systems',
              'checklists',
              'results',
            }.contains(widget.section))
              'per_page': 200,
            if (!{
                  'rare-cases',
                  'volunteers',
                  'cases',
                  'assignments',
                  'centers',
                  'departments',
                  'body-systems',
                  'records',
                  'checklists',
                  'results',
                }.contains(widget.section) &&
                _search.text.trim().isNotEmpty)
              'search': _search.text.trim(),
            if (widget.section == 'results' &&
                _status != null &&
                _status!.isNotEmpty)
              'grade': _status,
            if (widget.section != 'results' &&
                !{
                  'rare-cases',
                  'volunteers',
                  'cases',
                  'assignments',
                  'centers',
                  'departments',
                  'body-systems',
                }.contains(widget.section) &&
                _status != null &&
                _status!.isNotEmpty)
              'status': _status,
            if (widget.section == 'cases') 'include_assignment_summary': 1,
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
      currentRoute: _currentRoute,
      floatingActionButton:
          _canAdd && !(widget.section == 'checklists' && _showHiddenChecklists)
          ? Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.section == 'rare-cases'
                      ? [AppColors.warning, const Color(0xFFFFB347)]
                      : [AppColors.royalBlue, const Color(0xFF4D6FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.section == 'rare-cases'
                                ? AppColors.warning
                                : AppColors.royalBlue)
                            .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openCreate,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.section == 'rare-cases'
                              ? 'إعلان حالة نادرة'
                              : 'إضافة جديدة',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final payload = _docData(snapshot.data ?? const {});
          final data = payload is List
              ? <String, dynamic>{'data': payload}
              : _docMap(payload);
          final items = _itemsFrom(data);
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(title: _title, subtitle: _subtitle, icon: _icon),
                const SizedBox(height: 14),
                _buildSectionShortcuts(),
                const SizedBox(height: 14),
                if (widget.section == 'checklists')
                  _buildChecklistsModeSwitch(data),
                if (widget.section == 'checklists') const SizedBox(height: 14),
                if (widget.section == 'records') _buildRecordsStats(items),
                if (widget.section == 'checklists')
                  _buildChecklistsStats(items),
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
      !{'scanner', 'evaluation-start'}.contains(widget.section);

  Widget _buildSectionShortcuts() {
    if (widget.section == 'checklists') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.royalBlue, Color(0xFF4D6FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push(
                      DoctorClinicalSectionScreen.path('evaluation-start'),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'بدء تقييم جديد',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'أجرِ اختبار OSCE فوري للطلبة',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push(
                      DoctorClinicalSectionScreen.path('results'),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            color: AppColors.royalBlue,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'سجل النتائج',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.midnight,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'استعرض الدرجات والتقييمات',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (widget.section == 'records') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.teal, Color(0xFF3CD1C2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  context.push(DoctorClinicalSectionScreen.path('scanner')),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مسح رمز QR السريع لتسجيل الحضور وتأكيد النشاط',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
          onChanged: (text) {
            if (widget.section == 'records' ||
                widget.section == 'checklists' ||
                widget.section == 'results') {
              setState(() {});
            }
          },
          onSubmitted:
              {
                'rare-cases',
                'volunteers',
                'cases',
                'assignments',
                'centers',
                'departments',
                'body-systems',
                'records',
                'checklists',
                'results',
              }.contains(widget.section)
              ? null
              : (_) => _reload(),
          decoration: InputDecoration(
            hintText: 'بحث...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon:
                {
                  'rare-cases',
                  'volunteers',
                  'cases',
                  'assignments',
                  'centers',
                  'departments',
                  'body-systems',
                  'records',
                  'checklists',
                  'results',
                }.contains(widget.section)
                ? (_search.text.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            if (widget.section == 'records' ||
                                widget.section == 'checklists' ||
                                widget.section == 'results') {
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.close_rounded),
                        ))
                : IconButton(
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
          'volunteers',
          'rare-cases',
        }.contains(widget.section)) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'الحالة'),
            items: widget.section == 'volunteers'
                ? const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'available', child: Text('متاح')),
                    DropdownMenuItem(
                      value: 'unavailable',
                      child: Text('غير متاح'),
                    ),
                  ]
                : widget.section == 'rare-cases'
                ? const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'draft', child: Text('مسودات')),
                    DropdownMenuItem(value: 'published', child: Text('منشورة')),
                    DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
                    DropdownMenuItem(value: 'archived', child: Text('مؤرشفة')),
                  ]
                : widget.section == 'cases'
                ? const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'active', child: Text('حالة نشطة')),
                    DropdownMenuItem(
                      value: 'discharged',
                      child: Text('تم الخروج'),
                    ),
                    DropdownMenuItem(
                      value: 'transferred',
                      child: Text('تم التحويل'),
                    ),
                  ]
                : widget.section == 'assignments'
                ? const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(
                      value: 'assigned',
                      child: Text('قيد العمل'),
                    ),
                    DropdownMenuItem(
                      value: 'submitted_for_review',
                      child: Text('بانتظار المراجعة'),
                    ),
                    DropdownMenuItem(value: 'overdue', child: Text('متأخر')),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('تم الاعتماد'),
                    ),
                    DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                  ]
                : widget.section == 'results'
                ? const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'excellent', child: Text('ممتاز')),
                    DropdownMenuItem(value: 'good', child: Text('جيد جدا')),
                    DropdownMenuItem(value: 'acceptable', child: Text('مقبول')),
                    DropdownMenuItem(value: 'weak', child: Text('ضعيف')),
                    DropdownMenuItem(value: 'fail', child: Text('راسب')),
                  ]
                : const [
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
              if (widget.section == 'volunteers' ||
                  widget.section == 'rare-cases' ||
                  widget.section == 'cases' ||
                  widget.section == 'assignments' ||
                  widget.section == 'results') {
                setState(() {});
              } else {
                _reload();
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRecordsStats(List<_Json> items) {
    int pending = 0;
    int confirmed = 0;
    int rejected = 0;
    for (final item in items) {
      final status = _docText(item['status']);
      if (status == 'pending' || status == 'partially_confirmed') {
        pending++;
      } else if (status == 'confirmed' || status == 'approved') {
        confirmed++;
      } else if (status == 'rejected') {
        rejected++;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildBentoStatCard(
              title: 'معلقة',
              count: pending,
              color: AppColors.warning,
              icon: Icons.hourglass_empty_rounded,
              isActive: _status == 'pending',
              onTap: () {
                setState(() {
                  _status = _status == 'pending' ? null : 'pending';
                });
                _reload();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBentoStatCard(
              title: 'معتمدة',
              count: confirmed,
              color: AppColors.success,
              icon: Icons.verified_rounded,
              isActive: _status == 'confirmed',
              onTap: () {
                setState(() {
                  _status = _status == 'confirmed' ? null : 'confirmed';
                });
                _reload();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBentoStatCard(
              title: 'مرفوضة',
              count: rejected,
              color: AppColors.danger,
              icon: Icons.cancel_rounded,
              isActive: _status == 'rejected',
              onTap: () {
                setState(() {
                  _status = _status == 'rejected' ? null : 'rejected';
                });
                _reload();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : AppColors.slate100,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isActive ? 0.08 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      const Spacer(),
                      if (isActive)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isActive ? color : AppColors.midnight,
                      fontFamily: 'Cairo',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate500,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistsStats(List<_Json> items) {
    int history = 0;
    int exam = 0;
    int procComm = 0;
    for (final item in items) {
      final skill = _docText(item['skill_type']);
      if (skill == 'history_taking') {
        history++;
      } else if (skill == 'clinical_examination') {
        exam++;
      } else if (skill == 'procedure' || skill == 'communication') {
        procComm++;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildBentoStatCard(
              title: 'أخذ القصة',
              count: history,
              color: AppColors.royalBlue,
              icon: Icons.history_edu_rounded,
              isActive: _status == 'history_taking',
              onTap: () {
                setState(() {
                  _status = _status == 'history_taking'
                      ? null
                      : 'history_taking';
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBentoStatCard(
              title: 'الفحص السريري',
              count: exam,
              color: AppColors.gold,
              icon: Icons.person_search_rounded,
              isActive: _status == 'clinical_examination',
              onTap: () {
                setState(() {
                  _status = _status == 'clinical_examination'
                      ? null
                      : 'clinical_examination';
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBentoStatCard(
              title: 'الإجراءات والتواصل',
              count: procComm,
              color: AppColors.teal,
              icon: Icons.healing_rounded,
              isActive: _status == 'procedure',
              onTap: () {
                setState(() {
                  _status = _status == 'procedure' ? null : 'procedure';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistsModeSwitch(_Json data) {
    final hiddenCount = _docInt(data['hidden_count']);

    Widget buildOption({
      required bool hidden,
      required IconData icon,
      required String title,
      required String subtitle,
      int? count,
    }) {
      final active = _showHiddenChecklists == hidden;
      final color = hidden ? AppColors.warning : AppColors.royalBlue;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.35) : AppColors.slate100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? color.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.015),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: active
                ? null
                : () {
                    setState(() {
                      _showHiddenChecklists = hidden;
                      _status = null;
                      _future = _fetch();
                    });
                  },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: active ? color : AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: active ? Colors.white : color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: active ? color : AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            if (count != null && count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate500,
                            fontFamily: 'Cairo',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    active
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: active ? color : AppColors.slate300,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          buildOption(
            hidden: false,
            icon: Icons.fact_check_rounded,
            title: 'القوائم الظاهرة',
            subtitle: 'القوائم المتاحة حاليًا للتقييم والتدريب السريري',
          ),
          buildOption(
            hidden: true,
            icon: Icons.visibility_off_rounded,
            title: 'الثوابت المخفية',
            subtitle:
                'استرجاع قوائم التقييم الأساسية المخفية مسبقاً من الإدارة',
            count: hiddenCount,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(_Json data) {
    return switch (widget.section) {
      'scanner' => [_buildScanner()],
      'evaluation-start' => [_buildEvaluationStart(data)],
      'results' => _buildResults(data),
      'checklists' => _buildChecklists(data),
      'assignments' => _buildAssignments(data),
      'records' => _buildRecords(data),
      'rare-cases' => _buildRareCasesList(data),
      'volunteers' => _buildVolunteersList(data),
      'cases' => _buildCasesList(data),
      'centers' => _buildCentersList(data),
      'departments' => _buildDepartmentsList(data),
      'body-systems' => _buildBodySystemsList(data),
      _ => _buildGenericItems(data),
    };
  }

  List<Widget> _buildCasesList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((caseItem) {
      final matchesSearch =
          query.isEmpty || _matchesCaseSearch(caseItem, query);
      final matchesStatus =
          _status == null ||
          _status!.isEmpty ||
          _docText(caseItem['status']) == _status;
      return matchesSearch && matchesStatus;
    }).toList();

    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا توجد حالات سريرية مسجلة بعد.'
              : 'لا توجد نتائج مطابقة للبحث الحالي.',
        ),
        if (allItems.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openCaseForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة حالة سريرية جديدة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (caseItem) => _CaseCard(
            caseItem: caseItem,
            onTap: () => _showCaseDetails(caseItem),
            onEdit: () => _openCaseForm(item: caseItem),
            onDelete: () => _deleteItem(caseItem),
          ),
        )
        .toList();
  }

  bool _matchesCaseSearch(_Json caseItem, String query) {
    final normalized = query.toLowerCase();
    final center = _docText(_docMap(caseItem['training_center'])['name']);
    final dept = _docText(_docMap(caseItem['clinical_department'])['name']);
    final system = _docText(_docMap(caseItem['body_system'])['name']);
    return [
      caseItem['patient_name'],
      caseItem['diagnosis_or_description'],
      center,
      dept,
      system,
    ].any((value) => _docText(value).toLowerCase().contains(normalized));
  }

  List<Widget> _buildCentersList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((centerItem) {
      return query.isEmpty || _matchesCenterSearch(centerItem, query);
    }).toList();

    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا توجد مراكز تدريب مسجلة بعد.'
              : 'لا توجد نتائج مطابقة للبحث الحالي.',
        ),
        if (allItems.isEmpty && _canAdd) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openTrainingCenterForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة مركز تدريب جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (centerItem) => _TrainingCenterCard(
            centerItem: centerItem,
            onTap: () => _showTrainingCenterDetails(centerItem),
            onEdit: _canAdd
                ? () => _openTrainingCenterForm(item: centerItem)
                : null,
            onDelete: _canAdd ? () => _deleteItem(centerItem) : null,
          ),
        )
        .toList();
  }

  bool _matchesCenterSearch(_Json centerItem, String query) {
    final normalized = query.toLowerCase();
    return _docText(centerItem['name']).toLowerCase().contains(normalized) ||
        _docText(centerItem['location']).toLowerCase().contains(normalized) ||
        _docText(centerItem['description']).toLowerCase().contains(normalized);
  }

  List<Widget> _buildDepartmentsList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((item) {
      return query.isEmpty || _matchesDepartmentSearch(item, query);
    }).toList();

    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا توجد أقسام طبية مسجلة بعد.'
              : 'لا توجد نتائج مطابقة للبحث الحالي.',
        ),
        if (allItems.isEmpty && _canAdd) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openDepartmentForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة قسم طبي جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (item) => _DepartmentCard(
            departmentItem: item,
            onTap: () => _showDepartmentDetails(item),
            onEdit: _canAdd && item['doctor_id'] != null
                ? () => _openDepartmentForm(item: item)
                : null,
            onDelete: _canAdd ? () => _deleteItem(item) : null,
          ),
        )
        .toList();
  }

  bool _matchesDepartmentSearch(_Json item, String query) {
    final normalized = query.toLowerCase();
    return _docText(item['name']).toLowerCase().contains(normalized) ||
        _docText(item['description']).toLowerCase().contains(normalized);
  }

  List<Widget> _buildBodySystemsList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((item) {
      return query.isEmpty || _matchesBodySystemSearch(item, query);
    }).toList();

    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا توجد أنظمة جسم مسجلة بعد.'
              : 'لا توجد نتائج مطابقة للبحث الحالي.',
        ),
        if (allItems.isEmpty && _canAdd) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openBodySystemForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة نظام جسم جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (item) => _BodySystemCard(
            bodySystemItem: item,
            onTap: () => _showBodySystemDetails(item),
            onEdit: _canAdd && item['doctor_id'] != null
                ? () => _openBodySystemForm(item: item)
                : null,
            onDelete: _canAdd ? () => _deleteItem(item) : null,
          ),
        )
        .toList();
  }

  bool _matchesBodySystemSearch(_Json item, String query) {
    final normalized = query.toLowerCase();
    return _docText(item['name']).toLowerCase().contains(normalized) ||
        _docText(item['description']).toLowerCase().contains(normalized);
  }

  Future<void> _showCaseDetails(_Json caseItem) async {
    var details = caseItem;
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .get(
            '/doctor/clinical/cases/${caseItem['id']}',
            query: const {'include_assignments': 1},
          );
      details = _docMap(_docData(response));
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
      return;
    }
    if (!mounted) return;
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الحالة السريرية',
      icon: Icons.medical_information_rounded,
      color: AppColors.success,
      child: _CaseDetails(caseItem: details),
    );
  }

  List<Widget> _buildVolunteersList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((volunteer) {
      final matchesSearch =
          query.isEmpty || _matchesVolunteerSearch(volunteer, query);
      final matchesStatus =
          _status == null ||
          _status!.isEmpty ||
          (_status == 'available' && _docBool(volunteer['is_available'])) ||
          (_status == 'unavailable' && !_docBool(volunteer['is_available']));
      return matchesSearch && matchesStatus;
    }).toList();
    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا يوجد متطوعون في السجل بعد.'
              : 'لا توجد نتائج مطابقة للبحث أو الفلتر الحالي.',
        ),
        if (allItems.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openVolunteerForm(),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text(
                'إضافة متطوع جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (volunteer) => _VolunteerCard(
            volunteer: volunteer,
            onTap: () => _showVolunteerDetails(volunteer),
            onEdit: () => _openVolunteerForm(item: volunteer),
            onFollowUp: () => _openVolunteerFollowUpForm(volunteer),
            onCall: () => _callVolunteer(volunteer),
            onWhatsApp: () => _openVolunteerWhatsApp(volunteer),
            onCopy: () => _copyVolunteerContact(volunteer),
            onToggle: () => _toggleVolunteer(volunteer),
            onDelete: () => _deleteVolunteer(volunteer),
          ),
        )
        .toList();
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

  bool _matchesVolunteerSearch(_Json volunteer, String query) {
    final normalized = query.toLowerCase();
    return [
      volunteer['name'],
      volunteer['contact_info'],
      volunteer['phone_secondary'],
      volunteer['email'],
      volunteer['diagnosis'],
      volunteer['clinical_signs'],
    ].any((value) => _docText(value).toLowerCase().contains(normalized));
  }

  Future<void> _showVolunteerDetails(_Json volunteer) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل المتطوع',
      icon: Icons.person_rounded,
      color: _docBool(volunteer['is_available'])
          ? AppColors.success
          : AppColors.slate500,
      child: _VolunteerDetails(
        volunteer: volunteer,
        onFollowUp: () => _openVolunteerFollowUpForm(volunteer),
        onCall: () => _callVolunteer(volunteer),
        onWhatsApp: () => _openVolunteerWhatsApp(volunteer),
      ),
    );
  }

  Future<void> _openVolunteerFollowUpForm(_Json volunteer) async {
    final formKey = GlobalKey<FormState>();
    var status = _docText(volunteer['follow_up_status'], 'contacted');
    if (!_volunteerFollowUpStatuses.containsKey(status)) status = 'contacted';
    var method = _docText(volunteer['preferred_contact_method'], 'whatsapp');
    if (!_volunteerContactMethods.containsKey(method)) method = 'whatsapp';
    final notes = TextEditingController();

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تسجيل متابعة',
      icon: Icons.event_note_rounded,
      color: AppColors.teal,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow('المتطوع', _docText(volunteer['name'], 'متطوع')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'حالة المتابعة'),
              items: _volunteerFollowUpStatuses.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => status = value ?? status,
              validator: (value) =>
                  value == null || value.isEmpty ? 'حدد حالة المتابعة.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'طريقة التواصل'),
              items: _volunteerContactMethods.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => method = value ?? method,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notes,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'ملاحظات المتابعة',
                hintText: 'مثال: تم التواصل ووافق على الحضور يوم الخميس.',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ المتابعة'),
            ),
          ],
        ),
      ),
    );

    final payload = ok == true
        ? {
            'follow_up_status': status,
            'contact_method': method,
            'notes': notes.text.trim(),
          }
        : null;
    Future.delayed(const Duration(milliseconds: 500), notes.dispose);
    if (payload == null) return;

    try {
      await ref
          .read(staffRepositoryProvider)
          .post(
            '/doctor/clinical/volunteers/${volunteer['id']}/follow-up',
            payload,
          );
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم تسجيل المتابعة.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _callVolunteer(_Json volunteer) async {
    final phone = _docText(volunteer['contact_info']);
    if (phone.isEmpty) return;
    await _launchExternal(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openVolunteerWhatsApp(_Json volunteer) async {
    final phone = _normalizedPhone(_docText(volunteer['contact_info']));
    if (phone.isEmpty) {
      _docSnack(context, 'رقم التواصل غير صالح.', color: AppColors.warning);
      return;
    }
    await _launchExternal(Uri.parse('https://wa.me/$phone'));
  }

  Future<void> _copyVolunteerContact(_Json volunteer) async {
    final phone = _docText(volunteer['contact_info']);
    if (phone.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) return;
    _docSnack(context, 'تم نسخ رقم التواصل.', color: AppColors.success);
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted || launched) return;
      _docSnack(context, 'تعذر فتح التطبيق المناسب.', color: AppColors.warning);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  String _normalizedPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits.substring(1);
    if (digits.startsWith('00')) return digits.substring(2);
    return digits;
  }

  List<Widget> _buildRareCasesList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((item) {
      final matchesSearch =
          query.isEmpty || _matchesRareCaseSearch(item, query);
      final matchesStatus =
          _status == null ||
          _status!.isEmpty ||
          _docText(item['status']) == _status;
      return matchesSearch && matchesStatus;
    }).toList();
    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا توجد حالات نادرة منشورة بعد.'
              : 'لا توجد نتائج مطابقة للبحث الحالي.',
        ),
        if (allItems.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openRareCaseForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إعلان حالة نادرة جديدة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (rareCase) => _RareCaseCard(
            rareCase: rareCase,
            onTap: () => _showRareCaseDetails(rareCase),
            onEdit: () => _openRareCaseForm(item: rareCase),
            onToggle: () => _toggleRareCase(rareCase),
            onDelete: () => _deleteRareCase(rareCase),
          ),
        )
        .toList();
  }

  bool _matchesRareCaseSearch(_Json rareCase, String query) {
    final normalized = query.toLowerCase();
    return [
      rareCase['diagnosis'],
      rareCase['hospital'],
      rareCase['department'],
      rareCase['patient_name'],
      rareCase['room_number'],
      rareCase['clinical_signs'],
    ].any((value) => _docText(value).toLowerCase().contains(normalized));
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

  List<_Json> _itemsFrom(_Json data) {
    if (data.containsKey('checklists')) return _docList(data['checklists']);
    final nestedData = _docMap(data['data']);
    if (nestedData['data'] is List) return _docList(nestedData['data']);
    return _docList(data['data'] ?? data['items'] ?? data);
  }

  List<Widget> _buildGenericItems(_Json data) {
    final items = _itemsFrom(data);
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
    if (items.isEmpty) {
      return [const _DocEmpty('لا توجد تكليفات حالات.')];
    }
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
    final allItems = _itemsFrom(data);
    final query = _search.text.trim().toLowerCase();
    final items = allItems.where((item) {
      if (query.isEmpty) return true;
      final student = _docMap(item['student']);
      final name = _docText(
        student['name'],
        _docText(item['student_name']),
      ).toLowerCase();
      final number = _docText(
        student['student_number'],
        _docText(item['student_number']),
      ).toLowerCase();
      final center = _docText(
        _docMap(item['training_center'])['name'],
        _docText(item['training_center']),
      ).toLowerCase();
      final dept = _docText(
        _docMap(item['department'])['name'],
        _docText(item['department']),
      ).toLowerCase();
      final date = _docDate(item['log_date']).toLowerCase();
      return name.contains(query) ||
          number.contains(query) ||
          center.contains(query) ||
          dept.contains(query) ||
          date.contains(query);
    }).toList();

    if (items.isEmpty) {
      return [const _DocEmpty('لا توجد سجلات مطابقة للبحث.')];
    }
    return items.map((item) {
      return _ClinicalRecordCard(
        item: item,
        onTap: () => _showLogDetails(item),
      );
    }).toList();
  }

  List<Widget> _buildChecklists(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim().toLowerCase();

    final items = allItems.where((item) {
      if (query.isNotEmpty) {
        final title = _docText(item['title']).toLowerCase();
        final skill = _docText(item['skill_type']).toLowerCase();
        final desc = _docText(item['description']).toLowerCase();
        if (!title.contains(query) &&
            !skill.contains(query) &&
            !desc.contains(query)) {
          return false;
        }
      }

      if (_status != null && _status!.isNotEmpty) {
        final skill = _docText(item['skill_type']);
        if (_status == 'procedure') {
          if (skill != 'procedure' && skill != 'communication') return false;
        } else {
          if (skill != _status) return false;
        }
      }

      return true;
    }).toList();

    if (items.isEmpty) {
      return [
        _DocEmpty(
          _showHiddenChecklists
              ? 'لا توجد قوائم تقييم مخفية مطابقة.'
              : 'لا توجد قوائم تقييم مطابقة.',
        ),
      ];
    }
    return items.map((item) {
      return _ClinicalChecklistCard(
        item: item,
        onTap: () => _showGenericDetails(item),
        onEdit: _showHiddenChecklists ? null : () => _openEdit(item),
        onDelete: _showHiddenChecklists ? null : () => _deleteItem(item),
        onRestore: _showHiddenChecklists ? () => _restoreChecklist(item) : null,
        isHidden: _showHiddenChecklists,
      );
    }).toList();
  }

  List<Widget> _buildResults(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim().toLowerCase();

    final items = allItems.where((item) {
      if (query.isNotEmpty) {
        final studentName = _docText(
          _docMap(item['student'])['name'],
        ).toLowerCase();
        final studentNo = _docText(
          _docMap(item['student'])['student_number'],
        ).toLowerCase();
        final checklistTitle = _docText(
          _docMap(item['checklist'])['title'],
        ).toLowerCase();
        final grade = _docText(item['grade']).toLowerCase();
        if (!studentName.contains(query) &&
            !studentNo.contains(query) &&
            !checklistTitle.contains(query) &&
            !grade.contains(query)) {
          return false;
        }
      }

      if (_status != null && _status!.isNotEmpty) {
        final grade = _docText(item['grade']);
        if (grade != _status) return false;
      }

      return true;
    }).toList();

    return [
      if (items.isEmpty)
        const _DocEmpty('لا توجد نتائج تقييم مطابقة.')
      else
        ...items.map((item) {
          return _ClinicalEvaluationResultCard(
            item: item,
            onTap: () => _showEvaluationResult(item),
          );
        }),
    ];
  }

  Widget _buildScanner() {
    if (_scannerController == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
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
              controller: _scannerController,
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
              child: CustomPaint(painter: _ScannerOverlayPainter()),
            ),
          ),
          const _ScannerLaserLine(),
          Positioned(
            top: 16,
            right: 16,
            child: ValueListenableBuilder(
              valueListenable: _scannerController!,
              builder: (context, state, child) {
                final isTorchOn =
                    _scannerController!.value.torchState == TorchState.on;
                return IconButton(
                  onPressed: () => _scannerController!.toggleTorch(),
                  icon: Icon(
                    isTorchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: isTorchOn ? AppColors.gold : Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Text(
                _processingQr
                    ? 'جاري قراءة السجل السريري...'
                    : 'وجّه الكاميرا إلى QR السجل العملي للطالب',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
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
                          Icons.badge_rounded,
                          color: AppColors.royalBlue,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'بيانات المريض الأساسية',
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
                      controller: patient,
                      decoration: InputDecoration(
                        labelText: 'اسم المريض كامل',
                        prefixIcon: const Icon(
                          Icons.person_rounded,
                          color: AppColors.royalBlue,
                        ),
                        filled: true,
                        fillColor: AppColors.slate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.royalBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'اسم المريض مطلوب.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: age,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'العمر',
                              prefixIcon: const Icon(
                                Icons.cake_rounded,
                                color: AppColors.royalBlue,
                              ),
                              filled: true,
                              fillColor: AppColors.slate50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.slate200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.slate200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.royalBlue,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                int.tryParse(value?.trim() ?? '') == null
                                ? 'العمر مطلوب كرقم.'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: gender,
                            decoration: InputDecoration(
                              labelText: 'الجنس',
                              prefixIcon: const Icon(
                                Icons.wc_rounded,
                                color: AppColors.slate500,
                              ),
                              filled: true,
                              fillColor: AppColors.slate50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.slate200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.slate200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.slate500,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('ذكر'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('أنثى'),
                              ),
                            ],
                            onChanged: (v) =>
                                setLocal(() => gender = v ?? gender),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
                          Icons.local_hospital_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'الموقع والفرز الطبي',
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
                    _clinicalDropdown(
                      'المستشفى / المركز السريري',
                      centers,
                      centerId,
                      (v) => setLocal(() => centerId = v),
                      prefixIcon: Icons.local_hospital_rounded,
                      activeColor: AppColors.info,
                      validator: (value) =>
                          value == null ? 'اختر المركز.' : null,
                    ),
                    const SizedBox(height: 12),
                    _clinicalDropdown(
                      'القسم الطبي المختص',
                      departments,
                      departmentId,
                      (v) => setLocal(() => departmentId = v),
                      prefixIcon: Icons.account_tree_rounded,
                      activeColor: AppColors.info,
                      validator: (value) =>
                          value == null ? 'اختر القسم.' : null,
                    ),
                    const SizedBox(height: 12),
                    _clinicalDropdown(
                      'جهاز أو نظام الجسم',
                      systems,
                      systemId,
                      (v) => setLocal(() => systemId = v),
                      prefixIcon: Icons.biotech_rounded,
                      activeColor: AppColors.info,
                      validator: (value) =>
                          value == null ? 'اختر نظام الجسم.' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: 'حالة الاستعداد',
                        prefixIcon: const Icon(
                          Icons.shield_rounded,
                          color: AppColors.info,
                        ),
                        filled: true,
                        fillColor: AppColors.slate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.info,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('نشط')),
                        DropdownMenuItem(
                          value: 'discharged',
                          child: Text('خروج'),
                        ),
                        DropdownMenuItem(
                          value: 'transferred',
                          child: Text('تحويل'),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => status = v ?? status),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
                          Icons.medical_services_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'التفاصيل والتشخيص السريري',
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
                      controller: diagnosis,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'التشخيص أو الوصف التفصيلي',
                        prefixIcon: const Icon(
                          Icons.description_rounded,
                          color: AppColors.success,
                        ),
                        filled: true,
                        fillColor: AppColors.slate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.success,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'التشخيص أو الوصف مطلوب.'
                          : null,
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
                  'حفظ الحالة السريرية',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final payload = ok == true
        ? {
            'patient_name': patient.text.trim(),
            'age': int.tryParse(age.text.trim()),
            'gender': gender,
            'training_center_id': centerId,
            'clinical_department_id': departmentId,
            'body_system_id': systemId,
            'diagnosis_or_description': diagnosis.text.trim(),
            'status': status,
          }
        : null;

    Future.delayed(const Duration(milliseconds: 500), () {
      patient.dispose();
      age.dispose();
      diagnosis.dispose();
    });

    if (ok != true || payload == null) return;
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
    _Json? findItem(List<_Json> items, int? id) {
      if (id == null) return null;
      for (final item in items) {
        if (_docInt(item['id']) == id) return item;
      }
      return null;
    }

    List<_Json> uniqueRelationOptions(List<_Json> items, String key) {
      final seen = <int>{};
      final result = <_Json>[];
      for (final item in items) {
        final relation = _docMap(item[key]);
        final id = _docInt(relation['id']);
        final name = _docText(relation['name']);
        if (id > 0 && name.isNotEmpty && seen.add(id)) {
          result.add({'id': id, 'name': name});
        }
      }
      result.sort((a, b) => _docText(a['name']).compareTo(_docText(b['name'])));
      return result;
    }

    final results = await Future.wait([
      ref
          .read(staffRepositoryProvider)
          .get(
            '/doctor/clinical/cases',
            query: const {'per_page': 200, 'include_assignment_summary': 1},
          ),
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
    DateTime? dueAt;
    PlatformFile? attachment;
    final instructions = TextEditingController();

    final centers = uniqueRelationOptions(cases, 'training_center');
    final departments = uniqueRelationOptions(cases, 'clinical_department');
    final systems = uniqueRelationOptions(cases, 'body_system');

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تكليف حالة لطالب',
      icon: Icons.assignment_ind_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: StatefulBuilder(
        builder: (context, setLocal) {
          final selectedCase = findItem(cases, caseId);

          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bento Container 1: Parties Data
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              color: AppColors.royalBlue,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'أطراف التكليف',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.slate100,
                      ),
                      // Student Selector Tile
                      FormField<int>(
                        initialValue: studentId,
                        validator: (value) =>
                            value == null ? 'اختر الطالب المكلف.' : null,
                        builder: (fieldState) {
                          final selectedStudent = findItem(students, studentId);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () async {
                                  final selected =
                                      await showMoeenBottomSheet<_Json>(
                                        context: context,
                                        title: 'اختر الطالب المكلف',
                                        icon: Icons.school_rounded,
                                        color: AppColors.royalBlue,
                                        fullScreen: true,
                                        child: _StudentSearchPicker(
                                          students: students,
                                        ),
                                      );
                                  if (selected != null) {
                                    setLocal(() {
                                      studentId = _docInt(selected['id']);
                                      fieldState.didChange(studentId);
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: fieldState.hasError
                                          ? AppColors.danger
                                          : (studentId == null
                                                ? AppColors.slate200
                                                : AppColors.royalBlue),
                                      width: studentId == null ? 1 : 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.school_rounded,
                                        color: AppColors.royalBlue,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              studentId == null
                                                  ? 'الطالب المكلف'
                                                  : 'الطالب المحدد',
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                                color: AppColors.slate500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              studentId == null
                                                  ? 'اضغط للبحث واختيار طالب...'
                                                  : _docText(
                                                      selectedStudent?['name'],
                                                      'طالب',
                                                    ),
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                color: studentId == null
                                                    ? AppColors.slate400
                                                    : AppColors.slate900,
                                              ),
                                            ),
                                            if (selectedStudent != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'رقم القيد: ${_docText(selectedStudent['student_number'], '-')}',
                                                style: const TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                  color: AppColors.slate500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppColors.slate400,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (fieldState.hasError) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    fieldState.errorText ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      // Case Selector Tile
                      FormField<int>(
                        initialValue: caseId,
                        validator: (value) =>
                            value == null ? 'اختر الحالة السريرية.' : null,
                        builder: (fieldState) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () async {
                                  final selected =
                                      await showMoeenBottomSheet<_Json>(
                                        context: context,
                                        title: 'اختر الحالة السريرية',
                                        icon: Icons.medical_information_rounded,
                                        color: AppColors.teal,
                                        fullScreen: true,
                                        child: _CaseSearchPicker(
                                          cases: cases,
                                          centers: centers,
                                          departments: departments,
                                          systems: systems,
                                        ),
                                      );
                                  if (selected != null) {
                                    setLocal(() {
                                      caseId = _docInt(selected['id']);
                                      fieldState.didChange(caseId);
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: fieldState.hasError
                                          ? AppColors.danger
                                          : (caseId == null
                                                ? AppColors.slate200
                                                : AppColors.teal),
                                      width: caseId == null ? 1 : 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.medical_information_rounded,
                                        color: AppColors.teal,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              caseId == null
                                                  ? 'الحالة السريرية'
                                                  : 'الحالة المحددة',
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                                color: AppColors.slate500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              caseId == null
                                                  ? 'اضغط للبحث واختيار حالة سريرية...'
                                                  : _docText(
                                                      selectedCase?['patient_name'],
                                                      _docText(
                                                        selectedCase?['name'],
                                                        'حالة سريرية',
                                                      ),
                                                    ),
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                color: caseId == null
                                                    ? AppColors.slate400
                                                    : AppColors.slate900,
                                              ),
                                            ),
                                            if (selectedCase != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'التشخيص: ${_docText(selectedCase['diagnosis_or_description'], '-')}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                  color: AppColors.slate500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppColors.slate400,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (fieldState.hasError) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    fieldState.errorText ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      if (selectedCase != null) ...[
                        const SizedBox(height: 12),
                        _AssignmentCasePreview(caseItem: selectedCase),
                      ],
                    ],
                  ),
                ),

                // Bento Container 2: Task details
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.task_alt_rounded,
                              color: AppColors.warning,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'تفاصيل وتوجيهات المهمة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.slate100,
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: task,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color: AppColors.midnight,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'نوع المهمة المطلوبة',
                          labelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                          ),
                          prefixIcon: const Icon(
                            Icons.assignment_rounded,
                            color: AppColors.royalBlue,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'history_taking',
                            child: Text(
                              'أخذ قصة مرضية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'clinical_examination',
                            child: Text(
                              'الفحص السريري',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'follow_up',
                            child: Text(
                              'متابعة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setLocal(() => task = v ?? task),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dueAt ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 3),
                          );
                          if (date == null || !context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: dueAt == null
                                ? TimeOfDay.now()
                                : TimeOfDay.fromDateTime(dueAt!),
                          );
                          if (time == null) return;
                          setLocal(() {
                            dueAt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'موعد الاستحقاق',
                            prefixIcon: const Icon(
                              Icons.event_available_rounded,
                            ),
                            suffixIcon: dueAt == null
                                ? null
                                : IconButton(
                                    tooltip: 'مَسح الموعد',
                                    onPressed: () =>
                                        setLocal(() => dueAt = null),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                          child: Text(
                            dueAt == null
                                ? 'اختياري - بدون موعد محدد'
                                : _docDateTimeForInput(
                                    _docDateTimeForApi(dueAt!),
                                  ),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              color: AppColors.midnight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: instructions,
                        minLines: 3,
                        maxLines: 5,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.midnight,
                        ),
                        decoration: InputDecoration(
                          labelText: 'تعليمات وإرشادات للطالب',
                          labelStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                          ),
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(
                              Icons.description_rounded,
                              color: AppColors.slate500,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: false,
                            withData: false,
                          );
                          if (result == null || result.files.isEmpty) return;
                          setLocal(() => attachment = result.files.single);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: attachment == null
                                ? AppColors.slate50
                                : AppColors.royalBlue.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: attachment == null
                                  ? AppColors.slate200
                                  : AppColors.royalBlue.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                attachment == null
                                    ? Icons.attach_file_rounded
                                    : Icons.file_present_rounded,
                                color: attachment == null
                                    ? AppColors.slate500
                                    : AppColors.royalBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attachment?.name ??
                                          'إرفاق ملف أو صورة للتكليف',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                        color: AppColors.slate900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      attachment == null
                                          ? 'اختياري، يستخدم لتوجيه الطالب بصورة أو ملف للحالة.'
                                          : 'سيتم إرسال هذا المرفق مع التكليف.',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (attachment != null)
                                IconButton(
                                  tooltip: 'إزالة المرفق',
                                  onPressed: () =>
                                      setLocal(() => attachment = null),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.slate600,
                          side: const BorderSide(color: AppColors.slate300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (formKey.currentState?.validate() != true) return;
                          final summary = _docMap(
                            selectedCase?['assignment_summary'],
                          );
                          final similarSummary = _docMap(
                            selectedCase?['similar_cases_summary'],
                          );
                          final studentsCount = _docInt(
                            summary['students_count'],
                          );
                          final similarCount = _docInt(
                            similarSummary['cases_count'],
                          );
                          if (studentsCount > 0 || similarCount > 0) {
                            final approved = await showMoeenConfirmDialog(
                              context: context,
                              title: 'تأكيد تكليف الحالة',
                              message:
                                  'هذه الحالة عليها $studentsCount طالب مكلف، ويوجد $similarCount حالة مشابهة داخل الكلية. هل تريد إرسال التكليف رغم ذلك؟',
                              confirmLabel: 'نعم، إرسال التكليف',
                              cancelLabel: 'مراجعة الحالة',
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.warning,
                            );
                            if (!approved || !context.mounted) return;
                          }
                          Navigator.pop(context, true);
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'إرسال التكليف',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          shadowColor: AppColors.royalBlue.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    final payload = {
      'student_id': studentId,
      'clinical_case_id': caseId,
      'task_type': task,
      'instructions': instructions.text.trim(),
      if (dueAt != null) 'due_at': _docDateTimeForApi(dueAt!),
    };
    Future.delayed(const Duration(milliseconds: 500), () {
      instructions.dispose();
    });
    if (ok != true) return;
    try {
      if (attachment?.path != null) {
        await ref.read(staffRepositoryProvider).upload(_endpoint, {
          ...payload,
          'attachment': await MultipartFile.fromFile(
            attachment!.path!,
            filename: attachment!.name,
          ),
        });
      } else {
        await ref.read(staffRepositoryProvider).post(_endpoint, payload);
      }
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _openChecklistForm({_Json? item}) async {
    final router = GoRouter.of(context);
    final updated = item == null
        ? await router.push<bool>(DoctorChecklistFormScreen.createRoute)
        : await router.push<bool>(
            DoctorChecklistFormScreen.editRoute.replaceFirst(
              ':checklistId',
              '${item['id']}',
            ),
            extra: item,
          );
    if (updated == true && mounted) {
      _reload();
    }
  }

  // ignore: unused_element
  Future<void> _openLegacyChecklistForm({_Json? item}) async {
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
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'العنوان مطلوب.'
                    : null,
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
                  DropdownMenuItem(
                    value: 'procedure',
                    child: Text('إجراء عملي'),
                  ),
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
                        validator: (value) =>
                            value == null || value.trim().isEmpty
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

  Future<void> _openRareCaseForm({_Json? item}) async {
    final formKey = GlobalKey<FormState>();
    final diagnosis = TextEditingController(text: _docText(item?['diagnosis']));
    final hospital = TextEditingController(text: _docText(item?['hospital']));
    final department = TextEditingController(
      text: _docText(item?['department']),
    );
    final room = TextEditingController(text: _docText(item?['room_number']));
    final patientName = TextEditingController(
      text: _docText(item?['patient_name']),
    );
    final signs = TextEditingController(
      text: _docText(item?['clinical_signs']),
    );
    final internalNotes = TextEditingController(
      text: _docText(item?['internal_notes']),
    );
    var status = _docText(item?['status'], 'published');
    if (!{'draft', 'published', 'closed', 'archived'}.contains(status)) {
      status = 'published';
    }
    PlatformFile? attachment;

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'إعلان حالة نادرة' : 'تعديل إعلان الحالة',
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
                            Icons.medical_information_rounded,
                            color: AppColors.royalBlue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'البيانات الطبية',
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
                        controller: diagnosis,
                        decoration: InputDecoration(
                          labelText: 'التشخيص الطبي',
                          prefixIcon: const Icon(
                            Icons.medical_services_rounded,
                            color: AppColors.royalBlue,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'التشخيص مطلوب.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: signs,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'العلامات السريرية وأعراض الحالة',
                          prefixIcon: const Icon(
                            Icons.description_rounded,
                            color: AppColors.royalBlue,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                            Icons.local_hospital_rounded,
                            color: AppColors.teal,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'الموقع والمريض',
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
                        controller: hospital,
                        decoration: InputDecoration(
                          labelText: 'المستشفى / المركز',
                          prefixIcon: const Icon(
                            Icons.local_hospital_rounded,
                            color: AppColors.teal,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.teal,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'المستشفى مطلوب.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: department,
                        decoration: InputDecoration(
                          labelText: 'القسم الطبي',
                          prefixIcon: const Icon(
                            Icons.account_tree_rounded,
                            color: AppColors.teal,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.teal,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'القسم مطلوب.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: room,
                              decoration: InputDecoration(
                                labelText: 'رقم الغرفة',
                                prefixIcon: const Icon(
                                  Icons.meeting_room_rounded,
                                  color: AppColors.slate500,
                                ),
                                filled: true,
                                fillColor: AppColors.slate50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate500,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: patientName,
                              decoration: InputDecoration(
                                labelText: 'اسم المريض (اختياري)',
                                prefixIcon: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.slate500,
                                ),
                                filled: true,
                                fillColor: AppColors.slate50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate500,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                            Icons.image_rounded,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'المرفقات والصور',
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
                      if (item != null &&
                          _docText(item['attachment_url']).isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.warning,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'اترك الصورة بدون تغيير إذا كنت تريد الاحتفاظ بالمرفق الحالي.',
                                  style: TextStyle(
                                    color: AppColors.slate700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (result?.files.single != null) {
                            setLocal(() => attachment = result!.files.single);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: attachment == null
                            ? Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.slate300,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_rounded,
                                      color: AppColors.slate400,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'إضافة صورة مرفقة (اختياري)',
                                      style: TextStyle(
                                        color: AppColors.slate600,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'اضغط لتحديد ملف الصورة من المعرض',
                                      style: TextStyle(
                                        color: AppColors.slate400,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.royalBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        File(attachment!.path!),
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: FloatingActionButton.small(
                                          heroTag:
                                              'remove_attachment_rare_case',
                                          onPressed: () {
                                            setLocal(() => attachment = null);
                                          },
                                          backgroundColor: Colors.white,
                                          foregroundColor: AppColors.danger,
                                          child: const Icon(
                                            Icons.delete_rounded,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          child: Text(
                                            attachment!.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                            Icons.tune_rounded,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'إعدادات النشر والمتابعة',
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
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'الحالة'),
                        items: const [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('مسودة'),
                          ),
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('منشورة'),
                          ),
                          DropdownMenuItem(
                            value: 'closed',
                            child: Text('مغلقة'),
                          ),
                          DropdownMenuItem(
                            value: 'archived',
                            child: Text('مؤرشفة'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) status = value;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: internalNotes,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات داخلية لا تظهر للطلاب',
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
                  icon: Icon(
                    item == null ? Icons.send_rounded : Icons.save_rounded,
                  ),
                  label: Text(
                    item == null ? 'نشر الحالة الآن' : 'حفظ التعديلات',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      fontSize: 14,
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
                const SizedBox(height: 20),
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
            'status': status,
            'internal_notes': internalNotes.text.trim(),
          }
        : null;

    Future.delayed(const Duration(milliseconds: 500), () {
      patientName.dispose();
      hospital.dispose();
      department.dispose();
      room.dispose();
      diagnosis.dispose();
      signs.dispose();
      internalNotes.dispose();
    });

    if (ok != true || payload == null) return;
    try {
      if (attachment?.path != null) {
        payload['attachment'] = await MultipartFile.fromFile(
          attachment!.path!,
          filename: attachment!.name,
        );
      }
      if (item == null) {
        await ref.read(staffRepositoryProvider).upload(_endpoint, payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .uploadPut('$_endpoint/${item['id']}', payload);
      }
      if (!mounted) return;
      _reload();
      _docSnack(
        context,
        item == null ? 'تم نشر الحالة النادرة.' : 'تم تعديل الحالة النادرة.',
        color: AppColors.success,
      );
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
    final secondary = TextEditingController(
      text: _docText(item?['phone_secondary']),
    );
    final email = TextEditingController(text: _docText(item?['email']));
    final diagnosis = TextEditingController(text: _docText(item?['diagnosis']));
    final signs = TextEditingController(
      text: _docText(item?['clinical_signs']),
    );

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'إضافة متطوع جديد' : 'تعديل بيانات المتطوع',
      icon: Icons.person_add_alt_rounded,
      color: AppColors.teal,
      fullScreen: true,
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
                        Icons.badge_rounded,
                        color: AppColors.royalBlue,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'بيانات التعريف والاتصال',
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
                    decoration: InputDecoration(
                      labelText: 'اسم المتطوع كامل',
                      prefixIcon: const Icon(
                        Icons.person_rounded,
                        color: AppColors.royalBlue,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.royalBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'الاسم مطلوب.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: contact,
                          decoration: InputDecoration(
                            labelText: 'رقم التواصل الرئيسي',
                            prefixIcon: const Icon(
                              Icons.phone_rounded,
                              color: AppColors.royalBlue,
                            ),
                            filled: true,
                            fillColor: AppColors.slate50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.royalBlue,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'رقم التواصل مطلوب.'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: secondary,
                          decoration: InputDecoration(
                            labelText: 'رقم هاتف إضافي',
                            prefixIcon: const Icon(
                              Icons.phone_android_rounded,
                              color: AppColors.slate500,
                            ),
                            filled: true,
                            fillColor: AppColors.slate50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.slate200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.slate500,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني (اختياري)',
                      prefixIcon: const Icon(
                        Icons.email_rounded,
                        color: AppColors.royalBlue,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.royalBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      return text.contains('@')
                          ? null
                          : 'البريد الإلكتروني غير صحيح.';
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                        Icons.medical_information_rounded,
                        color: AppColors.teal,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'بيانات الحالة التشخيصية',
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
                    controller: diagnosis,
                    decoration: InputDecoration(
                      labelText: 'التشخيص الطبي للمتطوع',
                      prefixIcon: const Icon(
                        Icons.medical_services_rounded,
                        color: AppColors.teal,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.teal,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'التشخيص مطلوب.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: signs,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'العلامات السريرية المرافقة',
                      prefixIcon: const Icon(
                        Icons.description_rounded,
                        color: AppColors.teal,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.teal,
                          width: 1.5,
                        ),
                      ),
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
                'حفظ بيانات المتطوع',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                  fontSize: 14,
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

    Future.delayed(const Duration(milliseconds: 500), () {
      name.dispose();
      contact.dispose();
      secondary.dispose();
      email.dispose();
      diagnosis.dispose();
      signs.dispose();
    });

    if (ok != true || payload == null) return;
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
      _docSnack(context, 'تم حفظ بيانات المتطوع.', color: AppColors.success);
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
    IconData? prefixIcon,
    Color activeColor = AppColors.royalBlue,
  }) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: activeColor)
            : null,
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: activeColor, width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: _docInt(item['id']),
              child: Text(
                _docText(item[titleKey], _docText(item['name'], '-')),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Future<void> _showGenericDetails(_Json item) async {
    if (widget.section == 'departments') {
      await _showDepartmentDetails(item);
      return;
    }
    if (widget.section == 'body-systems') {
      await _showBodySystemDetails(item);
      return;
    }
    if (widget.section == 'checklists') {
      await showMoeenBottomSheet<void>(
        context: context,
        title: _genericTitle(item),
        icon: _icon,
        color: AppColors.royalBlue,
        child: _ChecklistDetailsView(item: item),
      );
      return;
    }
    await showMoeenBottomSheet<void>(
      context: context,
      title: _genericTitle(item),
      icon: _icon,
      color: AppColors.royalBlue,
      child: _JsonDetailsView(item: item),
    );
  }

  Future<void> _showEvaluationResult(_Json item) async {
    await GoRouter.of(context).push(
      DoctorEvaluationResultDetailsScreen.route.replaceFirst(
        ':resultId',
        '${item['id']}',
      ),
      extra: item,
    );
  }

  Future<void> _showLogDetails(_Json rawLog) async {
    final log = rawLog.containsKey('log') ? _docMap(rawLog['log']) : rawLog;
    final groups = _docList(log['groups']);
    final confirmations = <String, String>{
      for (final group in groups)
        _docText(group['key']): _docBool(group['confirmed'])
            ? 'approved'
            : _docBool(group['has_rejected'])
            ? 'rejected'
            : 'pending',
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
            _StudentLogInfoCard(log: log),
            const SizedBox(height: 16),
            if (groups.isNotEmpty)
              ...groups.map((group) {
                final key = _docText(group['key']);
                return _LogActivityGroupCard(
                  group: group,
                  status: confirmations[key] ?? 'pending',
                  onStatusChanged: (value) =>
                      setLocal(() => confirmations[key] = value),
                );
              }),
            _DoctorNotesBento(notesController: notes),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'reject'),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.danger,
                    ),
                    label: const Text(
                      'رفض كامل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final hasAnyConfirm = confirmations.values.any(
                        (val) => val != 'pending',
                      );
                      if (!hasAnyConfirm) {
                        _docSnack(
                          context,
                          'يرجى اختيار قرار واحد على الأقل للمجموعات السريرية.',
                          color: AppColors.warning,
                        );
                        return;
                      }
                      Navigator.pop(context, 'confirm');
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      'حفظ المراجعة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
              entry.key: {'status': entry.value},
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
    String reviewRating = 'good';

    final student = _docMap(assignment['student']);
    final studentName = _docText(student['name'], 'طالب');
    final studentNumber = _docText(student['student_number'], '-');

    final clinicalCase = _docMap(assignment['clinical_case']);
    final patientName = _docText(clinicalCase['patient_name'], 'مريض');
    final diagnosis = _docText(clinicalCase['diagnosis_or_description'], '-');
    final center = _docText(_docMap(clinicalCase['training_center'])['name']);
    final dept = _docText(_docMap(clinicalCase['clinical_department'])['name']);

    final taskType = _taskTypeLabel(_docText(assignment['task_type']));
    final studentMessage = _docText(assignment['student_completion_message']);
    final attachmentUrl = _docText(assignment['attachment_url']);
    final attachmentName = _docText(
      assignment['attachment_name'],
      'مرفق التكليف',
    );

    final action = await showMoeenBottomSheet<String>(
      context: context,
      title: 'مراجعة التكليف',
      icon: Icons.assignment_turned_in_rounded,
      color: AppColors.warning,
      child: StatefulBuilder(
        builder: (context, setLocal) {
          Widget buildDetailRow(String label, String value) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Student & Task info header card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.royalBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.royalBlue.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        studentName.isNotEmpty
                            ? studentName.substring(0, 1)
                            : 'ط',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.royalBlue,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnight,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'رقم القيد: $studentNumber',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate500,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        taskType,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Clinical Case details card
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
                          Icons.medical_services_rounded,
                          color: AppColors.royalBlue,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'تفاصيل الحالة الطبية',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnight,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 20,
                      thickness: 0.8,
                      color: AppColors.slate100,
                    ),
                    buildDetailRow('المريض', patientName),
                    buildDetailRow('التشخيص', diagnosis),
                    buildDetailRow(
                      'المركز السريري',
                      center.isNotEmpty ? center : '-',
                    ),
                    buildDetailRow(
                      'القسم المختص',
                      dept.isNotEmpty ? dept : '-',
                    ),
                  ],
                ),
              ),

              // 3. Student message & attachments if present
              if (studentMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.royalBlue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'رسالة إنجاز الطالب',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnight,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 20,
                        thickness: 0.8,
                        color: AppColors.slate200,
                      ),
                      Text(
                        studentMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate700,
                          height: 1.45,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (attachmentUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'الملف المرفق',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 6),
                _AssignmentAttachmentPreview(
                  url: attachmentUrl,
                  name: attachmentName,
                  mimeType: _docText(assignment['attachment_type']),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(
                height: 24,
                thickness: 1,
                color: AppColors.slate100,
              ),

              // Dropdown Rating
              DropdownButtonFormField<String>(
                initialValue: reviewRating,
                decoration: InputDecoration(
                  labelText: 'التقييم المختصر عند الاعتماد',
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                  prefixIcon: const Icon(
                    Icons.stars_rounded,
                    color: AppColors.gold,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'excellent',
                    child: Text(
                      'ممتاز',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'good',
                    child: Text(
                      'جيد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'needs_improvement',
                    child: Text(
                      'يحتاج تحسين',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setLocal(() => reviewRating = value ?? reviewRating),
              ),
              const SizedBox(height: 12),

              // Notes TextField
              TextField(
                controller: notes,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'ملاحظات المراجعة',
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                  prefixIcon: const Icon(
                    Icons.rate_review_rounded,
                    color: AppColors.royalBlue,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'reject'),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.danger,
                      ),
                      label: const Text(
                        'رفض التكليف',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, 'approve'),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text(
                        'اعتماد وإغلاق',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    if (action == null) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .post('/doctor/clinical/assignments/${assignment['id']}/review', {
            'action': action,
            'review_notes': notes.text.trim(),
            if (action == 'approve') 'review_rating': reviewRating,
          });
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

  Future<void> _restoreChecklist(_Json item) async {
    final title = _docText(item['title'], 'قائمة التقييم');
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'استرجاع قائمة التقييم',
      message: 'هل تريد استرجاع "$title" وإظهارها ضمن قوائم التقييم المتاحة؟',
      confirmLabel: 'استرجاع',
      icon: Icons.restore_rounded,
      color: AppColors.success,
    );
    if (!ok) return;

    try {
      await ref
          .read(staffRepositoryProvider)
          .post(
            '/doctor/clinical/evaluations/checklists/${item['id']}/restore',
            {},
          );
      if (!mounted) return;
      _docSnack(context, 'تم استرجاع قائمة التقييم.', color: AppColors.success);
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
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

class _ClinicalRecordCard extends StatelessWidget {
  const _ClinicalRecordCard({required this.item, required this.onTap});

  final _Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _docText(item['status']);
    final statusLabel = _docText(item['status_label'], status);
    final student = _docMap(item['student']);
    final studentName = _docText(
      student['name'],
      _docText(item['student_name'], 'طالب'),
    );
    final studentNumber = _docText(
      student['student_number'],
      _docText(item['student_number'], '-'),
    );

    final center = _docText(
      _docMap(item['training_center'])['name'],
      _docText(item['training_center'], '-'),
    );
    final dept = _docText(
      _docMap(item['department'])['name'],
      _docText(item['department'], '-'),
    );
    final logDate = _docDate(item['log_date']);

    final groups = _docList(item['groups']);
    int historyCount = 0;
    int examCount = 0;
    bool didRound = false;

    for (final g in groups) {
      final map = _docMap(g);
      final key = _docText(map['key']);
      final count = _docInt(map['count']);
      if (key == 'history') {
        historyCount = count;
      } else if (key == 'exam') {
        examCount = count;
      } else if (key == 'round') {
        didRound = count > 0;
      }
    }

    final initial = studentName.isNotEmpty ? studentName.substring(0, 1) : 'ط';
    final statusColor = _docStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.royalBlue.withValues(
                          alpha: 0.08,
                        ),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.royalBlue,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Student info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'رقم القيد: $studentNumber',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      _buildStatusBadge(status, statusLabel, statusColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Training center & department & date
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetaText(
                            Icons.local_hospital_rounded,
                            center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetaText(
                            Icons.account_tree_rounded,
                            dept,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildMetaText(
                          Icons.calendar_month_rounded,
                          logDate,
                          isExpanded: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Activities stats row
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatChip(
                              Icons.history_edu_rounded,
                              'قصص: $historyCount',
                              AppColors.royalBlue,
                              historyCount > 0,
                            ),
                            _buildStatChip(
                              Icons.person_search_rounded,
                              'فحوصات: $examCount',
                              AppColors.gold,
                              examCount > 0,
                            ),
                            _buildStatChip(
                              Icons.groups_rounded,
                              'مرور سريري',
                              AppColors.teal,
                              didRound,
                            ),
                          ],
                        ),
                      ),
                      if (status == 'pending' ||
                          status == 'partially_confirmed') ...[
                        const SizedBox(width: 8),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مراجعة السجل',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.royalBlue,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 10,
                              color: AppColors.royalBlue,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, String label, Color color) {
    IconData icon = Icons.info_outline_rounded;
    if (status == 'confirmed') {
      icon = Icons.verified_rounded;
    } else if (status == 'partially_confirmed') {
      icon = Icons.pending_actions_rounded;
    } else if (status == 'pending') {
      icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaText(IconData icon, String text, {bool isExpanded = true}) {
    final textWidget = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.slate600,
        fontWeight: FontWeight.w700,
        fontFamily: 'Cairo',
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.slate400),
        const SizedBox(width: 4),
        if (isExpanded) Expanded(child: textWidget) else textWidget,
      ],
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String label,
    Color color,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.15) : AppColors.slate200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isActive ? color : AppColors.slate400),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              color: isActive ? color : AppColors.slate500,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalChecklistCard extends StatelessWidget {
  const _ClinicalChecklistCard({
    required this.item,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.isHidden = false,
  });

  final _Json item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    final title = _docText(item['title'], 'قائمة تقييم');
    final desc = _docText(item['description']);
    final skillType = _docText(item['skill_type']);
    final totalMarks = _docInt(item['total_marks']);
    final timeLimit = _docInt(item['time_limit_minutes']);
    final isPractice = _docBool(item['is_practice_allowed']);
    final isStandard = _docBool(item['is_standard']);

    String skillLabel = 'مهارات أخرى';
    IconData skillIcon = Icons.fact_check_rounded;
    Color skillColor = AppColors.slate600;

    if (skillType == 'history_taking') {
      skillLabel = 'أخذ التاريخ المرضي';
      skillIcon = Icons.history_edu_rounded;
      skillColor = AppColors.royalBlue;
    } else if (skillType == 'clinical_examination') {
      skillLabel = 'الفحص السريري';
      skillIcon = Icons.person_search_rounded;
      skillColor = AppColors.gold;
    } else if (skillType == 'procedure') {
      skillLabel = 'إجراء طبي سريري';
      skillIcon = Icons.healing_rounded;
      skillColor = AppColors.teal;
    } else if (skillType == 'communication') {
      skillLabel = 'مهارات التواصل';
      skillIcon = Icons.forum_rounded;
      skillColor = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: skillColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(skillIcon, color: skillColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  skillLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: skillColor,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.slate300,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isStandard
                                        ? AppColors.royalBlue.withValues(
                                            alpha: 0.08,
                                          )
                                        : Colors.purple.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isStandard ? 'أساسية' : 'مخصصة',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: isStandard
                                          ? AppColors.royalBlue
                                          : Colors.purple,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                        height: 1.4,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            Icons.star_rounded,
                            '$totalMarks درجة',
                            AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.timer_rounded,
                            timeLimit > 0 ? '$timeLimit دقائق' : 'مفتوح',
                            AppColors.royalBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.psychology_rounded,
                            isPractice ? 'يسمح بالتدريب' : 'تقييم رسمي',
                            AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isHidden && onRestore != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          icon: Icons.visibility_rounded,
                          label: 'عرض البنود',
                          color: AppColors.royalBlue,
                          onTap: onTap,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: Icons.restore_rounded,
                          label: 'استرجاع',
                          color: AppColors.success,
                          onTap: onRestore!,
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          icon: Icons.visibility_rounded,
                          label: 'عرض البنود',
                          color: AppColors.royalBlue,
                          onTap: onTap,
                        ),
                        const SizedBox(width: 12),
                        _buildActionButton(
                          icon: onRestore != null
                              ? Icons.restore_rounded
                              : Icons.edit_rounded,
                          label: isStandard ? 'نسخ وتعديل' : 'تعديل',
                          color: onRestore != null
                              ? AppColors.success
                              : AppColors.success,
                          onTap: onEdit ?? onRestore ?? onTap,
                        ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 12),
                          _buildActionButton(
                            icon: Icons.delete_rounded,
                            label: isStandard ? 'إخفاء القائمة' : 'حذف',
                            color: AppColors.danger,
                            onTap: onDelete ?? onRestore ?? onTap,
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate600,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicalEvaluationResultCard extends StatelessWidget {
  const _ClinicalEvaluationResultCard({
    required this.item,
    required this.onTap,
  });

  final _Json item;
  final VoidCallback onTap;

  IconData _gradeIcon(String grade) {
    return switch (grade) {
      'excellent' => Icons.workspace_premium_rounded,
      'good' || 'very_good' => Icons.thumb_up_rounded,
      'acceptable' || 'pass' => Icons.check_circle_rounded,
      'weak' => Icons.info_rounded,
      'fail' => Icons.cancel_rounded,
      _ => Icons.star_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final student = _docMap(item['student']);
    final studentName = _docText(student['name'], 'طالب');
    final studentNo = _docText(student['student_number'], '-');
    final checklist = _docMap(item['checklist']);
    final checklistTitle = _docText(checklist['title'], 'تقييم');
    final percentage = _docDouble(item['percentage']);
    final grade = _docText(item['grade']);
    final hasFeedback = _docText(item['doctor_feedback']).trim().isNotEmpty;
    final date = _docText(item['created_at']);

    final gradeColor = _evaluationGradeColor(grade);
    final gradeLabel = _docText(
      item['grade_label'],
      _evaluationGradeLabel(grade),
    );

    String formattedDate = '';
    try {
      if (date.isNotEmpty) {
        final parsed = DateTime.parse(date).toLocal();
        formattedDate =
            '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      formattedDate = date;
    }

    final String initial = studentName.isNotEmpty
        ? studentName.trim().substring(0, 1)
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: gradeColor.withValues(alpha: 0.08),
            highlightColor: gradeColor.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: gradeColor.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: gradeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.slate50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.slate100.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                'رقم القيد: $studentNo',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slate600,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: gradeColor.withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _gradeIcon(grade),
                              color: gradeColor,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$gradeLabel - ${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: gradeColor,
                                fontFamily: 'Cairo',
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: AppColors.slate100.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 15,
                        color: AppColors.slate400,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          checklistTitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnight,
                            fontFamily: 'Cairo',
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.slate100.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 13,
                              color: AppColors.slate400,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.slate600,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasFeedback)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 13,
                                color: AppColors.royalBlue,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'ملاحظات مضافة',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.royalBlue,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistDetailsView extends StatefulWidget {
  const _ChecklistDetailsView({required this.item});

  final _Json item;

  @override
  State<_ChecklistDetailsView> createState() => _ChecklistDetailsViewState();
}

class _ChecklistDetailsViewState extends State<_ChecklistDetailsView> {
  double _fontSizeScale = 1.0;

  IconData _getAdaptiveIcon(String text) {
    final t = text.toLowerCase();
    if (t.contains('غسل') ||
        t.contains('تعقيم') ||
        t.contains('يد') ||
        t.contains('wash') ||
        t.contains('sanitize') ||
        t.contains('hand')) {
      return Icons.clean_hands_rounded;
    }
    if (t.contains('سماع') ||
        t.contains('فحص') ||
        t.contains('صدر') ||
        t.contains('قلب') ||
        t.contains('سماعة') ||
        t.contains('stethoscope') ||
        t.contains('examine') ||
        t.contains('heart') ||
        t.contains('chest')) {
      return Icons.hearing_rounded;
    }
    if (t.contains('تحدث') ||
        t.contains('شرح') ||
        t.contains('سؤال') ||
        t.contains('تواصل') ||
        t.contains('مريض') ||
        t.contains('explain') ||
        t.contains('ask') ||
        t.contains('communicate')) {
      return Icons.forum_rounded;
    }
    if (t.contains('كتابة') ||
        t.contains('تسجيل') ||
        t.contains('ملاحظة') ||
        t.contains('ملف') ||
        t.contains('تقرير') ||
        t.contains('write') ||
        t.contains('record') ||
        t.contains('note') ||
        t.contains('file')) {
      return Icons.rate_review_rounded;
    }
    if (t.contains('إبرة') ||
        t.contains('حقن') ||
        t.contains('سحب') ||
        t.contains('دم') ||
        t.contains('عينة') ||
        t.contains('needle') ||
        t.contains('injection') ||
        t.contains('blood')) {
      return Icons.vaccines_rounded;
    }
    if (t.contains('نبض') ||
        t.contains('ضغط') ||
        t.contains('حرارة') ||
        t.contains('تنفس') ||
        t.contains('pulse') ||
        t.contains('blood pressure') ||
        t.contains('temperature')) {
      return Icons.monitor_heart_rounded;
    }
    return Icons.subdirectory_arrow_left_rounded; // Default fallback icon
  }

  String? _getSkillTypeTag(String text) {
    final t = text.toLowerCase();
    if (t.contains('تواصل') ||
        t.contains('شرح') ||
        t.contains('سؤال') ||
        t.contains('تحدث') ||
        t.contains('مريض') ||
        t.contains('explain') ||
        t.contains('ask')) {
      return 'مهارة تواصل';
    }
    if (t.contains('فحص') ||
        t.contains('سماع') ||
        t.contains('جس') ||
        t.contains('قرع') ||
        t.contains('examine') ||
        t.contains('listen') ||
        t.contains('palpate')) {
      return 'فحص سريري';
    }
    if (t.contains('حقن') ||
        t.contains('سحب') ||
        t.contains('تركيب') ||
        t.contains('خياطة') ||
        t.contains('علاج') ||
        t.contains('procedure')) {
      return 'إجراء عملي';
    }
    return null; // No special tag
  }

  @override
  Widget build(BuildContext context) {
    final title = _docText(widget.item['title'], 'قائمة التقييم');
    final desc = _docText(widget.item['description']);
    final totalMarks = _docInt(widget.item['total_marks']);
    final timeLimit = _docInt(widget.item['time_limit_minutes']);
    final isStandard = _docBool(widget.item['is_standard']);
    final rawItems = _docList(widget.item['items']);

    // Separate parents and sub items
    final parents = rawItems.where((i) {
      final pid = _docText(i['parent_id']);
      return pid.isEmpty || pid == '0';
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title, zoom controls and tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isStandard
                                ? AppColors.royalBlue.withValues(alpha: 0.08)
                                : Colors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isStandard
                                  ? AppColors.royalBlue.withValues(alpha: 0.2)
                                  : Colors.purple.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            isStandard ? 'أساسية' : 'مخصصة',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isStandard
                                  ? AppColors.royalBlue
                                  : Colors.purple,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Zoom accessibility controls
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_fontSizeScale > 0.85) {
                                    setState(() {
                                      _fontSizeScale -= 0.15;
                                    });
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Icon(
                                    Icons.zoom_out,
                                    size: 14,
                                    color: AppColors.slate600,
                                  ),
                                ),
                              ),
                              Text(
                                '${(_fontSizeScale * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate700,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (_fontSizeScale < 1.3) {
                                    setState(() {
                                      _fontSizeScale += 0.15;
                                    });
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Icon(
                                    Icons.zoom_in,
                                    size: 14,
                                    color: AppColors.slate600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15 * _fontSizeScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.midnight,
                        fontFamily: 'Cairo',
                        height: 1.3,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 12 * _fontSizeScale,
                          color: AppColors.slate500,
                          fontFamily: 'Cairo',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppColors.royalBlue,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bento Grid for Metadata
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الدرجة الكلية',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.slate500,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              '$totalMarks درجة',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.royalBlue.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.timer_rounded,
                          color: AppColors.royalBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'زمن الاختبار',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.slate500,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              timeLimit > 0 ? '$timeLimit دقائق' : 'مفتوح',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'بنود ومعايير التقييم',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.midnight,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          if (parents.isEmpty)
            const _DocEmpty('لا توجد بنود تقييم مضافة لهذه القائمة.')
          else
            ...parents.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final parent = entry.value;
              final pid = _docInt(parent['id']);
              final subItems = rawItems
                  .where((i) => _docInt(i['parent_id']) == pid)
                  .toList();
              final indexStr = index.toString().padLeft(2, '0');
              final parentMarks = _docText(parent['marks'], '0');
              final parentDesc = _docText(parent['description']);

              // Calculate parent weight
              final parentMarksDbl = double.tryParse(parentMarks) ?? 0.0;
              final weight = totalMarks > 0
                  ? (parentMarksDbl / totalMarks)
                  : 0.0;
              final skillTag = _getSkillTypeTag(parentDesc);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.midnight.withValues(alpha: 0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Parent Item row
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sequential index circle
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.08,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              indexStr,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.royalBlue,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Content & Weight
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        parentDesc,
                                        style: TextStyle(
                                          fontSize: 12.5 * _fontSizeScale,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.midnight,
                                          fontFamily: 'Cairo',
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    if (skillTag != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.royalBlue.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          skillTag,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.royalBlue,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (weight > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: weight,
                                            backgroundColor: AppColors.slate100,
                                            color: AppColors.gold.withValues(
                                              alpha: 0.6,
                                            ),
                                            minHeight: 3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(weight * 100).toInt()}% من الإجمالي',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppColors.slate400,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Mark badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              '$parentMarks د',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (subItems.isNotEmpty) ...[
                      // Line separator
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: AppColors.slate100,
                      ),
                      // Nested sub items block
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: subItems.map((sub) {
                            final subMarks = _docText(sub['marks'], '0');
                            final subDesc = _docText(sub['description']);
                            final adaptiveIcon = _getAdaptiveIcon(subDesc);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Icon(
                                      adaptiveIcon,
                                      size: 13,
                                      color: AppColors.royalBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      subDesc,
                                      style: TextStyle(
                                        fontSize: 11.5 * _fontSizeScale,
                                        color: AppColors.slate700,
                                        fontFamily: 'Cairo',
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.slate200,
                                      ),
                                    ),
                                    child: Text(
                                      '$subMarks د',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.slate600,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _EvaluationResultDetailsView extends StatelessWidget {
  const _EvaluationResultDetailsView({required this.data});

  final _Json data;

  @override
  Widget build(BuildContext context) {
    final student = _docMap(data['student']);
    final studentName = _docText(student['name'], 'طالب');
    final studentNo = _docText(student['student_number'], '-');
    final checklist = _docMap(data['checklist']);
    final checklistTitle = _docText(checklist['title'], 'تقييم');

    final percentageText = _docText(data['percentage'], '0');
    final percentage = double.tryParse(percentageText) ?? 0.0;
    final totalMarks = _docInt(data['total_marks']);
    final grade = _docText(data['grade']);
    final timerType = _docText(data['timer_type'], 'fixed');
    final timeTaken = _docInt(data['time_taken_seconds']);
    final feedback = _docText(data['doctor_feedback']).trim();
    final date = _docText(data['created_at']);
    final scores = _docList(data['scores']);

    // Color and label by grade
    Color gradeColor = AppColors.slate600;
    String gradeLabel = 'غير معروف';
    if (grade == 'excellent') {
      gradeColor = AppColors.success;
      gradeLabel = 'ممتاز';
    } else if (grade == 'very_good') {
      gradeColor = AppColors.royalBlue;
      gradeLabel = 'جيد جداً';
    } else if (grade == 'good') {
      gradeColor = AppColors.teal;
      gradeLabel = 'جيد';
    } else if (grade == 'pass') {
      gradeColor = AppColors.gold;
      gradeLabel = 'مقبول';
    } else if (grade == 'fail') {
      gradeColor = AppColors.danger;
      gradeLabel = 'راسب';
    }

    String formattedDate = '';
    try {
      if (date.isNotEmpty) {
        final parsed = DateTime.parse(date).toLocal();
        formattedDate =
            '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      formattedDate = date;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradeColor.withValues(alpha: 0.15),
                  gradeColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: gradeColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: gradeColor,
                  child: Text(
                    studentName.isNotEmpty
                        ? studentName.trim().substring(0, 1)
                        : '؟',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.midnight,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'رقم القيد: $studentNo',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      gradeLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: gradeColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: gradeColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.slate100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  checklistTitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.slate100),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.star_rounded,
                        'الدرجة الكلية: $totalMarks',
                        AppColors.gold,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.timer_rounded,
                        timerType == 'open' ? 'مؤقت مفتوح' : 'ثابت / محدد',
                        AppColors.royalBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today_rounded,
                        formattedDate,
                        AppColors.slate600,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.speed_rounded,
                        timeTaken > 0 ? 'مستغرق: $timeTaken ثانية' : 'غير محدد',
                        AppColors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (feedback.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.comment_rounded,
                        size: 16,
                        color: AppColors.royalBlue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ملاحظات وتوجيهات الطبيب',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.royalBlue,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feedback,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.slate700,
                      fontFamily: 'Cairo',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'تفاصيل تقييم الخطوات السريرية',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.midnight,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 10),
          if (scores.isEmpty)
            const _DocEmpty('لا توجد بيانات تفصيلية للدرجات.')
          else
            ...scores.map((scoreObj) {
              final scoreItem = _docMap(scoreObj['checklist_item']);
              final description = _docText(
                scoreItem['description'],
                'خطوة تقييم',
              );
              final maxMarks = _docText(scoreItem['marks'], '1');
              final status = _docText(scoreObj['score']);
              final obtainedMarks = _docText(scoreObj['marks_obtained'], '0');

              Color scoreColor = AppColors.danger;
              String scoreLabel = 'لم يتم';
              if (status == 'done') {
                scoreColor = AppColors.success;
                scoreLabel = 'تم بالكامل';
              } else if (status == 'partial') {
                scoreColor = AppColors.gold;
                scoreLabel = 'تم جزئياً';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status == 'done'
                            ? Icons.check_circle_rounded
                            : status == 'partial'
                            ? Icons.pending_rounded
                            : Icons.cancel_rounded,
                        color: scoreColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.midnight,
                              fontFamily: 'Cairo',
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الدرجة المستحقة: $obtainedMarks من $maxMarks',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.slate500,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        scoreLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.slate700,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
