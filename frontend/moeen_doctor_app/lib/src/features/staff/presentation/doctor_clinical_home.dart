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
        const SizedBox(height: 12),
        _ClinicalBentoCard(
          title: 'إنجازات الطلاب العملية',
          subtitle:
              'تقرير تراكمي لكل طالب حسب نظام الجسم ونوع النشاط مع تصدير PDF وExcel.',
          icon: Icons.table_chart_rounded,
          color: AppColors.success,
          onTap: () =>
              context.push(DoctorClinicalSectionScreen.path('portfolios')),
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
}
