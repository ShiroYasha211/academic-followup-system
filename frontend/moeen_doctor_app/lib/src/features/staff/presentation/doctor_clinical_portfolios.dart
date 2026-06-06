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
    extends ConsumerState<DoctorClinicalPortfolioDetailsScreen> {
  late Future<_Json> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
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
                const SizedBox(height: 16),
                _PortfolioMatrixTable(rows: matrix),
                const SizedBox(height: 16),
                _PortfolioLogsTimeline(logs: logs),
              ],
            ),
          );
        },
      ),
    );
  }
}

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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.midnight, AppColors.royalBlue, AppColors.teal],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 21,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$number • $major • $level',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _heroMetric('إجمالي الأنشطة', summary['approved_activities']),
              _heroMetric('قصص مرضية', summary['history_taking']),
              _heroMetric('فحوصات سريرية', summary['clinical_examination']),
              _heroMetric('مرور', summary['round']),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.midnight,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCsv,
                  icon: const Icon(Icons.table_view_rounded),
                  label: const Text('Excel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.6),
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

  Widget _heroMetric(String label, Object? value) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _docText(value, '0'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioMatrixTable extends StatelessWidget {
  const _PortfolioMatrixTable({required this.rows});

  final List<_Json> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جدول الإنجاز التراكمي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.slate50),
              columns: const [
                DataColumn(label: Text('النظام/المهارة')),
                DataColumn(label: Text('قصص')),
                DataColumn(label: Text('فحوصات')),
                DataColumn(label: Text('مرور')),
                DataColumn(label: Text('الإجمالي')),
              ],
              rows: rows
                  .map(
                    (row) => DataRow(
                      cells: [
                        DataCell(Text(_docText(row['body_system'], '-'))),
                        DataCell(Text(_docText(row['history_taking'], '0'))),
                        DataCell(
                          Text(_docText(row['clinical_examination'], '0')),
                        ),
                        DataCell(Text(_docText(row['round'], '0'))),
                        DataCell(Text(_docText(row['total'], '0'))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioLogsTimeline extends StatelessWidget {
  const _PortfolioLogsTimeline({required this.logs});

  final List<_Json> logs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تفاصيل الجلسات المعتمدة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            const _DocEmpty('لا توجد جلسات معتمدة.')
          else
            ...logs.map((log) {
              final activities = _docList(log['activities']);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_docText(log['date'], '-')} • ${_docText(log['training_center'], '-')} • ${_docText(log['department'], '-')}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnight,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activities.map((activity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: Text(
                            '${_docText(activity['type_label'])}: ${_docText(activity['body_system'], '-')}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate700,
                              fontSize: 11.5,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
