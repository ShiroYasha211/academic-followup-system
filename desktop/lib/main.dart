import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MoeenDesktopApp());
}

abstract final class AppPalette {
  static const midnight = Color(0xFF0F172A);
  static const slate = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const surface = Color(0xFFF8FAFC);
  static const canvas = Color(0xFFF1F5F9);
  static const line = Color(0xFFE2E8F0);
  static const primary = Color(0xFF0F766E);
  static const primarySoft = Color(0xFFD9F7F2);
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0xFFDBEAFE);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFDCFCE7);
  static const card = Colors.white;
  static const gradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0F172A), Color(0xFF0F766E), Color(0xFF38BDF8)],
  );
}

class MoeenDesktopApp extends StatelessWidget {
  const MoeenDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moeen Attendance Display',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.primary,
          primary: AppPalette.primary,
          secondary: AppPalette.accent,
          surface: AppPalette.surface,
        ),
        scaffoldBackgroundColor: AppPalette.canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppPalette.midnight,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppPalette.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          margin: EdgeInsets.zero,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: DesktopAttendanceApp(),
      ),
    );
  }
}

class DesktopAttendanceApp extends StatefulWidget {
  const DesktopAttendanceApp({super.key});

  @override
  State<DesktopAttendanceApp> createState() => _DesktopAttendanceAppState();
}

class _DesktopAttendanceAppState extends State<DesktopAttendanceApp> {
  final DesktopStorage _storage = const DesktopStorage();

  bool _booting = true;
  String? _bootError;
  DesktopSession? _session;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _booting = true;
      _bootError = null;
    });

    try {
      final stored = await _storage.readSession();

      if (stored == null) {
        setState(() {
          _session = null;
          _booting = false;
        });
        return;
      }

      final api = DesktopApiClient(
        baseUrl: stored.baseUrl,
        token: stored.token,
      );
      final refreshed = await api.me();
      final hydrated = stored.copyWith(
        workspace: refreshed.workspace,
        userName: refreshed.userName,
        userRole: refreshed.userRole,
      );

      await _storage.saveSession(hydrated);

      setState(() {
        _session = hydrated;
        _booting = false;
      });
    } on ApiException catch (error) {
      await _storage.clearSession();
      setState(() {
        _session = null;
        _bootError = error.message;
        _booting = false;
      });
    } catch (_) {
      await _storage.clearSession();
      setState(() {
        _session = null;
        _bootError = 'تعذر استعادة الجلسة المحفوظة.';
        _booting = false;
      });
    }
  }

  Future<void> _handlePaired(DesktopSession session) async {
    await _storage.saveSession(session);
    setState(() {
      _session = session;
      _bootError = null;
      _booting = false;
    });
  }

  Future<void> _logout() async {
    final session = _session;
    if (session != null) {
      try {
        final api = DesktopApiClient(
          baseUrl: session.baseUrl,
          token: session.token,
        );
        await api.logout();
      } catch (_) {
        // Keep local logout resilient even if the server is unreachable.
      }
    }

    await _storage.clearSession();

    setState(() {
      _session = null;
      _bootError = null;
      _booting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const _LoadingScreen(message: 'جارٍ فحص الجلسة المحفوظة...');
    }

    if (_session == null) {
      return PairDeviceScreen(
        initialError: _bootError,
        initialBaseUrl: null,
        onPaired: _handlePaired,
      );
    }

    return SessionSetupScreen(session: _session!, onUnpair: _logout);
  }
}

class PairDeviceScreen extends StatefulWidget {
  const PairDeviceScreen({
    super.key,
    required this.onPaired,
    this.initialError,
    this.initialBaseUrl,
  });

  final Future<void> Function(DesktopSession session) onPaired;
  final String? initialError;
  final String? initialBaseUrl;

  @override
  State<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends State<PairDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _pairingCodeController = TextEditingController();
  final _deviceNameController = TextEditingController(
    text: 'Classroom Display',
  );

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _baseUrlController.text = widget.initialBaseUrl ?? 'https://moeen.tech';
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _pairingCodeController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final normalizedBaseUrl = normalizeBaseUrl(_baseUrlController.text);
      final api = DesktopApiClient(baseUrl: normalizedBaseUrl);
      final paired = await api.exchangePairingCode(
        code: _pairingCodeController.text.trim(),
        deviceName: _deviceNameController.text.trim(),
      );

      await widget.onPaired(paired);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(
        () => _error = 'تعذر الاتصال بالخادم. تأكد من الرابط ثم أعد المحاولة.',
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppPalette.gradient),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 44,
                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandBadge(label: 'Moeen'),
                      const SizedBox(height: 18),
                      const _SectionHeader(
                        title: 'ربط تطبيق العرض',
                        subtitle:
                            'أدخل رابط السيرفر ورمز الربط الذي تم توليده من صفحة الحضور في الموقع.',
                      ),
                      const SizedBox(height: 24),
                      _AppTextField(
                        controller: _baseUrlController,
                        label: 'رابط النظام',
                        hint: 'https://moeen.tech',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'رابط النظام مطلوب.';
                          }

                          final normalized = normalizeBaseUrl(value);
                          final uri = Uri.tryParse(normalized);
                          if (uri == null ||
                              !(uri.hasScheme && uri.host.isNotEmpty)) {
                            return 'أدخل رابطًا صالحًا مثل https://moeen.tech';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _AppTextField(
                        controller: _pairingCodeController,
                        label: 'رمز الربط',
                        hint: 'ABCD-1234',
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'رمز الربط مطلوب.';
                          }
                          if (DesktopSession.normalizePairingCode(
                                value,
                              ).length <
                              8) {
                            return 'أدخل رمز الربط كاملًا.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _AppTextField(
                        controller: _deviceNameController,
                        label: 'اسم الجهاز',
                        hint: 'Classroom Display',
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 18),
                        _ErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('ربط الجهاز'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({
    super.key,
    required this.session,
    required this.onUnpair,
  });

  final DesktopSession session;
  final Future<void> Function() onUnpair;

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  late final DesktopApiClient _api;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _lectureNumberController = TextEditingController();

  bool _loadingSubjects = true;
  bool _starting = false;
  String? _error;
  List<SubjectOption> _subjects = [];
  SubjectOption? _selectedSubject;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _api = DesktopApiClient(
      baseUrl: widget.session.baseUrl,
      token: widget.session.token,
    );
    _titleController.text =
        'محاضرة ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    final sessionContext = widget.session.sessionContext;
    _subjects = sessionContext.subject.id == 0 ? [] : [sessionContext.subject];
    _selectedSubject = _subjects.isNotEmpty ? _subjects.first : null;
    _titleController.text = sessionContext.title;
    _lectureNumberController.text = sessionContext.lectureNumber ?? '';
    _selectedDate = DateTime.tryParse(sessionContext.date) ?? DateTime.now();
    _loadingSubjects = false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lectureNumberController.dispose();
    super.dispose();
  }

  // ignore: unused_element
  Future<void> _loadSubjects() async {
    setState(() {
      _loadingSubjects = true;
      _error = null;
    });

    try {
      final subjects = await _api.subjects();
      setState(() {
        _subjects = subjects;
        _selectedSubject = subjects.isNotEmpty ? subjects.first : null;
      });
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل المواد من الخادم.');
    } finally {
      if (mounted) {
        setState(() => _loadingSubjects = false);
      }
    }
  }

  // ignore: unused_element
  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() => _selectedDate = selected);
    }
  }

  Future<void> _startSession() async {
    if (!_formKey.currentState!.validate() || _selectedSubject == null) {
      return;
    }

    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      final started = await _api.startQrSession(
        subjectId: _selectedSubject!.id,
        date: formatDate(_selectedDate),
        title: _titleController.text.trim(),
        lectureNumber: _lectureNumberController.text.trim().isEmpty
            ? null
            : _lectureNumberController.text.trim(),
      );

      if (!mounted) return;

      final summary = await Navigator.of(context).push<SessionClosureSummary>(
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: LiveQrScreen(
              session: widget.session,
              subject: _selectedSubject!,
              api: _api,
              startedSession: started,
              onUnpair: widget.onUnpair,
            ),
          ),
        ),
      );

      if (!mounted || summary == null) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: SessionClosedSummaryScreen(summary: summary),
          ),
        ),
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'تعذر بدء جلسة QR.');
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.userName;
    final workspace = widget.session.workspace == 'doctor'
        ? 'الدكتور'
        : 'المندوب';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إعداد جلسة QR',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '$workspace: $user',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: null,
            icon: const Icon(Icons.lock_outline),
            label: const Text('تحديث المواد'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: widget.onUnpair,
            icon: const Icon(Icons.logout),
            label: const Text('إلغاء الربط'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppPalette.line),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.midnight.withValues(alpha: 0.08),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: _loadingSubjects
                  ? const _LoadingSection(
                      message: 'جارٍ تحميل المواد المسموح التحضير لها...',
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _BrandBadge(label: 'Moeen Session'),
                          const SizedBox(height: 16),
                          const _SectionHeader(
                            title: 'بيانات الجلسة',
                            subtitle:
                                'اختر المادة ثم اضبط عنوان الجلسة وتاريخها قبل عرض QR على الشاشة.',
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: _error!),
                          ],
                          const SizedBox(height: 22),
                          DropdownButtonFormField<SubjectOption>(
                            initialValue: _selectedSubject,
                            decoration: inputDecoration('المادة'),
                            items: _subjects
                                .map(
                                  (subject) => DropdownMenuItem<SubjectOption>(
                                    value: subject,
                                    child: Text(
                                      '${subject.name}  •  ${subject.majorName} / ${subject.levelName}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: null,
                            validator: (value) =>
                                value == null ? 'اختر المادة أولًا.' : null,
                          ),
                          if (_selectedSubject != null) ...[
                            const SizedBox(height: 12),
                            _SubjectMetaCard(subject: _selectedSubject!),
                          ],
                          const SizedBox(height: 18),
                          _AppTextField(
                            controller: _titleController,
                            label: 'عنوان الجلسة',
                            hint: 'مثال: المحاضرة الثانية - المراجعة',
                            enabled: false,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'عنوان الجلسة مطلوب.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _DatePickerField(
                                  label: 'التاريخ',
                                  value: formatDate(_selectedDate),
                                  onTap: null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _AppTextField(
                                  controller: _lectureNumberController,
                                  label: 'رقم المحاضرة',
                                  hint: 'اختياري',
                                  enabled: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          FilledButton(
                            onPressed: _starting || _subjects.isEmpty
                                ? null
                                : _startSession,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPalette.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _starting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('بدء الجلسة وعرض QR'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class LiveQrScreen extends StatefulWidget {
  const LiveQrScreen({
    super.key,
    required this.session,
    required this.subject,
    required this.api,
    required this.startedSession,
    required this.onUnpair,
  });

  final DesktopSession session;
  final SubjectOption subject;
  final DesktopApiClient api;
  final StartedQrSession startedSession;
  final Future<void> Function() onUnpair;

  @override
  State<LiveQrScreen> createState() => _LiveQrScreenState();
}

class _LiveQrScreenState extends State<LiveQrScreen> {
  Timer? _statusTimer;
  Timer? _rotateTimer;
  Timer? _countdownTimer;

  late String _token;
  late int _rotationSeconds;
  late int _remainingSeconds;
  late int _sessionId;

  bool _busyFinalizing = false;
  bool _connectionLost = false;
  bool _showFullscreenQr = false;
  String? _error;
  SessionStatusPayload? _payload;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.startedSession.sessionId;
    _token = widget.startedSession.token;
    _rotationSeconds = widget.startedSession.rotationSeconds;
    _remainingSeconds = widget.startedSession.rotationSeconds;
    _beginTimers();
    _refreshStatus();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _rotateTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _beginTimers() {
    _statusTimer?.cancel();
    _rotateTimer?.cancel();
    _countdownTimer?.cancel();

    _statusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshStatus(),
    );
    _rotateTimer = Timer.periodic(
      Duration(seconds: _rotationSeconds),
      (_) => _rotateToken(),
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds = _remainingSeconds > 0 ? _remainingSeconds - 1 : 0;
      });
    });
  }

  Future<void> _rotateToken() async {
    try {
      final rotated = await widget.api.rotateToken(_sessionId);
      if (!mounted) return;

      setState(() {
        _token = rotated.token;
        _rotationSeconds = rotated.rotationSeconds;
        _remainingSeconds = rotated.rotationSeconds;
        _connectionLost = false;
      });

      _beginTimers();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _connectionLost = true;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connectionLost = true;
        _error = 'تعذر تحديث رمز QR من الخادم.';
      });
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final payload = await widget.api.sessionStatus(_sessionId);

      if (!mounted) return;

      setState(() {
        _payload = payload;
        _connectionLost = false;
        _error = null;
        _rotationSeconds = payload.rotationSeconds;
      });

      if (payload.sessionStatus == 'finalized' && !_busyFinalizing) {
        _closeWithSummary(
          SessionClosureSummary(
            subjectName: widget.subject.name,
            sessionTitle: payload.title,
            redirectUrl: null,
            missingScanCount:
                payload.verificationSummary['missing_scan_count'] ?? 0,
            sampleCheckCount:
                payload.verificationSummary['sample_check_count'] ?? 0,
            endedExternally: true,
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _connectionLost = true;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connectionLost = true;
        _error = 'تعذر تحميل حالة الجلسة الحالية.';
      });
    }
  }

  Future<void> _finalize() async {
    setState(() {
      _busyFinalizing = true;
      _error = null;
    });

    try {
      final result = await widget.api.finalizeSession(_sessionId);
      await widget.onUnpair();

      if (!mounted) return;

      _closeWithSummary(
        SessionClosureSummary(
          subjectName: widget.subject.name,
          sessionTitle: _payload?.title ?? widget.startedSession.title,
          redirectUrl: result.redirectUrl,
          missingScanCount: result.missingScanCount,
          sampleCheckCount: result.sampleCheckCount,
          endedExternally: false,
        ),
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'تعذر إنهاء الجلسة من التطبيق.');
    } finally {
      if (mounted) {
        setState(() => _busyFinalizing = false);
      }
    }
  }

  void _closeWithSummary(SessionClosureSummary summary) {
    _statusTimer?.cancel();
    _rotateTimer?.cancel();
    _countdownTimer?.cancel();
    Navigator.of(context).pop(summary);
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    final students = payload?.students ?? const <StudentScanStatus>[];
    final pendingStudents = students
        .where((student) => student.status != 'present')
        .toList();
    final allPresentStudents = students
        .where((student) => student.status == 'present')
        .toList();
    final scannedStudents =
        payload?.recentScans ?? allPresentStudents.take(12).toList();
    final attendeeSample = allPresentStudents
        .take(math.min(allPresentStudents.length, 18))
        .toList();

    if (_showFullscreenQr) {
      return _LiveFullscreenQr(
        token: _token,
        subjectName: widget.subject.name,
        title: payload?.title ?? widget.startedSession.title,
        remainingSeconds: _remainingSeconds,
        onClose: () => setState(() => _showFullscreenQr = false),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subject.name),
            Text(
              payload?.title ?? widget.startedSession.title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _refreshStatus,
            icon: const Icon(Icons.sync, color: Colors.white),
            label: const Text('تحديث', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_connectionLost)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Text(
                  _error ??
                      'انقطع الاتصال مؤقتًا. سيتم الاستئناف تلقائيًا عند عودة الشبكة.',
                  style: const TextStyle(
                    color: Color(0xFF9A3412),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'يتجدد خلال $_remainingSeconds ثانية',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _showFullscreenQr = true);
                            },
                            icon: const Icon(Icons.fullscreen),
                            label: const Text('تكبير QR للعرض على الشاشة'),
                          ),
                          const SizedBox(height: 22),
                          Expanded(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: QrImageView(
                                  data: _token,
                                  version: QrVersions.auto,
                                  size: 360,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'تم المسح',
                                  value: '${payload?.scannedCount ?? 0}',
                                  accent: const Color(0xFF16A34A),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _MetricCard(
                                  title: 'إجمالي الطلاب',
                                  value: '${payload?.totalStudents ?? 0}',
                                  accent: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _busyFinalizing ? null : _finalize,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _busyFinalizing
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'إنهاء الجلسة وتحويل المراجعة إلى الموقع',
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: _StudentPanel(
                            title: 'آخر من مسحوا',
                            subtitle: 'تحديث مباشر من الجلسة الحالية',
                            students: scannedStudents,
                            emptyLabel: 'لا يوجد مسح بعد.',
                            accent: const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: _StudentPanel(
                            title: 'عينة من الحاضرين',
                            subtitle:
                                'أسماء مختصرة من الطلاب الذين تم تسجيلهم كحضور',
                            students: attendeeSample,
                            emptyLabel: 'لم يتم تسجيل أي طالب كحاضر حتى الآن.',
                            accent: AppPalette.accent,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: _StudentPanel(
                            title: 'لم يمسحوا حتى الآن',
                            subtitle: 'سيحتاجون مراجعة عند إغلاق الجلسة',
                            students: pendingStudents,
                            emptyLabel: 'كل الطلاب الظاهرين تم تسجيل حضورهم.',
                            accent: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SessionClosedSummaryScreen extends StatelessWidget {
  const SessionClosedSummaryScreen({super.key, required this.summary});

  final SessionClosureSummary summary;

  Future<void> _openReview() async {
    if (summary.redirectUrl == null || summary.redirectUrl!.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(summary.redirectUrl!);
    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    title: summary.endedExternally
                        ? 'الجلسة أُغلقت من مكان آخر'
                        : 'تم إغلاق الجلسة بنجاح',
                    subtitle:
                        '${summary.subjectName} • ${summary.sessionTitle}',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'غير الماسحين',
                          value: '${summary.missingScanCount}',
                          accent: const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MetricCard(
                          title: 'عينة 2%',
                          value: '${summary.sampleCheckCount}',
                          accent: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      summary.redirectUrl == null
                          ? 'راجع الحضور النهائي من الموقع نفسه لأن الجلسة أُغلقت خارج تطبيق الديسكتوب.'
                          : 'المراجعة النهائية لا تزال على الموقع. افتح الصفحة الآن لتأكيد غير الماسحين وعينة التحقق 2%.',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: summary.redirectUrl == null ? null : _openReview,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('فتح صفحة المراجعة في المتصفح'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('العودة إلى إعداد جلسة جديدة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveFullscreenQr extends StatelessWidget {
  const _LiveFullscreenQr({
    required this.token,
    required this.subjectName,
    required this.title,
    required this.remainingSeconds,
    required this.onClose,
  });

  final String token;
  final String subjectName;
  final String title;
  final int remainingSeconds;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final qrSize = math.min(size.width * 0.72, size.height * 0.72);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: QrImageView(
                data: token,
                version: QrVersions.auto,
                size: qrSize,
                backgroundColor: Colors.white,
              ),
            ),
            Positioned(
              top: 18,
              right: 24,
              child: _BrandBadge(label: 'Moeen QR'),
            ),
            Positioned(
              left: 24,
              top: 18,
              child: IconButton.filled(
                onPressed: onClose,
                icon: const Icon(Icons.close_fullscreen),
                tooltip: 'إغلاق التكبير',
              ),
            ),
            Positioned(
              right: 28,
              bottom: 24,
              left: 28,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$subjectName - $title',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.midnight,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  _MetaPill(
                    label: 'يتجدد خلال',
                    value: '$remainingSeconds ثانية',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _LoadingSection(message: message)),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(height: 14),
        Text(message, style: const TextStyle(color: Color(0xFF475569))),
      ],
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.layers_rounded, color: AppPalette.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppPalette.midnight,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppPalette.muted,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.08), Colors.white],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentPanel extends StatelessWidget {
  const _StudentPanel({
    required this.title,
    required this.subtitle,
    required this.students,
    required this.emptyLabel,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final List<StudentScanStatus> students;
  final String emptyLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppPalette.midnight.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: accent,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppPalette.muted, height: 1.6),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Text(
                      emptyLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: accent.withValues(alpha: 0.12),
                          child: Text(
                            student.name.isEmpty
                                ? '?'
                                : student.name.substring(0, 1),
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(student.studentNumber ?? 'بدون رقم قيد'),
                        trailing: student.scannedAt == null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  student.status == 'present'
                                      ? 'حاضر'
                                      : 'بانتظار المسح',
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : Text(
                                timeOnly(student.scannedAt!),
                                style: const TextStyle(color: AppPalette.slate),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SubjectMetaCard extends StatelessWidget {
  const _SubjectMetaCard({required this.subject});

  final SubjectOption subject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _MetaPill(label: 'الكود', value: subject.code ?? 'غير محدد'),
          _MetaPill(label: 'التخصص', value: subject.majorName),
          _MetaPill(label: 'المستوى', value: subject.levelName),
          _MetaPill(label: 'الدكتور', value: subject.doctorName ?? 'غير محدد'),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      textCapitalization: textCapitalization,
      decoration: inputDecoration(label, hint: hint),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: inputDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.calendar_month_outlined),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFBE123C),
          fontWeight: FontWeight.w700,
          height: 1.7,
        ),
      ),
    );
  }
}

InputDecoration inputDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
    ),
  );
}

class DesktopStorage {
  const DesktopStorage();

  static const _storage = FlutterSecureStorage();

  Future<void> saveSession(DesktopSession session) async {
    await _storage.write(key: 'desktop_base_url', value: session.baseUrl);
    await _storage.write(key: 'desktop_token', value: session.token);
    await _storage.write(key: 'desktop_workspace', value: session.workspace);
    await _storage.write(key: 'desktop_user_name', value: session.userName);
    await _storage.write(key: 'desktop_user_role', value: session.userRole);
    await _storage.write(
      key: 'desktop_session_context',
      value: jsonEncode(session.sessionContext.toJson()),
    );
  }

  Future<DesktopSession?> readSession() async {
    final baseUrl = await _storage.read(key: 'desktop_base_url');
    final token = await _storage.read(key: 'desktop_token');
    final workspace = await _storage.read(key: 'desktop_workspace');
    final userName = await _storage.read(key: 'desktop_user_name');
    final userRole = await _storage.read(key: 'desktop_user_role');
    final sessionContextJson = await _storage.read(
      key: 'desktop_session_context',
    );

    if ([
      baseUrl,
      token,
      workspace,
      userName,
      userRole,
      sessionContextJson,
    ].any((value) => value == null || value.isEmpty)) {
      return null;
    }

    return DesktopSession(
      baseUrl: baseUrl!,
      token: token!,
      workspace: workspace!,
      userName: userName!,
      userRole: userRole!,
      sessionContext: SessionContext.fromJson(
        jsonDecode(sessionContextJson!) as Map<String, dynamic>,
      ),
    );
  }

  Future<void> clearSession() async {
    await _storage.delete(key: 'desktop_base_url');
    await _storage.delete(key: 'desktop_token');
    await _storage.delete(key: 'desktop_workspace');
    await _storage.delete(key: 'desktop_user_name');
    await _storage.delete(key: 'desktop_user_role');
    await _storage.delete(key: 'desktop_session_context');
  }
}

class DesktopApiClient {
  DesktopApiClient({required this.baseUrl, this.token});

  final String baseUrl;
  final String? token;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({bool authenticated = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated && token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<DesktopSession> exchangePairingCode({
    required String code,
    required String deviceName,
  }) async {
    final response = await http.post(
      _uri('/api/desktop/pairing/exchange'),
      headers: _headers(authenticated: false),
      body: jsonEncode({
        'code': DesktopSession.normalizePairingCode(code),
        'device_name': deviceName,
      }),
    );

    final payload = _decode(response);
    final data = _unwrap(response, payload);

    return DesktopSession(
      baseUrl: baseUrl,
      token: data['token'] as String,
      workspace: data['workspace'] as String,
      userName: (data['user'] as Map<String, dynamic>)['name'] as String,
      userRole: (data['user'] as Map<String, dynamic>)['role'].toString(),
      sessionContext: SessionContext.fromJson(
        data['session_context'] as Map<String, dynamic>,
      ),
    );
  }

  Future<DesktopSession> me() async {
    final response = await http.get(
      _uri('/api/desktop/me'),
      headers: _headers(),
    );

    final payload = _decode(response);
    final data = _unwrap(response, payload);
    final user = data['user'] as Map<String, dynamic>;

    return DesktopSession(
      baseUrl: baseUrl,
      token: token ?? '',
      workspace: data['workspace'] as String,
      userName: user['name'] as String,
      userRole: user['role'].toString(),
      sessionContext: SessionContext.empty(),
    );
  }

  Future<void> logout() async {
    final response = await http.post(
      _uri('/api/desktop/logout'),
      headers: _headers(),
    );

    final payload = _decode(response);
    _unwrap(response, payload);
  }

  Future<List<SubjectOption>> subjects() async {
    final response = await http.get(
      _uri('/api/desktop/qr-attendance/subjects'),
      headers: _headers(),
    );

    final payload = _decode(response);
    final data = _unwrap(response, payload);
    final subjects = (data['subjects'] as List<dynamic>? ?? const <dynamic>[]);

    return subjects
        .map(
          (subject) => SubjectOption.fromJson(subject as Map<String, dynamic>),
        )
        .toList();
  }

  Future<StartedQrSession> startQrSession({
    required int subjectId,
    required String date,
    required String title,
    String? lectureNumber,
  }) async {
    final response = await http.post(
      _uri('/api/desktop/qr-attendance/start'),
      headers: _headers(),
      body: jsonEncode({
        'subject_id': subjectId,
        'date': date,
        'title': title,
        'lecture_number': lectureNumber,
      }),
    );

    final payload = _decode(response);
    final data = _unwrap(response, payload);

    return StartedQrSession(
      sessionId: data['session_id'] as int,
      token: data['token'] as String,
      rotationSeconds: data['rotation_seconds'] as int,
      title: title,
    );
  }

  Future<RotatedToken> rotateToken(int sessionId) async {
    final response = await http.get(
      _uri('/api/desktop/qr-attendance/$sessionId/token'),
      headers: _headers(),
    );

    final payload = _decode(response);
    final data = _unwrap(response, payload);

    return RotatedToken(
      token: data['token'] as String,
      rotationSeconds: data['rotation_seconds'] as int,
    );
  }

  Future<SessionStatusPayload> sessionStatus(int sessionId) async {
    final response = await http.get(
      _uri('/api/desktop/qr-attendance/$sessionId/status'),
      headers: _headers(),
    );

    final payload = _decode(response);
    final data = _unwrap(response, payload);

    return SessionStatusPayload.fromJson(data);
  }

  Future<FinalizeResult> finalizeSession(int sessionId) async {
    final response = await http.post(
      _uri('/api/desktop/qr-attendance/$sessionId/finalize'),
      headers: _headers(),
    );

    final payload = _decode(response);
    final data = _unwrap(response, payload);
    final verification =
        (data['verification'] as Map<String, dynamic>? ??
        const <String, dynamic>{});
    final summary =
        (verification['summary'] as Map<String, dynamic>? ??
        const <String, dynamic>{});

    return FinalizeResult(
      redirectUrl: data['redirect_url'] as String?,
      missingScanCount: (summary['missing_scan_count'] as num?)?.toInt() ?? 0,
      sampleCheckCount: (summary['sample_check_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Map<String, dynamic> _unwrap(
    http.Response response,
    Map<String, dynamic> payload,
  ) {
    final success = payload['success'];
    if (response.statusCode >= 400 || success == false) {
      throw ApiException(
        payload['message']?.toString() ?? 'حدث خطأ غير متوقع.',
      );
    }

    return (payload['data'] as Map<String, dynamic>? ?? payload);
  }
}

class DesktopSession {
  const DesktopSession({
    required this.baseUrl,
    required this.token,
    required this.workspace,
    required this.userName,
    required this.userRole,
    required this.sessionContext,
  });

  final String baseUrl;
  final String token;
  final String workspace;
  final String userName;
  final String userRole;
  final SessionContext sessionContext;

  DesktopSession copyWith({
    String? workspace,
    String? userName,
    String? userRole,
    SessionContext? sessionContext,
  }) {
    return DesktopSession(
      baseUrl: baseUrl,
      token: token,
      workspace: workspace ?? this.workspace,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      sessionContext: sessionContext ?? this.sessionContext,
    );
  }

  static String normalizePairingCode(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}

class SessionContext {
  const SessionContext({
    required this.subject,
    required this.date,
    required this.title,
    this.lectureNumber,
  });

  final SubjectOption subject;
  final String date;
  final String title;
  final String? lectureNumber;

  factory SessionContext.empty() {
    return const SessionContext(
      subject: SubjectOption(
        id: 0,
        name: '',
        code: null,
        majorName: '',
        levelName: '',
      ),
      date: '',
      title: '',
    );
  }

  factory SessionContext.fromJson(Map<String, dynamic> json) {
    return SessionContext(
      subject: SubjectOption.fromJson(
        json['subject'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      date: json['date']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      lectureNumber: json['lecture_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.toJson(),
      'date': date,
      'title': title,
      'lecture_number': lectureNumber,
    };
  }
}

class SubjectOption {
  const SubjectOption({
    required this.id,
    required this.name,
    required this.code,
    required this.majorName,
    required this.levelName,
    this.doctorName,
  });

  final int id;
  final String name;
  final String? code;
  final String majorName;
  final String levelName;
  final String? doctorName;

  factory SubjectOption.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return const SubjectOption(
        id: 0,
        name: '',
        code: null,
        majorName: '',
        levelName: '',
      );
    }

    final major =
        json['major'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final level =
        json['level'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final doctor =
        json['doctor'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    return SubjectOption(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      majorName: major['name']?.toString() ?? 'بدون تخصص',
      levelName: level['name']?.toString() ?? 'بدون مستوى',
      doctorName: doctor['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'major': {'name': majorName},
      'level': {'name': levelName},
      'doctor': doctorName == null ? null : {'name': doctorName},
    };
  }
}

class StartedQrSession {
  const StartedQrSession({
    required this.sessionId,
    required this.token,
    required this.rotationSeconds,
    required this.title,
  });

  final int sessionId;
  final String token;
  final int rotationSeconds;
  final String title;
}

class RotatedToken {
  const RotatedToken({required this.token, required this.rotationSeconds});

  final String token;
  final int rotationSeconds;
}

class SessionStatusPayload {
  const SessionStatusPayload({
    required this.sessionStatus,
    required this.title,
    required this.rotationSeconds,
    required this.scannedCount,
    required this.totalStudents,
    required this.students,
    required this.recentScans,
    required this.verificationSummary,
  });

  final String sessionStatus;
  final String title;
  final int rotationSeconds;
  final int scannedCount;
  final int totalStudents;
  final List<StudentScanStatus> students;
  final List<StudentScanStatus> recentScans;
  final Map<String, int> verificationSummary;

  factory SessionStatusPayload.fromJson(Map<String, dynamic> json) {
    final students = (json['students'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (student) =>
              StudentScanStatus.fromJson(student as Map<String, dynamic>),
        )
        .toList();
    final recent = (json['recent_scans'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (student) =>
              StudentScanStatus.fromJson(student as Map<String, dynamic>),
        )
        .toList();
    final verification =
        (json['verification'] as Map<String, dynamic>? ??
        const <String, dynamic>{});
    final summary =
        (verification['summary'] as Map<String, dynamic>? ??
        const <String, dynamic>{});

    return SessionStatusPayload(
      sessionStatus: json['session_status']?.toString() ?? 'active',
      title: json['title']?.toString() ?? '',
      rotationSeconds: (json['rotation_seconds'] as num?)?.toInt() ?? 10,
      scannedCount: (json['scanned_count'] as num?)?.toInt() ?? 0,
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      students: students,
      recentScans: recent,
      verificationSummary: {
        'missing_scan_count':
            (summary['missing_scan_count'] as num?)?.toInt() ?? 0,
        'sample_check_count':
            (summary['sample_check_count'] as num?)?.toInt() ?? 0,
      },
    );
  }
}

class StudentScanStatus {
  const StudentScanStatus({
    required this.id,
    required this.name,
    required this.status,
    this.studentNumber,
    this.scannedAt,
  });

  final int id;
  final String name;
  final String status;
  final String? studentNumber;
  final DateTime? scannedAt;

  factory StudentScanStatus.fromJson(Map<String, dynamic> json) {
    final scannedAt = json['scanned_at']?.toString();

    return StudentScanStatus(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      studentNumber: json['student_number']?.toString(),
      scannedAt: scannedAt == null || scannedAt.isEmpty
          ? null
          : DateTime.tryParse(scannedAt),
    );
  }
}

class FinalizeResult {
  const FinalizeResult({
    required this.redirectUrl,
    required this.missingScanCount,
    required this.sampleCheckCount,
  });

  final String? redirectUrl;
  final int missingScanCount;
  final int sampleCheckCount;
}

class SessionClosureSummary {
  const SessionClosureSummary({
    required this.subjectName,
    required this.sessionTitle,
    required this.redirectUrl,
    required this.missingScanCount,
    required this.sampleCheckCount,
    required this.endedExternally,
  });

  final String subjectName;
  final String sessionTitle;
  final String? redirectUrl;
  final int missingScanCount;
  final int sampleCheckCount;
  final bool endedExternally;
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

String normalizeBaseUrl(String value) {
  var normalized = value.trim();
  if (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  if (normalized.endsWith('/api')) {
    normalized = normalized.substring(0, normalized.length - 4);
  }
  return normalized;
}

String formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String timeOnly(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
