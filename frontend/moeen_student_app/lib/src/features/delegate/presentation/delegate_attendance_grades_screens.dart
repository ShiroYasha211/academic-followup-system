part of 'delegate_screens.dart';

class DelegateAttendanceScreen extends ConsumerStatefulWidget {
  const DelegateAttendanceScreen({super.key});
  static const route = DelegateRoutes.attendance;

  @override
  ConsumerState<DelegateAttendanceScreen> createState() =>
      _DelegateAttendanceScreenState();
}

class _DelegateAttendanceScreenState
    extends ConsumerState<DelegateAttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: DelegateShell(
        currentIndex: 12,
        title: 'رصد الحضور',
        floatingActionButton: _AttendanceActionFAB(
          onManual: () => _showManualSubjectPicker(context, ref),
          onQr: () => _startQrSession(
            context,
            ref,
            onStarted: (session) {
              DefaultTabController.of(context).animateTo(1);
            },
          ),
          isEnabled: true,
          onUnauthorized: () => _showNoPermissionSnackBar(context),
        ),
        bottom: const TabBar(
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          tabs: [
            Tab(text: 'رصد يدوي', icon: Icon(Icons.how_to_reg_rounded)),
            Tab(text: 'QR حضور', icon: Icon(Icons.qr_code_2_rounded)),
          ],
        ),
        child: TabBarView(
          children: [
            _ManualAttendanceTab(),
            _QrAttendanceTab(),
          ],
        ),
      ),
    );
  }
}

class _ManualAttendanceTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AsyncBody<Map<String, dynamic>>(
      state: ref.watch(_delegateAttendanceProvider),
      onRetry: () => ref.invalidate(_delegateAttendanceProvider),
      builder: (data) {
        final items = asList(data['subjects']);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_delegateAttendanceProvider),
          child: _ListScaffold(
            title: 'رصد يدوي (${items.length})',
            subtitle: 'اختر المادة للبدء برصد حضور المحاضرة يدوياً.',
            icon: Icons.how_to_reg_rounded,
            colors: const [AppColors.success, AppColors.teal],
            children: [
              if (items.isEmpty) const _EmptyState('لا توجد مواد متاحة.'),
              for (final item in items)
                _DataCard(
                  title: text(item, 'name'),
                  subtitle: (item['allow_delegate_attendance'] == true)
                      ? 'متاح للمندوب رصد الحضور'
                      : 'مغلق من الدكتور',
                  icon: (item['allow_delegate_attendance'] == true)
                      ? Icons.check_circle_rounded
                      : Icons.lock_rounded,
                  color: (item['allow_delegate_attendance'] == true)
                      ? AppColors.success
                      : AppColors.slate400,
                  actions: [
                    if (item['allow_delegate_attendance'] == true)
                      IconButton(
                        onPressed: () {
                          _attendanceSheet(context, ref, asMap(item));
                        },
                        icon: Opacity(
                          opacity: 1.0,
                          child: const Icon(Icons.edit_calendar_rounded),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QrAttendanceTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_QrAttendanceTab> createState() => _QrAttendanceTabState();
}

class _QrAttendanceTabState extends ConsumerState<_QrAttendanceTab> {
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _status;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      children: [
        const _HeroPanel(
          title: 'جلسة QR حضور',
          subtitle: 'ابدأ جلسة تصوير للدفعة وتابع المسح مباشرة.',
          icon: Icons.qr_code_2_rounded,
          colors: [AppColors.teal, AppColors.royalBlue],
        ),
        const SizedBox(height: 16),
        if (_session == null)
          _GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 64,
                  color: AppColors.teal,
                ),
                const SizedBox(height: 12),
                const Text(
                  'لا توجد جلسة نشطة حالياً',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ابدأ جلسة جديدة لمشاركة الكود مع الطلاب.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate500),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _startQrSession(
                      context,
                      ref,
                      onStarted: (session) {
                        setState(() => _session = session);
                        unawaited(_startPolling());
                      },
                    );
                  },
                  icon: Opacity(
                    opacity: 1.0,
                    child: const Icon(Icons.play_arrow_rounded),
                  ),
                  label: const Text('بدء جلسة QR جديدة'),
                ),
              ],
            ),
          )
        else ...[
          _GlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('رمز الجلسة الحالي', style: _titleStyle),
                    _StatusBadge(status: 'نشط', color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.royalBlue.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.royalBlue.withValues(alpha: 0.12),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: text(
                      _session!,
                      'current_token',
                      fallback: text(_status, 'token', fallback: ''),
                    ),
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _StatItemRow(
                  label: 'عدد الطلاب المسجلين',
                  value: '${value(_status, 'scanned_count')} / ${value(_status, 'total_students')}',
                  icon: Icons.people_rounded,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _refreshQr,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('تحديث'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _finalizeQr,
                        icon: const Icon(Icons.stop_circle_rounded),
                        label: const Text('إنهاء الجلسة'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('عمليات المسح الأخيرة', Icons.history_rounded),
          const SizedBox(height: 10),
          ...asList(_status?['recent_scans'] ?? _status?['students'])
              .take(20)
              .map(
                (raw) => _DataCard(
                  title: text(raw, 'name', fallback: 'طالب'),
                  subtitle: 'تم المسح في: ${text(raw, 'scanned_at', fallback: '-')}',
                  icon: Icons.person_rounded,
                  color: AppColors.teal,
                ),
              ),
        ],
      ],
    );
  }

  Future<void> _refreshQr() async {
    final id = number(_session, 'id').toInt();
    if (id <= 0) return;
    try {
      final status = await ref.read(delegateRepositoryProvider).qrStatus(id);
      if (mounted) setState(() => _status = status);
    } catch (_) {}
  }

  Future<void> _finalizeQr() async {
    final id = number(_session, 'id').toInt();
    if (id <= 0) return;
    await _run(
      context,
      () => ref.read(delegateRepositoryProvider).finalizeQr(id),
      after: () {
        _timer?.cancel();
        setState(() {
          _session = null;
          _status = null;
        });
      },
    );
  }

  Future<void> _startPolling() async {
    _timer?.cancel();
    await _refreshQr();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshQr());
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StatItemRow extends StatelessWidget {
  const _StatItemRow({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.slate400),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.slate600, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.midnight)),
      ],
    );
  }
}


class _AttendanceActionFAB extends StatelessWidget {
  const _AttendanceActionFAB({
    required this.onManual,
    required this.onQr,
    this.isEnabled = true,
    this.onUnauthorized,
  });
  final VoidCallback onManual;
  final VoidCallback onQr;
  final bool isEnabled;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: isEnabled ? 0.3 : 0.1),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: isEnabled ? () => _showAttendanceOptions(context) : onUnauthorized,
          backgroundColor: AppColors.teal,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 26),
        label: const Text(
          'بدء تحضير',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    ),
  );
}

  void _showAttendanceOptions(BuildContext context) {
    showMoeenBottomSheet(
      context: context,
      title: 'بدء رصد حضور',
      icon: Icons.how_to_reg_rounded,
      color: AppColors.teal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_calendar_rounded, color: AppColors.success),
            title: const Text('رصد يدوي', style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: const Text('اختيار مادة ورصد الطلاب يدوياً'),
            onTap: () {
              Navigator.pop(context);
              onManual();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.royalBlue),
            title: const Text('جلسة QR حضور', style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: const Text('توليد كود QR ليمسحه الطلاب'),
            onTap: () {
              Navigator.pop(context);
              onQr();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

Future<void> _showManualSubjectPicker(BuildContext context, WidgetRef ref) async {
  final state = ref.read(_delegateAttendanceProvider);
  final subjects = asList(state.value?['subjects']);
  
  if (subjects.isEmpty) {
    _toast(context, 'لا توجد مواد متاحة حالياً.');
    return;
  }

  await showMoeenBottomSheet(
    context: context,
    title: 'اختر المادة',
    icon: Icons.book_rounded,
    color: AppColors.royalBlue,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in subjects)
          if (item['allow_delegate_attendance'] == true)
            ListTile(
              title: Text(text(item, 'name'), style: const TextStyle(fontWeight: FontWeight.w800)),
              leading: const Icon(Icons.auto_stories_rounded, color: AppColors.slate400),
              onTap: () {
                Navigator.pop(context);
                _attendanceSheet(context, ref, asMap(item));
              },
            ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

class DelegateAbsenceAlertsScreen extends ConsumerWidget {
  const DelegateAbsenceAlertsScreen({super.key});
  static const route = DelegateRoutes.absenceAlerts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_delegateAbsenceAlertsProvider);

    return DefaultTabController(
      length: 2,
      child: DelegateShell(
        currentIndex: 13,
        title: 'إنذارات الغياب',
        bottom: const TabBar(
          tabs: [
            Tab(text: 'غائبون اليوم', icon: Icon(Icons.today_rounded)),
            Tab(text: 'المعرضون للحرمان', icon: Icon(Icons.warning_amber_rounded)),
          ],
        ),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text('فشل تحميل البيانات: $e'),
                ElevatedButton(
                  onPressed: () => ref.invalidate(_delegateAbsenceAlertsProvider),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
          data: (data) => TabBarView(
            children: [
              _AbsentTodayTab(items: asList(data['absent_today'])),
              _AtRiskStudentsTab(items: asList(data['at_risk_students'])),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbsentTodayTab extends StatelessWidget {
  const _AbsentTodayTab({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
            SizedBox(height: 16),
            Text('لا توجد غيابات مسجلة اليوم', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = asMap(items[index]);
        final student = asMap(item['student']);
        final subject = asMap(item['subject']);
        final lecture = asMap(item['lecture']);

        return _AbsenceAlertCard(
          studentName: text(student, 'name', fallback: text(item, 'student_name', fallback: 'طالب')),
          studentId: number(student, 'id').toInt(),
          subjectName: text(subject, 'name', fallback: text(item, 'subject_name', fallback: 'مادة')),
          detail: 'محاضرة: ${text(lecture, 'title', fallback: 'غير محدد')}',
          isAtRisk: false,
        );
      },
    );
  }
}

class _AtRiskStudentsTab extends StatelessWidget {
  const _AtRiskStudentsTab({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_satisfied_alt_rounded, size: 64, color: AppColors.success),
            SizedBox(height: 16),
            Text('لا يوجد طلاب معرضون للحرمان حالياً', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = asMap(items[index]);
        final student = asMap(item['student']);
        final subject = asMap(item['subject']);
        final rate = number(item, 'absence_rate').toDouble();

        return _AbsenceAlertCard(
          studentName: text(student, 'name', fallback: 'طالب'),
          studentId: number(student, 'id').toInt(),
          subjectName: text(subject, 'name', fallback: 'مادة'),
          detail: 'نسبة الغياب: $rate% | عدد الغياب: ${value(item, 'absences')}',
          isAtRisk: true,
          riskLevel: rate >= 25 ? 'high' : 'medium',
        );
      },
    );
  }
}

class _AbsenceAlertCard extends StatelessWidget {
  const _AbsenceAlertCard({
    required this.studentName,
    required this.studentId,
    required this.subjectName,
    required this.detail,
    required this.isAtRisk,
    this.riskLevel = 'medium',
  });

  final String studentName;
  final int studentId;
  final String subjectName;
  final String detail;
  final bool isAtRisk;
  final String riskLevel;

  @override
  Widget build(BuildContext context) {
    final color = isAtRisk 
        ? (riskLevel == 'high' ? AppColors.danger : AppColors.warning)
        : AppColors.royalBlue;

    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(
                  isAtRisk ? Icons.warning_rounded : Icons.person_off_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    Text(
                      subjectName,
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAtRisk)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    riskLevel == 'high' ? 'خطر عالي' : 'تنبيه',
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Navigate to conversation with student
                  context.push('${DelegateRoutes.messages}/$studentId');
                },
                icon: const Icon(Icons.message_rounded, color: AppColors.royalBlue, size: 20),
                tooltip: 'مراسلة الطالب',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DelegateAuthorizedGradesScreen extends ConsumerStatefulWidget {
  const DelegateAuthorizedGradesScreen({super.key});
  static const route = DelegateRoutes.authorizedGrades;

  @override
  ConsumerState<DelegateAuthorizedGradesScreen> createState() => _DelegateAuthorizedGradesScreenState();
}

class _DelegateAuthorizedGradesScreenState extends ConsumerState<DelegateAuthorizedGradesScreen> {
  @override
  Widget build(BuildContext context) {
    final myGradesState = ref.watch(_delegateAuthorizedGradesProvider);
    final helperTasksState = ref.watch(_delegateHelperTasksProvider);

    return DefaultTabController(
      length: 2,
      child: DelegateShell(
        currentIndex: 14,
        title: 'الدرجات المفوضة',
        bottom: const TabBar(
          tabs: [
            Tab(text: 'مهامي', icon: Icon(Icons.assignment_ind_rounded)),
            Tab(text: 'المساعدون', icon: Icon(Icons.manage_accounts_rounded)),
          ],
        ),
        child: TabBarView(
          children: [
            _MyGradesDelegationsTab(state: myGradesState),
            _IssuedHelperTasksTab(state: helperTasksState),
          ],
        ),
      ),
    );
  }
}

class _MyGradesDelegationsTab extends ConsumerWidget {
  const _MyGradesDelegationsTab({required this.state});
  final AsyncValue<Map<String, dynamic>> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (data) {
        final direct = asList(data['direct_delegations']);
        final fromOthers = asList(data['helper_tasks']);
        final all = [...direct, ...fromOthers];

        if (all.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grade_outlined, size: 64, color: AppColors.slate300),
                SizedBox(height: 16),
                Text('لا توجد تفويضات رصد حالياً'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: all.length,
          itemBuilder: (context, index) {
            final item = asMap(all[index]);
            // helper_tasks has the category nested inside 'category' key
            final category = item.containsKey('category') ? asMap(item['category']) : item;
            final subject = asMap(category['subject']);
            final doctor = asMap(category['doctor']);
            final isFromHelper = item.containsKey('delegated_by');

            return _GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.goldDeep.withValues(alpha: 0.1),
                        child: const Icon(Icons.grade_rounded, color: AppColors.goldDeep),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text(category, 'name'),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            Text(
                              text(subject, 'name', fallback: 'مادة'),
                              style: const TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (isFromHelper)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.violet.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('من مندوب', style: TextStyle(color: AppColors.violet, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatItemRow(
                              label: 'الدكتور المسؤول:',
                              value: text(doctor, 'name', fallback: 'غير محدد'),
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 4),
                            _StatItemRow(
                              label: 'الدرجة القصوى:',
                              value: value(category, 'max_score'),
                              icon: Icons.score_rounded,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          _gradesEntrySheet(
                            context,
                            ref,
                            number(category, 'id').toInt(),
                          );
                        },
                        icon: Opacity(
                          opacity: 1.0,
                          child: const Icon(Icons.edit_note_rounded, size: 18),
                        ),
                        label: const Text('رصد'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _IssuedHelperTasksTab extends ConsumerWidget {
  const _IssuedHelperTasksTab({required this.state});
  final AsyncValue<Map<String, dynamic>> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (data) {
          final tasks = asList(data['tasks']);

          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_disabled_rounded, size: 64, color: AppColors.slate300),
                  SizedBox(height: 16),
                  Text('لم تقم بتفويض أي مساعدين بعد'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = asMap(tasks[index]);
              final helper = asMap(task['helper_user']);
              final category = asMap(task['category']);
              final subject = asMap(category['subject']);

              return _GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.violet.withValues(alpha: 0.1),
                          child: const Icon(Icons.manage_accounts_rounded, color: AppColors.violet),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text(helper, 'name', fallback: 'مساعد'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              Text(
                                '${text(task, 'title')} | ${text(subject, 'name')}',
                                style: const TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _delete(
                            context,
                            () => ref.read(delegateRepositoryProvider).revokeHelperDelegation(number(task, 'id').toInt()),
                            () => ref.invalidate(_delegateHelperTasksProvider),
                          ),
                          icon: const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 22),
                          tooltip: 'إلغاء التفويض',
                        ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: AppColors.slate400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'النوع: ${text(task, 'delegation_type') == 'full' ? 'كامل الفئة' : 'طلاب محددين'}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate600),
                          ),
                        ),
                        if (task['due_at'] != null)
                          Text(
                            'الموعد: ${dateOnly(text(task, 'due_at'))}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _helperDelegationSheet(context, ref),
        backgroundColor: AppColors.violet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('تفويض مساعد جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
