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
        builder: (context, controller) => _AttendanceReportWidget(
          session: session,
          scrollController: controller,
        ),
      ),
    ),
  );
}

class _AttendanceReportWidget extends ConsumerStatefulWidget {
  const _AttendanceReportWidget({
    required this.session,
    required this.scrollController,
  });
  final Map<String, dynamic> session;
  final ScrollController scrollController;

  @override
  ConsumerState<_AttendanceReportWidget> createState() =>
      _AttendanceReportWidgetState();
}

class _AttendanceReportWidgetState
    extends ConsumerState<_AttendanceReportWidget> {
  bool _isLoading = true;
  bool _isDownloading = false;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _fetchData();
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

    final session = ref.read(authControllerProvider).valueOrNull;
    final token = session?.token;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_report == null) {
      return const Center(child: Text('فشل تحميل التقرير.'));
    }

    final appStudents = asList(_report!['app_students']);
    final students = appStudents.isNotEmpty ? appStudents : asList(_report!['students']);
    final summary = asMap(_report!['summary']);
    final present = summary.isNotEmpty
        ? number(summary, 'present').toInt()
        : students.where((s) => text(s, 'status') == 'present').length;
    final absent = summary.isNotEmpty
        ? number(summary, 'absent').toInt()
        : students.where((s) => text(s, 'status') == 'absent').length;
    final lateCount = summary.isNotEmpty
        ? number(summary, 'late').toInt()
        : students.where((s) => text(s, 'status') == 'late').length;
    final excusedCount = summary.isNotEmpty
        ? number(summary, 'excused').toInt()
        : students.where((s) => text(s, 'status') == 'excused').length;
    final total = students.length;

    final lecture = asMap(_report!['lecture']);
    final dateRaw = text(widget.session, 'date');
    DateTime? dateObj;
    try {
      dateObj = DateTime.tryParse(dateRaw);
    } catch (_) {}
    final formattedDate = dateObj != null
        ? intl.DateFormat('yMMMMEEEEd', 'ar').format(dateObj)
        : dateRaw;

    final isUnofficial = boolValue(_report, 'is_unofficial');
    final lectureType = text(lecture, 'lecture_type');
    String typeLabel = 'محاضرة رسمية';
    Color typeColor = AppColors.royalBlue;
    if (isUnofficial) {
      typeLabel = 'جلسة غير رسمية';
      typeColor = Colors.orange;
    } else if (lectureType == 'special') {
      typeLabel = 'محاضرة إضافية';
      typeColor = AppColors.teal;
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        // Header Section
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnofficial
                      ? Icons.stars_rounded
                      : Icons.assignment_turned_in_rounded,
                  color: typeColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text(widget.session, 'display_name'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: 4),
              _ReportTypeBadge(
                status: isUnofficial ? 'unofficial' : 'official',
                label: typeLabel,
                color: typeColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Info Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _ReportInfoCard(
              icon: Icons.book_rounded,
              label: 'المادة',
              value: text(
                asMap(widget.session['subject']),
                'name',
                fallback: 'غير محدد',
              ),
              color: AppColors.royalBlue,
            ),
            _ReportInfoCard(
              icon: Icons.title_rounded,
              label: 'العنوان',
              value: text(lecture, 'title', fallback: 'جلسة عادية'),
              color: AppColors.teal,
            ),
            _ReportInfoCard(
              icon: Icons.calendar_today_rounded,
              label: 'التاريخ',
              value: formattedDate,
              color: AppColors.slate600,
            ),
            _ReportInfoCard(
              icon: Icons.category_rounded,
              label: 'النوع',
              value: typeLabel,
              color: typeColor,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Summary Stats Row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReportStatSummary(
                label: 'حاضر',
                value: present,
                color: AppColors.success,
              ),
              _ReportStatSummary(
                label: 'غائب',
                value: absent,
                color: AppColors.danger,
              ),
              _ReportStatSummary(
                label: 'متأخر',
                value: lateCount,
                color: AppColors.warning,
              ),
              _ReportStatSummary(
                label: 'عذر',
                value: excusedCount,
                color: AppColors.royalBlue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Actions Row
        Row(
          children: [
            Expanded(
              child: _ReportActionButton(
                onTap: _handleEdit,
                icon: Icons.edit_note_rounded,
                label: 'تعديل السجل',
                color: AppColors.royalBlue,
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportActionButton(
                onTap: _isDownloading ? null : _handlePrint,
                icon: Icons.picture_as_pdf_rounded,
                label: 'تحميل التقرير',
                color: AppColors.danger,
                isPrimary: false,
                loading: _isDownloading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Students List Header
        Row(
          children: [
            const Icon(
              Icons.people_rounded,
              color: AppColors.slate500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'سجل حضور الطلاب ($total)',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.slate700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        for (final student in students)
          _SessionStudentCard(
            name: text(student, 'name'),
            status: text(student, 'status'),
            studentNumber: text(student, 'student_number'),
          ),
      ],
    );
  }
}

class _ReportInfoCard extends StatelessWidget {
  const _ReportInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.slate400,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: AppColors.midnight,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportStatSummary extends StatelessWidget {
  const _ReportStatSummary({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.slate500,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ReportActionButton extends StatelessWidget {
  const _ReportActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
    required this.isPrimary,
    this.loading = false,
  });
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? Colors.white : color,
                ),
              )
            else
              Icon(icon, size: 20, color: isPrimary ? Colors.white : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTypeBadge extends StatelessWidget {
  const _ReportTypeBadge({
    required this.status,
    required this.label,
    required this.color,
  });
  final String status;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.success;
    String label = 'حاضر';
    IconData icon = Icons.check_circle_rounded;

    if (status == 'absent') {
      color = AppColors.danger;
      label = 'غائب';
      icon = Icons.cancel_rounded;
    } else if (status == 'late') {
      color = AppColors.warning;
      label = 'متأخر';
      icon = Icons.watch_later_rounded;
    } else if (status == 'excused') {
      color = AppColors.royalBlue;
      label = 'عذر';
      icon = Icons.info_outline_rounded;
    } else if (status.isEmpty || status == 'null') {
      color = AppColors.slate400;
      label = 'غير مسجل';
      icon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0] : 'S',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: AppColors.midnight,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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
