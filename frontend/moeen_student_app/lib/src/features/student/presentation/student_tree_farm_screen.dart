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
  Map<String, dynamic>? _onlineSession;
  bool _busy = false;
  bool _syncing = false;
  DateTime? _pausedAt;

  Map<String, dynamic>? get _activeSession =>
      _onlineSession ?? _local.activeSession;

  bool get _isLocalActive => _local.activeSession != null;
  bool get _hasActiveSession => _activeSession != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocal();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _hasActiveSession) setState(() {});
    });
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) unawaited(_sendHeartbeat());
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _tickTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now().toUtc();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (pausedAt != null &&
          _hasActiveSession &&
          DateTime.now().toUtc().difference(pausedAt) >
              const Duration(minutes: 3)) {
        unawaited(_finishSession(interrupted: true));
      }
      unawaited(_trySyncPending());
    }
  }

  Future<void> _loadLocal() async {
    _local = await ref.read(treeFarmLocalStoreProvider).load();
    if (mounted) setState(() {});
    unawaited(_trySyncPending());
  }

  Future<void> _saveLocal(TreeFarmLocalState state) async {
    _local = state;
    await ref.read(treeFarmLocalStoreProvider).save(state);
    if (mounted) setState(() {});
  }

  Future<void> _trySyncPending() async {
    if (_syncing ||
        (_local.pendingSessions.isEmpty && _local.pendingThoughts.isEmpty)) {
      return;
    }
    final online = await ref.read(connectivityServiceProvider).isOnline();
    if (!online) return;

    setState(() => _syncing = true);
    try {
      await ref
          .read(studentContentRepositoryProvider)
          .syncTreeFarmOffline(
            sessions: _local.pendingSessions,
            thoughts: _local.pendingThoughts,
          );
      await _saveLocal(
        _local.copyWith(
          pendingSessions: const [],
          pendingThoughts: const [],
          pendingPlants: const [],
        ),
      );
      ref.invalidate(_treeFarmProvider);
    } catch (_) {
      // Keep pending items for the next online sync attempt.
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _sendHeartbeat() async {
    final session = _activeSession;
    if (session == null) return;

    if (_isLocalActive) {
      final updated = {...session};
      updated['heartbeat_count'] = _asInt(updated['heartbeat_count']) + 1;
      updated['last_heartbeat_at'] = DateTime.now().toUtc().toIso8601String();
      await _saveLocal(_local.copyWith(activeSession: updated));
      return;
    }

    final id = _asInt(session['id']);
    if (id <= 0) return;
    try {
      await ref.read(studentContentRepositoryProvider).treeFarmHeartbeat(id);
    } catch (_) {}
  }

  Future<bool> _handleBack() async {
    if (!_hasActiveSession) return false;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جلسة تركيز نشطة'),
        content: const Text(
          'إذا خرجت الآن سيتم إنهاء الجلسة ومنحك أعلى شجرة مكتملة فقط.',
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
  }) async {
    if (_hasActiveSession || _busy) return;
    if (_local.hasExpiredPendingSession) {
      _showMessage(
        'يرجى الاتصال بالإنترنت أولًا لمزامنة جلسات أقدم من 24 ساعة.',
      );
      return;
    }

    setState(() => _busy = true);
    final clientUuid = _clientUuid();
    try {
      final online = await ref.read(connectivityServiceProvider).isOnline();
      if (online) {
        final data = await ref
            .read(studentContentRepositoryProvider)
            .startTreeFarmSession(
              farmScope: farmScope,
              plannedMinutes: minutes,
              clientUuid: clientUuid,
            );
        _onlineSession = _asMap(data['session']);
      } else {
        final now = DateTime.now().toUtc().toIso8601String();
        await _saveLocal(
          _local.copyWith(
            activeSession: {
              'client_uuid': clientUuid,
              'farm_scope': farmScope,
              'source': 'offline',
              'status': 'active',
              'started_at': now,
              'planned_seconds': minutes * 60,
              'heartbeat_count': 0,
              'grace_seconds_used': 0,
            },
          ),
        );
      }
    } catch (error) {
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishSession({bool interrupted = false}) async {
    final session = _activeSession;
    if (session == null || _busy) return;
    setState(() => _busy = true);

    try {
      if (_isLocalActive) {
        final finished = {...session};
        finished['ended_at'] = DateTime.now().toUtc().toIso8601String();
        finished['status'] = interrupted ? 'interrupted' : 'pending_sync';
        final plant = _pendingPlantFor(finished);
        await _saveLocal(
          _local.copyWith(
            clearActiveSession: true,
            pendingSessions: [..._local.pendingSessions, finished],
            pendingPlants: [..._local.pendingPlants, if (plant != null) plant],
          ),
        );
        _showMessage(
          plant == null
              ? 'انتهت الجلسة قبل الحد الأدنى للشجرة.'
              : 'تم حفظ الشجرة محليًا وستظهر بانتظار المزامنة.',
        );
      } else {
        final id = _asInt(session['id']);
        final data = await ref
            .read(studentContentRepositoryProvider)
            .finishTreeFarmSession(id);
        _onlineSession = null;
        ref.invalidate(_treeFarmProvider);
        _showMessage(
          data['plant'] == null
              ? 'انتهت الجلسة قبل الحد الأدنى للشجرة.'
              : 'تمت إضافة الشجرة إلى مزرعتك.',
        );
      }
    } catch (error) {
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestGrace() async {
    final session = _activeSession;
    if (session == null) return;
    if (_isLocalActive) {
      final updated = {...session};
      updated['grace_seconds_used'] = math.min(
        180,
        _asInt(updated['grace_seconds_used']) + 180,
      );
      await _saveLocal(_local.copyWith(activeSession: updated));
      _showMessage('تم منحك مهلة 3 دقائق للعودة.');
      return;
    }
    final id = _asInt(session['id']);
    try {
      await ref
          .read(studentContentRepositoryProvider)
          .requestTreeFarmGrace(sessionId: id, seconds: 180);
      _showMessage('تم منحك مهلة 3 دقائق للعودة.');
    } catch (error) {
      _showMessage(_errorMessage(error));
    }
  }

  Future<void> _addThought() async {
    final controller = TextEditingController();
    final body = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفريغ الأفكار'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'اكتب الفكرة أو المهمة التي ظهرت أثناء المذاكرة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (body == null || body.isEmpty) return;

    try {
      final online = await ref.read(connectivityServiceProvider).isOnline();
      if (online) {
        await ref
            .read(studentContentRepositoryProvider)
            .storeTreeFarmThought(
              body: body,
              clientUuid: _clientUuid(),
              sessionId: _asInt(_onlineSession?['id']) > 0
                  ? _asInt(_onlineSession?['id'])
                  : null,
            );
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
      _showMessage('تم حفظ الفكرة.');
    } catch (error) {
      _showMessage(_errorMessage(error));
    }
  }

  Future<void> _requestReward(int coins) async {
    if (coins < 100) {
      _showMessage('أقل طلب مكافأة هو 100 عملة.');
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

  @override
  Widget build(BuildContext context) {
    final farmAsync = ref.watch(_treeFarmProvider);
    final isOnline = ref.watch(onlineStatusProvider).valueOrNull ?? true;

    return StudentShell(
      currentIndex: 35,
      title: 'مزرعة الأشجار',
      onBackPressed: _handleBack,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_treeFarmProvider);
          await _trySyncPending();
        },
        child: farmAsync.when(
          data: (data) => _buildContent(data, isOnline),
          loading: () => const Center(child: CircularProgressIndicator()),
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
    final session = _activeSession;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        if (errorMessage != null) _InfoBanner(message: errorMessage),
        if (!isOnline)
          const _InfoBanner(
            message:
                'أنت تعمل بدون إنترنت. الجلسات تحفظ محليًا وتنتظر المزامنة.',
          ),
        if (_local.pendingSessions.isNotEmpty || _syncing)
          _InfoBanner(
            message: _syncing
                ? 'جاري مزامنة جلسات المزرعة...'
                : 'لديك ${_local.pendingSessions.length} جلسة بانتظار المزامنة.',
          ),
        _FarmHeader(
          coins: _asInt(profile['coins_balance']),
          focusSeconds: _asInt(profile['total_focus_seconds']),
          publicFocusSeconds: _asInt(profile['total_public_focus_seconds']),
          onReward: () => _requestReward(_asInt(profile['coins_balance'])),
        ),
        const SizedBox(height: 14),
        if (session == null)
          _StartSessionCard(
            busy: _busy,
            catalog: catalog,
            onStart: _startSession,
          )
        else
          _ActiveSessionCard(
            session: session,
            local: _isLocalActive,
            busy: _busy,
            onFinish: () => _finishSession(),
            onGrace: _requestGrace,
            onThought: _addThought,
          ),
        const SizedBox(height: 18),
        _SectionTitle(title: 'مزرعتي', subtitle: '${plants.length} شجرة ووردة'),
        const SizedBox(height: 10),
        _PlantGrid(plants: plants),
        const SizedBox(height: 18),
        _SectionTitle(title: 'مرتبة الشرف', subtitle: 'المزرعة العامة'),
        const SizedBox(height: 10),
        _LeaderboardList(rows: leaderboard),
      ],
    );
  }

  Map<String, dynamic>? _pendingPlantFor(Map<String, dynamic> session) {
    final focused = _focusedSeconds(session);
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
    };
  }

  int _focusedSeconds(Map<String, dynamic> session) {
    final startedAt = DateTime.tryParse(
      session['started_at']?.toString() ?? '',
    );
    final endedAt =
        DateTime.tryParse(session['ended_at']?.toString() ?? '') ??
        DateTime.now().toUtc();
    final elapsed = startedAt == null
        ? 0
        : endedAt.toUtc().difference(startedAt.toUtc()).inSeconds;
    final heartbeatSeconds =
        (_asInt(session['heartbeat_count']) * 30) +
        30 +
        _asInt(session['grace_seconds_used']);
    final planned = _asInt(session['planned_seconds']);
    return math.max(0, math.min(planned, math.min(elapsed, heartbeatSeconds)));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}

class _FarmHeader extends StatelessWidget {
  const _FarmHeader({
    required this.coins,
    required this.focusSeconds,
    required this.publicFocusSeconds,
    required this.onReward,
  });

  final int coins;
  final int focusSeconds;
  final int publicFocusSeconds;
  final VoidCallback onReward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.royalBlue.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
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
              const Icon(
                Icons.park_rounded,
                color: Color(0xff15803d),
                size: 34,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'مزرعة الأشجار',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.icon(
                onPressed: onReward,
                icon: const Icon(Icons.redeem_rounded, size: 18),
                label: const Text('طلب مكافأة'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(label: 'العملات', value: '$coins'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'وقت التركيز',
                  value: _formatDuration(focusSeconds),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'العام',
                  value: _formatDuration(publicFocusSeconds),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartSessionCard extends StatefulWidget {
  const _StartSessionCard({
    required this.busy,
    required this.catalog,
    required this.onStart,
  });

  final bool busy;
  final List<Map<String, dynamic>> catalog;
  final Future<void> Function({required String farmScope, required int minutes})
  onStart;

  @override
  State<_StartSessionCard> createState() => _StartSessionCardState();
}

class _StartSessionCardState extends State<_StartSessionCard> {
  String _scope = 'private';
  int _minutes = 15;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'ابدأ جلسة تركيز',
            subtitle: 'اختر المدة والمزرعة المستهدفة',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('خاصة'),
                selected: _scope == 'private',
                onSelected: (_) => setState(() => _scope = 'private'),
              ),
              ChoiceChip(
                label: const Text('عامة'),
                selected: _scope == 'public',
                onSelected: (_) => setState(() => _scope = 'public'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [15, 30, 45, 60].map((minutes) {
              return ChoiceChip(
                label: Text('$minutes دقيقة'),
                selected: _minutes == minutes,
                onSelected: (_) => setState(() => _minutes = minutes),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _CatalogPreview(catalog: widget.catalog),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.busy
                  ? null
                  : () => widget.onStart(farmScope: _scope, minutes: _minutes),
              icon: widget.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: const Text('بدء الزراعة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.session,
    required this.local,
    required this.busy,
    required this.onFinish,
    required this.onGrace,
    required this.onThought,
  });

  final Map<String, dynamic> session;
  final bool local;
  final bool busy;
  final VoidCallback onFinish;
  final VoidCallback onGrace;
  final VoidCallback onThought;

  @override
  Widget build(BuildContext context) {
    final planned = _asInt(session['planned_seconds']);
    final startedAt = DateTime.tryParse(
      session['started_at']?.toString() ?? '',
    );
    final elapsed = startedAt == null
        ? 0
        : DateTime.now().toUtc().difference(startedAt.toUtc()).inSeconds;
    final progress = planned <= 0 ? 0.0 : (elapsed / planned).clamp(0.0, 1.0);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  local ? 'جلسة أوفلاين نشطة' : 'جلسة تركيز نشطة',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatDuration(math.max(0, planned - elapsed)),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: Center(child: _PlantAnimation(progress: progress)),
          ),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onGrace,
                icon: const Icon(Icons.timer_rounded),
                label: const Text('مهلة 3 دقائق'),
              ),
              OutlinedButton.icon(
                onPressed: onThought,
                icon: const Icon(Icons.lightbulb_rounded),
                label: const Text('تفريغ فكرة'),
              ),
              FilledButton.icon(
                onPressed: busy ? null : onFinish,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('إنهاء الجلسة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlantGrid extends StatelessWidget {
  const _PlantGrid({required this.plants});

  final List<Map<String, dynamic>> plants;

  @override
  Widget build(BuildContext context) {
    if (plants.isEmpty) {
      return const _EmptyBox(message: 'لم تزرع أي شجرة بعد.');
    }
    return GridView.builder(
      itemCount: plants.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final plant = plants[index];
        final pending = plant['status'] == 'pending_sync';
        return _Panel(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 72,
                child: _PlantAnimation(
                  progress: 1,
                  code: plant['plant_code']?.toString(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plant['name']?.toString() ?? 'شجرة',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                pending
                    ? 'بانتظار المزامنة'
                    : '+${_asInt(plant['coins_awarded'])} عملة',
                style: TextStyle(
                  color: pending
                      ? Colors.orange.shade800
                      : Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty)
      return const _EmptyBox(message: 'لا توجد مزارع عامة بعد.');
    return _Panel(
      child: Column(
        children: rows.take(10).map((row) {
          return ListTile(
            leading: CircleAvatar(child: Text('${_asInt(row['rank'])}')),
            title: Text(row['name']?.toString() ?? 'طالب'),
            subtitle: Text(_formatDuration(_asInt(row['focus_seconds']))),
            trailing: Text('${_asInt(row['coins'])} عملة'),
          );
        }).toList(),
      ),
    );
  }
}

class _CatalogPreview extends StatelessWidget {
  const _CatalogPreview({required this.catalog});

  final List<Map<String, dynamic>> catalog;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: catalog.map((plant) {
        return Chip(
          avatar: const Icon(Icons.eco_rounded, size: 18),
          label: Text(
            '${plant['name']} - ${_formatDuration(_asInt(plant['required_seconds']))}',
          ),
        );
      }).toList(),
    );
  }
}

class _PlantAnimation extends StatelessWidget {
  const _PlantAnimation({required this.progress, this.code});

  final double progress;
  final String? code;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlantPainter(progress: progress, code: code),
      child: const SizedBox.expand(),
    );
  }
}

class _PlantPainter extends CustomPainter {
  const _PlantPainter({required this.progress, this.code});

  final double progress;
  final String? code;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.05, 1.0);
    final groundPaint = Paint()..color = const Color(0xffbbf7d0);
    final trunkPaint = Paint()
      ..color = const Color(0xff92400e)
      ..strokeWidth = math.max(5, size.width * .08)
      ..strokeCap = StrokeCap.round;
    final leafPaint = Paint()..color = _leafColor(code);
    final flowerPaint = Paint()..color = const Color(0xfff472b6);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .86),
        width: size.width * .72,
        height: size.height * .16,
      ),
      groundPaint,
    );

    final base = Offset(size.width / 2, size.height * .82);
    final top = Offset(size.width / 2, size.height * (.82 - .46 * p));
    canvas.drawLine(base, top, trunkPaint);

    final crownRadius = size.shortestSide * (.12 + .22 * p);
    canvas.drawCircle(top, crownRadius, leafPaint);
    canvas.drawCircle(
      top.translate(-crownRadius * .65, crownRadius * .25),
      crownRadius * .72,
      leafPaint,
    );
    canvas.drawCircle(
      top.translate(crownRadius * .65, crownRadius * .25),
      crownRadius * .72,
      leafPaint,
    );

    if (code == 'rose' || p < .35) {
      canvas.drawCircle(
        top.translate(0, -crownRadius * .15),
        crownRadius * .35,
        flowerPaint,
      );
    }
  }

  Color _leafColor(String? code) {
    switch (code) {
      case 'golden_tree':
        return const Color(0xfff59e0b);
      case 'palm':
        return const Color(0xff16a34a);
      case 'apple_tree':
        return const Color(0xff65a30d);
      default:
        return const Color(0xff22c55e);
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) {
    return progress != oldDelegate.progress || code != oldDelegate.code;
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(.05)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        if (subtitle != null)
          Text(subtitle!, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(message, style: const TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}

const _fallbackPlants = <Map<String, dynamic>>[
  {
    'plant_code': 'rose',
    'code': 'rose',
    'name': 'وردة التركيز',
    'required_seconds': 900,
    'coins_awarded': 15,
    'coins': 15,
  },
  {
    'plant_code': 'apple_tree',
    'code': 'apple_tree',
    'name': 'شجرة التفاح',
    'required_seconds': 1800,
    'coins_awarded': 35,
    'coins': 35,
  },
  {
    'plant_code': 'palm',
    'code': 'palm',
    'name': 'نخلة الإنجاز',
    'required_seconds': 2700,
    'coins_awarded': 55,
    'coins': 55,
  },
  {
    'plant_code': 'golden_tree',
    'code': 'golden_tree',
    'name': 'الشجرة الذهبية',
    'required_seconds': 3600,
    'coins_awarded': 80,
    'coins': 80,
  },
];

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

String _errorMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}
