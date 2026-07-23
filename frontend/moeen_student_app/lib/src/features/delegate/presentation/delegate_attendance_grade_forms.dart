part of 'delegate_screens.dart';

Future<void> _attendanceSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> subject, {
  Map<String, dynamic>? qrSessionData,
  String? date,
  int? lectureId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) => _AttendanceFormWidget(
          subject: subject,
          scrollController: controller,
          qrSessionData: qrSessionData,
          date: date,
          lectureId: lectureId,
        ),
      ),
    ),
  );
}

class _AttendanceFormWidget extends ConsumerStatefulWidget {
  const _AttendanceFormWidget({
    required this.subject,
    required this.scrollController,
    this.qrSessionData,
    this.date,
    this.lectureId,
  });
  final Map<String, dynamic> subject;
  final ScrollController scrollController;
  final Map<String, dynamic>? qrSessionData;
  final String? date;
  final int? lectureId;

  @override
  ConsumerState<_AttendanceFormWidget> createState() =>
      _AttendanceFormWidgetState();
}

class _AttendanceFormWidgetState extends ConsumerState<_AttendanceFormWidget> {
  bool _isLoading = true;
  String _date = DateTime.now().toIso8601String().split('T').first;
  String _genderFilter = 'all';

  final _titleController = TextEditingController();
  final _lectureNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _lectureType = 'official';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<dynamic> _students = [];
  Map<int, String> _statuses = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.date != null) {
      _date = widget.date!;
    }
    if (widget.qrSessionData != null) {
      final qrSessionId = number(widget.qrSessionData, 'id').toInt();
      _fetchData(qrSessionId: qrSessionId);
    } else {
      _fetchData(lectureId: widget.lectureId);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lectureNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({int? qrSessionId, int? lectureId}) async {
    setState(() => _isLoading = true);
    try {
      final data = await ref
          .read(delegateRepositoryProvider)
          .attendanceCreate(
            subjectId: number(widget.subject, 'id').toInt(),
            date: _date,
            qrSessionId: qrSessionId,
            lectureId: lectureId,
          );
      if (!mounted) return;

      final prefill = asMap(data['prefill']);
      final records = asMap(data['attendance_records']);
      _students = asList(data['students']);

      _titleController.text = text(
        prefill,
        'title',
        fallback: _titleController.text,
      );
      if (_titleController.text.isEmpty) {
        _titleController.text = 'محاضرة $_date';
      }

      _lectureNumberController.text = text(
        prefill,
        'lecture_number',
        fallback: _lectureNumberController.text,
      );
      _descriptionController.text = text(
        prefill,
        'description',
        fallback: _descriptionController.text,
      );
      _lectureType = text(prefill, 'lecture_type', fallback: 'official');
      _date = text(prefill, 'date', fallback: _date);

      final st = text(prefill, 'start_time');
      if (st.isNotEmpty) {
        final parts = st.split(':');
        if (parts.length >= 2) {
          _startTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      final et = text(prefill, 'end_time');
      if (et.isNotEmpty) {
        final parts = et.split(':');
        if (parts.length >= 2) {
          _endTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }

      _statuses.clear();
      for (final raw in _students) {
        final id = number(raw, 'id').toInt();
        final record = records[id.toString()];
        if (record != null) {
          _statuses[id] = text(asMap(record), 'status', fallback: 'present');
        } else {
          _statuses[id] = 'present';
        }
      }

      if (data['verification'] != null) {
        final verifications = asList(
          asMap(data['verification'])['verifications'],
        );
        for (final v in verifications) {
          final studentId = number(v, 'student_id').toInt();
          final vStatus = text(v, 'verification_status');
          if (vStatus == 'confirmed_present' || vStatus == 'scanned_present') {
            _statuses[studentId] = 'present';
          } else if (vStatus == 'confirmed_absent' ||
              vStatus == 'unscanned_absent') {
            _statuses[studentId] = 'absent';
          }
        }
      }
    } catch (e) {
      if (mounted) _toast(context, 'خطأ في جلب البيانات: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectAll(String status) {
    setState(() {
      for (final raw in _students) {
        _statuses[number(raw, 'id').toInt()] = status;
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final newDate = picked.toIso8601String().split('T').first;
      if (newDate != _date) {
        _date = newDate;
        _fetchData();
      }
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredStudents = _students.where((s) {
      if (_searchQuery.isEmpty) return true;
      final name = text(s, 'name').toLowerCase();
      final num = text(s, 'student_number').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          num.contains(_searchQuery.toLowerCase());
    }).toList();

    final presentCount = _statuses.values.where((v) => v == 'present').length;
    final absentCount = _statuses.values.where((v) => v == 'absent').length;
    final lateCount = _statuses.values.where((v) => v == 'late').length;
    final totalCount = _students.length;

    DateTime? dateObj;
    try {
      dateObj = DateTime.tryParse(_date);
    } catch (_) {}

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        const SizedBox(height: 12),
        _FormHeader(
          subjectName: text(widget.subject, 'name'),
          dateText: dateObj != null
              ? intl.DateFormat('yMMMMEEEEd', 'ar').format(dateObj)
              : _date,
          presentCount: presentCount,
          absentCount: absentCount,
          lateCount: lateCount,
          totalCount: totalCount,
          isQr: widget.qrSessionData != null,
        ),
        const SizedBox(height: 24),
        _GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان المحاضرة *',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'التاريخ *',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        child: Text(
                          _date,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _lectureType,
                      items: const [
                        DropdownMenuItem(
                          value: 'official',
                          child: Text('رسمية'),
                        ),
                        DropdownMenuItem(
                          value: 'special',
                          child: Text('إضافية/خاصة'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _lectureType = v ?? 'official'),
                      decoration: const InputDecoration(
                        labelText: 'نوع المحاضرة',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lectureNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'رقم المحاضرة',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'وقت البدء',
                          prefixIcon: Icon(Icons.access_time_rounded),
                        ),
                        child: Text(
                          _startTime?.format(context) ?? 'غير محدد',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'وقت الانتهاء',
                          prefixIcon: Icon(Icons.access_time_filled_rounded),
                        ),
                        child: Text(
                          _endTime?.format(context) ?? 'غير محدد',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.people_rounded, color: AppColors.royalBlue),
            const SizedBox(width: 8),
            const Text(
              'قائمة الطلاب',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const Spacer(),
            Text(
              'تم اختيار $presentCount طالب',
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickActionBtn(
              label: 'حضور الكل',
              icon: Icons.done_all_rounded,
              color: AppColors.success,
              onTap: () => _selectAll('present'),
            ),
            const SizedBox(width: 8),
            _QuickActionBtn(
              label: 'غياب الكل',
              icon: Icons.remove_done_rounded,
              color: AppColors.danger,
              onTap: () => _selectAll('absent'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'بحث باسم الطالب أو الرقم الجامعي...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.royalBlue,
            ),
            filled: true,
            fillColor: AppColors.slate100.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 20),
        if (filteredStudents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: _EmptyState('لا يوجد طلاب يطابقون البحث.'),
          )
        else
          ...filteredStudents.map((raw) {
            final id = number(raw, 'id').toInt();
            return _StudentAttendanceCard(
              name: text(raw, 'name'),
              studentNumber: text(raw, 'student_number'),
              status: _statuses[id] ?? 'present',
              onChanged: (newStatus) =>
                  setState(() => _statuses[id] = newStatus),
            );
          }),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () async {
            if (_titleController.text.trim().isEmpty) {
              _toast(context, 'يرجى إدخال عنوان المحاضرة');
              return;
            }
            final payload = {
              'subject_id': number(widget.subject, 'id').toInt(),
              'title': _titleController.text.trim(),
              'date': _date,
              'lecture_type': _lectureType,
              if (_lectureNumberController.text.trim().isNotEmpty)
                'lecture_number': _lectureNumberController.text.trim(),
              if (_descriptionController.text.trim().isNotEmpty)
                'description': _descriptionController.text.trim(),
              if (_startTime != null)
                'start_time':
                    '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
              if (_endTime != null)
                'end_time':
                    '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
              'gender_filter': _genderFilter,
              if (widget.qrSessionData != null)
                'qr_session_id': number(widget.qrSessionData, 'id').toInt(),
              'students': _statuses.entries
                  .map((entry) => {'id': entry.key, 'status': entry.value})
                  .toList(),
            };

            await _run(
              context,
              () =>
                  ref.read(delegateRepositoryProvider).saveAttendance(payload),
              after: () => ref.invalidate(_delegateAttendanceProvider),
            );
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.royalBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'حفظ وإرسال سجل الحضور',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.subjectName,
    required this.dateText,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.totalCount,
    required this.isQr,
  });

  final String subjectName;
  final String dateText;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int totalCount;
  final bool isQr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: AppColors.midnight,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isQr)
              const _TagBadge(
                label: 'جلسة QR',
                color: AppColors.teal,
                icon: Icons.qr_code_scanner_rounded,
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StatCard(
              label: 'حاضر',
              count: presentCount,
              color: AppColors.success,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'غائب',
              count: absentCount,
              color: AppColors.danger,
              icon: Icons.cancel_rounded,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'تأخر',
              count: lateCount,
              color: AppColors.warning,
              icon: Icons.watch_later_rounded,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'الكل',
              count: totalCount,
              color: AppColors.royalBlue,
              icon: Icons.people_alt_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({
    required this.label,
    required this.color,
    required this.icon,
  });
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentAttendanceCard extends StatelessWidget {
  const _StudentAttendanceCard({
    required this.name,
    required this.studentNumber,
    required this.status,
    required this.onChanged,
  });

  final String name;
  final String studentNumber;
  final String status;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);

    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0] : 'S',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      studentNumber,
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusMiniBadge(status: status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatusToggle(
                label: 'حاضر',
                icon: Icons.check_rounded,
                isActive: status == 'present',
                activeColor: AppColors.success,
                onTap: () => onChanged('present'),
              ),
              _StatusToggle(
                label: 'غائب',
                icon: Icons.close_rounded,
                isActive: status == 'absent',
                activeColor: AppColors.danger,
                onTap: () => onChanged('absent'),
              ),
              _StatusToggle(
                label: 'متأخر',
                icon: Icons.access_time_rounded,
                isActive: status == 'late',
                activeColor: AppColors.warning,
                onTap: () => onChanged('late'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.danger;
      case 'late':
        return AppColors.warning;
      default:
        return AppColors.slate400;
    }
  }
}

class _StatusMiniBadge extends StatelessWidget {
  const _StatusMiniBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    String label = 'حاضر';
    Color color = AppColors.success;
    if (status == 'absent') {
      label = 'غائب';
      color = AppColors.danger;
    } else if (status == 'late') {
      label = 'متأخر';
      color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor : AppColors.slate50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? activeColor : AppColors.slate200,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : AppColors.slate400,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isActive ? Colors.white : AppColors.slate600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showAttendanceReportSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> session,
) async {
  await showMoeenBottomSheet(
    context: context,
    title: 'تقرير الحضور',
    icon: Icons.analytics_rounded,
    color: AppColors.royalBlue,
    fullScreen: true,
    child: _AttendanceReportWidget(
      session: session,
    ),
  );
}

class _AttendanceReportWidget extends ConsumerStatefulWidget {
  const _AttendanceReportWidget({
    required this.session,
  });
  final Map<String, dynamic> session;

  @override
  ConsumerState<_AttendanceReportWidget> createState() =>
      _AttendanceReportWidgetState();
}

class _AttendanceReportWidgetState
    extends ConsumerState<_AttendanceReportWidget> {
  bool _isLoading = true;
  bool _isDownloading = false;
  Map<String, dynamic>? _report;
  String _searchQuery = '';
  String _statusFilter = 'all';
  late final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final sId = number(widget.session, 'subject_id').toInt();
      final subId = sId > 0 ? sId : number(asMap(widget.session['subject']), 'id').toInt();
      
      final lId = number(widget.session, 'lecture_id').toInt();
      final lectId = lId > 0 ? lId : number(asMap(widget.session['lecture']), 'id').toInt();

      final data = await ref
          .read(delegateRepositoryProvider)
          .attendanceReport(
            subjectId: subId,
            date: text(widget.session, 'date'),
            lectureId: lectId > 0 ? lectId : null,
          );
      if (mounted) setState(() => _report = data);
    } catch (e) {
      if (mounted) _toast(context, 'خطأ في جلب التقرير: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePrint() async {
    if (_isDownloading) return;
    
    final date = text(widget.session, 'date');
    final lId = number(widget.session, 'lecture_id').toInt();
    final lectureId = lId > 0 ? lId : number(asMap(widget.session['lecture']), 'id').toInt();
    
    final sId = number(widget.session, 'subject_id').toInt();
    final subjectId = sId > 0 ? sId : number(asMap(widget.session['subject']), 'id').toInt();
    
    final displaySubjectId = (subjectId == 0 || boolValue(_report, 'is_unofficial')) ? 0 : subjectId;

    final sessionToken = ref.read(authControllerProvider).valueOrNull;
    final token = sessionToken?.token;
    if (token == null) {
      _toast(context, 'الرجاء تسجيل الدخول مرة أخرى');
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final baseUrl = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
      final lectureQuery = lectureId > 0 ? '?lecture_id=$lectureId' : '';
      await DownloadService.downloadUrl(
        url: '$baseUrl/delegate/attendances/$displaySubjectId/$date/report-pdf$lectureQuery',
        fileName: 'تقرير_حضور_${text(widget.session, 'display_name')}_$date.pdf',
        headers: {
          'Accept': 'application/pdf',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      if (mounted) _toast(context, 'فشل تحميل التقرير: $e');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleEdit() async {
    Navigator.pop(context);
    final subject = asMap(widget.session['subject']);
    final date = text(widget.session, 'date');
    final lId = number(widget.session, 'lecture_id').toInt();
    final lectureId = lId > 0 ? lId : number(asMap(widget.session['lecture']), 'id').toInt();

    final editSubject = subject.isEmpty
        ? {'id': 0, 'name': text(widget.session, 'display_name')}
        : subject;

    await _attendanceSheet(
      context,
      ref,
      editSubject,
      date: date,
      lectureId: lectureId,
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final selected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeAttendanceStatus(String status) {
    if (status == 'present' || status == 'absent' || status == 'late' || status == 'excused') {
      return status;
    }
    return 'present';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_report == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('فشل تحميل التقرير.')),
      );
    }

    final appStudents = asList(_report!['app_students']).map(asMap).toList();
    final students = (appStudents.isNotEmpty ? appStudents : asList(_report!['students'])).map(asMap).toList();
    
    final summary = asMap(_report!['summary']);
    final present = summary.isNotEmpty
        ? number(summary, 'present').toInt()
        : students.where((s) => _normalizeAttendanceStatus(text(s, 'status')) == 'present').length;
    final absent = summary.isNotEmpty
        ? number(summary, 'absent').toInt()
        : students.where((s) => _normalizeAttendanceStatus(text(s, 'status')) == 'absent').length;
    final lateCount = summary.isNotEmpty
        ? number(summary, 'late').toInt()
        : students.where((s) => _normalizeAttendanceStatus(text(s, 'status')) == 'late').length;
    final excusedCount = summary.isNotEmpty
        ? number(summary, 'excused').toInt()
        : students.where((s) => _normalizeAttendanceStatus(text(s, 'status')) == 'excused').length;

    final lecture = asMap(_report!['lecture']);
    final dateRaw = text(widget.session, 'date');
    DateTime? dateObj;
    try {
      dateObj = DateTime.tryParse(dateRaw);
    } catch (_) {}
    final formattedDate = dateObj != null
        ? intl.DateFormat('yMMMMEEEEd', 'ar').format(dateObj)
        : dateRaw;
    final isQr = text(widget.session, 'attendance_method') == 'qr';
    final displaySubjectName = text(asMap(widget.session['subject']), 'name', fallback: text(widget.session, 'display_name'));

    // Apply client-side search and status filters
    final filteredStudents = students.where((student) {
      final name = text(student, 'name').toLowerCase();
      final numberStr = text(student, 'student_number').toLowerCase();
      final status = _normalizeAttendanceStatus(text(student, 'status'));

      final matchesQuery = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          numberStr.contains(_searchQuery.toLowerCase());

      if (!matchesQuery) return false;

      if (_statusFilter != 'all') {
        return status == _statusFilter;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gorgeous Academic Ticket Subject Card
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.slate100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent stripe
                  Container(width: 6, color: AppColors.royalBlue),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.royalBlue.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_stories_rounded,
                                  color: AppColors.royalBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displaySubjectName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Cairo',
                                        color: AppColors.midnight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'تفاصيل جلسة رصد حضور الطلاب',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate400,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _DashedDivider(),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ReportMetaChip(
                                icon: Icons.calendar_month_rounded,
                                label: formattedDate,
                              ),
                              if (lecture.isNotEmpty)
                                _ReportMetaChip(
                                  icon: Icons.menu_book_rounded,
                                  label: text(lecture, 'title', fallback: 'محاضرة'),
                                ),
                              if (text(lecture, 'lecture_number').isNotEmpty)
                                _ReportMetaChip(
                                  icon: Icons.tag_rounded,
                                  label: 'رقم ${text(lecture, 'lecture_number')}',
                                ),
                              _ReportMetaChip(
                                icon: isQr ? Icons.qr_code_rounded : Icons.edit_calendar_rounded,
                                label: isQr ? 'تحضير QR' : 'تحضير يدوي',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bento Grid Metrics Row
        Row(
          children: [
            _ReportMetricCard(
              label: 'الطلاب',
              value: '${students.length}',
              color: AppColors.royalBlue,
              icon: Icons.people_alt_rounded,
            ),
            const SizedBox(width: 8),
            _ReportMetricCard(
              label: 'حاضر',
              value: '$present',
              color: AppColors.success,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(width: 8),
            _ReportMetricCard(
              label: 'غائب',
              value: '$absent',
              color: AppColors.danger,
              icon: Icons.cancel_rounded,
            ),
            const SizedBox(width: 8),
            _ReportMetricCard(
              label: 'متأخر',
              value: '$lateCount',
              color: AppColors.warning,
              icon: Icons.watch_later_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Actions Row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _handleEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.royalBlue,
                  side: const BorderSide(color: AppColors.royalBlue, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text(
                  'تعديل الجلسة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isDownloading ? null : _handlePrint,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.royalBlue.withValues(alpha: 0.2),
                ),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text(
                  'تحميل التقرير',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Real-time Reactive Search Box
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.midnight,
          ),
          decoration: InputDecoration(
            hintText: 'بحث باسم الطالب أو رقم القيد...',
            hintStyle: const TextStyle(color: AppColors.slate400),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.royalBlue,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.slate400,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.slate50,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.slate100,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.royalBlue,
                width: 2,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.slate100,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal Category Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'الكل (${students.length})', AppColors.royalBlue),
              const SizedBox(width: 8),
              _buildFilterChip('present', 'حاضر ($present)', AppColors.success),
              const SizedBox(width: 8),
              _buildFilterChip('absent', 'غائب ($absent)', AppColors.danger),
              const SizedBox(width: 8),
              _buildFilterChip('late', 'متأخر ($lateCount)', AppColors.warning),
              const SizedBox(width: 8),
              _buildFilterChip('excused', 'عذر ($excusedCount)', AppColors.royalBlue),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Students list
        filteredStudents.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'لا يوجد طلاب يطابقون خيارات التصفية والبحث.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return _SessionStudentCard(
                    name: text(student, 'name'),
                    status: _normalizeAttendanceStatus(text(student, 'status')),
                    studentNumber: text(student, 'student_number'),
                  );
                },
              ),
      ],
    );
  }
}

class _SessionStudentCard extends StatelessWidget {
  const _SessionStudentCard({
    required this.name,
    required this.status,
    required this.studentNumber,
  });
  final String name;
  final String status;
  final String studentNumber;

  Color _statusColor(String status) {
    if (status == 'present') return AppColors.success;
    if (status == 'absent') return AppColors.danger;
    if (status == 'late') return AppColors.warning;
    if (status == 'excused') return AppColors.royalBlue;
    return AppColors.slate400;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final initialLetter = name.isNotEmpty ? name[0] : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status accent strip
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Circular initial avatar with gradient & overlay
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: 0.15),
                                  color.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initialLetter,
                              style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          // Mini status badge overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                status == 'present'
                                    ? Icons.check_rounded
                                    : status == 'absent'
                                        ? Icons.close_rounded
                                        : status == 'late'
                                            ? Icons.access_time_rounded
                                            : Icons.info_outline_rounded,
                                size: 10,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Student details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.midnight,
                                fontSize: 14,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            if (studentNumber.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge_rounded,
                                    size: 13,
                                    color: AppColors.slate400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    studentNumber,
                                    style: const TextStyle(
                                      color: AppColors.slate400,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Premium Status Badge
                      _PremiumStatusBadge(
                        status: status,
                        color: color,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _startQrSession(
  BuildContext context,
  WidgetRef ref, {
  int? subjectId,
  String? title,
  String? date,
  String? lectureNumber,
  String? lectureType,
  required ValueChanged<Map<String, dynamic>> onStarted,
}) async {
  if (subjectId != null && title != null && date != null) {
    final session = await ref.read(delegateRepositoryProvider).startQrAttendance({
      'subject_id': subjectId,
      'title': title,
      'date': date,
      if (lectureNumber != null) 'lecture_number': lectureNumber,
      if (lectureType != null) 'lecture_type': lectureType,
    });
    onStarted(session);
    return;
  }

  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;
  var selectedSubjectId = subjects.isNotEmpty
      ? number(subjects.first, 'id').toInt()
      : 0;
  final titleController = TextEditingController(text: 'جلسة حضور QR');
  final dateController = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  await _formSheet(
    context,
    title: 'بدء جلسة QR',
    fields: [
      DropdownButtonFormField<int>(
        value: selectedSubjectId == 0 ? null : selectedSubjectId,
        items: subjects
            .where(
              (subject) => asMap(subject)['allow_delegate_attendance'] == true,
            )
            .map(
              (subject) => DropdownMenuItem(
                value: number(subject, 'id').toInt(),
                child: Text(text(subject, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => selectedSubjectId = value ?? 0,
        decoration: const InputDecoration(labelText: 'المادة'),
      ),
      TextField(
        controller: titleController,
        decoration: const InputDecoration(labelText: 'عنوان الجلسة'),
      ),
      TextField(
        controller: dateController,
        decoration: const InputDecoration(labelText: 'التاريخ'),
      ),
    ],
    onSave: () async {
      final session = await ref
          .read(delegateRepositoryProvider)
          .startQrAttendance({
            'subject_id': selectedSubjectId,
            'title': titleController.text.trim(),
            'date': dateController.text.trim(),
          });
      onStarted(session);
      return 'تم بدء الجلسة.';
    },
    after: () {},
  );
}

Future<void> _gradesEntrySheet(
  BuildContext context,
  WidgetRef ref,
  int categoryId,
) async {
  final data = await ref
      .read(delegateRepositoryProvider)
      .authorizedGradeDetails(categoryId);
  if (!context.mounted) return;
  final students = asList(data['students']);
  final controllers = <int, TextEditingController>{};
  for (final raw in students) {
    final id = number(raw, 'id').toInt();
    final current = asMap(raw)['current_grade'];
    controllers[id] = TextEditingController(text: text(current, 'score'));
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('رصد الدرجات', style: _titleStyle),
            const SizedBox(height: 12),
            for (final raw in students)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: controllers[number(raw, 'id').toInt()],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        '${text(raw, 'name')} - ${text(raw, 'student_number', fallback: '-')}',
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                final grades = controllers.entries
                    .where((entry) => entry.value.text.trim().isNotEmpty)
                    .map(
                      (entry) => {
                        'student_id': entry.key,
                        'score': entry.value.text.trim(),
                      },
                    )
                    .toList();
                await _run(
                  context,
                  () => ref
                      .read(delegateRepositoryProvider)
                      .saveAuthorizedGrades(
                        categoryId: categoryId,
                        grades: grades,
                      ),
                  after: () =>
                      ref.invalidate(_delegateAuthorizedGradesProvider),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('إرسال للمراجعة'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _helperDelegationSheet(BuildContext context, WidgetRef ref) async {
  final grades = await ref.read(delegateRepositoryProvider).authorizedGrades();
  final categories = asList(grades['direct_delegations']);
  if (!context.mounted || categories.isEmpty) {
    if (context.mounted)
      _toast(context, 'لا توجد تصنيفات مفوضة لإنشاء تفويض مساعد.');
    return;
  }
  var categoryId = number(categories.first, 'id').toInt();
  final title = TextEditingController(text: 'مهمة رصد درجات');
  final notes = TextEditingController();
  var helperId = 0;
  var delegationType = 'full';
  List<dynamic> students = const [];
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          8,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تفويض مساعد رصد', style: _titleStyle),
              DropdownButtonFormField<int>(
                value: categoryId,
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: number(category, 'id').toInt(),
                        child: Text(text(category, 'name')),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  categoryId = value ?? categoryId;
                  final data = await ref
                      .read(delegateRepositoryProvider)
                      .helperDelegationStudents(categoryId);
                  setState(() {
                    students = asList(data['eligible_students']);
                    helperId = students.isNotEmpty
                        ? number(students.first, 'id').toInt()
                        : 0;
                  });
                },
                decoration: const InputDecoration(labelText: 'التصنيف'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final data = await ref
                      .read(delegateRepositoryProvider)
                      .helperDelegationStudents(categoryId);
                  setState(() {
                    students = asList(data['eligible_students']);
                    helperId = students.isNotEmpty
                        ? number(students.first, 'id').toInt()
                        : 0;
                  });
                },
                icon: const Icon(Icons.people_rounded),
                label: const Text('تحميل الطلاب المتاحين'),
              ),
              if (students.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: helperId == 0 ? null : helperId,
                  items: students
                      .map(
                        (student) => DropdownMenuItem(
                          value: number(student, 'id').toInt(),
                          child: Text(
                            '${text(student, 'name')} - ${text(student, 'role')}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => helperId = value ?? 0,
                  decoration: const InputDecoration(labelText: 'المساعد'),
                ),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'عنوان المهمة'),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
              DropdownButtonFormField<String>(
                value: delegationType,
                items: const [
                  DropdownMenuItem(value: 'full', child: Text('كل الطلاب')),
                  DropdownMenuItem(value: 'partial', child: Text('تفويض جزئي')),
                ],
                onChanged: (value) => delegationType = value ?? 'full',
                decoration: const InputDecoration(labelText: 'نطاق التفويض'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: helperId == 0
                    ? null
                    : () async {
                        await _run(
                          context,
                          () => ref
                              .read(delegateRepositoryProvider)
                              .createHelperDelegation({
                                'category_id': categoryId,
                                'helper_user_id': helperId,
                                'delegation_type': delegationType,
                                'title': title.text.trim(),
                                'notes': notes.text.trim(),
                                if (delegationType == 'partial')
                                  'student_ids': students
                                      .map(
                                        (student) =>
                                            number(student, 'id').toInt(),
                                      )
                                      .take(1)
                                      .toList(),
                              }),
                          after: () =>
                              ref.invalidate(_delegateHelperTasksProvider),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                child: const Text('إنشاء التفويض'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.slate100,
    );
  }
}

class _ReportMetaChip extends StatelessWidget {
  const _ReportMetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.slate500),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.slate600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Icon(icon, size: 16, color: color.withValues(alpha: 0.6)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.slate400,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumStatusBadge extends StatelessWidget {
  const _PremiumStatusBadge({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    String label = 'حاضر';
    if (status == 'absent') {
      label = 'غائب';
    } else if (status == 'late') {
      label = 'متأخر';
    } else if (status == 'excused') {
      label = 'عذر';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
