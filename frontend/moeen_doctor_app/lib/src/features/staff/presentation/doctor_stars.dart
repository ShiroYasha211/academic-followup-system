part of 'staff_screens.dart';

class DoctorStarsScreen extends ConsumerStatefulWidget {
  const DoctorStarsScreen({super.key});

  static const route = '/doctor/stars';

  @override
  ConsumerState<DoctorStarsScreen> createState() => _DoctorStarsScreenV2State();
}

class _DoctorStarsScreenV2State extends ConsumerState<DoctorStarsScreen> {
  final _search = TextEditingController();
  final _amount = TextEditingController(text: '3');
  final _description = TextEditingController();
  int? _subjectId;
  int? _majorId;
  int? _levelId;
  bool _filtersExpanded = false;
  final Set<int> _selected = {};
  Map<int, String> _visibleStudentNames = {};
  late Future<Map<String, dynamic>> _future = _fetch();

  static const List<int> _quickAmounts = [1, 3, 5, 10];
  static const List<String> _quickReasons = [
    'مشاركة فعالة',
    'إجابة مميزة',
    'التزام بالحضور',
    'مساعدة الزملاء',
  ];

  @override
  void dispose() {
    _search.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get(
      '/doctor/stars',
      query: {
        if (_subjectId != null) 'subject_id': _subjectId,
        if (_majorId != null) 'major_id': _majorId,
        if (_levelId != null) 'level_id': _levelId,
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
        'per_page': 100,
      },
    );
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'منح النجوم',
      currentRoute: DoctorStarsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final data = _clinicalDataMap(snapshot.data ?? const {});
          final subjects = _docList(data['subjects']);
          final majors = _docList(data['majors']);
          final levels = _docList(data['levels']);
          final page = _docMap(data['students']);
          final students = _docList(page['data']);
          final total = _docInt(page['total'], students.length);
          _visibleStudentNames = {
            for (final student in students)
              _docInt(student['id']): _docText(student['name'], 'طالب'),
          };
          final selectedAmount = int.tryParse(_amount.text.trim()) ?? 0;
          final totalStars = selectedAmount * _selected.length;
          final hasFilters =
              _subjectId != null ||
              _majorId != null ||
              _levelId != null ||
              _search.text.trim().isNotEmpty;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    _selected.isEmpty ? 96 : 178,
                  ),
                  children: [
                    _StarGrantHeroV2(
                      totalStudents: total,
                      selectedCount: _selected.length,
                      totalStars: totalStars,
                    ),
                    const SizedBox(height: 16),
                    _StarSearchPanelV2(
                      search: _search,
                      subjects: subjects,
                      majors: majors,
                      levels: levels,
                      subjectId: _subjectId,
                      majorId: _majorId,
                      levelId: _levelId,
                      expanded: _filtersExpanded,
                      hasFilters: hasFilters,
                      onSearch: _reload,
                      onToggleExpanded: () => setState(
                        () => _filtersExpanded = !_filtersExpanded,
                      ),
                      onClearFilters: _clearStarFilters,
                      onSubjectChanged: (value) {
                        setState(() {
                          _subjectId = value;
                          _selected.clear();
                          _future = _fetch();
                        });
                      },
                      onMajorChanged: (value) {
                        setState(() {
                          _majorId = value;
                          _selected.clear();
                          _future = _fetch();
                        });
                      },
                      onLevelChanged: (value) {
                        setState(() {
                          _levelId = value;
                          _selected.clear();
                          _future = _fetch();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _StarGrantSetupV2(
                      amount: _amount,
                      description: _description,
                      quickAmounts: _quickAmounts,
                      quickReasons: _quickReasons,
                      onAmountChanged: () => setState(() {}),
                      onQuickAmount: (value) => setState(() {
                        _amount.text = value.toString();
                      }),
                      onQuickReason: (value) => setState(() {
                        _description.text = value;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _StarSelectionToolbarV2(
                      visibleCount: students.length,
                      selectedCount: _selected.length,
                      onSelectVisible: students.isEmpty
                          ? null
                          : () => setState(() {
                              _selected
                                ..clear()
                                ..addAll(students.map((s) => _docInt(s['id'])));
                            }),
                      onClear: _selected.isEmpty
                          ? null
                          : () => setState(_selected.clear),
                    ),
                    const SizedBox(height: 12),
                    if (students.isEmpty)
                      const _DocEmpty('لا يوجد طلاب مطابقون للفلاتر.')
                    else
                      ...students.map(
                        (student) => _StarStudentCardV2(
                          student: student,
                          selected: _selected.contains(_docInt(student['id'])),
                          onChanged: (selected) {
                            setState(() {
                              final id = _docInt(student['id']);
                              if (selected) {
                                _selected.add(id);
                              } else {
                                _selected.remove(id);
                              }
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (_selected.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: _StarBottomGrantBarV2(
                    selectedCount: _selected.length,
                    amount: selectedAmount,
                    totalStars: totalStars,
                    onGrant: _grantStars,
                    onClear: () => setState(_selected.clear),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _clearStarFilters() {
    setState(() {
      _subjectId = null;
      _majorId = null;
      _levelId = null;
      _search.clear();
      _selected.clear();
      _future = _fetch();
    });
  }

  Future<void> _grantStars() async {
    final parsed = int.tryParse(_amount.text.trim());
    if (parsed == null || parsed < 1 || parsed > 100) {
      _docSnack(
        context,
        'اكتب عدد نجوم من 1 إلى 100.',
        color: AppColors.warning,
      );
      return;
    }
    final selectedNames = _selected
        .map((id) => _visibleStudentNames[id])
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .take(5)
        .toList();
    final confirmationMessage = [
      'سيتم منح ${_selected.length} طالب/طلاب عدد $parsed نجمة لكل طالب.',
      'إجمالي النجوم: ${_selected.length * parsed}',
      if (selectedNames.isNotEmpty) 'الطلاب: ${selectedNames.join('، ')}',
      if (_selected.length > selectedNames.length)
        'و ${_selected.length - selectedNames.length} طالب آخر.',
      if (_description.text.trim().isNotEmpty)
        'السبب: ${_description.text.trim()}',
    ].join('\n');
    final confirmed = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد منح النجوم',
      message: confirmationMessage,
      confirmLabel: 'نعم، منح النجوم',
      cancelLabel: 'إلغاء',
      icon: Icons.stars_rounded,
      color: AppColors.goldDeep,
    );
    if (!confirmed) return;
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .post('/doctor/stars/grant', {
            'student_ids': _selected.toList(),
            'amount': parsed,
            if (_description.text.trim().isNotEmpty)
              'description': _description.text.trim(),
          });
      if (!mounted) return;
      _selected.clear();
      _description.clear();
      _reload();
      await showMoeenInfoDialog(
        context: context,
        title: 'تم منح النجوم',
        message: _docText(response['message'], 'تم منح النجوم بنجاح.'),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

// ignore: unused_element
class _DoctorStarsScreenState extends ConsumerState<DoctorStarsScreen> {
  final _search = TextEditingController();
  final _amount = TextEditingController(text: '1');
  final _description = TextEditingController();
  int? _subjectId;
  int? _majorId;
  int? _levelId;
  final Set<int> _selected = {};
  Map<int, String> _visibleStudentNames = {};
  late Future<Map<String, dynamic>> _future = _fetch();

  // ignore: unused_field
  static const List<int> _quickAmounts = [1, 3, 5, 10];
  // ignore: unused_field
  static const List<String> _quickReasons = [
    'مشاركة فعالة',
    'إجابة مميزة',
    'التزام بالحضور',
    'مساعدة الزملاء',
  ];

  @override
  void dispose() {
    _search.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/stars',
          query: {
            if (_subjectId != null) 'subject_id': _subjectId,
            if (_majorId != null) 'major_id': _majorId,
            if (_levelId != null) 'level_id': _levelId,
            if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
            'per_page': 100,
          },
        );
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'منح النجوم',
      currentRoute: DoctorStarsScreen.route,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selected.isEmpty ? null : _grantStars,
        icon: const Icon(Icons.stars_rounded),
        label: Text(
          _selected.isEmpty ? 'اختر طلاب' : 'منح ${_selected.length}',
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final data = _docMap(_docData(snapshot.data ?? const {}));
          final subjects = _docList(data['subjects']);
          final majors = _docList(data['majors']);
          final levels = _docList(data['levels']);
          final page = _docMap(data['students']);
          final students = _docList(page['data']);
          final total = _docInt(page['total'], students.length);
          _visibleStudentNames = {
            for (final student in students)
              _docInt(student['id']): _docText(student['name'], 'طالب'),
          };

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'منح النجوم',
                  subtitle:
                      'اختر طالبًا أو أكثر وامنحهم نقاط تحفيزية ضمن نطاق موادك.',
                  icon: Icons.stars_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: _selected.isEmpty ? null : _grantStars,
                    icon: const Icon(Icons.card_giftcard_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'طلاب متاحون',
                      value: total.toString(),
                      color: AppColors.royalBlue,
                      icon: Icons.groups_rounded,
                    ),
                    _DocMetric(
                      label: 'محدد',
                      value: _selected.length.toString(),
                      color: AppColors.success,
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _StarFilters(
                  search: _search,
                  subjects: subjects,
                  majors: majors,
                  levels: levels,
                  subjectId: _subjectId,
                  majorId: _majorId,
                  levelId: _levelId,
                  onSearch: _reload,
                  onSubjectChanged: (value) {
                    setState(() {
                      _subjectId = value;
                      _selected.clear();
                      _future = _fetch();
                    });
                  },
                  onMajorChanged: (value) {
                    setState(() {
                      _majorId = value;
                      _selected.clear();
                      _future = _fetch();
                    });
                  },
                  onLevelChanged: (value) {
                    setState(() {
                      _levelId = value;
                      _selected.clear();
                      _future = _fetch();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _StarGrantComposer(
                  amount: _amount,
                  description: _description,
                  selectedCount: _selected.length,
                  onGrant: _selected.isEmpty ? null : _grantStars,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: students.isEmpty
                            ? null
                            : () => setState(() {
                                _selected
                                  ..clear()
                                  ..addAll(
                                    students.map((s) => _docInt(s['id'])),
                                  );
                              }),
                        icon: const Icon(Icons.done_all_rounded),
                        label: const Text('تحديد الكل'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => setState(_selected.clear),
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text('مسح التحديد'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (students.isEmpty)
                  const _DocEmpty('لا يوجد طلاب مطابقون للفلاتر.')
                else
                  ...students.map(
                    (student) => _StarStudentCard(
                      student: student,
                      selected: _selected.contains(_docInt(student['id'])),
                      onChanged: (selected) {
                        setState(() {
                          final id = _docInt(student['id']);
                          if (selected) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        });
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

  Future<void> _grantStars() async {
    final parsed = int.tryParse(_amount.text.trim());
    if (parsed == null || parsed < 1 || parsed > 100) {
      _docSnack(
        context,
        'اكتب عدد نجوم من 1 إلى 100.',
        color: AppColors.warning,
      );
      return;
    }
    final selectedNames = _selected
        .map((id) => _visibleStudentNames[id])
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .take(4)
        .toList();
    final confirmationMessage = [
      'سيتم منح ${_selected.length} طالب/طلاب عدد $parsed نجمة.',
      if (selectedNames.isNotEmpty) 'الطلاب: ${selectedNames.join('، ')}',
      if (_selected.length > selectedNames.length)
        'و ${_selected.length - selectedNames.length} طالب آخر.',
      if (_description.text.trim().isNotEmpty)
        'السبب: ${_description.text.trim()}',
    ].join('\n');
    final confirmed = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد منح النجوم',
      message: confirmationMessage,
      confirmLabel: 'نعم، منح النجوم',
      cancelLabel: 'إلغاء',
      icon: Icons.stars_rounded,
      color: AppColors.goldDeep,
    );
    if (!confirmed) return;
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .post('/doctor/stars/grant', {
            'student_ids': _selected.toList(),
            'amount': parsed,
            if (_description.text.trim().isNotEmpty)
              'description': _description.text.trim(),
          });
      if (!mounted) return;
      _selected.clear();
      _description.clear();
      _reload();
      await showMoeenInfoDialog(
        context: context,
        title: 'تم منح النجوم',
        message: _docText(response['message'], 'تم منح النجوم بنجاح.'),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _StarGrantHeroV2 extends StatelessWidget {
  const _StarGrantHeroV2({
    required this.totalStudents,
    required this.selectedCount,
    required this.totalStars,
  });

  final int totalStudents;
  final int selectedCount;
  final int totalStars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4A03), Color(0xFFC77700), Color(0xFFFFB020)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -18,
            top: -22,
            child: Icon(
              Icons.stars_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'منح النجوم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'اختر الطلاب ثم راجع المنح قبل الإرسال.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StarHeroMetricV2(
                      label: 'المتاحون',
                      value: '$totalStudents',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StarHeroMetricV2(
                      label: 'المحددون',
                      value: '$selectedCount',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StarHeroMetricV2(
                      label: 'الإجمالي',
                      value: '$totalStars',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarHeroMetricV2 extends StatelessWidget {
  const _StarHeroMetricV2({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarSearchPanelV2 extends StatelessWidget {
  const _StarSearchPanelV2({
    required this.search,
    required this.subjects,
    required this.majors,
    required this.levels,
    required this.subjectId,
    required this.majorId,
    required this.levelId,
    required this.expanded,
    required this.hasFilters,
    required this.onSearch,
    required this.onToggleExpanded,
    required this.onClearFilters,
    required this.onSubjectChanged,
    required this.onMajorChanged,
    required this.onLevelChanged,
  });

  final TextEditingController search;
  final List<_Json> subjects;
  final List<_Json> majors;
  final List<_Json> levels;
  final int? subjectId;
  final int? majorId;
  final int? levelId;
  final bool expanded;
  final bool hasFilters;
  final VoidCallback onSearch;
  final VoidCallback onToggleExpanded;
  final VoidCallback onClearFilters;
  final ValueChanged<int?> onSubjectChanged;
  final ValueChanged<int?> onMajorChanged;
  final ValueChanged<int?> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'بحث باسم الطالب أو رقم القيد...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleExpanded,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue.withValues(alpha: 0.07),
                    foregroundColor: AppColors.midnight,
                    side: BorderSide(
                      color: AppColors.royalBlue.withValues(alpha: 0.16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: Icon(
                    expanded
                        ? Icons.tune_rounded
                        : Icons.filter_alt_outlined,
                  ),
                  label: Text(expanded ? 'إخفاء الفلاتر' : 'فلترة الطلاب'),
                ),
              ),
              const SizedBox(width: 8),
              if (hasFilters)
                IconButton.filledTonal(
                  onPressed: onClearFilters,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                    foregroundColor: AppColors.danger,
                    fixedSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  tooltip: 'مسح الفلاتر',
                ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _starDropdown(
                    label: 'التخصص',
                    value: majorId,
                    allLabel: 'كل التخصصات',
                    items: majors,
                    onChanged: onMajorChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _starDropdown(
                    label: 'المستوى',
                    value: levelId,
                    allLabel: 'كل المستويات',
                    items: levels,
                    onChanged: onLevelChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _starDropdown(
              label: 'المادة',
              value: subjectId,
              allLabel: 'كل المواد',
              items: subjects,
              onChanged: onSubjectChanged,
            ),
          ],
        ],
      ),
    );
  }

  DropdownButtonFormField<int?> _starDropdown({
    required String label,
    required int? value,
    required String allLabel,
    required List<_Json> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<int?>(value: null, child: Text(allLabel)),
        ...items.map(
          (item) => DropdownMenuItem<int?>(
            value: _docInt(item['id']),
            child: Text(_docText(item['name'])),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _StarGrantSetupV2 extends StatelessWidget {
  const _StarGrantSetupV2({
    required this.amount,
    required this.description,
    required this.quickAmounts,
    required this.quickReasons,
    required this.onAmountChanged,
    required this.onQuickAmount,
    required this.onQuickReason,
  });

  final TextEditingController amount;
  final TextEditingController description;
  final List<int> quickAmounts;
  final List<String> quickReasons;
  final VoidCallback onAmountChanged;
  final ValueChanged<int> onQuickAmount;
  final ValueChanged<String> onQuickReason;

  @override
  Widget build(BuildContext context) {
    final currentAmount = int.tryParse(amount.text.trim());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'إعداد المنح',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickAmounts.map((value) {
              return ChoiceChip(
                selected: currentAmount == value,
                showCheckmark: false,
                avatar: Icon(
                  Icons.stars_rounded,
                  size: 16,
                  color: currentAmount == value
                      ? Colors.white
                      : AppColors.warning,
                ),
                selectedColor: AppColors.warning,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: currentAmount == value
                      ? AppColors.warning
                      : AppColors.warning.withValues(alpha: 0.18),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                labelStyle: TextStyle(
                  color: currentAmount == value
                      ? Colors.white
                      : AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                label: Text('$value نجوم'),
                onSelected: (_) => onQuickAmount(value),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 116,
                child: TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onAmountChanged(),
                  decoration: const InputDecoration(
                    labelText: 'العدد',
                    prefixIcon: Icon(Icons.stars_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: description,
                  onChanged: (_) => onAmountChanged(),
                  decoration: const InputDecoration(
                    labelText: 'سبب المنح',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickReasons.map((reason) {
              return ActionChip(
                onPressed: () => onQuickReason(reason),
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.slate200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                labelStyle: const TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                avatar: const Icon(Icons.add_rounded, size: 16),
                label: Text(reason),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StarSelectionToolbarV2 extends StatelessWidget {
  const _StarSelectionToolbarV2({
    required this.visibleCount,
    required this.selectedCount,
    required this.onSelectVisible,
    required this.onClear,
  });

  final int visibleCount;
  final int selectedCount;
  final VoidCallback? onSelectVisible;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSelectVisible,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.success.withValues(alpha: 0.07),
              foregroundColor: AppColors.midnight,
              side: BorderSide(color: AppColors.success.withValues(alpha: 0.18)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.done_all_rounded),
            label: Text('تحديد الظاهرين ($visibleCount)'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.danger.withValues(alpha: 0.06),
              foregroundColor: AppColors.midnight,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.15)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.clear_rounded),
            label: Text(selectedCount == 0 ? 'مسح التحديد' : 'مسح ($selectedCount)'),
          ),
        ),
      ],
    );
  }
}

class _StarBottomGrantBarV2 extends StatelessWidget {
  const _StarBottomGrantBarV2({
    required this.selectedCount,
    required this.amount,
    required this.totalStars,
    required this.onGrant,
    required this.onClear,
  });

  final int selectedCount;
  final int amount;
  final int totalStars;
  final VoidCallback onGrant;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.11),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.stars_rounded, color: AppColors.warning),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$selectedCount طالب محدد',
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'لكل طالب $amount نجمة | الإجمالي $totalStars',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.slate100,
              foregroundColor: AppColors.slate600,
              fixedSize: const Size(42, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'مسح التحديد',
          ),
          FilledButton.icon(
            onPressed: onGrant,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.card_giftcard_rounded, size: 18),
            label: const Text('مراجعة'),
          ),
        ],
      ),
    );
  }
}

class _StarStudentCardV2 extends StatelessWidget {
  const _StarStudentCardV2({
    required this.student,
    required this.selected,
    required this.onChanged,
  });

  final _Json student;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final major = _docMap(student['major']);
    final level = _docMap(student['level']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.warning.withValues(alpha: 0.065)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? AppColors.warning.withValues(alpha: 0.34)
              : AppColors.slate100,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.045 : 0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: selected
                        ? AppColors.warning
                        : AppColors.warning.withValues(alpha: 0.12),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.person_rounded,
                      color: selected ? Colors.white : AppColors.warning,
                    ),
                  ),
                  PositionedDirectional(
                    end: -3,
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: AppColors.warning,
                        size: 14,
                      ),
                    ),
                  ),
                ],
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _DocPill(
                          _docText(student['student_number'], '-'),
                          AppColors.royalBlue,
                          icon: Icons.badge_rounded,
                        ),
                        _DocPill(
                          _docText(major['name'], 'التخصص غير محدد'),
                          AppColors.info,
                          icon: Icons.school_rounded,
                        ),
                        _DocPill(
                          _docText(level['name'], 'المستوى غير محدد'),
                          AppColors.success,
                          icon: Icons.layers_rounded,
                        ),
                        _DocPill(
                          '${_docText(student['stars_balance'], '0')} نجمة',
                          AppColors.warning,
                          icon: Icons.stars_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.warning : AppColors.slate300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StarFilters extends StatelessWidget {
  const _StarFilters({
    required this.search,
    required this.subjects,
    required this.majors,
    required this.levels,
    required this.subjectId,
    required this.majorId,
    required this.levelId,
    required this.onSearch,
    required this.onSubjectChanged,
    required this.onMajorChanged,
    required this.onLevelChanged,
  });

  final TextEditingController search;
  final List<Map<String, dynamic>> subjects;
  final List<_Json> majors;
  final List<_Json> levels;
  final int? subjectId;
  final int? majorId;
  final int? levelId;
  final VoidCallback onSearch;
  final ValueChanged<int?> onSubjectChanged;
  final ValueChanged<int?> onMajorChanged;
  final ValueChanged<int?> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          TextField(
            controller: search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'بحث باسم الطالب أو رقم القيد...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: majorId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'التخصص'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('كل التخصصات'),
                    ),
                    ...majors.map(
                      (major) => DropdownMenuItem<int?>(
                        value: _docInt(major['id']),
                        child: Text(_docText(major['name'])),
                      ),
                    ),
                  ],
                  onChanged: onMajorChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: levelId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'المستوى'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('كل المستويات'),
                    ),
                    ...levels.map(
                      (level) => DropdownMenuItem<int?>(
                        value: _docInt(level['id']),
                        child: Text(_docText(level['name'])),
                      ),
                    ),
                  ],
                  onChanged: onLevelChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: subjectId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المادة'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('كل المواد'),
              ),
              ...subjects.map(
                (subject) => DropdownMenuItem<int?>(
                  value: _docInt(subject['id']),
                  child: Text(_docText(subject['name'])),
                ),
              ),
            ],
            onChanged: onSubjectChanged,
          ),
        ],
      ),
    );
  }
}

class _StarGrantComposer extends StatelessWidget {
  const _StarGrantComposer({
    required this.amount,
    required this.description,
    required this.selectedCount,
    required this.onGrant,
  });

  final TextEditingController amount;
  final TextEditingController description;
  final int selectedCount;
  final VoidCallback? onGrant;

  @override
  Widget build(BuildContext context) {
    final active = selectedCount > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  active
                      ? 'سيتم منح النجوم إلى $selectedCount طالب'
                      : 'اختر طالبًا من القائمة لإرسال النجوم',
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'عدد النجوم',
                    prefixIcon: Icon(Icons.stars_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'سبب المنح',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onGrant,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.stars_rounded),
            label: const Text(
              'منح النجوم الآن',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarStudentCard extends StatelessWidget {
  const _StarStudentCard({
    required this.student,
    required this.selected,
    required this.onChanged,
  });

  final _Json student;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final major = _docMap(student['major']);
    final level = _docMap(student['level']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration().copyWith(
        color: selected
            ? AppColors.warning.withValues(alpha: 0.06)
            : Colors.white,
        border: Border.all(
          color: selected
              ? AppColors.warning.withValues(alpha: 0.34)
              : AppColors.slate100,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.warning.withValues(alpha: 0.12),
              child: const Icon(Icons.stars_rounded, color: AppColors.warning),
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _DocPill(
                        _docText(student['student_number'], '-'),
                        AppColors.royalBlue,
                        icon: Icons.badge_rounded,
                      ),
                      _DocPill(
                        _docText(major['name'], 'التخصص غير محدد'),
                        AppColors.info,
                        icon: Icons.school_rounded,
                      ),
                      _DocPill(
                        _docText(level['name'], 'المستوى غير محدد'),
                        AppColors.success,
                        icon: Icons.layers_rounded,
                      ),
                      _DocPill(
                        '${_docText(student['stars_balance'], '0')} نجمة',
                        AppColors.warning,
                        icon: Icons.stars_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.warning : AppColors.slate300,
            ),
          ],
        ),
      ),
    );
  }
}

