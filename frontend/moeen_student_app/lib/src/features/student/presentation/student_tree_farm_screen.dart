part of 'student_content_screens.dart';

class StudentTreeFarmScreen extends ConsumerStatefulWidget {
  const StudentTreeFarmScreen({super.key});

  static const route = '/student/tree-farm';

  @override
  ConsumerState<StudentTreeFarmScreen> createState() =>
      _StudentTreeFarmScreenState();
}

class _StudentTreeFarmScreenState extends ConsumerState<StudentTreeFarmScreen>
    with WidgetsBindingObserver {
  Timer? _tickTimer;
  Timer? _heartbeatTimer;
  TreeFarmLocalState _local = const TreeFarmLocalState();
  bool _busy = false;
  DateTime? _pausedAt;

  // حالة إعداد الجلسة الجديدة
  int _selectedTab = 0; // 0: التركيز، 1: غابتي، 2: المتجر، 3: الإعدادات
  int _forestSubTab = 0; // 0: تخطيط الغابة، 1: إحصائيات المواد
  String _selectedPlantCode = 'red_flower';
  int _minutes = 15;
  bool _isFreeTime = false;
  int? _selectedSubjectId;
  String? _selectedSubjectName;

  // حالة أصوات الخلفية المهدئة للتركيز
  AudioPlayer? _ambientAudioPlayer;
  String? _activeAmbientSound;
  double _ambientVolume = 0.5;

  Map<String, dynamic>? get _activeSession => _local.activeSession;
  bool get _hasActiveSession => _activeSession != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocal();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _hasActiveSession) {
        final session = _activeSession;
        if (session != null && session['is_free_time'] != true) {
          final planned = _asInt(session['planned_seconds']);
          final startedAt = DateTime.tryParse(session['started_at']?.toString() ?? '');
          if (startedAt != null) {
            final elapsed = DateTime.now().toUtc().difference(startedAt.toUtc()).inSeconds;
            if (elapsed >= planned) {
              _finishSession(interrupted: false);
              return;
            }
          }
        }
        setState(() {});
      }
    });
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) unawaited(_sendHeartbeat());
    });
  }

  @override
  void dispose() {
    _ambientAudioPlayer?.dispose();
    _heartbeatTimer?.cancel();
    _tickTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_pausedAt == null && _hasActiveSession) {
        _pausedAt = DateTime.now().toUtc();
        // جدولة إشعار تحذيري واحد يظهر بعد 10 ثوانٍ مع عداد تنازلي نشط مدته 30 ثانية
        unawaited(PushNotificationService.scheduleFocusWarningNotification(
          delay: const Duration(seconds: 10),
          countdownDuration: const Duration(seconds: 30),
        ));
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;

      // إلغاء الإشعار المجدول فوراً عند العودة للتطبيق
      unawaited(PushNotificationService.cancelFocusWarningNotification());

      if (pausedAt != null &&
          _hasActiveSession &&
          DateTime.now().toUtc().difference(pausedAt) >
              const Duration(seconds: 40)) { // 10 ثوانٍ انتظار + 30 ثانية عداد تنازلي = 40 ثانية إجمالاً
        unawaited(_finishSession(interrupted: true));
        _showMessage('للأسف! لقد قضيت وقتاً طويلاً خارج التطبيق وجفت شجرتك 🥀');
      }
      unawaited(_trySyncPending());
    }
  }

  Future<void> _loadLocal() async {
    _local = await ref.read(treeFarmLocalStoreProvider).load();
    if (mounted) setState(() {});
    
    if (_hasActiveSession) {
      await _finishSession(interrupted: true);
    }
    
    unawaited(_trySyncPending());
  }

  Future<void> _saveLocal(TreeFarmLocalState state) async {
    _local = state;
    await ref.read(treeFarmLocalStoreProvider).save(state);
    if (mounted) setState(() {});
  }

  Future<void> _trySyncPending() async {
    if (_local.pendingThoughts.isEmpty) return;
    final online = await ref.read(connectivityServiceProvider).isOnline();
    if (!online) return;
    try {
      for (final thought in _local.pendingThoughts) {
        await ref.read(studentContentRepositoryProvider).storeTreeFarmThought(
              body: thought['body']?.toString() ?? '',
              clientUuid: thought['client_uuid']?.toString(),
            );
      }
      await _saveLocal(_local.copyWith(pendingThoughts: const []));
    } catch (_) {}
  }

  Future<void> _sendHeartbeat() async {
    final session = _activeSession;
    if (session == null) return;
    final updated = Map<String, dynamic>.from(session);
    updated['heartbeat_count'] = _asInt(updated['heartbeat_count']) + 1;
    updated['last_heartbeat_at'] = DateTime.now().toUtc().toIso8601String();
    await _saveLocal(_local.copyWith(activeSession: updated));
  }

  Future<bool> _handleBack() async {
    if (!_hasActiveSession) return false;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جلسة تركيز نشطة'),
        content: const Text(
          'إذا خرجت الآن سيتم إنهاء الجلسة ومنحك ما أنجزته من وقت فقط.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('البقاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إنهاء والخروج'),
          ),
        ],
      ),
    );
    if (leave != true) return true;
    await _finishSession(interrupted: true);
    if (mounted) context.go(StudentDashboardScreen.route);
    return true;
  }

  Future<void> _startSession({
    required String farmScope,
    required int minutes,
    required bool isFreeTime,
  }) async {
    if (_hasActiveSession || _busy) return;

    final now = DateTime.now().toUtc().toIso8601String();
    await _saveLocal(
      _local.copyWith(
        activeSession: {
          'client_uuid': _clientUuid(),
          'farm_scope': farmScope,
          'source': 'local',
          'status': 'active',
          'started_at': now,
          'planned_seconds': isFreeTime ? 0 : minutes * 60,
          'is_free_time': isFreeTime,
          'selected_plant_code': _selectedPlantCode,
          'subject_id': _selectedSubjectId,
          'subject_name': _selectedSubjectName,
          'heartbeat_count': 0,
          'grace_seconds_used': 0,
        },
      ),
    );
  }

  Future<void> _finishSession({bool interrupted = false}) async {
    final session = _activeSession;
    if (session == null || _busy) return;
    setState(() => _busy = true);

    // إيقاف أي أصوات خلفية مهدئة عند إنهاء الجلسة
    if (_ambientAudioPlayer != null) {
      unawaited(_ambientAudioPlayer!.stop());
      _activeAmbientSound = null;
    }

    try {
      final endedAt = DateTime.now().toUtc();
      final startedAt = DateTime.tryParse(
        session['started_at']?.toString() ?? '',
      )?.toUtc();

      // 1. حساب الشجرة محلياً
      final finished = Map<String, dynamic>.from(session);
      finished['ended_at'] = endedAt.toIso8601String();
      finished['status'] = interrupted ? 'interrupted' : 'completed';

      final focusedSecs = _focusedSeconds(finished);
      final plant = _pendingPlantFor(finished);

      // حفظ تفاصيل الشجرة محلياً للمطابقة التاريخية أوفلاين
      List<Map<String, dynamic>> updatedHistory = _local.localHistoryMetadata;
      if (plant != null) {
        final newMetadata = {
          'plant_code': plant['plant_code']?.toString(),
          'planted_at': plant['planted_at'] ?? DateTime.now().toUtc().toIso8601String(),
          'subject_name': finished['subject_name']?.toString(),
          'thoughts': finished['thoughts'] != null ? List<String>.from(finished['thoughts']) : <String>[],
        };
        updatedHistory = [
          ..._local.localHistoryMetadata,
          newMetadata,
        ];
      }

      // 2. مسح الجلسة النشطة وإضافة الشجرة محلياً مؤقتاً
      await _saveLocal(
        _local.copyWith(
          clearActiveSession: true,
          pendingPlants: [
            ..._local.pendingPlants,
            if (plant != null) plant,
          ],
          localHistoryMetadata: updatedHistory,
        ),
      );

      // 3. عرض النتيجة للمستخدم فوراً
      _showSessionResult(plant, focusedSecs);

      // 4. إرسال السجل للسيرفر في الخلفية
      if (startedAt != null) {
        unawaited(_logToServer(
          session: session,
          focusedSeconds: focusedSecs,
          startedAt: startedAt,
          endedAt: endedAt,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logToServer({
    required Map<String, dynamic> session,
    required int focusedSeconds,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    try {
      await ref.read(studentContentRepositoryProvider).logTreeFarmSession(
            farmScope: session['farm_scope']?.toString() ?? 'private',
            focusedSeconds: focusedSeconds,
            startedAt: startedAt.toIso8601String(),
            endedAt: endedAt.toIso8601String(),
            clientUuid: session['client_uuid']?.toString() ?? _clientUuid(),
            subjectId: _asInt(session['subject_id']) > 0
                ? _asInt(session['subject_id'])
                : null,
            subjectName: session['subject_name']?.toString(),
          );

      ref.invalidate(_treeFarmProvider);

      // مسح الأشجار المحلية المؤقتة بعد المزامنة
      await _saveLocal(_local.copyWith(pendingPlants: const []));
    } catch (_) {
      // فشل الإرسال -> تبقى محلياً
    }
  }

  void _showSessionResult(Map<String, dynamic>? plant, int focusedSeconds) {
    if (!mounted) return;
    final isBurned = plant != null && plant['plant_code'] == 'burned_tree';

    if (plant != null && !isBurned) {
      unawaited(SystemSound.play(SystemSoundType.alert));
      
      // إرسال إشعار محلي بصوت النغمة الافتراضية
      unawaited(PushNotificationService.showLocalNotification(
        title: '🌱 أحسنت! زرعت شجرة جديدة بنجاح',
        body: 'لقد نجحت في التركيز لمدة ${focusedSeconds ~/ 60} دقيقة وحصلت على +${_asInt(plant['coins_awarded'])} عملة! 🌟',
      ));

      // اهتزاز متتابع متدرج (قوي ثم متوسط ثم خفيف)
      unawaited(Future.microtask(() async {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.lightImpact();
      }));
    } else if (isBurned) {
      unawaited(HapticFeedback.vibrate());
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isBurned
              ? '🥀 للأسف! جفت شجرتك'
              : (plant != null ? '🌱 أحسنت! زرعت شجرة' : 'انتهت الجلسة'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (plant != null) ...[
              SizedBox(
                height: 120,
                width: 120,
                child: _PlantAnimation(
                  progress: 1.0,
                  code: plant['plant_code']?.toString(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isBurned ? 'شجرة ذابلة' : (plant['name']?.toString() ?? 'نبتة'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: isBurned ? const Color(0xffb91c1c) : const Color(0xff1b4332),
                ),
              ),
              const SizedBox(height: 6),
              if (isBurned)
                const Text(
                  'لم تتمكن من إكمال وقت التركيز المخطط له بسبب مقاطعة الجلسة أو قصر الوقت.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xffd8f3dc),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+${_asInt(plant['coins_awarded'])} عملة',
                    style: const TextStyle(
                      color: Color(0xff2d6a4f),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
            ] else ...[
              const Icon(Icons.timer_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'وقت التركيز: ${_formatDuration(focusedSeconds)}',
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text('لم تبلغ الحد الأدنى لزراعة شجرة (5 دقائق).', textAlign: TextAlign.center),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: isBurned ? const Color(0xffb91c1c) : const Color(0xff2d6a4f),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(isBurned ? 'موافق' : 'رائع!'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted && plant != null) {
        setState(() {
          _selectedTab = 1;
        });
      }
    });
  }



  Future<void> _addThought() async {
    final controller = TextEditingController();
    final body = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xffd8f3dc),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xff2d6a4f),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تفريغ الأفكار المشتتة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff1b4332),
                          ),
                        ),
                        Text(
                          'فرغ ما يشغلك الآن لتستمر بتركيز',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 5,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff2d3748),
                ),
                decoration: InputDecoration(
                  hintText: 'ما هي الفكرة التي تشغل بالك الآن؟ اكتبها هنا لتفرغها وتعود إليها لاحقاً...',
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: const Color(0xfff7f9fa),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xff2d6a4f), width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, controller.text.trim()),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff2d6a4f),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تفريغ وحفظ 💡',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (body == null || body.isEmpty) return;

    if (_hasActiveSession) {
      final updatedSession = Map<String, dynamic>.from(_activeSession!);
      final list = List<String>.from(updatedSession['thoughts'] ?? <String>[]);
      list.add(body);
      updatedSession['thoughts'] = list;
      await _saveLocal(_local.copyWith(activeSession: updatedSession));
    }

    try {
      final online = await ref.read(connectivityServiceProvider).isOnline();
      if (online) {
        await ref
            .read(studentContentRepositoryProvider)
            .storeTreeFarmThought(
              body: body,
              clientUuid: _clientUuid(),
            );
        ref.invalidate(_treeFarmProvider);
      } else {
        await _saveLocal(
          _local.copyWith(
            pendingThoughts: [
              ..._local.pendingThoughts,
              {
                'client_uuid': _clientUuid(),
                'body': body,
                'created_at': DateTime.now().toUtc().toIso8601String(),
              },
            ],
          ),
        );
      }
      _showMessage('تم حفظ الفكرة وتفريغها بنجاح!');
    } catch (error) {
      _showMessage(_errorMessage(error));
    }
  }

  Future<void> _requestReward(int coins) async {
    if (coins < 25) {
      _showMessage('أقل طلب مكافأة هو 25 عملة.');
      return;
    }
    try {
      await ref
          .read(studentContentRepositoryProvider)
          .requestTreeFarmReward(coins);
      ref.invalidate(_treeFarmProvider);
      _showMessage('تم إرسال طلب المكافأة للمراجعة.');
    } catch (error) {
      _showMessage(_errorMessage(error));
    }
  }

  Future<void> _showRewardDialog(int availableCoins) async {
    if (availableCoins < 25) {
      _showMessage('رصيدك أقل من الحد الأدنى لطلب المكافأة (25 عملة).');
      return;
    }

    final controller = TextEditingController(text: '25');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final val = int.tryParse(controller.text) ?? 0;
            final stars = val ~/ 25;
            final isValid = val >= 25 && val <= availableCoins && val % 25 == 0;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'طلب مكافأة تحويل النجوم',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الرصيد المتاح: $availableCoins عملة',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'عدد العملات للتحويل',
                      hintText: 'مثال: 25، 50...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (isValid)
                    Text(
                      'ستحصل على: $stars ${stars == 1 ? 'نجمة' : stars == 2 ? 'نجمتين' : 'نجوم'}',
                      style: const TextStyle(
                        color: Color(0xff15803d),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  else if (val < 25)
                    const Text(
                      'أقل قيمة للطلب هي 25 عملة',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    )
                  else if (val > availableCoins)
                    const Text(
                      'رصيدك المتاح لا يكفي',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    )
                  else if (val % 25 != 0)
                    const Text(
                      'يرجى إدخال مضاعفات الـ 25 (25، 50...)',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [25, 50, 100].map((amount) {
                      return ActionChip(
                        label: Text('$amount عملة'),
                        onPressed: amount <= availableCoins
                            ? () {
                                controller.text = amount.toString();
                                setState(() {});
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: !isValid
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _requestReward(val);
                        },
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xff2d6a4f)),
                  child: const Text('إرسال الطلب'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmAsync = ref.watch(_treeFarmProvider);
    final isOnline = ref.watch(onlineStatusProvider).valueOrNull ?? true;

    return StudentShell(
      currentIndex: 35,
      title: 'مزرعة الأشجار',
      onBackPressed: _handleBack,
      resizeToAvoidBottomInset: false,
      disableDrawer: _hasActiveSession,
      child: farmAsync.when(
        data: (data) => _buildContent(data, isOnline),
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xff2d6a4f))),
        error: (error, _) => _buildContent(
          {
            'profile': const <String, dynamic>{},
            'plant_catalog': _fallbackPlants,
            'plants': const [],
            'leaderboard': const [],
          },
          isOnline,
          errorMessage: _errorMessage(error),
        ),
      ),
    );
  }

  Widget _buildContent(
    Map<String, dynamic> data,
    bool isOnline, {
    String? errorMessage,
  }) {
    final profile = _asMap(data['profile']);
    final plants = [
      ..._asList(data['plants']).whereType<Map>().map(_mapFromDynamic),
      ..._local.pendingPlants,
    ];
    final catalog = _asList(data['plant_catalog']).isEmpty
        ? _fallbackPlants
        : _asList(
            data['plant_catalog'],
          ).whereType<Map>().map(_mapFromDynamic).toList();
    final leaderboard = _asList(
      data['leaderboard'],
    ).whereType<Map>().map(_mapFromDynamic).toList();
    final thoughts = [
      ..._local.pendingThoughts,
      ..._asList(data['thoughts']).whereType<Map>().map(_mapFromDynamic),
    ];
    final rewardRequests = _asList(data['reward_requests']).whereType<Map>().map(_mapFromDynamic).toList();
    final session = _activeSession;

    // جلب المقررات الدراسية الحالية للطالب لربطها بالتركيز
    final subjectsAsync = ref.watch(_subjectsProvider(const SubjectFilters()));
    final subjectsList = subjectsAsync.valueOrNull?['subjects'] as List? ?? [];

    // في حال وجود جلسة نشطة، نجبر المستخدم على البقاء في شاشة التركيز الفعالة فقط
    if (session != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xfffdfbf7),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: _buildActiveFocusView(session),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: const Color(0xfffdfbf7), // خلفية بيج دافئة لطيفة
            child: Column(
              children: [
                if (errorMessage != null) _InfoBanner(message: errorMessage),
                if (!isOnline)
                  const _InfoBanner(
                    message: 'أنت تعمل بدون اتصال. سيتم تسجيل الأشجار محلياً ومزامنتها لاحقاً.',
                  ),
                
                // المحتوى المتغير بناء على التبويب
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _buildFocusSetupTab(catalog, subjectsList, profile),
                      _buildForestTab(plants, profile, leaderboard),
                      _buildStoreTab(catalog, profile, rewardRequests),
                      _buildSettingsTab(profile, thoughts),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // شريط التنقل السفلي العائم الزجاجي الفخم
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _buildFloatingDock(),
        ),
      ],
    );
  }

  Widget _buildCoinsBadge(Map<String, dynamic> profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffe8efe9),
        border: Border.all(color: const Color(0xff2d6a4f).withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 6),
          Text(
            '${_asInt(profile['coins_balance'])}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xff1b4332),
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingDock() {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1b4332).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildDockItem(0, 'التركيز', Icons.spa_rounded),
                _buildDockItem(1, 'غابتي', Icons.park_rounded),
                _buildDockItem(2, 'المتجر', Icons.storefront_rounded),
                _buildDockItem(3, 'الإعدادات', Icons.settings_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedTab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xff2d6a4f), Color(0xff40916c)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xff2d6a4f).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xff5f7d6a),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? const Color(0xff1b4332) : const Color(0xff5f7d6a),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  // تبويب 0: التركيز واعداد الجلسة (ثابت تماماً ولا يسحب)
  Widget _buildFocusSetupTab(
    List<Map<String, dynamic>> catalog,
    List<dynamic> subjects,
    Map<String, dynamic> profile,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 85), // مساحة سفلية للشريط العائم
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // توزيع متناسق على ارتفاع الشاشة
        children: [
          // لوحة اختيار نمط التركيز المنزلقة الفخمة مع رصيد العملات المدمج
          Row(
            children: [
              Expanded(child: _buildFocusModeTabs()),
              const SizedBox(width: 12),
              _buildCoinsBadge(profile),
            ],
          ),

          // قرص العداد الدائري التفاعلي
          SizedBox(
            width: 200,
            height: 200,
            child: _CircularTimerDial(
              duration: Duration(minutes: _minutes),
              minMinutes: 10,
              maxMinutes: 120,
              readOnly: _isFreeTime,
              onChanged: (d) {
                setState(() {
                  _minutes = d.inMinutes;
                  // التحديث التلقائي للنبتة المناسبة بناءً على الوقت المحدد عند السحب للأمام أو الخلف
                  final bestCode = _bestPlantCodeForSeconds(
                    _minutes * 60,
                    catalog,
                  );
                  if (bestCode != _selectedPlantCode) {
                    HapticFeedback.mediumImpact(); // اهتزاز عند تغيير البذرة
                    _selectedPlantCode = bestCode;
                  }
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isFreeTime ? 'وقت حر' : 'مدة التركيز',
                    style: const TextStyle(color: Color(0xff5f7d6a), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isFreeTime ? '∞' : _formatRemainingTime(_minutes * 60),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff1b4332),
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (!_isFreeTime) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$_minutes دقيقة',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // شريط أزرار تعديل الوقت السريعة (تظهر فقط عند نمط التنازلي)
          if (!_isFreeTime)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeAdjustButton('-5 د', () {
                  setState(() {
                    _minutes = math.max(10, _minutes - 5);
                    // تحديث الشجرة تلقائياً
                    final bestCode = _bestPlantCodeForSeconds(
                      _minutes * 60,
                      catalog,
                    );
                    if (bestCode != _selectedPlantCode) {
                      HapticFeedback.mediumImpact();
                      _selectedPlantCode = bestCode;
                    }
                  });
                }),
                const SizedBox(width: 16),
                _buildTimeAdjustButton('+5 د', () {
                  setState(() {
                    _minutes = math.min(120, _minutes + 5);
                    // تحديث الشجرة تلقائياً
                    final bestCode = _bestPlantCodeForSeconds(
                      _minutes * 60,
                      catalog,
                    );
                    if (bestCode != _selectedPlantCode) {
                      HapticFeedback.mediumImpact();
                      _selectedPlantCode = bestCode;
                    }
                  });
                }),
              ],
            ),

          // كتالوج اختيار النبتة (أفق كاروسيل)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر البذرة لزراعتها:',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xff1b4332)),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: catalog.length,
                  itemBuilder: (context, index) {
                    final plant = catalog[index];
                    final code = plant['code']?.toString() ?? '';
                    final isSelected = _selectedPlantCode == code;
                    final reqMin = _asInt(plant['required_seconds']) ~/ 60;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlantCode = code;
                          if (!_isFreeTime) {
                            // تعيين وقت المؤقت تلقائياً للحد الأدنى المسموح به للنبتة
                            _minutes = math.max(_minutes, reqMin);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 104,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xffe8efe9) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xff2d6a4f) : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 66,
                              width: 70,
                              child: _PlantAnimation(progress: 1.0, code: code),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plant['name']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                                color: isSelected ? const Color(0xff1b4332) : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$reqMinد',
                              style: const TextStyle(fontSize: 8, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // ربط المواد
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر المادة الدراسية للتركيز عليها:',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xff1b4332)),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int?>(
                value: _selectedSubjectId,
                dropdownColor: const Color(0xfffdfbf7),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xff2d6a4f), width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('عام / بدون تحديد مقرر', style: TextStyle(fontSize: 12)),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('عام / بدون تحديد مقرر', style: TextStyle(fontSize: 12)),
                  ),
                  ...subjects.map((sub) {
                    final subMap = _asMap(sub);
                    final id = _asInt(subMap['id']);
                    final name = subMap['name']?.toString() ?? 'مقرر';
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(name, style: const TextStyle(fontSize: 12)),
                    );
                  }),
                ],
                onChanged: (id) {
                  setState(() {
                    _selectedSubjectId = id;
                    if (id == null) {
                      _selectedSubjectName = null;
                    } else {
                      final found = subjects.firstWhere(
                        (sub) => _asInt(_asMap(sub)['id']) == id,
                        orElse: () => null,
                      );
                      _selectedSubjectName = found != null ? _asMap(found)['name']?.toString() : null;
                    }
                  });
                },
              ),
            ],
          ),

          // زر بدء التركيز الأسطوري
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _startSession(
                        farmScope: 'private',
                        minutes: _minutes,
                        isFreeTime: _isFreeTime,
                      ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff2d6a4f),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              icon: const Icon(Icons.spa_rounded, size: 20),
              label: Text(
                _isFreeTime ? 'بدء التركيز الحر' : 'بدء التركيز الآن',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeTabs() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffe8efe9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isFreeTime = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: !_isFreeTime ? const Color(0xff2d6a4f) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: !_isFreeTime
                      ? [
                          BoxShadow(
                            color: const Color(0xff2d6a4f).withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'مؤقت تنازلي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: !_isFreeTime ? Colors.white : const Color(0xff5f7d6a),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isFreeTime = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: _isFreeTime ? const Color(0xff2d6a4f) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isFreeTime
                      ? [
                          BoxShadow(
                            color: const Color(0xff2d6a4f).withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'وقت حر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _isFreeTime ? Colors.white : const Color(0xff5f7d6a),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAdjustButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff2d6a4f),
        side: const BorderSide(color: Color(0xff2d6a4f), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  // شاشة الجلسة النشطة
  Widget _buildActiveFocusView(Map<String, dynamic> session) {
    final isFreeTime = session['is_free_time'] == true;
    final planned = _asInt(session['planned_seconds']);
    final startedAt = DateTime.tryParse(session['started_at']?.toString() ?? '');
    final elapsed = startedAt == null
        ? 0
        : DateTime.now().toUtc().difference(startedAt.toUtc()).inSeconds;

    double progress = 0.0;
    final activePlantCode = _growthPlantCodeForSeconds(elapsed);

    if (isFreeTime) {
      progress = (elapsed % 7200 / 7200).clamp(0.0, 1.0);
    } else {
      progress = planned <= 0 ? 0.0 : (elapsed / planned).clamp(0.0, 1.0);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.center_focus_strong_rounded, color: Color(0xff2d6a4f), size: 40),
        const SizedBox(height: 10),
        const Text(
          'أنت الآن في وضع التركيز العميق',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xff1b4332)),
        ),
        const SizedBox(height: 6),
        Text(
          isFreeTime ? 'الوقت يمر والتربة تنمو ثماراً...' : 'ابق بعيداً عن المشتتات لتنمو شجرتك!',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 36),

        // عداد دائري نشط
        SizedBox(
          width: 230,
          height: 230,
          child: _CircularTimerDial(
            duration: Duration(seconds: isFreeTime ? elapsed : math.max(0, planned - elapsed)),
            minMinutes: 10,
            maxMinutes: 120,
            readOnly: true,
            progress: isFreeTime ? (elapsed % 3600 / 3600) : progress,
            onChanged: (_) {},
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_activeAmbientSound != null && (_activeAmbientSound == 'rain' || _activeAmbientSound == 'forest'))
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(115),
                      child: _WeatherOverlay(type: _activeAmbientSound!),
                    ),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: _PlantAnimation(progress: 1.0, code: activePlantCode),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFreeTime ? _formatRemainingTime(elapsed) : _formatRemainingTime(math.max(0, planned - elapsed)),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff1b4332),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),

        // أزرار التحكم الفعالة
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFocusActionButton('تفريغ فكرة 💡', const Color(0xffe8efe9), const Color(0xff2d6a4f), _addThought),
          ],
        ),
        _buildAmbientPlayer(),
        const SizedBox(height: 12),
        SizedBox(
          width: 200,
          height: 48,
          child: FilledButton.icon(
            onPressed: _busy ? null : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('إنهاء الجلسة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  content: const Text('هل أنت متأكد من رغبتك في إنهاء جلسة التركيز الحالية؟', style: TextStyle(fontFamily: 'Cairo')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xffb91c1c)),
                      child: const Text('إنهاء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _finishSession();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffb91c1c),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.stop_circle_rounded),
            label: const Text('إنهاء الجلسة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusActionButton(String label, Color bg, Color textCol, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  // تبويب 1: غابتي (الحديقة المرئية)
  Widget _buildForestTab(
    List<Map<String, dynamic>> plants,
    Map<String, dynamic> profile,
    List<Map<String, dynamic>> leaderboard,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_treeFarmProvider);
        await _trySyncPending();
      },
      color: const Color(0xff2d6a4f),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 95), // مساحة سفلية للشريط العائم
        child: Column(
          children: [
            // كرت الإحصائيات
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildForestStat('إجمالي التركيز', _formatDuration(_asInt(profile['total_focus_seconds'])), Icons.punch_clock_rounded),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildForestStat('عدد الأشجار', '${plants.length}', Icons.eco_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // مفتاح التنقل بين خريطة الغابة وإحصائيات المواد
            _buildForestSubTabSelector(),
            const SizedBox(height: 20),

            if (_forestSubTab == 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'أشجاري هذا الأسبوع:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xff1b4332)),
                  ),
                  _buildCoinsBadge(profile),
                ],
              ),
              const SizedBox(height: 10),

              // خريطة الشبكة المرئية
              _buildForestGridMap(plants),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'سجل زراعة الأشجار الأخير:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xff1b4332)),
                ),
              ),
              const SizedBox(height: 10),
              if (plants.isEmpty)
                const _EmptyBox(message: 'لم تزرع أي أشجار بعد.')
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: List.generate(
                      math.min(5, plants.length),
                      (index) {
                        final plant = plants[index];
                        final subject = plant['subject_name']?.toString();
                        final plantCode = plant['plant_code']?.toString() ?? plant['code']?.toString();
                        final isBurned = plantCode == 'burned_tree';
                        final plantName = isBurned ? 'شجرة جافة 🍂' : (plant['name']?.toString() ?? 'شجرة');
                        
                        return ListTile(
                          leading: SizedBox(
                            width: 32,
                            height: 32,
                            child: _PlantAnimation(
                              progress: 1.0,
                              code: plantCode,
                            ),
                          ),
                          title: Text(plantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(_formatDateTime(plant['planted_at'] ?? plant['synced_at'])),
                          trailing: subject != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffe8efe9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    subject,
                                    style: const TextStyle(color: Color(0xff2d6a4f), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                 )
                              : null,
                        );
                      },
                    ),
                  ),
                ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'توزيع التركيز حسب المواد الدراسية:',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xff1b4332)),
                  ),
                  _buildCoinsBadge(profile),
                ],
              ),
              const SizedBox(height: 16),
              _SubjectPieChart(data: _getSubjectFocusData(plants)),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'تفاصيل أوقات المذاكرة لكل مقرر:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xff1b4332)),
                ),
              ),
              const SizedBox(height: 10),
              _buildSubjectBreakdownList(_getSubjectFocusData(plants)),
            ],
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'مرتبة الشرف (المزرعة العامة) 🏆',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xff1b4332)),
              ),
            ),
            const SizedBox(height: 10),
            _LeaderboardList(rows: leaderboard),
          ],
        ),
      ),
    );
  }

  Widget _buildForestStat(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xff2d6a4f), size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xff1b4332))),
      ],
    );
  }

  Widget _buildForestGridMap(List<Map<String, dynamic>> plants) {
    // شبكة خريطة 5x5 (25 عنصر)
    const gridSize = 25;
    final displayPlants = plants.take(gridSize).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffe8efe9), // لون خلفية عشبية للحديقة
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffd8f3dc), width: 2),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: gridSize,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final hasTree = index < displayPlants.length;
          final plant = hasTree ? displayPlants[index] : null;
          final subject = plant?['subject_name']?.toString();

          return Tooltip(
            message: hasTree
                ? '${plant?['name']} ${subject != null ? '($subject)' : ''}'
                : 'تربة فارغة',
            child: InkWell(
              onTap: hasTree && plant != null
                  ? () => _showPlantDetailsBottomSheet(plant)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: hasTree ? const Color(0xffd8f3dc) : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasTree ? const Color(0xffb7e4c7) : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: hasTree
                    ? _PlantAnimation(progress: 1.0, code: plant?['plant_code']?.toString())
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  // تبويب 2: المتجر والمكافآت
  Widget _buildStoreTab(
    List<Map<String, dynamic>> catalog,
    Map<String, dynamic> profile,
    List<Map<String, dynamic>> rewardRequests,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_treeFarmProvider);
        await _trySyncPending();
      },
      color: const Color(0xff2d6a4f),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 95), // مساحة سفلية للشريط العائم
        children: [
          // كرت طلب جائزة فوري
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xffd8f3dc)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.redeem_rounded, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('طلب مكافأة نجوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('حول 25 عملة إلى نجمة واحدة لدعم مستواك', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _showRewardDialog(_asInt(profile['coins_balance'])),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff2d6a4f),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('طلب تحويل العملات الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // قائمة كتالوج الأشجار المتاحة في اللعبة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'كتالوج بذور النباتات المتاحة 🌱',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff1b4332)),
              ),
              _buildCoinsBadge(profile),
            ],
          ),
          const SizedBox(height: 10),
          ...catalog.map((plant) {
            final code = plant['code']?.toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: SizedBox(
                  width: 72,
                  height: 72,
                  child: _PlantAnimation(progress: 1.0, code: code),
                ),
                title: Text(
                  plant['name']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'وقت النمو: ${_formatDuration(_asInt(plant['required_seconds']))}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xffe8efe9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${_asInt(plant['coins'])} عملة',
                    style: const TextStyle(color: Color(0xff2d6a4f), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 18),
          _RewardRequestsSection(requests: rewardRequests),
        ],
      ),
    );
  }

  // تبويب 3: الإعدادات والأفكار
  Widget _buildSettingsTab(Map<String, dynamic> profile, List<Map<String, dynamic>> thoughts) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_treeFarmProvider);
        await _trySyncPending();
      },
      color: const Color(0xff2d6a4f),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 95), // مساحة سفلية للشريط العائم
        children: [
          _ProfileSettingsSection(
            profile: profile,
            onUpdate: _updateProfile,
          ),
          const SizedBox(height: 20),
          _ThoughtsSection(
            thoughts: thoughts,
            onAddThought: _addThought,
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile({
    String? publicName,
    bool? isPublic,
    bool? useAlias,
  }) async {
    try {
      await ref.read(studentContentRepositoryProvider).updateTreeFarmProfile(
            publicName: publicName,
            isPublic: isPublic,
            useAlias: useAlias,
          );
      ref.invalidate(_treeFarmProvider);
      _showMessage('تم حفظ التغييرات بنجاح.');
    } catch (error) {
      _showMessage(_errorMessage(error));
    }
  }

  Map<String, dynamic>? _pendingPlantFor(Map<String, dynamic> session) {
    final status = session['status']?.toString();
    final isInterrupted = status == 'interrupted';
    final focused = _focusedSeconds(session);

    if (isInterrupted || focused < 600) {
      return {
        'plant_code': 'burned_tree',
        'code': 'burned_tree',
        'name': 'شجرة ذابلة',
        'required_seconds': session['planned_seconds'] ?? 0,
        'coins_awarded': 0,
        'coins': 0,
        'farm_scope': session['farm_scope'] ?? 'private',
        'status': 'pending_sync',
        'planted_at': DateTime.now().toUtc().toIso8601String(),
        'subject_id': session['subject_id'],
        'subject_name': session['subject_name'],
        'thoughts': session['thoughts'] ?? <String>[],
      };
    }

    Map<String, dynamic>? selected;
    for (final plant in _fallbackPlants) {
      if (focused >= _asInt(plant['required_seconds'])) selected = plant;
    }
    if (selected == null) return null;
    return {
      ...selected,
      'farm_scope': session['farm_scope'] ?? 'private',
      'status': 'pending_sync',
      'planted_at': DateTime.now().toUtc().toIso8601String(),
      'subject_id': session['subject_id'],
      'subject_name': session['subject_name'],
      'thoughts': session['thoughts'] ?? <String>[],
    };
  }

  int _focusedSeconds(Map<String, dynamic> session) {
    final startedAt = DateTime.tryParse(session['started_at']?.toString() ?? '');
    final endedAt = DateTime.tryParse(session['ended_at']?.toString() ?? '') ?? DateTime.now().toUtc();
    final elapsed = startedAt == null
        ? 0
        : endedAt.toUtc().difference(startedAt.toUtc()).inSeconds;
    final planned = _asInt(session['planned_seconds']);
    
    // إذا كانت وقت حر، لا يوجد حد أقصى مخطط، نكتفي بالـ 4 ساعات (14400 ثانية) كحد أقصى
    final isFree = session['is_free_time'] == true;
    final limit = isFree ? 14400 : planned;
    
    return math.max(0, math.min(limit, elapsed));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==========================================
  // --- ميزات متقدمة: أصوات الخلفية وتفاصيل الأشجار التفاعلية ---
  // ==========================================

  Widget _buildAmbientPlayer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffe8efe9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.headset_rounded, color: Color(0xff2d6a4f), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'أصوات الخلفية المهدئة (أوفلاين) 🎧',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1b4332),
                    ),
                  ),
                ],
              ),
              if (_activeAmbientSound != null)
                const Icon(
                  Icons.music_note_rounded,
                  color: Color(0xff2d6a4f),
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAmbientOption('rain', '🌧️ مطر', 'audio/rain.mp3'),
              _buildAmbientOption('forest', '🌲 غابة', 'audio/forest.mp3'),
              _buildAmbientOption('cafe', '☕ مقهى', 'audio/cafe.mp3'),
            ],
          ),
          if (_activeAmbientSound != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.volume_down_rounded, color: Colors.grey, size: 16),
                Expanded(
                  child: Slider(
                    value: _ambientVolume,
                    onChanged: (val) {
                      setState(() {
                        _ambientVolume = val;
                      });
                      _ambientAudioPlayer?.setVolume(val);
                    },
                    activeColor: const Color(0xff2d6a4f),
                    inactiveColor: const Color(0xffe8efe9),
                  ),
                ),
                const Icon(Icons.volume_up_rounded, color: Colors.grey, size: 16),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmbientOption(String id, String label, String assetPath) {
    final isActive = _activeAmbientSound == id;
    return InkWell(
      onTap: () => _toggleAmbientSound(id, assetPath),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xff2d6a4f) : const Color(0xfff7f9fa),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xff1b4332) : Colors.grey.shade200,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xff5a6578),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAmbientSound(String id, String assetPath) async {
    final previousActiveSound = _activeAmbientSound;
    try {
      _ambientAudioPlayer ??= AudioPlayer();

      if (_activeAmbientSound == id) {
        setState(() {
          _activeAmbientSound = null;
        });
        await _ambientAudioPlayer?.stop();
      } else {
        setState(() {
          _activeAmbientSound = id;
        });
        await _ambientAudioPlayer?.stop();
        await _ambientAudioPlayer?.setReleaseMode(ReleaseMode.loop);
        await _ambientAudioPlayer?.setVolume(_ambientVolume);
        await _ambientAudioPlayer?.play(AssetSource(assetPath));
      }
    } catch (e) {
      debugPrint('Failed to toggle ambient sound: $e');
      setState(() {
        _activeAmbientSound = previousActiveSound;
      });
      _showMessage('عذراً، تعذر تشغيل الصوت. الرجاء إيقاف التطبيق بالكامل وإعادة تشغيله (flutter run) لتفعيل إضافات الصوت. خطأ: $e');
    }
  }

  Map<String, dynamic>? _getPlantMetadata(Map<String, dynamic> plant) {
    final code = plant['plant_code']?.toString() ?? plant['code']?.toString();
    final plantedAtStr = plant['planted_at'] ?? plant['synced_at'];
    if (code == null || plantedAtStr == null) return null;
    
    final plantedAt = DateTime.tryParse(plantedAtStr.toString());
    if (plantedAt == null) return null;
    
    Map<String, dynamic>? bestMatch;
    int minDiffSeconds = 999999;
    
    for (final meta in _local.localHistoryMetadata) {
      if (meta['plant_code'] != code) continue;
      final metaTimeStr = meta['planted_at'];
      if (metaTimeStr == null) continue;
      final metaTime = DateTime.tryParse(metaTimeStr.toString());
      if (metaTime == null) continue;
      
      final diff = metaTime.difference(plantedAt).inSeconds.abs();
      if (diff < minDiffSeconds && diff < 600) { // Max 10 minutes difference
        minDiffSeconds = diff;
        bestMatch = meta;
      }
    }
    
    return bestMatch;
  }

  void _showPlantDetailsBottomSheet(Map<String, dynamic> plant) {
    final meta = _getPlantMetadata(plant);
    final subject = plant['subject_name']?.toString() ?? meta?['subject_name']?.toString();
    final thoughts = _asList(plant['thoughts']).isNotEmpty 
        ? _asList(plant['thoughts']).cast<String>() 
        : (meta?['thoughts'] != null ? List<String>.from(meta!['thoughts']) : const <String>[]);
    final durationMin = _asInt(plant['required_seconds']) ~/ 60;
    final isBurned = plant['plant_code']?.toString() == 'burned_tree';
    final plantName = isBurned ? 'شجرة جافة 🍂' : (plant['name']?.toString() ?? 'نبتة');

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xfffdfbf7), // Warm premium cream paper color
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SafeArea(
          bottom: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isBurned
                            ? [
                                const Color(0xfffee2e2),
                                const Color(0xfffef2f2).withOpacity(0.4),
                                Colors.transparent,
                              ]
                            : [
                                const Color(0xffd8f3dc).withOpacity(0.6),
                                const Color(0xffe8efe9).withOpacity(0.2),
                                Colors.transparent,
                              ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        height: 52,
                        width: 52,
                        child: _PlantAnimation(progress: 1.0, code: plant['plant_code']?.toString()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plantName,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isBurned ? const Color(0xffb45309) : const Color(0xff1b4332),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تمت زراعتها في ${_formatDateTime(plant['planted_at'] ?? plant['synced_at'])}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildBentoStatCard(
                      icon: Icons.timer_rounded,
                      value: '$durationMin دقيقة',
                      label: 'مدة التركيز',
                      bgColor: const Color(0xffe8efe9),
                      iconColor: const Color(0xff2d6a4f),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBentoStatCard(
                      icon: Icons.monetization_on_rounded,
                      value: isBurned ? '0' : '+${_asInt(plant['coins_awarded'])}',
                      label: 'العملات',
                      bgColor: isBurned ? const Color(0xfff5f5f5) : const Color(0xfffef3c7),
                      iconColor: isBurned ? Colors.grey.shade600 : const Color(0xffb45309),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBentoStatCard(
                      icon: Icons.book_rounded,
                      value: subject ?? 'غير محددة',
                      label: 'المادة',
                      bgColor: const Color(0xffe0f2fe),
                      iconColor: const Color(0xff0369a1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                '💭 الأفكار المفرغة خلال الجلسة:',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff1b4332),
                ),
              ),
              const SizedBox(height: 10),
              if (thoughts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isBurned ? const Color(0xfffdfaf7) : const Color(0xfff7fbf7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isBurned ? const Color(0xfffee2e2) : const Color(0xffe8efe9),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isBurned ? Icons.info_outline_rounded : Icons.stars_rounded,
                        color: isBurned ? const Color(0xffb45309) : const Color(0xff2d6a4f),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isBurned
                              ? 'لم يتم تفريغ أي أفكار خلال هذه الجلسة وتوقف التركيز.'
                              : 'تركيز كامل وذهن صافٍ! لم تتشتت بأي فكرة خلال هذه الجلسة الرائعة. 🧘‍♂️✨',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: isBurned ? const Color(0xff78350f) : const Color(0xff1b4332),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: SingleChildScrollView(
                    child: Column(
                      children: thoughts.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xfffdfbf7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 10,
                                  left: 10,
                                  right: 14,
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff2c3e50),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                bottom: 0,
                                right: 0,
                                width: 3,
                                child: Container(
                                  color: const Color(0xff2d6a4f),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final shareText = isBurned
                            ? 'لقد حاولت زراعة شجرة في مزرعة معين لتركيزي، سأحاول مجدداً وبشكل أفضل!'
                            : 'لقد زرعت شجرة $plantName بنجاح في مزرعة معين لتركيزي لمدة $durationMin دقيقة! 🌲✨';
                        Clipboard.setData(ClipboardData(text: shareText)).then((_) {
                          _showMessage('تم نسخ تفاصيل الإنجاز لمشاركتها مع أصدقائك! 📋');
                        });
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'مشاركة الإنجاز',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff2d6a4f),
                        side: const BorderSide(color: Color(0xff2d6a4f)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff2d6a4f),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'حسناً',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor.withOpacity(0.9), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: iconColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: iconColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForestSubTabSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xffe8efe9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _forestSubTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _forestSubTab == 0 ? const Color(0xff2d6a4f) : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: Text(
                  'خريطة الغابة 🌲',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _forestSubTab == 0 ? Colors.white : const Color(0xff5f7d6a),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _forestSubTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _forestSubTab == 1 ? const Color(0xff2d6a4f) : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: Text(
                  'إحصائيات المواد 📊',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _forestSubTab == 1 ? Colors.white : const Color(0xff5f7d6a),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdownList(Map<String, int> data) {
    if (data.isEmpty) {
      return const _EmptyBox(message: 'لا توجد سجلات تركيز للمواد الدراسية بعد.');
    }
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: sorted.map((entry) {
          final hours = (entry.value / 3600.0).toStringAsFixed(1);
          final mins = entry.value ~/ 60;
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xffe8efe9),
              foregroundColor: Color(0xff2d6a4f),
              child: Icon(Icons.menu_book_rounded, size: 18),
            ),
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            subtitle: Text('إجمالي الدقائق: $mins دقيقة', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xffe8efe9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$hours ساعة',
                style: const TextStyle(color: Color(0xff2d6a4f), fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, int> _getSubjectFocusData(List<Map<String, dynamic>> plants) {
    final data = <String, int>{};
    for (final p in plants) {
      final subject = p['subject_name']?.toString() ?? 'عام / بدون تحديد مقرر';
      final seconds = _asInt(p['required_seconds']);
      data[subject] = (data[subject] ?? 0) + seconds;
    }
    return data;
  }
}

// العداد الدائري التفاعلي المخصص
class _CircularTimerDial extends StatefulWidget {
  const _CircularTimerDial({
    required this.duration,
    required this.minMinutes,
    required this.maxMinutes,
    required this.onChanged,
    required this.child,
    this.readOnly = false,
    this.progress = 0.0,
  });

  final Duration duration;
  final int minMinutes;
  final int maxMinutes;
  final ValueChanged<Duration> onChanged;
  final Widget child;
  final bool readOnly;
  final double progress;

  @override
  State<_CircularTimerDial> createState() => _CircularTimerDialState();
}

class _CircularTimerDialState extends State<_CircularTimerDial> {
  bool _isDragging = false;

  void _updateAngle(Offset localPosition, RenderBox box) {
    final center = box.size.center(Offset.zero);
    final pos = localPosition - center;
    double rad = math.atan2(pos.dy, pos.dx);
    double angle = rad + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    double pct = angle / (2 * math.pi);
    int minutes = (pct * widget.maxMinutes).round();
    minutes = ((minutes / 5).round() * 5).clamp(widget.minMinutes, widget.maxMinutes);
    if (minutes != widget.duration.inMinutes) {
      HapticFeedback.lightImpact();
      widget.onChanged(Duration(minutes: minutes));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: widget.readOnly
          ? null
          : (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final center = box.size.center(Offset.zero);
              final pos = details.localPosition - center;
              final distance = pos.distance;
              final radius = box.size.shortestSide / 2 - 10;
              // تفعيل السحب فقط عند الضغط بالقرب من محيط الدائرة (نطاق 35 بكسل) لمنع قفز المؤشر عند النقر بالمنتصف
              if (distance >= (radius - 35) && distance <= (radius + 40)) {
                setState(() => _isDragging = true);
                _updateAngle(details.localPosition, box);
              } else {
                setState(() => _isDragging = false);
              }
            },
      onPanUpdate: widget.readOnly
          ? null
          : (details) {
              if (!_isDragging) return;
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              _updateAngle(details.localPosition, box);
            },
      onPanEnd: (_) => setState(() => _isDragging = false),
      onPanCancel: () => setState(() => _isDragging = false),
      child: CustomPaint(
        painter: _TimerDialPainter(
          progress: widget.readOnly ? widget.progress : (widget.duration.inMinutes / widget.maxMinutes),
          readOnly: widget.readOnly,
          isDragging: _isDragging,
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _TimerDialPainter extends CustomPainter {
  const _TimerDialPainter({
    required this.progress,
    required this.readOnly,
    this.isDragging = false,
  });

  final double progress;
  final bool readOnly;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 10;

    final trackPaint = Paint()
      ..color = const Color(0xffe8efe9)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = readOnly ? const Color(0xff15803d) : const Color(0xff2d6a4f)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );

    if (!readOnly) {
      final thumbAngle = -math.pi / 2 + sweepAngle;
      final thumbOffset = Offset(
        center.dx + radius * math.cos(thumbAngle),
        center.dy + radius * math.sin(thumbAngle),
      );

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(isDragging ? 0.15 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(thumbOffset, isDragging ? 16 : 14, shadowPaint);

      final thumbPaint = Paint()
        ..color = const Color(0xff1e3f20)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(thumbOffset, isDragging ? 14 : 12, thumbPaint);
      canvas.drawCircle(
        thumbOffset,
        isDragging ? 7 : 6,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerDialPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        readOnly != oldDelegate.readOnly ||
        isDragging != oldDelegate.isDragging;
  }
}

class _PlantAnimation extends StatelessWidget {
  const _PlantAnimation({required this.progress, this.code});

  final double progress;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.15, 1.0);
    final plantCode = code ?? 'grass';

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final bottomPadding = height * 0.04;
        final plantHeight = height * 0.9;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: SizedBox(
              height: plantHeight,
              width: constraints.maxWidth * 0.95,
              child: AnimatedScale(
                scale: p,
                curve: Curves.elasticOut,
                duration: const Duration(milliseconds: 1200),
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  'assets/plants/$plantCode.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      plantCode == 'burned_tree'
                          ? Icons.local_fire_department_rounded
                          : Icons.local_florist_rounded,
                      color: plantCode == 'burned_tree'
                          ? const Color(0xffb45309)
                          : const Color(0xff2d6a4f),
                      size: plantHeight * 0.72,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffffbeb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xfffde68a)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Color(0xffb45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xffb45309)),
            ),
          ),
        ],
      ),
    );
  }
}

const _fallbackPlants = <Map<String, dynamic>>[
  {
    'plant_code': 'grass',
    'code': 'grass',
    'name': 'عشب البداية',
    'required_seconds': 600,
    'coins_awarded': 8,
    'coins': 8,
  },
  {
    'plant_code': 'red_flower',
    'code': 'red_flower',
    'name': 'زهرة حمراء',
    'required_seconds': 900,
    'coins_awarded': 15,
    'coins': 15,
  },
  {
    'plant_code': 'blue_flower',
    'code': 'blue_flower',
    'name': 'زهرة زرقاء',
    'required_seconds': 1200,
    'coins_awarded': 20,
    'coins': 20,
  },
  {
    'plant_code': 'blue_bud',
    'code': 'blue_bud',
    'name': 'برعم أزرق',
    'required_seconds': 1500,
    'coins_awarded': 25,
    'coins': 25,
  },
  {
    'plant_code': 'purple_flower',
    'code': 'purple_flower',
    'name': 'زهرة بنفسجية',
    'required_seconds': 1800,
    'coins_awarded': 35,
    'coins': 35,
  },
  {
    'plant_code': 'pine_small',
    'code': 'pine_small',
    'name': 'صنوبرة صغيرة',
    'required_seconds': 2700,
    'coins_awarded': 55,
    'coins': 55,
  },
  {
    'plant_code': 'pine_tall',
    'code': 'pine_tall',
    'name': 'صنوبرة شامخة',
    'required_seconds': 3600,
    'coins_awarded': 80,
    'coins': 80,
  },
  {
    'plant_code': 'orange_tree',
    'code': 'orange_tree',
    'name': 'شجرة برتقالية',
    'required_seconds': 5400,
    'coins_awarded': 120,
    'coins': 120,
  },
  {
    'plant_code': 'orange_cypress',
    'code': 'orange_cypress',
    'name': 'سرو برتقالي',
    'required_seconds': 7200,
    'coins_awarded': 170,
    'coins': 170,
  },
];

String _bestPlantCodeForSeconds(
  int seconds,
  List<Map<String, dynamic>> catalog,
) {
  var selected = catalog.isNotEmpty
      ? catalog.first['code']?.toString() ?? 'grass'
      : 'grass';
  for (final plant in catalog) {
    if (seconds >= _asInt(plant['required_seconds'])) {
      selected = plant['code']?.toString() ?? selected;
    }
  }
  return selected;
}

String _growthPlantCodeForSeconds(int seconds) {
  if (seconds < 300) return 'sprout_seed';
  if (seconds < 600) return 'sprout';
  return _bestPlantCodeForSeconds(seconds, _fallbackPlants);
}

String _clientUuid() {
  return '${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(999999)}';
}

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(Object? value) => value is List ? value : const [];

Map<String, dynamic> _mapFromDynamic(Map value) {
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours > 0) return '$hours س $rest د';
  return '$minutes د';
}

String _formatRemainingTime(int seconds) {
  if (seconds < 0) seconds = 0;
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  final minutesStr = minutes.toString().padLeft(2, '0');
  final secsStr = secs.toString().padLeft(2, '0');
  return '$minutesStr:$secsStr';
}

String _errorMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}

class _ThoughtsSection extends StatelessWidget {
  const _ThoughtsSection({
    required this.thoughts,
    required this.onAddThought,
  });

  final List<Map<String, dynamic>> thoughts;
  final VoidCallback onAddThought;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffe8efe9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    color: Color(0xff1b4332),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'تفريغ الأفكار المشتتة 💡',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff1b4332),
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: onAddThought,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'أضف فكرة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff2d6a4f),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (thoughts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xfff7f9fa),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xff2d6a4f),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'لا توجد أفكار مفرغة حالياً. كلما خطرت ببالك فكرة تشتتك أثناء جلسة التركيز، فرغها هنا لتسترجع صفاء عقلك وتكمل دراستك.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Color(0xff5a6578),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(5, thoughts.length),
              itemBuilder: (context, index) {
                final thought = thoughts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xfffdfbf7), // Warm premium cream paper color
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16,
                            bottom: 16,
                            left: 16,
                            right: 20, // extra padding on the right for the accent line
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xfffaedcd).withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Transform.rotate(
                                  angle: -0.2,
                                  child: const Icon(
                                    Icons.push_pin_rounded,
                                    size: 16,
                                    color: Color(0xffe76f51), // Subtle warm orange pin color
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      thought['body']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xff2c3e50),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDateTime(thought['created_at'] ?? thought['synced_at']),
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          width: 4,
                          child: Container(
                            color: const Color(0xff2d6a4f),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RewardRequestsSection extends StatelessWidget {
  const _RewardRequestsSection({required this.requests});

  final List<Map<String, dynamic>> requests;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'طلبات المكافآت السابقة 🎁',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xff1b4332)),
          ),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'لم تقم بتقديم أي طلبات مكافآت بعد.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(5, requests.length),
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];
                final coins = _asInt(req['coins_amount']);
                final stars = _asInt(req['stars_amount']);
                final status = req['status']?.toString() ?? 'pending';
                final reason = req['rejection_reason']?.toString();

                Color statusColor;
                String statusText;
                if (status == 'approved') {
                  statusColor = const Color(0xff15803d);
                  statusText = 'مقبول';
                } else if (status == 'rejected') {
                  statusColor = const Color(0xffb91c1c);
                  statusText = 'مرفوض';
                } else {
                  statusColor = const Color(0xffd97706);
                  statusText = 'معلق';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$stars ${stars == 1 ? 'نجمة' : stars == 2 ? 'نجمتين' : 'نجوم'} ($coins عملة)',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            if (status == 'rejected' && reason != null && reason.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'السبب: $reason',
                                style: const TextStyle(color: Color(0xffb91c1c), fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ProfileSettingsSection extends StatefulWidget {
  const _ProfileSettingsSection({
    required this.profile,
    required this.onUpdate,
  });

  final Map<String, dynamic> profile;
  final Future<void> Function({
    String? publicName,
    bool? isPublic,
    bool? useAlias,
  }) onUpdate;

  @override
  State<_ProfileSettingsSection> createState() => _ProfileSettingsSectionState();
}

class _ProfileSettingsSectionState extends State<_ProfileSettingsSection> {
  late bool _isPublic;
  late bool _useAlias;
  late TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.profile['is_public'] == true;
    _useAlias = widget.profile['use_alias'] == true;
    _nameController = TextEditingController(text: widget.profile['public_name']?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _ProfileSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _isPublic = widget.profile['is_public'] == true;
      _useAlias = widget.profile['use_alias'] == true;
      _nameController.text = widget.profile['public_name']?.toString() ?? '';
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onUpdate(
        publicName: _useAlias ? _nameController.text.trim() : null,
        isPublic: _isPublic,
        useAlias: _useAlias,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إعدادات الخصوصية واللوحة العامة ⚙️',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xff1b4332)),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('عرض اسمي في لوحة الصدارة العامة'),
            subtitle: const Text('يسمح للآخرين بمشاهدة وقت تركيزك الكلي في المزرعة العامة', style: TextStyle(fontSize: 11)),
            activeColor: const Color(0xff2d6a4f),
            value: _isPublic,
            onChanged: (val) {
              setState(() => _isPublic = val);
              _save();
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('استخدام اسم مستعار'),
            subtitle: const Text('إخفاء اسمك الحقيقي واستبداله باسم مستعار في قائمة المتصدرين', style: TextStyle(fontSize: 11)),
            activeColor: const Color(0xff2d6a4f),
            value: _useAlias,
            onChanged: (val) {
              setState(() => _useAlias = val);
              _save();
            },
          ),
          if (_useAlias) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم المستعار الظاهر للجميع',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xff2d6a4f)),
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDateTime(Object? dateStr) {
  if (dateStr == null) return '';
  final date = DateTime.tryParse(dateStr.toString())?.toLocal();
  if (date == null) return '';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty)
      return const _EmptyBox(message: 'لا توجد مزارع عامة بعد.');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: rows.take(10).map((row) {
          final rank = _asInt(row['rank']);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: rank == 1
                  ? Colors.amber.shade100
                  : rank == 2
                      ? Colors.grey.shade300
                      : rank == 3
                          ? const Color(0xfffcd34d).withOpacity(0.2)
                          : const Color(0xffe8efe9),
              foregroundColor: rank == 1
                  ? Colors.amber.shade900
                  : rank == 2
                      ? Colors.grey.shade700
                      : rank == 3
                          ? Colors.amber.shade800
                          : const Color(0xff2d6a4f),
              child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(row['name']?.toString() ?? 'طالب', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('وقت التركيز الكلي: ${_formatDuration(_asInt(row['focus_seconds']))}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xffe8efe9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_asInt(row['coins'])} عملة',
                style: const TextStyle(color: Color(0xff2d6a4f), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _WeatherOverlay extends StatefulWidget {
  const _WeatherOverlay({required this.type});
  final String type;

  @override
  State<_WeatherOverlay> createState() => _WeatherOverlayState();
}

class _WeatherOverlayState extends State<_WeatherOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initializeParticles();
  }

  @override
  void didUpdateWidget(covariant _WeatherOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _initializeParticles();
    }
  }

  void _initializeParticles() {
    _particles.clear();
    final count = widget.type == 'rain' ? 35 : 15;
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.01 + _random.nextDouble() * 0.02,
        size: widget.type == 'rain' 
            ? 1.2 + _random.nextDouble() * 1.5
            : 2.5 + _random.nextDouble() * 3.5,
        opacity: 0.1 + _random.nextDouble() * 0.6,
        angle: widget.type == 'rain' ? math.pi / 6 : _random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _updateParticles();
        return CustomPaint(
          painter: _WeatherPainter(
            particles: _particles,
            type: widget.type,
            tick: _controller.value,
          ),
        );
      },
    );
  }

  void _updateParticles() {
    for (final p in _particles) {
      if (widget.type == 'rain') {
        p.y += p.speed;
        p.x -= p.speed * math.tan(math.pi / 12);
        if (p.y > 1.0) {
          p.y = 0.0;
          p.x = _random.nextDouble();
        }
      } else if (widget.type == 'forest') {
        p.x += math.cos(p.angle) * 0.002;
        p.y += math.sin(p.angle) * 0.002;
        
        // Wrap around boundary coordinates
        if (p.x < 0) p.x = 1.0;
        if (p.x > 1.0) p.x = 0.0;
        if (p.y < 0) p.y = 1.0;
        if (p.y > 1.0) p.y = 0.0;
        
        // Randomly change directions occasionally
        if (_random.nextDouble() < 0.02) {
          p.angle = _random.nextDouble() * 2 * math.pi;
        }
      }
    }
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.angle,
  });

  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double angle;
}

class _WeatherPainter extends CustomPainter {
  _WeatherPainter({required this.particles, required this.type, required this.tick});
  final List<_Particle> particles;
  final String type;
  final double tick;

  @override
  void paint(Canvas canvas, Size size) {
    if (type == 'rain') {
      final paint = Paint()
        ..color = const Color(0xff5bc0be).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (final p in particles) {
        final startX = p.x * size.width;
        final startY = p.y * size.height;
        final endX = startX - 6 * math.tan(math.pi / 12);
        final endY = startY + 10;
        paint.strokeWidth = p.size;
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }
    } else if (type == 'forest') {
      for (final p in particles) {
        final cx = p.x * size.width;
        final cy = p.y * size.height;
        // Pulse opacity using sine based on the tick
        final pulseOpacity = (p.opacity * (0.4 + 0.6 * (math.sin(tick * 2 * math.pi + p.size) + 1.0) / 2.0)).clamp(0.0, 1.0);
        
        // Firefly glow
        final paintGlow = Paint()
          ..color = const Color(0xff52b788).withOpacity(pulseOpacity * 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), p.size * 2.2, paintGlow);

        // Core glowing particle
        final paintCore = Paint()
          ..color = const Color(0xffd8f3dc).withOpacity(pulseOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), p.size * 0.7, paintCore);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SubjectPieChart extends StatelessWidget {
  const _SubjectPieChart({required this.data});
  final Map<String, int> data;

  static const List<Color> _palette = [
    Color(0xff2d6a4f),
    Color(0xff40916c),
    Color(0xff52b788),
    Color(0xff74c69d),
    Color(0xff95d5b2),
    Color(0xffb7e4c7),
    Color(0xffd8f3dc),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'لا توجد بيانات لرسوم بيانية بعد.',
            style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final totalSeconds = data.values.fold<int>(0, (a, b) => a + b);
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    double startAngle = -math.pi / 2;
    final List<_PieSegment> segments = [];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final percentage = totalSeconds == 0 ? 0.0 : entry.value / totalSeconds;
      final sweepAngle = percentage * 2 * math.pi;
      final color = _palette[i % _palette.length];
      segments.add(_PieSegment(
        subject: entry.key,
        seconds: entry.value,
        percentage: percentage,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        color: color,
      ));
      startAngle += sweepAngle;
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: CustomPaint(
            painter: _PieChartPainter(segments: segments),
            child: Center(
              child: Container(
                width: 95,
                height: 95,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'التركيز الكلي',
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatDurationHours(totalSeconds),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff1b4332),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: segments.map((seg) {
            final formattedTime = _formatDurationHours(seg.seconds);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xfff7f9fa),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: seg.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${seg.subject} (${(seg.percentage * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff5a6578),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($formattedTime)',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatDurationHours(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '$minutesد';
    }
    final hours = minutes / 60.0;
    return '${hours.toStringAsFixed(1)}س';
  }
}

class _PieSegment {
  _PieSegment({
    required this.subject,
    required this.seconds,
    required this.percentage,
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
  });

  final String subject;
  final int seconds;
  final double percentage;
  final double startAngle;
  final double sweepAngle;
  final Color color;
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.segments});
  final List<_PieSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final seg in segments) {
      paint.color = seg.color;
      canvas.drawArc(rect, seg.startAngle, seg.sweepAngle, true, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
