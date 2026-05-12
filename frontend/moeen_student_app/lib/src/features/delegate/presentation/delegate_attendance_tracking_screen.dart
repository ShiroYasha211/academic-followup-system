part of 'delegate_screens.dart';

class DelegateAttendanceTrackingScreen extends ConsumerStatefulWidget {
  const DelegateAttendanceTrackingScreen({super.key, required this.subject});
  final Map<String, dynamic> subject;

  @override
  ConsumerState<DelegateAttendanceTrackingScreen> createState() =>
      _DelegateAttendanceTrackingScreenState();
}

class _DelegateAttendanceTrackingScreenState
    extends ConsumerState<DelegateAttendanceTrackingScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showStudents = true;
  bool _qrStarting = false;
  bool _qrFinalizing = false;
  bool _pairingWaiting = false;
  bool _externalFinalizedDialogShown = false;
  bool _desktopManagedQr = false;

  String _date = DateTime.now().toIso8601String().split('T').first;
  final _titleController = TextEditingController();
  final _lectureNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _lectureType = 'official';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<dynamic> _students = [];
  final Map<int, String> _statuses = {};
  String _searchQuery = '';

  int? _qrSessionId;
  String? _qrToken;
  int _rotationSeconds = 30;
  int _remainingSeconds = 30;
  Map<String, dynamic>? _qrStatus;
  Timer? _statusTimer;
  Timer? _rotateTimer;
  Timer? _countdownTimer;
  Timer? _pairingTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _stopQrTimers();
    _pairingTimer?.cancel();
    _titleController.dispose();
    _lectureNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({int? qrSessionId}) async {
    setState(() => _isLoading = true);
    try {
      final data = await ref.read(delegateRepositoryProvider).attendanceCreate(
            subjectId: number(widget.subject, 'id').toInt(),
            date: _date,
            qrSessionId: qrSessionId,
          );

      final prefill = asMap(data['prefill']);
      if (prefill.isNotEmpty && _titleController.text.trim().isEmpty) {
        _titleController.text = text(prefill, 'title');
        _lectureNumberController.text = text(prefill, 'lecture_number');
        _descriptionController.text = text(prefill, 'description');
        _lectureType = text(prefill, 'lecture_type', fallback: 'official');
      }

      final records = asMap(data['attendance_records']);
      _students = asList(data['students']);
      _statuses.clear();
      for (final raw in _students) {
        final id = number(raw, 'id').toInt();
        final record = records[id.toString()];
        _statuses[id] = record == null
            ? 'present'
            : text(asMap(record), 'status', fallback: 'present');
      }
    } catch (e) {
      if (mounted) _toast(context, 'خطأ في جلب بيانات التحضير: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _hasActiveQr => _qrSessionId != null && _qrToken != null;

  Future<void> _handleBack() async {
    if (_hasActiveQr) {
      final confirm = await _confirmCancelSession();
      if (!confirm) return;
      await _cancelQrSession(showMessage: false);
    }
    if (mounted) context.pop();
  }

  Future<bool> _confirmCancelSession() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء جلسة التحضير؟'),
        content: const Text(
          'إذا خرجت الآن سيتم إلغاء جلسة QR الحالية ولن يقبل الكود أي تحضير جديد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('البقاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('إلغاء الجلسة والخروج'),
          ),
        ],
      ),
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final doctor = asMap(widget.subject['doctor']);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
          ),
          title: const Text(
            'بدء تحضير جديد',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _SubjectHeader(subject: widget.subject, doctor: doctor),
                  const SizedBox(height: 20),
                  _SessionForm(
                    date: _date,
                    onDateChanged: _changeDate,
                    titleController: _titleController,
                    lectureNumberController: _lectureNumberController,
                    descriptionController: _descriptionController,
                    lectureType: _lectureType,
                    onTypeChanged: (val) =>
                        setState(() => _lectureType = val ?? 'official'),
                    startTime: _startTime,
                    endTime: _endTime,
                    onStartTimeChanged: (val) => setState(() => _startTime = val),
                    onEndTimeChanged: (val) => setState(() => _endTime = val),
                  ),
                  const SizedBox(height: 20),
                  _IntegratedActionBar(
                    isEnabled: widget.subject['allow_delegate_attendance'] == true,
                    showStudents: _showStudents,
                    qrActive: _hasActiveQr,
                    qrStarting: _qrStarting,
                    pairingWaiting: _pairingWaiting,
                    onManual: () => setState(() => _showStudents = true),
                    onQr: _startQr,
                    onPairing: _startPairing,
                  ),
                  if (_hasActiveQr) ...[
                    const SizedBox(height: 20),
                    _QrLivePanel(
                      token: _qrToken!,
                      remainingSeconds: _remainingSeconds,
                      scannedCount: number(_qrStatus, 'scanned_count').toInt(),
                      totalStudents: number(_qrStatus, 'total_students',
                              fallback: _students.length)
                          .toInt(),
                      recentScans: asList(_qrStatus?['recent_scans']),
                      presentStudents: asList(_qrStatus?['students'])
                          .where((s) => text(s, 'status') == 'present')
                          .take(8)
                          .toList(),
                      finalizing: _qrFinalizing,
                      onRefresh: _refreshQrStatus,
                      onFinalize: _finalizeQrSession,
                    ),
                  ],
                  if (_pairingWaiting && !_hasActiveQr) ...[
                    const SizedBox(height: 20),
                    const _PairingWaitingCard(),
                  ],
                  const SizedBox(height: 20),
                  if (_showStudents) _buildStudentsSection(),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAttendance,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('حفظ سجل الحضور'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStudentsSection() {
    final filteredStudents = _students.where((s) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return text(s, 'name').toLowerCase().contains(query) ||
          text(s, 'student_number').toLowerCase().contains(query);
    }).toList();

    final presentCount = _statuses.values.where((v) => v == 'present').length;
    final absentCount = _statuses.values.where((v) => v == 'absent').length;
    final lateCount = _statuses.values.where((v) => v == 'late').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'حاضر',
                count: presentCount,
                color: AppColors.success,
                icon: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'غائب',
                count: absentCount,
                color: AppColors.danger,
                icon: Icons.cancel_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'متأخر',
                count: lateCount,
                color: AppColors.warning,
                icon: Icons.watch_later_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'بحث باسم الطالب أو رقم القيد...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickBtn(
                label: 'حضور الكل',
                color: AppColors.success,
                onTap: () => _selectAll('present'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickBtn(
                label: 'غياب الكل',
                color: AppColors.danger,
                onTap: () => _selectAll('absent'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final student in filteredStudents)
          _StudentAttendanceCard(
            name: text(student, 'name'),
            studentNumber: text(student, 'student_number'),
            status: _statuses[number(student, 'id').toInt()] ?? 'present',
            onChanged: (value) => setState(
              () => _statuses[number(student, 'id').toInt()] = value,
            ),
          ),
      ],
    );
  }

  void _changeDate(String value) {
    setState(() => _date = value);
    _fetchData();
  }

  void _selectAll(String status) {
    setState(() {
      for (final raw in _students) {
        _statuses[number(raw, 'id').toInt()] = status;
      }
    });
  }

  bool _validateSessionFields() {
    if (_titleController.text.trim().isEmpty) {
      _toast(context, 'يرجى إدخال عنوان الجلسة');
      return false;
    }
    return true;
  }

  Future<void> _startQr() async {
    if (!_validateSessionFields() || _qrStarting || _hasActiveQr) return;

    setState(() {
      _qrStarting = true;
      _showStudents = true;
    });

    try {
      final session = await ref.read(delegateRepositoryProvider).startQrAttendance({
        'subject_id': number(widget.subject, 'id').toInt(),
        'title': _titleController.text.trim(),
        'date': _date,
        if (_lectureNumberController.text.trim().isNotEmpty)
          'lecture_number': _lectureNumberController.text.trim(),
        'lecture_type': _lectureType,
      });

      _activateQrSession(session);
    } catch (e) {
      if (mounted) _toast(context, 'تعذر بدء جلسة QR: $e');
    } finally {
      if (mounted) setState(() => _qrStarting = false);
    }
  }

  Future<void> _startPairing() async {
    if (!_validateSessionFields()) return;

    try {
      _showLoadingDialog(context);
      final result = await ref.read(delegateRepositoryProvider).issuePairingCode(
            subjectId: number(widget.subject, 'id').toInt(),
            date: _date,
            title: _titleController.text.trim(),
            lectureNumber: _lectureNumberController.text.trim(),
            deviceName: 'Mobile App',
          );

      if (!mounted) return;
      Navigator.pop(context);

      final data = asMap(result);
      final code = text(data, 'display_code', fallback: text(data, 'code'));
      final expiresAt = text(data, 'expires_at');
      if (code.isEmpty) {
        _toast(context, 'فشل توليد رمز الربط.');
        return;
      }

      setState(() => _pairingWaiting = true);
      _startPairingPolling();
      _showPairingCodeDialog(context, code, expiresAt);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError(context, e);
      }
    }
  }

  void _activateQrSession(Map<String, dynamic> session) {
    final id = number(session, 'session_id', fallback: number(session, 'id')).toInt();
    final token = text(session, 'token', fallback: text(session, 'qr_code'));
    if (id <= 0 || token.isEmpty) {
      _toast(context, 'استجابة جلسة QR غير مكتملة.');
      return;
    }

    _stopQrTimers();
    setState(() {
      _qrSessionId = id;
      _qrToken = token;
      _rotationSeconds = number(session, 'rotation_seconds', fallback: 30).toInt();
      _remainingSeconds = _rotationSeconds;
      _pairingWaiting = false;
      _externalFinalizedDialogShown = false;
      _desktopManagedQr = false;
    });
    _beginQrTimers();
    _refreshQrStatus();
  }

  void _beginQrTimers() {
    _statusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshQrStatus(),
    );
    _rotateTimer = Timer.periodic(
      Duration(seconds: _rotationSeconds),
      (_) => _rotateQrToken(),
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds = _remainingSeconds > 0
            ? _remainingSeconds - 1
            : _rotationSeconds;
      });
    });
  }

  void _stopQrTimers() {
    _statusTimer?.cancel();
    _rotateTimer?.cancel();
    _countdownTimer?.cancel();
    _statusTimer = null;
    _rotateTimer = null;
    _countdownTimer = null;
  }

  Future<void> _rotateQrToken() async {
    final id = _qrSessionId;
    if (id == null) return;
    if (_desktopManagedQr) return;

    try {
      final data = await ref.read(delegateRepositoryProvider).qrToken(id);
      if (!mounted) return;
      setState(() {
        _qrToken = text(data, 'token');
        _rotationSeconds = number(data, 'rotation_seconds', fallback: 30).toInt();
        _remainingSeconds = _rotationSeconds;
      });
    } catch (_) {
      // Status polling will surface finalized/cancelled sessions.
    }
  }

  Future<void> _refreshQrStatus() async {
    final id = _qrSessionId;
    if (id == null) return;

    try {
      final data = await ref.read(delegateRepositoryProvider).qrStatus(id);
      if (!mounted) return;
      setState(() => _qrStatus = data);

      if (text(data, 'session_status') == 'finalized') {
        _stopQrTimers();
        _applyQrStatus(data);
        if (!_externalFinalizedDialogShown) {
          _externalFinalizedDialogShown = true;
          await _showExternalFinalizedDialog();
        }
      }
    } catch (e) {
      if (mounted) _toast(context, 'تعذر تحديث حالة QR: $e');
    }
  }

  void _applyQrStatus(Map<String, dynamic> data) {
    final students = asList(data['students']);
    setState(() {
      for (final student in students) {
        final id = number(student, 'id').toInt();
        _statuses[id] = text(student, 'status') == 'present'
            ? 'present'
            : 'absent';
      }
      _showStudents = true;
      _qrToken = null;
    });
  }

  Future<void> _finalizeQrSession() async {
    final id = _qrSessionId;
    if (id == null || _qrFinalizing) return;

    setState(() => _qrFinalizing = true);
    try {
      await ref.read(delegateRepositoryProvider).finalizeQr(id);
      final status = await ref.read(delegateRepositoryProvider).qrStatus(id);
      _stopQrTimers();
      _applyQrStatus(status);
      if (mounted) _toast(context, 'تم إنهاء QR وتجهيز المراجعة.');
    } catch (e) {
      if (mounted) _toast(context, 'تعذر إنهاء جلسة QR: $e');
    } finally {
      if (mounted) setState(() => _qrFinalizing = false);
    }
  }

  Future<void> _cancelQrSession({bool showMessage = true}) async {
    final id = _qrSessionId;
    if (id == null) return;

    _stopQrTimers();
    try {
      await ref.read(delegateRepositoryProvider).cancelQr(id);
      if (showMessage && mounted) _toast(context, 'تم إلغاء جلسة QR.');
    } catch (e) {
      if (mounted) _toast(context, 'تعذر إلغاء جلسة QR: $e');
    } finally {
      if (mounted) {
        setState(() {
          _qrSessionId = null;
          _qrToken = null;
          _qrStatus = null;
          _desktopManagedQr = false;
        });
      }
    }
  }

  void _startPairingPolling() {
    _pairingTimer?.cancel();
    _pairingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _hasActiveQr) return;

      try {
        final data = await ref.read(delegateRepositoryProvider).activeQrAttendance(
              subjectId: number(widget.subject, 'id').toInt(),
              date: _date,
              title: _titleController.text.trim(),
            );
        final session = asMap(data['session']);
        final id = number(session, 'id').toInt();
        if (id > 0) {
          _pairingTimer?.cancel();
          setState(() {
            _qrSessionId = id;
            _qrToken = 'desktop-session';
            _pairingWaiting = false;
            _desktopManagedQr = true;
          });
          _beginQrTimers();
          await _refreshQrStatus();
        }
      } catch (_) {}
    });
  }

  Future<void> _showExternalFinalizedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تم إنهاء الجلسة من الحاسوب'),
        content: const Text(
          'تم تجهيز الحضور من جلسة QR. راجع القائمة وعدل الحالات عند الحاجة ثم احفظ السجل.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAttendance() async {
    if (!_validateSessionFields() || _isSaving) return;

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
      if (_qrSessionId != null) 'qr_session_id': _qrSessionId,
      'students': _statuses.entries
          .map((entry) => {'id': entry.key, 'status': entry.value})
          .toList(),
    };

    setState(() => _isSaving = true);
    await _run(
      context,
      () => ref.read(delegateRepositoryProvider).saveAttendance(payload),
      after: () {
        ref.invalidate(_delegateAttendanceProvider);
        context.pop();
      },
    );
    if (mounted) setState(() => _isSaving = false);
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showPairingCodeDialog(
    BuildContext context,
    String code,
    String expiresAt,
  ) {
    showDialog(
      context: context,
      builder: (context) => _PairingCodeDialog(
        code: code,
        expiresAt: expiresAt,
        onCancel: () {
          _pairingTimer?.cancel();
          setState(() => _pairingWaiting = false);
        },
      ),
    );
  }
}

class _IntegratedActionBar extends StatelessWidget {
  const _IntegratedActionBar({
    required this.isEnabled,
    required this.showStudents,
    required this.qrActive,
    required this.qrStarting,
    required this.pairingWaiting,
    required this.onManual,
    required this.onQr,
    required this.onPairing,
  });
  final bool isEnabled;
  final bool showStudents;
  final bool qrActive;
  final bool qrStarting;
  final bool pairingWaiting;
  final VoidCallback onManual;
  final VoidCallback onQr;
  final VoidCallback onPairing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isEnabled ? onManual : null,
                icon: const Icon(Icons.edit_calendar_rounded),
                label: Text(showStudents ? 'قائمة الطلاب مفتوحة' : 'رصد يدوي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isEnabled && !qrActive && !qrStarting ? onQr : null,
                icon: qrStarting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.qr_code_scanner_rounded),
                label: Text(qrActive ? 'QR نشط' : 'بدء QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isEnabled && !pairingWaiting ? onPairing : null,
            icon: const Icon(Icons.cast_rounded),
            label: Text(pairingWaiting
                ? 'بانتظار اتصال تطبيق العرض'
                : 'ربط تطبيق العرض'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: isEnabled ? AppColors.royalBlue : AppColors.slate300,
              ),
              foregroundColor:
                  isEnabled ? AppColors.royalBlue : AppColors.slate400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (!isEnabled)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'ليس لديك صلاحية التحضير لهذه المادة حالياً',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _QrLivePanel extends StatelessWidget {
  const _QrLivePanel({
    required this.token,
    required this.remainingSeconds,
    required this.scannedCount,
    required this.totalStudents,
    required this.recentScans,
    required this.presentStudents,
    required this.finalizing,
    required this.onRefresh,
    required this.onFinalize,
  });
  final String token;
  final int remainingSeconds;
  final int scannedCount;
  final int totalStudents;
  final List<dynamic> recentScans;
  final List<dynamic> presentStudents;
  final bool finalizing;
  final VoidCallback onRefresh;
  final VoidCallback onFinalize;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: AppColors.teal),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'جلسة QR مباشرة',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.sync_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (token != 'desktop-session')
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: QrImageView(
                  data: token,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
            )
          else
            const _DesktopManagedQrNotice(),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: remainingSeconds <= 0 ? 0 : remainingSeconds / 30,
            backgroundColor: AppColors.slate100,
            color: AppColors.teal,
          ),
          const SizedBox(height: 8),
          Text(
            'يتجدد خلال $remainingSeconds ثانية',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QrMetric(
                  label: 'تم المسح',
                  value: scannedCount,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QrMetric(
                  label: 'إجمالي الطلاب',
                  value: totalStudents,
                  color: AppColors.midnight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MiniStudentList(title: 'آخر من مسحوا', students: recentScans),
          const SizedBox(height: 10),
          _MiniStudentList(title: 'عينة من الحاضرين', students: presentStudents),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: finalizing ? null : onFinalize,
            icon: finalizing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.stop_circle_rounded),
            label: const Text('إنهاء الجلسة وتجهيز المراجعة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrMetric extends StatelessWidget {
  const _QrMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStudentList extends StatelessWidget {
  const _MiniStudentList({required this.title, required this.students});
  final String title;
  final List<dynamic> students;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 8),
          if (students.isEmpty)
            const Text(
              'لا توجد بيانات بعد',
              style: TextStyle(
                color: AppColors.slate400,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (final student in students.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        text(student, 'name'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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

class _DesktopManagedQrNotice extends StatelessWidget {
  const _DesktopManagedQrNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.desktop_windows_rounded, color: AppColors.royalBlue),
          SizedBox(height: 8),
          Text(
            'QR يدار حالياً من تطبيق العرض',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PairingWaitingCard extends StatelessWidget {
  const _PairingWaitingCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'بانتظار أن يبدأ تطبيق العرض جلسة QR. سيتم التحديث تلقائياً.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({required this.subject, required this.doctor});
  final Map<String, dynamic> subject;
  final Map<String, dynamic> doctor;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.royalBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(subject, 'name'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  text(doctor, 'name', fallback: 'دكتور المادة'),
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
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

class _SessionForm extends StatelessWidget {
  const _SessionForm({
    required this.date,
    required this.onDateChanged,
    required this.titleController,
    required this.lectureNumberController,
    required this.descriptionController,
    required this.lectureType,
    required this.onTypeChanged,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  final String date;
  final ValueChanged<String> onDateChanged;
  final TextEditingController titleController;
  final TextEditingController lectureNumberController;
  final TextEditingController descriptionController;
  final String lectureType;
  final ValueChanged<String?> onTypeChanged;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final ValueChanged<TimeOfDay?> onStartTimeChanged;
  final ValueChanged<TimeOfDay?> onEndTimeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تفاصيل الجلسة',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 16),
        _MoeenTextField(
          controller: TextEditingController(text: date),
          label: 'تاريخ التحضير',
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(date) ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) {
              onDateChanged(picked.toIso8601String().split('T').first);
            }
          },
          prefixIcon: Icons.calendar_today_rounded,
        ),
        const SizedBox(height: 16),
        _MoeenTextField(
          controller: titleController,
          label: 'عنوان المحاضرة',
          prefixIcon: Icons.title_rounded,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MoeenTextField(
                controller: lectureNumberController,
                label: 'رقم المحاضرة',
                prefixIcon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: lectureType,
                    items: const [
                      DropdownMenuItem(
                        value: 'official',
                        child: Text('رسمية'),
                      ),
                      DropdownMenuItem(
                        value: 'special',
                        child: Text('إضافية'),
                      ),
                    ],
                    onChanged: onTypeChanged,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.midnight,
                    ),
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
              child: _TimePickerField(
                label: 'وقت البدء',
                time: startTime,
                onChanged: onStartTimeChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimePickerField(
                label: 'وقت الانتهاء',
                time: endTime,
                onChanged: onEndTimeChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onChanged,
  });
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: AppColors.slate400,
            ),
            const SizedBox(width: 8),
            Text(
              time?.format(context) ?? label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: time != null ? AppColors.midnight : AppColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PairingCodeDialog extends StatefulWidget {
  const _PairingCodeDialog({
    required this.code,
    required this.expiresAt,
    required this.onCancel,
  });
  final String code;
  final String expiresAt;
  final VoidCallback onCancel;

  @override
  State<_PairingCodeDialog> createState() => _PairingCodeDialogState();
}

class _PairingCodeDialogState extends State<_PairingCodeDialog>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _timeLeft;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    final expiry = DateTime.tryParse(widget.expiresAt) ??
        DateTime.now().add(const Duration(minutes: 10));
    _timeLeft = expiry.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeLeft = expiry.difference(DateTime.now());
        if (_timeLeft.isNegative) {
          _timer.cancel();
          Navigator.pop(context);
        }
      });
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ربط تطبيق العرض'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'أدخل هذا الرمز في تطبيق العرض على الكمبيوتر. سيبدأ الهاتف المتابعة تلقائياً عند بدء الجلسة.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FadeTransition(
            opacity: Tween(begin: 0.8, end: 1.0).animate(_pulseController),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                widget.code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  color: AppColors.royalBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'ينتهي خلال ${_formatDuration(_timeLeft)}',
            style: const TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancel();
            Navigator.pop(context);
          },
          child: const Text('إلغاء الربط'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إخفاء ومتابعة الانتظار'),
        ),
      ],
    );
  }
}

class _MoeenTextField extends StatelessWidget {
  const _MoeenTextField({
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.royalBlue)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
      ),
    );
  }
}
