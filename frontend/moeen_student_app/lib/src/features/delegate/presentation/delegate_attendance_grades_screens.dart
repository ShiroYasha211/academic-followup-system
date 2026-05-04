part of 'delegate_screens.dart';

class DelegateAttendanceScreen extends ConsumerWidget {
  const DelegateAttendanceScreen({super.key});
  static const route = DelegateRoutes.attendance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<Map<String, dynamic>>(
      title: 'رصد الحضور',
      index: 12,
      state: ref.watch(_delegateAttendanceProvider),
      onRetry: () => ref.invalidate(_delegateAttendanceProvider),
      icon: Icons.how_to_reg_rounded,
      colors: const [AppColors.success, AppColors.teal],
      extractor: (data) => asList(data['subjects']),
      itemBuilder: (item) {
        final subject = asMap(item);
        final allowed = subject['allow_delegate_attendance'] == true;
        return _DataCard(
          title: text(subject, 'name'),
          subtitle: allowed ? 'متاح للمندوب رصد الحضور' : 'مغلق من الدكتور',
          icon: allowed ? Icons.check_circle_rounded : Icons.lock_rounded,
          color: allowed ? AppColors.success : AppColors.slate400,
          actions: [
            if (allowed)
              IconButton(
                onPressed: () => _attendanceSheet(context, ref, subject),
                icon: const Icon(Icons.edit_calendar_rounded),
              ),
          ],
        );
      },
    );
  }
}

class DelegateQrAttendanceScreen extends ConsumerStatefulWidget {
  const DelegateQrAttendanceScreen({super.key});
  static const route = DelegateRoutes.qrAttendance;

  @override
  ConsumerState<DelegateQrAttendanceScreen> createState() =>
      _DelegateQrAttendanceScreenState();
}

class _DelegateQrAttendanceScreenState
    extends ConsumerState<DelegateQrAttendanceScreen> {
  Map<String, dynamic>? _session;
  Map<String, dynamic>? _status;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DelegateShell(
      currentIndex: 13,
      title: 'QR حضور',
      child: ListView(
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
            ElevatedButton.icon(
              onPressed: () => _startQrSession(
                context,
                ref,
                onStarted: (session) {
                  setState(() => _session = session);
                  unawaited(_startPolling());
                },
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('بدء جلسة QR'),
            )
          else ...[
            _GlassCard(
              child: Column(
                children: [
                  const Text('رمز الجلسة الحالي', style: _titleStyle),
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
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    text(
                      _session!,
                      'current_token',
                      fallback: text(_status, 'token', fallback: ''),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'المصوّرون: ${value(_status, 'scanned_count')} / ${value(_status, 'total_students')}',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _refreshQr,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('تحديث'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _finalizeQr,
                        icon: const Icon(Icons.stop_circle_rounded),
                        label: const Text('إنهاء'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionTitle('آخر حالة', Icons.people_rounded),
            ...asList(_status?['students'])
                .take(30)
                .map(
                  (raw) => _DataCard(
                    title: text(
                      raw,
                      'name',
                      fallback: text(raw, 'student_name'),
                    ),
                    subtitle: text(
                      raw,
                      'status',
                      fallback: text(raw, 'scan_status', fallback: '-'),
                    ),
                    icon: Icons.person_rounded,
                    color: AppColors.teal,
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Future<void> _refreshQr() async {
    final id = number(_session, 'id').toInt();
    if (id <= 0) return;
    final status = await ref.read(delegateRepositoryProvider).qrStatus(id);
    if (mounted) setState(() => _status = status);
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

class DelegateAbsenceAlertsScreen extends ConsumerWidget {
  const DelegateAbsenceAlertsScreen({super.key});
  static const route = DelegateRoutes.absenceAlerts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<Map<String, dynamic>>(
      title: 'إنذارات الغياب',
      index: 14,
      state: ref.watch(_delegateAbsenceAlertsProvider),
      onRetry: () => ref.invalidate(_delegateAbsenceAlertsProvider),
      icon: Icons.warning_rounded,
      colors: const [AppColors.warning, AppColors.danger],
      extractor: (data) => [
        ...asList(data['absent_today']),
        ...asList(data['at_risk_students']),
      ],
      itemBuilder: (item) {
        final student = asMap(item['student']);
        final subject = asMap(item['subject']);
        return _DataCard(
          title: text(
            student,
            'name',
            fallback: text(item, 'student_name', fallback: 'طالب'),
          ),
          subtitle:
              '${text(subject, 'name', fallback: text(item, 'subject_name', fallback: 'مادة'))} | نسبة/عدد الغياب: ${value(item, 'absence_rate', fallback: value(item, 'absence_count'))}',
          icon: Icons.person_off_rounded,
          color: AppColors.warning,
        );
      },
    );
  }
}

class DelegateAuthorizedGradesScreen extends ConsumerWidget {
  const DelegateAuthorizedGradesScreen({super.key});
  static const route = DelegateRoutes.authorizedGrades;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<Map<String, dynamic>>(
      title: 'الدرجات المفوضة',
      index: 15,
      state: ref.watch(_delegateAuthorizedGradesProvider),
      onRetry: () => ref.invalidate(_delegateAuthorizedGradesProvider),
      icon: Icons.grade_rounded,
      colors: const [AppColors.goldDeep, AppColors.orange],
      extractor: (data) => [
        ...asList(data['direct_delegations']),
        ...asList(data['helper_tasks']).map((task) => asMap(task)['category']),
      ],
      itemBuilder: (item) {
        final category = asMap(item);
        final subject = asMap(category['subject']);
        return _DataCard(
          title: text(
            category,
            'name',
            fallback: text(category, 'title', fallback: 'تفويض درجات'),
          ),
          subtitle:
              '${text(subject, 'name', fallback: 'مادة')} | الدرجة: ${value(category, 'max_score')}',
          icon: Icons.grade_rounded,
          color: AppColors.goldDeep,
          actions: [
            IconButton(
              onPressed: () => _gradesEntrySheet(
                context,
                ref,
                number(category, 'id').toInt(),
              ),
              icon: const Icon(Icons.edit_note_rounded),
            ),
          ],
        );
      },
    );
  }
}

class DelegateGradeHelperDelegationsScreen extends ConsumerWidget {
  const DelegateGradeHelperDelegationsScreen({super.key});
  static const route = DelegateRoutes.gradeDelegations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<Map<String, dynamic>>(
      title: 'تفويض مساعدي الرصد',
      index: 16,
      state: ref.watch(_delegateHelperTasksProvider),
      onRetry: () => ref.invalidate(_delegateHelperTasksProvider),
      icon: Icons.manage_accounts_rounded,
      colors: const [AppColors.violet, AppColors.royalBlue],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _helperDelegationSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('تفويض'),
      ),
      extractor: (data) => asList(data['tasks']),
      itemBuilder: (item) => _DataCard(
        title: text(item, 'title', fallback: 'تفويض مساعد'),
        subtitle:
            '${text(asMap(item)['helper_user'], 'name', fallback: '-')} | ${text(item, 'delegation_type', fallback: '-')}',
        icon: Icons.manage_accounts_rounded,
        color: AppColors.violet,
        actions: [
          IconButton(
            onPressed: () => _delete(
              context,
              () => ref
                  .read(delegateRepositoryProvider)
                  .revokeHelperDelegation(number(item, 'id').toInt()),
              () => ref.invalidate(_delegateHelperTasksProvider),
            ),
            icon: const Icon(Icons.cancel_rounded, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
