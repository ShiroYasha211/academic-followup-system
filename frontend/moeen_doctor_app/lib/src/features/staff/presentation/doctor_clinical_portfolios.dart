part of 'staff_screens.dart';

class DoctorClinicalPortfolioDetailsScreen extends ConsumerStatefulWidget {
  const DoctorClinicalPortfolioDetailsScreen({
    super.key,
    required this.studentId,
  });

  static const route = '/doctor/clinical/portfolios/:studentId';

  final int studentId;

  static String path(String studentId) =>
      '/doctor/clinical/portfolios/$studentId';

  @override
  ConsumerState<DoctorClinicalPortfolioDetailsScreen> createState() =>
      _DoctorClinicalPortfolioDetailsScreenState();
}

class _DoctorClinicalPortfolioDetailsScreenState
    extends ConsumerState<DoctorClinicalPortfolioDetailsScreen>
    with SingleTickerProviderStateMixin {
  late Future<_Json> _future;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_Json> _fetch() async {
    final response = await ref
        .read(staffRepositoryProvider)
        .get('/doctor/clinical/logbook/students/${widget.studentId}');
    return _docMap(_docData(response));
  }

  Future<void> _download(String format, _Json portfolio) async {
    try {
      final student = _docMap(portfolio['student']);
      final extension = format == 'pdf' ? 'pdf' : 'csv';
      final bytes = await ref
          .read(staffRepositoryProvider)
          .download(
            '/doctor/clinical/logbook/students/${widget.studentId}/$extension',
          );
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName:
            'clinical_portfolio_${_docText(student['student_number'], '${widget.studentId}')}_${DateTime.now().toIso8601String().substring(0, 10)}.$extension',
        section: 'ClinicalReports',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تحميل التقرير',
        message: 'تم حفظ الملف في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'تفاصيل إنجازات الطالب',
      currentRoute: DoctorClinicalSectionScreen.path('portfolios'),
      child: FutureBuilder<_Json>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return StatusMessage(
              title: 'تعذر تحميل التقرير',
              message: snapshot.error.toString(),
              icon: Icons.error_outline_rounded,
              action: FilledButton.icon(
                onPressed: () => setState(() => _future = _fetch()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            );
          }

          final portfolio = snapshot.data ?? const {};
          final student = _docMap(portfolio['student']);
          final summary = _docMap(portfolio['summary']);
          final matrix = _docList(portfolio['matrix']);
          final logs = _docList(portfolio['logs']);

          // Split logs by status
          final confirmedLogs = logs.where((l) {
            final s = _docText(_docMap(l)['status'], 'pending');
            return s == 'confirmed';
          }).toList();

          final partialLogs = logs.where((l) {
            final s = _docText(_docMap(l)['status'], 'pending');
            return s == 'pending' || s == 'submitted_for_review' || s == 'partially_confirmed';
          }).toList();

          final rejectedLogs = logs.where((l) {
            final s = _docText(_docMap(l)['status'], 'pending');
            return s == 'rejected';
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _fetch()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _PortfolioHero(
                  student: student,
                  summary: summary,
                  onPdf: () => _download('pdf', portfolio),
                  onCsv: () => _download('csv', portfolio),
                ),
                const SizedBox(height: 20),
                _PortfolioMatrixTable(rows: matrix),
                const SizedBox(height: 20),
                _PortfolioLogsTabs(
                  tabController: _tabController,
                  confirmedLogs: confirmedLogs,
                  partialLogs: partialLogs,
                  rejectedLogs: rejectedLogs,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Student Card (used in the list screen)
// ─────────────────────────────────────────────

class _ClinicalPortfolioStudentCard extends StatelessWidget {
  const _ClinicalPortfolioStudentCard({
    required this.student,
    required this.summary,
    required this.onTap,
  });

  final _Json student;
  final _Json summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = _docText(student['name'], 'طالب');
    final number = _docText(student['student_number'], '-');
    final major = _docText(_docMap(student['major'])['name'], '-');
    final level = _docText(_docMap(student['level'])['name'], '-');

    Widget metric(String label, Object? value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Text(
          '$label ${_docText(value, '0')}',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
            fontSize: 11.5,
            color: color,
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalBlue.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1) : 'ط',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          color: AppColors.midnight,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$number • $major • $level',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.slate500,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                metric(
                  'الأنشطة',
                  summary['approved_activities'],
                  AppColors.royalBlue,
                ),
                metric('قصص', summary['history_taking'], AppColors.teal),
                metric(
                  'فحوصات',
                  summary['clinical_examination'],
                  AppColors.gold,
                ),
                metric('مرور', summary['round'], AppColors.success),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hero Card
// ─────────────────────────────────────────────

class _PortfolioHero extends StatelessWidget {
  const _PortfolioHero({
    required this.student,
    required this.summary,
    required this.onPdf,
    required this.onCsv,
  });

  final _Json student;
  final _Json summary;
  final VoidCallback onPdf;
  final VoidCallback onCsv;

  @override
  Widget build(BuildContext context) {
    final name = _docText(student['name'], 'طالب');
    final number = _docText(student['student_number'], '-');
    final major = _docText(_docMap(student['major'])['name'], '-');
    final level = _docText(_docMap(student['level'])['name'], '-');
    final initial = name.isNotEmpty ? name.substring(0, 1) : 'ط';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1B35), Color(0xFF1E3A7A), Color(0xFF0D5F5A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Student identity ──────────────────────────────────
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    color: AppColors.teal,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$number • $major',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      level,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 2×2 Metric Grid ───────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.35,
            children: [
              _HeroMetricTile(
                label: 'إجمالي الأنشطة',
                value: _docText(summary['approved_activities'], '0'),
                color: Colors.white,
                icon: Icons.verified_rounded,
              ),
              _HeroMetricTile(
                label: 'قصص مرضية',
                value: _docText(summary['history_taking'], '0'),
                color: AppColors.teal,
                icon: Icons.description_rounded,
              ),
              _HeroMetricTile(
                label: 'فحوصات سريرية',
                value: _docText(summary['clinical_examination'], '0'),
                color: AppColors.gold,
                icon: Icons.medical_services_rounded,
              ),
              _HeroMetricTile(
                label: 'مرور',
                value: _docText(summary['round'], '0'),
                color: AppColors.success,
                icon: Icons.route_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Export Buttons ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text(
                    'تصدير PDF',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F1B35),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCsv,
                  icon: const Icon(Icons.table_view_rounded, size: 18),
                  label: const Text(
                    'تصدير Excel',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.withValues(alpha: 0.85)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: color,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.60),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Achievement Matrix Table
// ─────────────────────────────────────────────

class _PortfolioMatrixTable extends StatelessWidget {
  const _PortfolioMatrixTable({required this.rows});

  final List<_Json> rows;

  @override
  Widget build(BuildContext context) {
    int totalStories = 0;
    int totalExams = 0;
    int totalRounds = 0;
    int grandTotal = 0;

    for (final row in rows) {
      totalStories += _docInt(row['history_taking']);
      totalExams += _docInt(row['clinical_examination']);
      totalRounds += _docInt(row['round']);
      grandTotal += _docInt(row['total']);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'جدول الإنجاز التراكمي',
          icon: Icons.table_chart_rounded,
          color: AppColors.teal,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate100),
            boxShadow: [
              BoxShadow(
                color: AppColors.midnight.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                color: const Color(0xFF0F1B35),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _TableHeaderCell('النظام / المهارة'),
                    ),
                    _TableHeaderCell('قصص'),
                    const SizedBox(width: 6),
                    _TableHeaderCell('فحوصات'),
                    const SizedBox(width: 6),
                    _TableHeaderCell('مرور'),
                    const SizedBox(width: 6),
                    _TableHeaderCell('الإجمالي'),
                  ],
                ),
              ),

              // Data rows
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: _DocEmpty('لا توجد بيانات في الجدول.'),
                )
              else
                ...rows.asMap().entries.map((entry) {
                  final isOdd = entry.key.isOdd;
                  final row = entry.value;
                  return _MatrixDataRow(
                    systemName: _docText(row['body_system'], '-'),
                    stories: _docText(row['history_taking'], '0'),
                    exams: _docText(row['clinical_examination'], '0'),
                    rounds: _docText(row['round'], '0'),
                    total: _docText(row['total'], '0'),
                    isOdd: isOdd,
                  );
                }),

              // Totals row
              if (rows.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.midnight.withValues(alpha: 0.06),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.midnight.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: const Text(
                          'الإجمالي الكلي',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: AppColors.midnight,
                          ),
                        ),
                      ),
                      _TableTotalCell('$totalStories', AppColors.teal),
                      const SizedBox(width: 6),
                      _TableTotalCell('$totalExams', AppColors.gold),
                      const SizedBox(width: 6),
                      _TableTotalCell('$totalRounds', AppColors.success),
                      const SizedBox(width: 6),
                      _TableTotalCell('$grandTotal', AppColors.midnight),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatrixDataRow extends StatelessWidget {
  const _MatrixDataRow({
    required this.systemName,
    required this.stories,
    required this.exams,
    required this.rounds,
    required this.total,
    required this.isOdd,
  });

  final String systemName;
  final String stories;
  final String exams;
  final String rounds;
  final String total;
  final bool isOdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      color: isOdd ? AppColors.slate50 : Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              systemName,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.midnight,
              ),
            ),
          ),
          _TableDataCell(stories, AppColors.teal),
          const SizedBox(width: 6),
          _TableDataCell(exams, AppColors.gold),
          const SizedBox(width: 6),
          _TableDataCell(rounds, AppColors.success),
          const SizedBox(width: 6),
          _TableDataCell(total, AppColors.midnight, isBold: true),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _TableDataCell extends StatelessWidget {
  const _TableDataCell(this.value, this.color, {this.isBold = false});
  final String value;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
          fontSize: 13,
          color: color,
        ),
      ),
    );
  }
}

class _TableTotalCell extends StatelessWidget {
  const _TableTotalCell(this.value, this.color);
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Logs Tabs Section
// ─────────────────────────────────────────────

class _PortfolioLogsTabs extends StatelessWidget {
  const _PortfolioLogsTabs({
    required this.tabController,
    required this.confirmedLogs,
    required this.partialLogs,
    required this.rejectedLogs,
  });

  final TabController tabController;
  final List<_Json> confirmedLogs;
  final List<_Json> partialLogs;
  final List<_Json> rejectedLogs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'سجل الجلسات',
          icon: Icons.timeline_rounded,
          color: AppColors.royalBlue,
        ),
        const SizedBox(height: 12),

        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate100),
          ),
          child: TabBar(
            controller: tabController,
            padding: const EdgeInsets.all(4),
            labelPadding: EdgeInsets.zero,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.midnight.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.midnight,
            unselectedLabelColor: AppColors.slate500,
            tabs: [
              _LogTab(
                label: 'معتمدة',
                count: confirmedLogs.length,
                activeColor: AppColors.success,
              ),
              _LogTab(
                label: 'جزئياً',
                count: partialLogs.length,
                activeColor: AppColors.gold,
              ),
              _LogTab(
                label: 'مرفوضة',
                count: rejectedLogs.length,
                activeColor: AppColors.slate400,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Tab content — rendered directly (no TabBarView to avoid nested scrolling issues)
        AnimatedBuilder(
          animation: tabController,
          builder: (context, _) {
            final index = tabController.index;
            final logs = index == 0
                ? confirmedLogs
                : index == 1
                ? partialLogs
                : rejectedLogs;
            final accentColor = index == 0
                ? AppColors.success
                : index == 1
                ? AppColors.gold
                : AppColors.slate400;

            if (logs.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: const _DocEmpty('لا توجد جلسات في هذه الفئة.'),
              );
            }

            return Column(
              children: logs.asMap().entries.map((entry) {
                final isLast = entry.key == logs.length - 1;
                return _TimelineEntry(
                  log: entry.value,
                  isLast: isLast,
                  accentColor: accentColor,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _LogTab extends StatelessWidget {
  const _LogTab({
    required this.label,
    required this.count,
    required this.activeColor,
  });

  final String label;
  final int count;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                  color: activeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Timeline Entry — self-contained dot + line
// ─────────────────────────────────────────────

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.log,
    required this.isLast,
    required this.accentColor,
  });

  final _Json log;
  final bool isLast;
  final Color accentColor;

  Color _activityColor(String? typeLabel) {
    if (typeLabel == null) return AppColors.slate400;
    final lower = typeLabel.toLowerCase();
    if (lower.contains('قصة') || lower.contains('تاريخ')) {
      return AppColors.teal;
    }
    if (lower.contains('فحص') || lower.contains('سريري')) {
      return AppColors.gold;
    }
    if (lower.contains('مرور') || lower.contains('جولة')) {
      return AppColors.success;
    }
    return AppColors.royalBlue;
  }

  @override
  Widget build(BuildContext context) {
    final activities = _docList(log['activities']);
    final date = _docText(log['date'], '-');
    final center = _docText(log['training_center'], '-');
    final department = _docText(log['department'], '-');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card (fills IntrinsicHeight) ──────────────────
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.midnight.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Right-side accent strip matching the borderRadius
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 3,
                      color: accentColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 11,
                                color: accentColor.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                date,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Center name
                        Text(
                          center,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.midnight,
                          ),
                        ),

                        // Department
                        if (department != '-' && department.isNotEmpty)
                          Text(
                            department,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                              color: AppColors.slate500,
                            ),
                          ),

                        // Activity chips
                        if (activities.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: activities.map((activity) {
                              final typeLabel = _docText(activity['type_label']);
                              final bodySystem = _docText(
                                activity['body_system'],
                                '-',
                              );
                              final reviewStatus = _docText(activity['review_status'], 'approved');
                              final statusSuffix = switch (reviewStatus) {
                                'rejected' => ' (مرفوض)',
                                'pending' => ' (معلق)',
                                _ => '',
                              };
                              final baseColor = _activityColor(typeLabel);
                              final chipColor = switch (reviewStatus) {
                                'rejected' => AppColors.danger,
                                'pending' => AppColors.warning,
                                _ => baseColor,
                              };
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: chipColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: chipColor.withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Text(
                                  '$typeLabel: $bodySystem$statusSuffix',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: chipColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Timeline column: dot + line ───────────────────
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // Dot aligned to top of card (with padding offset)
                const SizedBox(height: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Connecting line (grows to fill remaining height)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor.withValues(alpha: 0.5),
                            accentColor.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.midnight,
          ),
        ),
      ],
    );
  }
}
