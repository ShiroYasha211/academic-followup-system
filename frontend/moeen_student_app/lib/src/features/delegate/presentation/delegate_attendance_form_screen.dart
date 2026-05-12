part of 'delegate_screens.dart';

class DelegateAttendanceFormScreen extends ConsumerStatefulWidget {
  const DelegateAttendanceFormScreen({
    super.key,
    required this.subject,
    required this.initialData,
  });

  final Map<String, dynamic> subject;
  final Map<String, dynamic> initialData;

  @override
  ConsumerState<DelegateAttendanceFormScreen> createState() =>
      _DelegateAttendanceFormScreenState();
}

class _DelegateAttendanceFormScreenState
    extends ConsumerState<DelegateAttendanceFormScreen> {
  bool _isLoading = true;
  late String _date;
  late String _title;
  late String _lectureNumber;
  late String _lectureType;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<dynamic> _students = [];
  final Map<int, String> _statuses = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _date = text(widget.initialData, 'date');
    _title = text(widget.initialData, 'title');
    _lectureNumber = text(widget.initialData, 'lecture_number');
    _lectureType = text(widget.initialData, 'lecture_type', fallback: 'official');
    _startTime = widget.initialData['start_time'];
    _endTime = widget.initialData['end_time'];
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ref.read(delegateRepositoryProvider).attendanceCreate(
            subjectId: number(widget.subject, 'id').toInt(),
            date: _date,
          );
      
      _students = asList(data['students']);
      final records = asMap(data['attendance_records']);

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
    } catch (e) {
      if (mounted) _toast(context, 'خطأ في جلب الطلاب: $e');
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('رصد الحضور')),
        body: const Center(child: CircularProgressIndicator()),
      );
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

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(text(widget.subject, 'name'), style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _StatCard(label: 'حاضر', count: presentCount, color: AppColors.success, icon: Icons.check_circle_rounded),
                const SizedBox(width: 8),
                _StatCard(label: 'غائب', count: absentCount, color: AppColors.danger, icon: Icons.cancel_rounded),
                const SizedBox(width: 8),
                _StatCard(label: 'متأخر', count: lateCount, color: AppColors.warning, icon: Icons.watch_later_rounded),
              ],
            ),
          ),
          // Search & Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'بحث باسم الطالب...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _QuickBtn(label: 'حضور الكل', color: AppColors.success, onTap: () => _selectAll('present'))),
                    const SizedBox(width: 10),
                    Expanded(child: _QuickBtn(label: 'غياب الكل', color: AppColors.danger, onTap: () => _selectAll('absent'))),
                  ],
                ),
              ],
            ),
          ),
          // Student List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final id = number(student, 'id').toInt();
                return _StudentAttendanceCard(
                  name: text(student, 'name'),
                  studentNumber: text(student, 'student_number'),
                  status: _statuses[id] ?? 'present',
                  onChanged: (val) => setState(() => _statuses[id] = val),
                );
              },
            ),
          ),
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('حفظ وإرسال السجل', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final payload = {
      'subject_id': number(widget.subject, 'id').toInt(),
      'title': _title,
      'date': _date,
      'lecture_type': _lectureType,
      if (_lectureNumber.isNotEmpty) 'lecture_number': _lectureNumber,
      if (_startTime != null) 'start_time': '${_startTime!.hour}:${_startTime!.minute}',
      if (_endTime != null) 'end_time': '${_endTime!.hour}:${_endTime!.minute}',
      'students': _statuses.entries.map((e) => {'id': e.key, 'status': e.value}).toList(),
    };

    await _run(
      context,
      () => ref.read(delegateRepositoryProvider).saveAttendance(payload),
      after: () {
        ref.invalidate(_delegateAttendanceProvider);
        context.pop(); // Pop form
        context.pop(); // Pop tracking screen
      },
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
    );
  }
}
