part of 'staff_screens.dart';

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
  String? _portfolioMajor;
  String? _portfolioLevel;
  String? _portfolioSort = 'name_asc';
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
            'portfolios',
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
    'portfolios' => '/doctor/clinical/logbook/students',
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
    'portfolios' => 'إنجازات الطلاب العملية',
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
    'portfolios' =>
      'استعرض التقرير التراكمي لكل طالب حسب نظام الجسم ونوع النشاط، وقم بتصدير تقرير نهاية السنة.',
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
    'portfolios' => Icons.table_chart_rounded,
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
                  'portfolios',
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

  void _update(VoidCallback callback) => setState(callback);

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
                if (_showsFilters) _buildFilters(data),
                if (_showsFilters) const SizedBox(height: 14),
                ..._buildBody(data),
              ],
            ),
          );
        },
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
    case 'attendance_edit_request':
      return 'طلب تعديل حضور';
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
    case 'attendance_edit_request':
      return AppColors.warning;
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
    case 'attendance_edit_request':
      return Icons.edit_calendar_rounded;
    case 'resource':
      return Icons.folder_rounded;
    case 'announcement':
      return Icons.campaign_rounded;
    default:
      return Icons.notifications_rounded;
  }
}
