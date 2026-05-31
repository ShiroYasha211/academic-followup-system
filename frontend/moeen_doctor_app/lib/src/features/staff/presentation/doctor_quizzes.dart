part of 'staff_screens.dart';

class DoctorQuizzesScreen extends ConsumerStatefulWidget {
  const DoctorQuizzesScreen({super.key});

  static const route = '/doctor/quizzes';

  @override
  ConsumerState<DoctorQuizzesScreen> createState() =>
      _DoctorQuizzesScreenState();
}

class _DoctorQuizzesScreenState extends ConsumerState<DoctorQuizzesScreen> {
  String _status = 'all';
  final _search = TextEditingController();
  late Future<Map<String, dynamic>> _future = _fetch();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/quizzes',
          query: {if (_status != 'all') 'status': _status, 'per_page': 50},
        );
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'كويزاتي',
      currentRoute: DoctorQuizzesScreen.route,
      floatingActionButton: _QuizFloatingButton(
        onPressed: () async {
          final data = await _future;
          if (!context.mounted) return;
          final subjects = _docList(
            _docMap(_docMap(_docData(data))['filters'])['subjects'],
          );
          await context.push(
            DoctorQuizFormScreen.createRoute,
            extra: {'subjects': subjects},
          );
          _reload();
        },
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final payload = _docMap(_docData(snapshot.data ?? const {}));
          final quizzes = _docList(payload['quizzes']);
          final subjects = _docList(_docMap(payload['filters'])['subjects']);
          final stats = _docMap(payload['stats']);

          final query = _search.text.trim().toLowerCase();
          final filteredQuizzes = quizzes.where((quiz) {
            final title = _docText(quiz['title']).toLowerCase();
            final subjectName = _docText(
              _docMap(quiz['subject'])['name'],
            ).toLowerCase();
            return title.contains(query) || subjectName.contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'كويزاتي',
                  subtitle: 'إنشاء الكويزات وإدارتها ومتابعة النتائج.',
                  icon: Icons.quiz_rounded,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'الكل',
                      value: _docText(
                        stats['total'],
                        quizzes.length.toString(),
                      ),
                      color: AppColors.royalBlue,
                      icon: Icons.quiz_rounded,
                    ),
                    _DocMetric(
                      label: 'منشور',
                      value: _docText(stats['published'], '0'),
                      color: AppColors.success,
                      icon: Icons.public_rounded,
                    ),
                    _DocMetric(
                      label: 'مجدول',
                      value: _docText(stats['scheduled'], '0'),
                      color: AppColors.warning,
                      icon: Icons.schedule_rounded,
                    ),
                    _DocMetric(
                      label: 'مغلق',
                      value: _docText(stats['closed'], '0'),
                      color: AppColors.danger,
                      icon: Icons.lock_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن كويز أو مادة...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.slate200.withValues(alpha: 0.8),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.royalBlue,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DocSegmentFilter(
                  value: _status,
                  onChanged: (value) {
                    setState(() {
                      _status = value;
                      _future = _fetch();
                    });
                  },
                  choices: const [
                    _DocFilterChoice(
                      value: 'all',
                      label: 'الكل',
                      icon: Icons.apps_rounded,
                      color: AppColors.royalBlue,
                    ),
                    _DocFilterChoice(
                      value: 'draft',
                      label: 'مسودة',
                      icon: Icons.edit_note_rounded,
                      color: AppColors.warning,
                    ),
                    _DocFilterChoice(
                      value: 'published',
                      label: 'منشور',
                      icon: Icons.public_rounded,
                      color: AppColors.success,
                    ),
                    _DocFilterChoice(
                      value: 'scheduled',
                      label: 'مجدول',
                      icon: Icons.schedule_rounded,
                      color: AppColors.info,
                    ),
                    _DocFilterChoice(
                      value: 'closed',
                      label: 'مغلق',
                      icon: Icons.lock_rounded,
                      color: AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (filteredQuizzes.isEmpty)
                  _DocEmpty(
                    quizzes.isEmpty
                        ? 'لا توجد كويزات في هذا التصنيف.'
                        : 'لا توجد نتائج مطابقة لبحثك.',
                  )
                else
                  ...filteredQuizzes.map(
                    (quiz) => _QuizCard(
                      quiz: quiz,
                      onTap: () async {
                        await context.push(
                          DoctorQuizDetailsScreen.path(_docInt(quiz['id'])),
                          extra: {'subjects': subjects},
                        );
                        _reload();
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Future<void> _showQuizDetails(_Json quiz, List<_Json> subjects) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الكويز',
      icon: Icons.quiz_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _QuizDetailsPanel(
        quizId: _docInt(quiz['id']),
        subjects: subjects,
        onChanged: _reload,
        onEdit: (details) async {
          Navigator.pop(context);
          await _showQuizForm(subjects: subjects, quizDetails: details);
        },
      ),
    );
    _reload();
  }

  Future<void> _showQuizForm({
    required List<_Json> subjects,
    _Json? quizDetails,
  }) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: quizDetails == null ? 'إنشاء كويز' : 'تعديل كويز',
      icon: Icons.quiz_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _QuizFormSheet(
        subjects: subjects,
        quizDetails: quizDetails,
        onSaved: _reload,
      ),
    );
  }
}

class DoctorQuizDetailsScreen extends ConsumerStatefulWidget {
  const DoctorQuizDetailsScreen({
    super.key,
    required this.quizId,
    this.subjects = const [],
  });

  static const route = '/doctor/quizzes/:quizId';

  final int quizId;
  final List<Map<String, dynamic>> subjects;

  static String path(int quizId) => '/doctor/quizzes/$quizId';

  @override
  ConsumerState<DoctorQuizDetailsScreen> createState() =>
      _DoctorQuizDetailsScreenState();
}

class _DoctorQuizDetailsScreenState
    extends ConsumerState<DoctorQuizDetailsScreen> {
  late List<Map<String, dynamic>> _subjects = widget.subjects;
  int _refreshToken = 0;

  Future<List<Map<String, dynamic>>> _loadSubjects() async {
    if (_subjects.isNotEmpty) return _subjects;
    final response = await ref
        .read(staffRepositoryProvider)
        .get('/doctor/subjects/options');
    _subjects = _docList(_docMap(_docData(response))['subjects']);
    return _subjects;
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'تفاصيل الكويز',
      currentRoute: DoctorQuizzesScreen.route,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadSubjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final subjects = snapshot.data ?? const <Map<String, dynamic>>[];
          return SingleChildScrollView(
            key: ValueKey(_refreshToken),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            child: _QuizDetailsPanel(
              quizId: widget.quizId,
              subjects: subjects,
              onChanged: () {},
              onEdit: (details) async {
                await context.push(
                  DoctorQuizFormScreen.editPath(widget.quizId),
                  extra: {'subjects': subjects, 'details': details},
                );
                if (mounted) setState(() => _refreshToken++);
              },
            ),
          );
        },
      ),
    );
  }
}

class DoctorQuizFormScreen extends ConsumerStatefulWidget {
  const DoctorQuizFormScreen({
    super.key,
    this.quizId,
    this.subjects = const [],
    this.quizDetails = const {},
  });

  static const createRoute = '/doctor/quizzes/create';
  static const editRoute = '/doctor/quizzes/:quizId/edit';

  final int? quizId;
  final List<Map<String, dynamic>> subjects;
  final Map<String, dynamic> quizDetails;

  static String editPath(int quizId) => '/doctor/quizzes/$quizId/edit';

  @override
  ConsumerState<DoctorQuizFormScreen> createState() =>
      _DoctorQuizFormScreenState();
}

class _DoctorQuizFormScreenState extends ConsumerState<DoctorQuizFormScreen> {
  late final Future<
    ({List<Map<String, dynamic>> subjects, Map<String, dynamic> details})
  >
  _future = _load();

  Future<({List<Map<String, dynamic>> subjects, Map<String, dynamic> details})>
  _load() async {
    var subjects = widget.subjects;
    if (subjects.isEmpty) {
      final response = await ref
          .read(staffRepositoryProvider)
          .get('/doctor/subjects/options');
      subjects = _docList(_docMap(_docData(response))['subjects']);
    }

    var details = widget.quizDetails;
    final quizId = widget.quizId;
    if (quizId != null && details.isEmpty) {
      final response = await ref
          .read(staffRepositoryProvider)
          .get('/doctor/quizzes/$quizId');
      details = _docMap(_docData(response));
    }

    return (subjects: subjects, details: details);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.quizId != null;
    return StaffShell(
      title: editing ? 'تعديل كويز' : 'إنشاء كويز',
      currentRoute: DoctorQuizzesScreen.route,
      child:
          FutureBuilder<
            ({
              List<Map<String, dynamic>> subjects,
              Map<String, dynamic> details,
            })
          >(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
              final bundle = snapshot.data!;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 96,
                ),
                child: _QuizFormSheet(
                  subjects: bundle.subjects,
                  quizDetails: editing ? bundle.details : null,
                  onSaved: () {},
                ),
              );
            },
          ),
    );
  }
}

class _QuizFloatingButton extends StatelessWidget {
  const _QuizFloatingButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 18, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'كويز جديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _quizStatusIcon(String status) {
  switch (status) {
    case 'published':
      return Icons.public_rounded;
    case 'scheduled':
      return Icons.schedule_rounded;
    case 'closed':
      return Icons.lock_rounded;
    case 'draft':
      return Icons.edit_note_rounded;
    default:
      return Icons.quiz_rounded;
  }
}

String _quizTimerLabel(_Json quiz) {
  return _docText(quiz['timer_mode']) == 'per_question'
      ? 'وقت لكل سؤال'
      : '${_docText(quiz['time_limit_minutes'], '-')} دقيقة';
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz, required this.onTap});

  final _Json quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(quiz['subject']);
    final status = _docText(quiz['status'], 'draft');
    final models = _docList(quiz['models']);
    final color = _docStatusColor(status);
    final scheduledAt = _docText(quiz['scheduled_at']);
    final closesAt = _docText(quiz['closes_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: color.withValues(alpha: 0.14),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Icon(
                              _quizStatusIcon(status),
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _docText(quiz['title'], 'كويز'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.midnight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _docText(subject['name'], '-'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _DocPill(
                            _docStatusLabel(status),
                            color,
                            icon: _quizStatusIcon(status),
                          ),
                        ],
                      ),
                      if (_docText(quiz['description']).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.slate100),
                          ),
                          child: Text(
                            _docText(quiz['description']),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.slate700,
                              fontWeight: FontWeight.w700,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DocPill(
                            '${models.length} نموذج',
                            AppColors.royalBlue,
                            icon: Icons.view_module_rounded,
                          ),
                          _DocPill(
                            '${_docInt(quiz['attempts_count'])} محاولة',
                            AppColors.success,
                            icon: Icons.groups_rounded,
                          ),
                          _DocPill(
                            _quizTimerLabel(quiz),
                            AppColors.warning,
                            icon: Icons.timer_rounded,
                          ),
                          if (status == 'scheduled' && scheduledAt.isNotEmpty)
                            _DocPill(
                              'يبدأ: ${_docDate(quiz['scheduled_at'])}',
                              AppColors.info,
                              icon: Icons.event_available_rounded,
                            ),
                          if (status == 'published' && closesAt.isNotEmpty)
                            _DocPill(
                              'ينتهي: ${_docDate(quiz['closes_at'])}',
                              AppColors.danger,
                              icon: Icons.event_busy_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizDetailsPanel extends ConsumerStatefulWidget {
  const _QuizDetailsPanel({
    required this.quizId,
    required this.subjects,
    required this.onChanged,
    required this.onEdit,
  });

  final int quizId;
  final List<Map<String, dynamic>> subjects;
  final VoidCallback onChanged;
  final Future<void> Function(_Json details) onEdit;

  @override
  ConsumerState<_QuizDetailsPanel> createState() => _QuizDetailsPanelState();
}

class _QuizDetailsPanelState extends ConsumerState<_QuizDetailsPanel> {
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _busy = false;
  final Set<int> _expandedModels = {};

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/quizzes/${widget.quizId}');
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  Future<void> _action(
    String path,
    String success, {
    Map<String, dynamic>? data,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (data == null) {
        await ref.read(staffRepositoryProvider).patch(path, {});
      } else {
        await ref.read(staffRepositoryProvider).post(path, data);
      }
      if (!mounted) return;
      _reload();
      widget.onChanged();
      _docSnack(context, success, color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف الكويز',
      message: 'هل تريد حذف هذا الكويز؟',
      confirmLabel: 'حذف',
      color: AppColors.danger,
      icon: Icons.delete_rounded,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/quizzes/${widget.quizId}');
      if (!mounted) return;
      Navigator.pop(context);
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _results() async {
    context.push(DoctorQuizResultsScreen.path(widget.quizId));
    /*
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'نتائج الكويز',
      icon: Icons.analytics_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _QuizResultsPanel(quizId: widget.quizId),
    );
    */
  }

  Future<void> _shareResults(String visibility) {
    return _action(
      '/doctor/quizzes/${widget.quizId}/share-results',
      'تم تحديث ظهور النتائج.',
      data: {'visibility': visibility},
    );
  }

  Widget _buildBentoMetricCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsVisibilityChips({
    required String current,
    required ValueChanged<String> onChanged,
  }) {
    final choices = [
      {
        'value': 'hidden',
        'label': 'مخفية للكل',
        'icon': Icons.visibility_off_rounded,
        'color': AppColors.danger,
      },
      {
        'value': 'individual',
        'label': 'فردية للطلاب',
        'icon': Icons.person_rounded,
        'color': AppColors.warning,
      },
      {
        'value': 'public',
        'label': 'عامة للجميع',
        'icon': Icons.public_rounded,
        'color': AppColors.success,
      },
    ];

    return Row(
      children: choices.map((choice) {
        final val = choice['value'] as String;
        final label = choice['label'] as String;
        final icon = choice['icon'] as IconData;
        final color = choice['color'] as Color;
        final isSelected = current == val;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              avatar: Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : color,
              ),
              selectedColor: color,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? Colors.transparent : AppColors.slate200,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              labelPadding: EdgeInsets.zero,
              label: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.slate700,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && val != current) {
                  onChanged(val);
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
  }) {
    final isDisabled = onPressed == null;
    final buttonColor = isDisabled ? AppColors.slate300 : color;

    if (filled) {
      return SizedBox(
        height: 44,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
            disabledBackgroundColor: AppColors.slate100,
            disabledForegroundColor: AppColors.slate400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          disabledForegroundColor: AppColors.slate400,
          side: BorderSide(
            color: isDisabled
                ? AppColors.slate200
                : color.withValues(alpha: 0.5),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /*
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final quiz = _docMap(data['quiz']);
        final stats = _docMap(data['stats']);
        final models = _docList(quiz['models']);
        final canEditContent = _docBool(data['can_edit_content']);
        final status = _docText(quiz['status'], 'draft');
        final statusColor = _docStatusColor(status);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(_quizStatusIcon(status), color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docText(quiz['title'], 'كويز'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _quizTimerLabel(quiz),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docStatusLabel(status),
                  statusColor,
                  icon: _quizStatusIcon(status),
                ),
                _DocPill(
                  _quizTimerLabel(quiz),
                  AppColors.warning,
                  icon: Icons.timer_rounded,
                ),
                _DocPill(
                  _docText(quiz['results_visibility'], 'hidden'),
                  AppColors.royalBlue,
                  icon: Icons.visibility_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DocMetric(
                  label: 'المحاولات',
                  value: _docText(stats['total_attempts'], '0'),
                  color: AppColors.info,
                  icon: Icons.people_rounded,
                ),
                _DocMetric(
                  label: 'المتوسط',
                  value: _docText(stats['avg_score'], '0'),
                  color: AppColors.royalBlue,
                  icon: Icons.analytics_rounded,
                ),
                _DocMetric(
                  label: 'الأعلى',
                  value: _docText(stats['highest_score'], '0'),
                  color: AppColors.success,
                  icon: Icons.trending_up_rounded,
                ),
                _DocMetric(
                  label: 'الأدنى',
                  value: _docText(stats['lowest_score'], '0'),
                  color: AppColors.danger,
                  icon: Icons.trending_down_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InquiryMessageBlock(
              title: 'وصف الكويز',
              icon: Icons.notes_rounded,
              color: AppColors.royalBlue,
              text: _docText(quiz['description'], 'لا يوجد وصف.'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuizInfoCard(
                    label: 'الجدولة',
                    value: _docDate(quiz['scheduled_at']),
                    icon: Icons.event_available_rounded,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuizInfoCard(
                    label: 'الإغلاق',
                    value: _docDate(quiz['closes_at']),
                    icon: Icons.event_busy_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DocFilterPanel(
              title: 'نماذج الكويز',
              icon: Icons.view_module_rounded,
              children: [
                if (models.isEmpty)
                  const _DocEmpty('لا توجد نماذج مرتبطة بهذا الكويز.')
                else
                  ...models.map((model) {
                    final questions = _docList(model['questions']);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.slate100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.ballot_rounded,
                              color: AppColors.royalBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _docText(model['name'], 'نموذج'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.midnight,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${questions.length} سؤال • كود الدخول: ${_docText(model['access_code'], 'بدون')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 14),
            _DocFilterPanel(
              title: 'إجراءات الكويز',
              icon: Icons.tune_rounded,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy || status == 'published'
                          ? null
                          : () => _action(
                              '/doctor/quizzes/${widget.quizId}/publish',
                              'تم نشر الكويز.',
                            ),
                      icon: const Icon(Icons.public_rounded),
                      label: const Text('نشر'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy || status == 'closed'
                          ? null
                          : () => _action(
                              '/doctor/quizzes/${widget.quizId}/close',
                              'تم إغلاق الكويز.',
                            ),
                      icon: const Icon(Icons.lock_rounded),
                      label: const Text('إغلاق'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _results,
                      icon: const Icon(Icons.analytics_rounded),
                      label: const Text('النتائج'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => widget.onEdit(data),
                      icon: const Icon(Icons.edit_rounded),
                      label: Text(
                        canEditContent ? 'تعديل كامل' : 'تعديل الإعدادات',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _docText(quiz['results_visibility'], 'hidden'),
                  decoration: const InputDecoration(
                    labelText: 'ظهور النتائج',
                    prefixIcon: Icon(Icons.visibility_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'hidden', child: Text('مخفية')),
                    DropdownMenuItem(value: 'individual', child: Text('فردية')),
                    DropdownMenuItem(value: 'public', child: Text('عامة')),
                  ],
                  onChanged: (value) {
                    if (value != null) _shareResults(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
              label: const Text(
                'حذف الكويز',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );
    */

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final quiz = _docMap(data['quiz']);
        final stats = _docMap(data['stats']);
        final models = _docList(quiz['models']);
        final canEditContent = _docBool(data['can_edit_content']);
        final status = _docText(quiz['status'], 'draft');
        final statusColor = _docStatusColor(status);

        final darkenColor = HSLColor.fromColor(statusColor)
            .withLightness(
              (HSLColor.fromColor(statusColor).lightness - 0.12).clamp(
                0.0,
                1.0,
              ),
            )
            .toColor();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.85),
                    darkenColor.withValues(alpha: 0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      _quizStatusIcon(status),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docText(quiz['title'], 'كويز'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _quizTimerLabel(quiz),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Cairo',
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docStatusLabel(status),
                  statusColor,
                  icon: _quizStatusIcon(status),
                ),
                _DocPill(
                  _quizTimerLabel(quiz),
                  AppColors.warning,
                  icon: Icons.timer_rounded,
                ),
                _DocPill(
                  _docText(
                    quiz['results_visibility'] == 'hidden'
                        ? 'النتائج مخفية'
                        : quiz['results_visibility'] == 'individual'
                        ? 'نتائج فردية'
                        : 'نتائج عامة',
                    'النتائج مخفية',
                  ),
                  AppColors.royalBlue,
                  icon: Icons.visibility_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildBentoMetricCard(
                    label: 'المحاولات',
                    value: _docText(stats['total_attempts'], '0'),
                    color: AppColors.info,
                    icon: Icons.people_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoMetricCard(
                    label: 'المتوسط',
                    value: _docText(stats['avg_score'], '0'),
                    color: AppColors.royalBlue,
                    icon: Icons.analytics_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBentoMetricCard(
                    label: 'الأعلى',
                    value: _docText(stats['highest_score'], '0'),
                    color: AppColors.success,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoMetricCard(
                    label: 'الأدنى',
                    value: _docText(stats['lowest_score'], '0'),
                    color: AppColors.danger,
                    icon: Icons.trending_down_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InquiryMessageBlock(
              title: 'وصف الكويز',
              icon: Icons.notes_rounded,
              color: AppColors.royalBlue,
              text: _docText(quiz['description'], 'لا يوجد وصف.'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuizInfoCard(
                    label: 'الجدولة',
                    value: _docDate(quiz['scheduled_at']),
                    icon: Icons.event_available_rounded,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuizInfoCard(
                    label: 'الإغلاق',
                    value: _docDate(quiz['closes_at']),
                    icon: Icons.event_busy_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DocFilterPanel(
              title: 'نماذج الكويز',
              icon: Icons.view_module_rounded,
              children: [
                if (models.isEmpty)
                  const _DocEmpty('لا توجد نماذج مرتبطة بهذا الكويز.')
                else
                  ...models.map((model) {
                    final modelId = _docInt(model['id']);
                    final questions = _docList(model['questions']);
                    final isExpanded = _expandedModels.contains(modelId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isExpanded
                              ? AppColors.royalBlue.withValues(alpha: 0.2)
                              : AppColors.slate200,
                          width: isExpanded ? 1.4 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isExpanded
                                ? AppColors.royalBlue.withValues(alpha: 0.05)
                                : AppColors.slate900.withValues(alpha: 0.02),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: PageStorageKey(modelId),
                          initiallyExpanded: isExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              if (expanded) {
                                _expandedModels.add(modelId);
                              } else {
                                _expandedModels.remove(modelId);
                              }
                            });
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? AppColors.royalBlue.withValues(alpha: 0.1)
                                  : AppColors.slate100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.ballot_rounded,
                              color: isExpanded
                                  ? AppColors.royalBlue
                                  : AppColors.slate600,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            _docText(model['name'], 'نموذج'),
                            style: const TextStyle(
                              color: AppColors.midnight,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          subtitle: Text(
                            '${questions.length} أسئلة • كود الدخول: ${_docText(model['access_code'], 'لا يوجد')}',
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          children: [
                            if (questions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: _DocEmpty(
                                  'لا توجد أسئلة في هذا النموذج.',
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: questions.asMap().entries.map((
                                    qEntry,
                                  ) {
                                    final qIdx = qEntry.key;
                                    final q = qEntry.value;
                                    final qText = _docText(q['question_text']);
                                    final qScore = _docText(q['score'], '1');
                                    final timeLimit = _docText(
                                      q['time_limit_seconds'],
                                    );
                                    final note = _docText(q['correction_note']);
                                    final source = _docText(q['info_source']);
                                    final options = _docList(q['options']);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.slate50,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: AppColors.slate200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 26,
                                                height: 26,
                                                decoration: BoxDecoration(
                                                  color: AppColors.royalBlue
                                                      .withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${qIdx + 1}',
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.royalBlue,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      qText,
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors.midnight,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 13,
                                                        fontFamily: 'Cairo',
                                                        height: 1.45,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.royalBlue
                                                          .withValues(
                                                            alpha: 0.08,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '$qScore درجة',
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors.royalBlue,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontFamily: 'Cairo',
                                                      ),
                                                    ),
                                                  ),
                                                  if (timeLimit.isNotEmpty &&
                                                      timeLimit != '0') ...[
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.warning
                                                            .withValues(
                                                              alpha: 0.08,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '$timeLimit ثانية',
                                                        style: const TextStyle(
                                                          color:
                                                              AppColors.warning,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontFamily: 'Cairo',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Column(
                                            children: options.map((opt) {
                                              final optText = _docText(
                                                opt['option_text'],
                                              );
                                              final isCorrect = _docBool(
                                                opt['is_correct'],
                                              );

                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isCorrect
                                                      ? AppColors.success
                                                            .withValues(
                                                              alpha: 0.08,
                                                            )
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isCorrect
                                                        ? AppColors.success
                                                              .withValues(
                                                                alpha: 0.35,
                                                              )
                                                        : AppColors.slate200,
                                                    width: isCorrect ? 1.2 : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isCorrect
                                                          ? Icons
                                                                .check_circle_rounded
                                                          : Icons
                                                                .radio_button_off_rounded,
                                                      color: isCorrect
                                                          ? AppColors.success
                                                          : AppColors.slate400,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        optText,
                                                        style: TextStyle(
                                                          color: isCorrect
                                                              ? AppColors
                                                                    .success
                                                              : AppColors
                                                                    .midnight,
                                                          fontWeight: isCorrect
                                                              ? FontWeight.w900
                                                              : FontWeight.w700,
                                                          fontSize: 12,
                                                          fontFamily: 'Cairo',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          if (note.isNotEmpty ||
                                              source.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Divider(
                                              color: AppColors.slate200,
                                              height: 1,
                                            ),
                                            const SizedBox(height: 8),
                                            if (note.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 4,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                      Icons.fact_check_rounded,
                                                      color:
                                                          AppColors.royalBlue,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        'ملاحظة التصحيح: $note',
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .slate600,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontFamily: 'Cairo',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (source.isNotEmpty)
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                    Icons.source_rounded,
                                                    color: AppColors.slate500,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'المصدر: $source',
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors.slate600,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontFamily: 'Cairo',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 14),
            _DocFilterPanel(
              title: 'إجراءات الكويز',
              icon: Icons.tune_rounded,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildActionButton(
                      onPressed: _busy || status == 'published'
                          ? null
                          : () => _action(
                              '/doctor/quizzes/${widget.quizId}/publish',
                              'تم نشر الكويز.',
                            ),
                      label: 'نشر',
                      icon: Icons.public_rounded,
                      color: AppColors.success,
                      filled: status != 'published',
                    ),
                    _buildActionButton(
                      onPressed: _busy || status == 'closed'
                          ? null
                          : () => _action(
                              '/doctor/quizzes/${widget.quizId}/close',
                              'تم إغلاق الكويز.',
                            ),
                      label: 'إغلاق',
                      icon: Icons.lock_rounded,
                      color: AppColors.danger,
                      filled: false,
                    ),
                    _buildActionButton(
                      onPressed: _results,
                      label: 'النتائج',
                      icon: Icons.analytics_rounded,
                      color: AppColors.royalBlue,
                      filled: false,
                    ),
                    _buildActionButton(
                      onPressed: () => widget.onEdit(data),
                      label: canEditContent ? 'تعديل كامل' : 'تعديل الإعدادات',
                      icon: Icons.edit_rounded,
                      color: AppColors.royalBlue,
                      filled: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'ظهور نتائج الكويز للطلاب',
                  style: TextStyle(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                _buildResultsVisibilityChips(
                  current: _docText(quiz['results_visibility'], 'hidden'),
                  onChanged: (value) => _shareResults(value),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.delete_forever_rounded, size: 20),
              label: const Text(
                'حذف هذا الكويز نهائياً',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuizInfoCard extends StatelessWidget {
  const _QuizInfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/*
class _QuizResultsPanel extends ConsumerStatefulWidget {
  const _QuizResultsPanel({required this.quizId});

  final int quizId;

  @override
  ConsumerState<_QuizResultsPanel> createState() => _QuizResultsPanelState();
}

class _QuizResultsPanelState extends ConsumerState<_QuizResultsPanel> {
  late final Future<Map<String, dynamic>> _future = ref
      .read(staffRepositoryProvider)
      .get('/doctor/quizzes/${widget.quizId}/results');
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(staffRepositoryProvider)
          .download('/doctor/quizzes/${widget.quizId}/results/export');
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName: 'quiz_results_${widget.quizId}.csv',
        section: 'QuizReports',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تصدير النتائج',
        message: 'تم حفظ الملف في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final attempts = _docList(data['attempts']);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نتائج المحاولات',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'راجع أداء الطلاب أو صدّر التقرير.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _exporting ? null : _export,
                    icon: const Icon(Icons.table_chart_rounded),
                    label: const Text('تصدير'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (attempts.isEmpty)
              const _DocEmpty('لا توجد محاولات بعد.')
            else
              ...attempts.map((attempt) {
                final student = _docMap(attempt['student']);
                final model = _docMap(attempt['quiz_model']);
                final percentage = _docNum(attempt['percentage']);
                final color = percentage >= 80
                    ? AppColors.success
                    : percentage >= 50
                    ? AppColors.warning
                    : AppColors.danger;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withValues(alpha: 0.14)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.045),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 21,
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person_rounded,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _docText(student['name'], 'طالب'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.midnight,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${_docText(student['student_number'], '-')} • ${_docText(model['name'], '-')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _DocPill(
                            '${_docText(attempt['percentage'], '0')}%',
                            color,
                            icon: Icons.percent_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DocPill(
                            'الدرجة ${_docText(attempt['score'], '0')} / ${_docText(attempt['max_score'], '0')}',
                            AppColors.success,
                            icon: Icons.grade_rounded,
                          ),
                          _DocPill(
                            'صحيح ${_docText(attempt['correct_count'], '0')}',
                            AppColors.royalBlue,
                            icon: Icons.check_circle_rounded,
                          ),
                          _DocPill(
                            'خاطئ ${_docText(attempt['wrong_count'], '0')}',
                            AppColors.danger,
                            icon: Icons.cancel_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
*/

class DoctorQuizResultsScreen extends ConsumerStatefulWidget {
  const DoctorQuizResultsScreen({super.key, required this.quizId});

  static const route = '/doctor/quizzes/:quizId/results';
  static String path(int quizId) => '/doctor/quizzes/$quizId/results';

  final int quizId;

  @override
  ConsumerState<DoctorQuizResultsScreen> createState() =>
      _DoctorQuizResultsScreenState();
}

class _DoctorQuizResultsScreenState
    extends ConsumerState<DoctorQuizResultsScreen> {
  late Future<Map<String, dynamic>> _future;
  bool _exporting = false;

  // Filter states
  String _searchQuery = '';
  String _selectedModel = 'الكل';
  String _selectedStatus = 'الكل'; // الكل, ممتاز, متوسط, ضعيف
  String _sortBy = 'date_desc'; // date_desc, date_asc, score_desc, score_asc

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = ref
        .read(staffRepositoryProvider)
        .get('/doctor/quizzes/${widget.quizId}/results');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(staffRepositoryProvider)
          .download('/doctor/quizzes/${widget.quizId}/results/export');
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName: 'quiz_results_${widget.quizId}.csv',
        section: 'QuizReports',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تصدير النتائج',
        message: 'تم حفظ الملف في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'ط';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return parts[0].isNotEmpty ? parts[0][0] : 'ط';
  }

  String _formatShortDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final parsed = DateTime.tryParse(dateStr.trim());
      if (parsed != null) {
        final local = parsed.toLocal();
        final day = local.day.toString().padLeft(2, '0');
        final month = local.month.toString().padLeft(2, '0');
        final year = local.year.toString();
        final hour = local.hour.toString().padLeft(2, '0');
        final minute = local.minute.toString().padLeft(2, '0');
        return '$day/$month/$year - $hour:$minute';
      }

      final parts = dateStr.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        final shortDate = dateParts.length >= 3
            ? '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}'
            : parts[0];
        final shortTime = timeParts.length >= 2
            ? '${timeParts[0]}:${timeParts[1]}'
            : parts[1];
        return '$shortDate - $shortTime';
      }
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildHeaderMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(double width, Map<String, dynamic> quiz) {
    final isNarrow = width < 600;

    final metaContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _docText(quiz['title'], 'نتائج الكويز'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            if (quiz['subject_name'] != null)
              _buildHeaderMeta(
                Icons.book_outlined,
                _docText(quiz['subject_name'], ''),
              ),
            if (quiz['level_name'] != null)
              _buildHeaderMeta(
                Icons.school_outlined,
                _docText(quiz['level_name'], ''),
              ),
            if (quiz['major_name'] != null)
              _buildHeaderMeta(
                Icons.account_balance_outlined,
                _docText(quiz['major_name'], ''),
              ),
          ],
        ),
      ],
    );

    final exportButton = FilledButton.icon(
      onPressed: _exporting ? null : _export,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: _exporting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : const Icon(Icons.table_chart_rounded, size: 16),
      label: const Text(
        'تصدير',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFamily: 'Cairo',
        ),
      ),
    );

    if (isNarrow) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: metaContent),
              ],
            ),
            const SizedBox(height: 16),
            exportButton,
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalBlue.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: metaContent),
            const SizedBox(width: 14),
            exportButton,
          ],
        ),
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStats(
    double width,
    int total,
    double avg,
    double high,
    double low,
  ) {
    final crossAxisCount = width > 750 ? 4 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: width > 750 ? 1.7 : 1.5,
      children: [
        _buildStatCard(
          title: 'إجمالي المحاولات',
          value: '$total',
          subtitle: 'طالب وطالبة',
          icon: Icons.people_alt_rounded,
          color: AppColors.royalBlue,
        ),
        _buildStatCard(
          title: 'متوسط الدرجات',
          value: '${avg.toStringAsFixed(1)}%',
          subtitle: 'معدل أداء الدفعة',
          icon: Icons.analytics_rounded,
          color: AppColors.success,
        ),
        _buildStatCard(
          title: 'أعلى درجة',
          value: '${high.toStringAsFixed(1)}%',
          subtitle: 'أعلى نسبة مسجلة',
          icon: Icons.trending_up_rounded,
          color: AppColors.primary,
        ),
        _buildStatCard(
          title: 'أقل درجة',
          value: '${low.toStringAsFixed(1)}%',
          subtitle: 'أدنى نسبة مسجلة',
          icon: Icons.trending_down_rounded,
          color: AppColors.danger,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String label,
    required ValueChanged<T?> onChanged,
    Map<T, String>? labels,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.slate500,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        filled: true,
        fillColor: AppColors.slate50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.slate200.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      icon: const Icon(
        Icons.arrow_drop_down_rounded,
        color: AppColors.slate500,
      ),
      items: items.map((T item) {
        final text = labels != null
            ? (labels[item] ?? item.toString())
            : item.toString();
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildFiltersPanel(BuildContext context, Set<String> models) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    final searchField = TextField(
      controller: _searchController,
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      decoration: InputDecoration(
        hintText: 'البحث عن طالب أو رقم جامعي...',
        hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate400),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.slate200.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );

    final modelFilter = _buildDropdown<String>(
      value: _selectedModel,
      items: models.toList(),
      label: 'النموذج',
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedModel = val;
          });
        }
      },
    );

    final statusFilter = _buildDropdown<String>(
      value: _selectedStatus,
      items: const ['الكل', 'ممتاز', 'متوسط', 'ضعيف'],
      label: 'التقدير',
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedStatus = val;
          });
        }
      },
    );

    final sortFilter = _buildDropdown<String>(
      value: _sortBy,
      items: const ['date_desc', 'date_asc', 'score_desc', 'score_asc'],
      labels: const {
        'date_desc': 'الأحدث تقديماً',
        'date_asc': 'الأقدم تقديماً',
        'score_desc': 'الأعلى درجة',
        'score_asc': 'الأقل درجة',
      },
      label: 'الترتيب',
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _sortBy = val;
          });
        }
      },
    );

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate200.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(flex: 3, child: searchField),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: modelFilter),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: statusFilter),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: sortFilter),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate200.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: modelFilter),
                const SizedBox(width: 8),
                Expanded(child: statusFilter),
              ],
            ),
            const SizedBox(height: 12),
            sortFilter,
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'نتائج الكويز',
      currentRoute: DoctorQuizzesScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);

          final data = _docMap(_docData(snapshot.data ?? const {}));
          final quiz = _docMap(data['quiz']);
          final attempts = _docList(data['attempts']);

          final stats = _docMap(data['stats']);
          final attemptPercentages = attempts
              .map(
                (attempt) => _docNum(_docMap(attempt)['percentage']).toDouble(),
              )
              .toList();
          final totalAttempts = _docInt(
            stats['total_attempts'],
            attempts.length,
          );
          final avgPct = stats.containsKey('avg_score')
              ? _docNum(stats['avg_score']).toDouble()
              : (attemptPercentages.isEmpty
                    ? 0.0
                    : attemptPercentages.reduce((a, b) => a + b) /
                          attemptPercentages.length);
          final highPct = stats.containsKey('highest_score')
              ? _docNum(stats['highest_score']).toDouble()
              : (attemptPercentages.isEmpty
                    ? 0.0
                    : attemptPercentages.reduce((a, b) => a > b ? a : b));
          final lowPct = stats.containsKey('lowest_score')
              ? _docNum(stats['lowest_score']).toDouble()
              : (attemptPercentages.isEmpty
                    ? 0.0
                    : attemptPercentages.reduce((a, b) => a < b ? a : b));

          // Collect models dynamically
          final models = {'الكل'};
          for (var a in attempts) {
            final model = _docMap(a['quiz_model']);
            final mName = _docText(model['name'], '');
            if (mName.isNotEmpty) {
              models.add(mName);
            }
          }

          // Filter and Sort attempts
          final filteredAttempts = attempts.where((attempt) {
            final student = _docMap(attempt['student']);
            final model = _docMap(attempt['quiz_model']);
            final name = _docText(student['name'], '').toLowerCase();
            final num = _docText(student['student_number'], '').toLowerCase();
            final modelName = _docText(model['name'], '');
            final percentage = _docNum(attempt['percentage']);

            // Search filter
            final query = _searchQuery.toLowerCase();
            if (query.isNotEmpty &&
                !name.contains(query) &&
                !num.contains(query)) {
              return false;
            }

            // Model filter
            if (_selectedModel != 'الكل' && modelName != _selectedModel) {
              return false;
            }

            // Status filter
            if (_selectedStatus != 'الكل') {
              if (_selectedStatus == 'ممتاز' && percentage < 80) {
                return false;
              }
              if (_selectedStatus == 'متوسط' &&
                  (percentage < 50 || percentage >= 80)) {
                return false;
              }
              if (_selectedStatus == 'ضعيف' && percentage >= 50) {
                return false;
              }
            }

            return true;
          }).toList();

          // Sort
          filteredAttempts.sort((a, b) {
            if (_sortBy == 'score_desc') {
              return _docNum(
                b['percentage'],
              ).compareTo(_docNum(a['percentage']));
            } else if (_sortBy == 'score_asc') {
              return _docNum(
                a['percentage'],
              ).compareTo(_docNum(b['percentage']));
            } else if (_sortBy == 'date_asc') {
              final da = _docText(a['submitted_at'], '');
              final db = _docText(b['submitted_at'], '');
              return da.compareTo(db);
            } else {
              // default date_desc
              final da = _docText(a['submitted_at'], '');
              final db = _docText(b['submitted_at'], '');
              return db.compareTo(da);
            }
          });

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadData();
              });
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header Card ---
                      _buildHeaderCard(width, quiz),

                      const SizedBox(height: 24),

                      // --- Bento Statistics Grid ---
                      _buildBentoStats(
                        width,
                        totalAttempts,
                        avgPct,
                        highPct,
                        lowPct,
                      ),

                      const SizedBox(height: 24),

                      // --- Filters and Controls Panel ---
                      _buildFiltersPanel(context, models),

                      const SizedBox(height: 24),

                      // --- Table Header / Title Row ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'نتائج الطلاب (${filteredAttempts.length} من $totalAttempts)',
                            style: const TextStyle(
                              color: AppColors.midnight,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (filteredAttempts.length < totalAttempts)
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedModel = 'الكل';
                                  _selectedStatus = 'الكل';
                                  _sortBy = 'date_desc';
                                });
                              },
                              icon: const Icon(
                                Icons.restart_alt_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'إعادة تعيين الفلاتر',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // --- List of attempts ---
                      if (filteredAttempts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: _DocEmpty(
                            'لا توجد نتائج تطابق الفلاتر المحددة.',
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredAttempts.length,
                          itemBuilder: (context, index) {
                            final attempt = filteredAttempts[index];
                            final student = _docMap(attempt['student']);
                            final model = _docMap(attempt['quiz_model']);
                            final percentage = _docNum(attempt['percentage']);
                            final color = percentage >= 80
                                ? AppColors.success
                                : percentage >= 50
                                ? AppColors.warning
                                : AppColors.danger;

                            final duration = attempt['duration'] != null
                                ? '${_docText(attempt['duration'], '')} دقيقة'
                                : null;
                            final submittedAt = _docText(
                              attempt['submitted_at_label'],
                              _docText(attempt['submitted_at']),
                            );
                            final formattedDate = submittedAt.isNotEmpty
                                ? _formatShortDate(submittedAt)
                                : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: color.withValues(
                                          alpha: 0.1,
                                        ),
                                        child: Text(
                                          _getInitials(
                                            _docText(student['name'], 'طالب'),
                                          ),
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _docText(student['name'], 'طالب'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.midnight,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'رقم جامعي: ${_docText(student['student_number'], '-')}  •  ${_docText(model['name'], '-')}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.slate500,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _DocPill(
                                        '${_docText(attempt['percentage'], '0')}%',
                                        color,
                                        icon: Icons.percent_rounded,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(
                                    height: 1,
                                    color: AppColors.slate100,
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _DocPill(
                                        'الدرجة ${_docText(attempt['score'], '0')} / ${_docText(attempt['max_score'], '0')}',
                                        AppColors.success,
                                        icon: Icons.grade_rounded,
                                      ),
                                      _DocPill(
                                        'صحيح ${_docText(attempt['correct_count'], '0')}',
                                        AppColors.royalBlue,
                                        icon: Icons.check_circle_rounded,
                                      ),
                                      _DocPill(
                                        'خاطئ ${_docText(attempt['wrong_count'], '0')}',
                                        AppColors.danger,
                                        icon: Icons.cancel_rounded,
                                      ),
                                      if (duration != null)
                                        _DocPill(
                                          duration,
                                          AppColors.slate600,
                                          icon: Icons.timer_outlined,
                                        ),
                                      if (formattedDate != null &&
                                          formattedDate.isNotEmpty)
                                        _DocPill(
                                          formattedDate,
                                          AppColors.slate600,
                                          icon: Icons.calendar_today_rounded,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _QuizFormSheet extends ConsumerStatefulWidget {
  const _QuizFormSheet({
    required this.subjects,
    required this.onSaved,
    this.quizDetails,
  });

  final List<Map<String, dynamic>> subjects;
  final _Json? quizDetails;
  final VoidCallback onSaved;

  @override
  ConsumerState<_QuizFormSheet> createState() => _QuizFormSheetState();
}

class _QuizFormSheetState extends ConsumerState<_QuizFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _timeLimit = TextEditingController(text: '30');
  final _scheduledAt = TextEditingController();
  final _closesAt = TextEditingController();
  final List<_QuizModelDraft> _models = [];
  int? _subjectId;
  String _timerMode = 'quiz';
  String _resultsVisibility = 'hidden';
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;
  bool _showCorrectAnswers = false;
  bool _showCorrectionNotes = true;
  bool _notifyStudents = false;
  bool _showCountdown = true;
  bool _useAccessCode = false;
  bool _saving = false;
  bool _canEditContent = true;

  _Json? get _quiz => _docMap(widget.quizDetails?['quiz']);

  @override
  void initState() {
    super.initState();
    final quiz = _quiz;
    if (quiz != null && quiz.isNotEmpty) {
      _subjectId = _docInt(quiz['subject_id']);
      _title.text = _docText(quiz['title']);
      _description.text = _docText(quiz['description']);
      _timeLimit.text = _docText(quiz['time_limit_minutes'], '30');
      _timerMode = _docText(quiz['timer_mode'], 'quiz');
      _resultsVisibility = _docText(quiz['results_visibility'], 'hidden');
      _scheduledAt.text = _docDateTimeForInput(quiz['scheduled_at']);
      _closesAt.text = _docDateTimeForInput(quiz['closes_at']);
      _shuffleQuestions = _docBool(quiz['shuffle_questions']);
      _shuffleOptions = _docBool(quiz['shuffle_options']);
      _showCorrectAnswers = _docBool(quiz['show_correct_answers']);
      _showCorrectionNotes = _docBool(quiz['show_correction_notes']);
      _notifyStudents = _docBool(quiz['notify_students']);
      _showCountdown = _docBool(quiz['show_countdown']);
      _canEditContent = _docBool(widget.quizDetails?['can_edit_content']);
      final models = _docList(quiz['models']);
      _models.addAll(models.map(_QuizModelDraft.fromJson));
      _useAccessCode = models.any(
        (model) => _docText(model['access_code']).isNotEmpty,
      );
    } else {
      _subjectId = widget.subjects.isEmpty
          ? null
          : _docInt(widget.subjects.first['id']);
      _models.add(_QuizModelDraft.empty());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _timeLimit.dispose();
    _scheduledAt.dispose();
    _closesAt.dispose();
    for (final model in _models) {
      model.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DocFilterPanel(
            title: 'البيانات الأساسية',
            icon: Icons.assignment_rounded,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _subjectId,
                isExpanded: true,
                decoration: _quizInputDecoration(
                  'المادة',
                  Icons.menu_book_rounded,
                ),
                items: widget.subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: _docInt(subject['id']),
                        child: Text(_docText(subject['name'])),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _subjectId = value),
                validator: (value) => value == null ? 'اختر المادة.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: _quizInputDecoration(
                  'عنوان الكويز',
                  Icons.title_rounded,
                ),
                validator: (value) =>
                    _docText(value).isEmpty ? 'اكتب عنوان الكويز.' : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: _quizInputDecoration(
                  'الوصف',
                  Icons.notes_rounded,
                  alignLabel: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DocFilterPanel(
            title: 'التوقيت والظهور',
            icon: Icons.timer_rounded,
            children: [
              _DocSegmentFilter(
                value: _timerMode,
                onChanged: (value) => setState(() => _timerMode = value),
                choices: const [
                  _DocFilterChoice(
                    value: 'quiz',
                    label: 'وقت عام',
                    icon: Icons.timer_rounded,
                    color: AppColors.royalBlue,
                  ),
                  _DocFilterChoice(
                    value: 'per_question',
                    label: 'لكل سؤال',
                    icon: Icons.av_timer_rounded,
                    color: AppColors.warning,
                  ),
                ],
              ),
              if (_timerMode == 'quiz') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timeLimit,
                  keyboardType: TextInputType.number,
                  scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 160,
                  ),
                  decoration: _quizInputDecoration(
                    'مدة الاختبار بالدقائق',
                    Icons.schedule_rounded,
                  ),
                  validator: (value) => int.tryParse(_docText(value)) == null
                      ? 'اكتب مدة صحيحة.'
                      : null,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _scheduledAt,
                      readOnly: true,
                      onTap: () async {
                        final current =
                            DateTime.tryParse(_scheduledAt.text.trim()) ??
                            DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: current,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date == null) return;
                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(current),
                        );
                        if (time == null) return;
                        if (!mounted) return;
                        setState(() {
                          _scheduledAt.text = _docDateTimeForApi(
                            DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        });
                      },
                      decoration:
                          _quizInputDecoration(
                            'تاريخ البدء',
                            Icons.event_available_rounded,
                          ).copyWith(
                            hintText: 'النشر فوراً',
                            suffixIcon: _scheduledAt.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: AppColors.danger,
                                    ),
                                    onPressed: () =>
                                        setState(() => _scheduledAt.clear()),
                                  )
                                : const Icon(Icons.calendar_month_rounded),
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _closesAt,
                      readOnly: true,
                      onTap: () async {
                        final current =
                            DateTime.tryParse(_closesAt.text.trim()) ??
                            DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: current,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date == null) return;
                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(current),
                        );
                        if (time == null) return;
                        if (!mounted) return;
                        setState(() {
                          _closesAt.text = _docDateTimeForApi(
                            DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        });
                      },
                      decoration:
                          _quizInputDecoration(
                            'تاريخ الإغلاق',
                            Icons.event_busy_rounded,
                          ).copyWith(
                            hintText: 'غير محدد',
                            suffixIcon: _closesAt.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: AppColors.danger,
                                    ),
                                    onPressed: () =>
                                        setState(() => _closesAt.clear()),
                                  )
                                : const Icon(Icons.calendar_month_rounded),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _resultsVisibility,
                decoration: _quizInputDecoration(
                  'ظهور النتائج',
                  Icons.visibility_rounded,
                ),
                items: const [
                  DropdownMenuItem(value: 'hidden', child: Text('مخفية')),
                  DropdownMenuItem(value: 'individual', child: Text('فردية')),
                  DropdownMenuItem(value: 'public', child: Text('عامة')),
                ],
                onChanged: (value) =>
                    setState(() => _resultsVisibility = value ?? 'hidden'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DocFilterPanel(
            title: 'خيارات التشغيل',
            icon: Icons.settings_rounded,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuizSwitch(
                    label: 'كود دخول',
                    value: _useAccessCode,
                    onChanged: (v) => setState(() => _useAccessCode = v),
                  ),
                  _QuizSwitch(
                    label: 'خلط الأسئلة',
                    value: _shuffleQuestions,
                    onChanged: (v) => setState(() => _shuffleQuestions = v),
                  ),
                  _QuizSwitch(
                    label: 'خلط الخيارات',
                    value: _shuffleOptions,
                    onChanged: (v) => setState(() => _shuffleOptions = v),
                  ),
                  _QuizSwitch(
                    label: 'إظهار الصحيح',
                    value: _showCorrectAnswers,
                    onChanged: (v) => setState(() => _showCorrectAnswers = v),
                  ),
                  _QuizSwitch(
                    label: 'ملاحظات التصحيح',
                    value: _showCorrectionNotes,
                    onChanged: (v) => setState(() => _showCorrectionNotes = v),
                  ),
                  _QuizSwitch(
                    label: 'إشعار الطلاب',
                    value: _notifyStudents,
                    onChanged: (v) => setState(() => _notifyStudents = v),
                  ),
                  _QuizSwitch(
                    label: 'إظهار العداد',
                    value: _showCountdown,
                    onChanged: (v) => setState(() => _showCountdown = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!_canEditContent)
            const _DocEmpty(
              'لا يمكن تعديل الأسئلة بعد وجود محاولات. يمكنك تعديل الإعدادات فقط.',
            )
          else ...[
            _DocFilterPanel(
              title: 'النماذج والأسئلة',
              icon: Icons.schema_rounded,
              children: [
                ..._models.asMap().entries.map(
                  (entry) => _QuizModelEditor(
                    index: entry.key,
                    model: entry.value,
                    timerMode: _timerMode,
                    useAccessCode: _useAccessCode,
                    onDelete: _models.length == 1
                        ? null
                        : () => setState(() {
                            _models.removeAt(entry.key).dispose();
                          }),
                  ),
                ),
                InkWell(
                  onTap: () =>
                      setState(() => _models.add(_QuizModelDraft.empty())),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_rounded),
                        SizedBox(width: 8),
                        Text(
                          'إضافة نموذج جديد',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.slate100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _quiz == null || _quiz!.isEmpty
                      ? 'حفظ إعدادات الكويز'
                      : 'حفظ تعديلات الكويز',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true || _subjectId == null) return;
    if (_canEditContent && !_validateModels()) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'subject_id': _subjectId,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'timer_mode': _timerMode,
        'time_limit_minutes': _timerMode == 'quiz'
            ? int.tryParse(_timeLimit.text.trim())
            : null,
        'shuffle_questions': _shuffleQuestions,
        'shuffle_options': _shuffleOptions,
        'show_correct_answers': _showCorrectAnswers,
        'show_correction_notes': _showCorrectionNotes,
        'notify_students': _notifyStudents,
        'show_countdown': _showCountdown,
        'use_access_code': _useAccessCode,
        'results_visibility': _resultsVisibility,
        if (_scheduledAt.text.trim().isNotEmpty)
          'scheduled_at': _scheduledAt.text.trim(),
        if (_closesAt.text.trim().isNotEmpty)
          'closes_at': _closesAt.text.trim(),
        if (_canEditContent)
          'models': _models
              .map((model) => model.toPayload(_timerMode))
              .toList(),
      };
      final quiz = _quiz;
      if (quiz == null || quiz.isEmpty) {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/quizzes', payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('/doctor/quizzes/${quiz['id']}', payload);
      }
      if (!mounted) return;
      widget.onSaved();
      Navigator.pop(context);
      _docSnack(context, 'تم حفظ الكويز.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _validateModels() {
    for (var modelIndex = 0; modelIndex < _models.length; modelIndex++) {
      final model = _models[modelIndex];
      final modelName = model.name.text.trim();
      final modelLabel = modelName.isEmpty
          ? 'النموذج ${modelIndex + 1}'
          : modelName;

      if (modelName.isEmpty) {
        _quizValidationError('اكتب اسم النموذج رقم ${modelIndex + 1}.');
        return false;
      }

      if (model.questions.isEmpty) {
        _quizValidationError('أضف سؤالًا واحدًا على الأقل في $modelLabel.');
        return false;
      }

      if (_useAccessCode && model.accessCode.text.trim().isEmpty) {
        _quizValidationError('اكتب كود الدخول الخاص بـ $modelLabel.');
        return false;
      }

      for (
        var questionIndex = 0;
        questionIndex < model.questions.length;
        questionIndex++
      ) {
        final question = model.questions[questionIndex];
        final questionLabel = 'السؤال ${questionIndex + 1} في $modelLabel';
        final score = num.tryParse(question.score.text.trim());

        if (question.question.text.trim().isEmpty) {
          _quizValidationError('اكتب نص $questionLabel.');
          return false;
        }

        if (score == null || score <= 0) {
          _quizValidationError(
            'اكتب درجة صحيحة أكبر من صفر في $questionLabel.',
          );
          return false;
        }

        if (question.options.length < 2) {
          _quizValidationError('$questionLabel يحتاج خيارين على الأقل.');
          return false;
        }

        for (
          var optionIndex = 0;
          optionIndex < question.options.length;
          optionIndex++
        ) {
          if (question.options[optionIndex].text.text.trim().isEmpty) {
            _quizValidationError(
              'اكتب نص الخيار ${optionIndex + 1} في $questionLabel.',
            );
            return false;
          }
        }

        final correctCount = question.options
            .where((option) => option.isCorrect)
            .length;
        if (correctCount == 0) {
          _quizValidationError('حدد إجابة صحيحة في $questionLabel.');
          return false;
        }

        if (correctCount > 1) {
          _quizValidationError('اختر إجابة صحيحة واحدة فقط في $questionLabel.');
          return false;
        }

        if (_timerMode == 'per_question') {
          final timeLimit = int.tryParse(question.timeLimit.text.trim());
          if (timeLimit == null || timeLimit <= 0) {
            _quizValidationError('اكتب وقت $questionLabel بالثواني.');
            return false;
          }
        }
      }
    }
    return true;
  }

  void _quizValidationError(String message) {
    _docSnack(context, message, color: AppColors.warning);
  }
}

class _QuizSwitch extends StatelessWidget {
  const _QuizSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: value
              ? AppColors.royalBlue.withValues(alpha: 0.11)
              : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: value ? AppColors.royalBlue : AppColors.slate200,
            width: value ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_rounded : Icons.circle_outlined,
              size: 16,
              color: value ? AppColors.royalBlue : AppColors.slate500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? AppColors.royalBlue : AppColors.slate600,
                fontSize: 12,
                fontWeight: value ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizModelEditor extends StatefulWidget {
  const _QuizModelEditor({
    required this.index,
    required this.model,
    required this.timerMode,
    required this.useAccessCode,
    required this.onDelete,
  });

  final int index;
  final _QuizModelDraft model;
  final String timerMode;
  final bool useAccessCode;
  final VoidCallback? onDelete;

  @override
  State<_QuizModelEditor> createState() => _QuizModelEditorState();
}

class _QuizModelEditorState extends State<_QuizModelEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نموذج ${widget.index + 1}',
                      style: const TextStyle(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.model.questions.length} سؤال في هذا النموذج',
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onDelete != null)
                Tooltip(
                  message: 'حذف النموذج',
                  child: IconButton.filledTonal(
                    onPressed: widget.onDelete,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.delete_rounded),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: widget.model.name,
            decoration: _quizInputDecoration(
              'اسم النموذج',
              Icons.bookmark_rounded,
            ),
          ),
          if (widget.useAccessCode) ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.model.accessCode,
              decoration: _quizInputDecoration(
                'كود الدخول للنموذج',
                Icons.password_rounded,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ...widget.model.questions.asMap().entries.map(
            (entry) => _QuizQuestionEditor(
              index: entry.key,
              question: entry.value,
              timerMode: widget.timerMode,
              onDelete: widget.model.questions.length == 1
                  ? null
                  : () => setState(() {
                      widget.model.questions.removeAt(entry.key).dispose();
                    }),
            ),
          ),
          InkWell(
            onTap: () => setState(
              () => widget.model.questions.add(_QuizQuestionDraft.empty()),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'إضافة سؤال داخل النموذج',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizQuestionEditor extends StatefulWidget {
  const _QuizQuestionEditor({
    required this.index,
    required this.question,
    required this.timerMode,
    required this.onDelete,
  });

  final int index;
  final _QuizQuestionDraft question;
  final String timerMode;
  final VoidCallback? onDelete;

  @override
  State<_QuizQuestionEditor> createState() => _QuizQuestionEditorState();
}

class _QuizQuestionEditorState extends State<_QuizQuestionEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.help_rounded,
                  color: AppColors.royalBlue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سؤال ${widget.index + 1}',
                      style: const TextStyle(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.question.type == 'true_false'
                          ? 'صح أو خطأ'
                          : 'اختيار من متعدد',
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onDelete != null)
                Tooltip(
                  message: 'حذف السؤال',
                  child: IconButton(
                    onPressed: widget.onDelete,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.delete_rounded),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.question.question,
            maxLines: 3,
            decoration: _quizInputDecoration(
              'نص السؤال',
              Icons.edit_note_rounded,
              alignLabel: true,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: widget.question.type,
            isExpanded: true,
            decoration: _quizInputDecoration(
              'نوع السؤال',
              Icons.category_rounded,
            ),
            items: const [
              DropdownMenuItem(
                value: 'multiple_choice',
                child: Text('اختيار من متعدد'),
              ),
              DropdownMenuItem(value: 'true_false', child: Text('صح/خطأ')),
            ],
            onChanged: (value) => setState(() {
              widget.question.type = value ?? 'multiple_choice';
              if (widget.question.type == 'true_false') {
                widget.question.setTrueFalseOptions();
              }
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.question.score,
                  keyboardType: TextInputType.number,
                  scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 160,
                  ),
                  decoration: _quizInputDecoration(
                    'الدرجة',
                    Icons.grade_rounded,
                  ),
                ),
              ),
              if (widget.timerMode == 'per_question') ...[
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: widget.question.timeLimit,
                    keyboardType: TextInputType.number,
                    decoration: _quizInputDecoration(
                      'الوقت (ثواني)',
                      Icons.av_timer_rounded,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.question.correctionNote,
            decoration: _quizInputDecoration(
              'ملاحظة التصحيح',
              Icons.fact_check_rounded,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.question.infoSource,
            decoration: _quizInputDecoration(
              'مصدر المعلومة',
              Icons.source_rounded,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'الخيارات والإجابة الصحيحة',
            style: TextStyle(
              color: AppColors.slate700,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.question.options.asMap().entries.map((entry) {
            final option = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: option.isCorrect
                    ? AppColors.success.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: option.isCorrect
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.slate100,
                ),
              ),
              child: Row(
                children: [
                  Tooltip(
                    message: 'تحديد كإجابة صحيحة',
                    child: IconButton(
                      onPressed: () => setState(() {
                        for (final item in widget.question.options) {
                          item.isCorrect = false;
                        }
                        option.isCorrect = true;
                      }),
                      icon: Icon(
                        option.isCorrect
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: option.isCorrect
                            ? AppColors.success
                            : AppColors.slate400,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: option.text,
                      readOnly: widget.question.type == 'true_false',
                      decoration: InputDecoration(
                        labelText: 'خيار ${entry.key + 1}',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  if (widget.question.type != 'true_false' &&
                      widget.question.options.length > 2)
                    IconButton(
                      onPressed: () => setState(() {
                        widget.question.options.removeAt(entry.key).dispose();
                      }),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            );
          }),
          if (widget.question.type != 'true_false')
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(
                  () => widget.question.options.add(_QuizOptionDraft.empty()),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة خيار'),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuizModelDraft {
  _QuizModelDraft({
    required this.name,
    required this.accessCode,
    required this.questions,
  });

  final TextEditingController name;
  final TextEditingController accessCode;
  final List<_QuizQuestionDraft> questions;

  factory _QuizModelDraft.empty() => _QuizModelDraft(
    name: TextEditingController(text: 'نموذج A'),
    accessCode: TextEditingController(),
    questions: [_QuizQuestionDraft.empty()],
  );

  factory _QuizModelDraft.fromJson(_Json json) => _QuizModelDraft(
    name: TextEditingController(text: _docText(json['name'])),
    accessCode: TextEditingController(text: _docText(json['access_code'])),
    questions: _docList(json['questions']).isEmpty
        ? [_QuizQuestionDraft.empty()]
        : _docList(json['questions']).map(_QuizQuestionDraft.fromJson).toList(),
  );

  Map<String, dynamic> toPayload(String timerMode) => {
    'name': name.text.trim(),
    'access_code': accessCode.text.trim(),
    'questions': questions
        .map((question) => question.toPayload(timerMode))
        .toList(),
  };

  void dispose() {
    name.dispose();
    accessCode.dispose();
    for (final question in questions) {
      question.dispose();
    }
  }
}

class _QuizQuestionDraft {
  _QuizQuestionDraft({
    required this.question,
    required this.score,
    required this.timeLimit,
    required this.correctionNote,
    required this.infoSource,
    required this.options,
    required this.type,
  });

  final TextEditingController question;
  final TextEditingController score;
  final TextEditingController timeLimit;
  final TextEditingController correctionNote;
  final TextEditingController infoSource;
  final List<_QuizOptionDraft> options;
  String type;

  factory _QuizQuestionDraft.empty() => _QuizQuestionDraft(
    question: TextEditingController(),
    score: TextEditingController(text: '1'),
    timeLimit: TextEditingController(text: '60'),
    correctionNote: TextEditingController(),
    infoSource: TextEditingController(),
    type: 'multiple_choice',
    options: [_QuizOptionDraft.empty(), _QuizOptionDraft.empty()],
  );

  factory _QuizQuestionDraft.fromJson(_Json json) => _QuizQuestionDraft(
    question: TextEditingController(text: _docText(json['question_text'])),
    score: TextEditingController(text: _docText(json['score'], '1')),
    timeLimit: TextEditingController(
      text: _docText(json['time_limit_seconds'], '60'),
    ),
    correctionNote: TextEditingController(
      text: _docText(json['correction_note']),
    ),
    infoSource: TextEditingController(text: _docText(json['info_source'])),
    type: _docText(json['question_type'], 'multiple_choice'),
    options: _docList(json['options']).isEmpty
        ? [_QuizOptionDraft.empty(), _QuizOptionDraft.empty()]
        : _docList(json['options']).map(_QuizOptionDraft.fromJson).toList(),
  );

  void setTrueFalseOptions() {
    for (final option in options) {
      option.dispose();
    }
    options
      ..clear()
      ..addAll([
        _QuizOptionDraft(
          text: TextEditingController(text: 'صح'),
          isCorrect: true,
        ),
        _QuizOptionDraft(
          text: TextEditingController(text: 'خطأ'),
          isCorrect: false,
        ),
      ]);
  }

  Map<String, dynamic> toPayload(String timerMode) => {
    'question_text': question.text.trim(),
    'question_type': type,
    'score': num.tryParse(score.text.trim()) ?? 1,
    if (timerMode == 'per_question')
      'time_limit_seconds': int.tryParse(timeLimit.text.trim()) ?? 60,
    'correction_note': correctionNote.text.trim(),
    'info_source': infoSource.text.trim(),
    'options': options.map((option) => option.toPayload()).toList(),
  };

  void dispose() {
    question.dispose();
    score.dispose();
    timeLimit.dispose();
    correctionNote.dispose();
    infoSource.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class _QuizOptionDraft {
  _QuizOptionDraft({required this.text, required this.isCorrect});

  final TextEditingController text;
  bool isCorrect;

  factory _QuizOptionDraft.empty() =>
      _QuizOptionDraft(text: TextEditingController(), isCorrect: false);

  factory _QuizOptionDraft.fromJson(_Json json) => _QuizOptionDraft(
    text: TextEditingController(text: _docText(json['option_text'])),
    isCorrect: _docBool(json['is_correct']),
  );

  Map<String, dynamic> toPayload() => {
    'option_text': text.text.trim(),
    'is_correct': isCorrect,
  };

  void dispose() => text.dispose();
}

InputDecoration _quizInputDecoration(
  String label,
  IconData icon, {
  bool alignLabel = false,
}) {
  return InputDecoration(
    labelText: label,
    alignLabelWithHint: alignLabel,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: AppColors.slate50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
    ),
  );
}
