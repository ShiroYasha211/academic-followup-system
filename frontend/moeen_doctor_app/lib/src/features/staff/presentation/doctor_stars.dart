part of 'staff_screens.dart';

class DoctorStarsScreen extends ConsumerStatefulWidget {
  const DoctorStarsScreen({super.key});

  static const route = '/doctor/stars';

  @override
  ConsumerState<DoctorStarsScreen> createState() => _DoctorStarsScreenV3State();
}

class _DoctorStarsScreenV3State extends ConsumerState<DoctorStarsScreen> {
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
                    _selected.isEmpty ? 96 : 186,
                  ),
                  children: [
                    _StarGrantHeroV3(
                      totalStudents: total,
                      selectedCount: _selected.length,
                      totalStars: totalStars,
                    ),
                    const SizedBox(height: 16),
                    _StarSearchPanelV3(
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
                    const SizedBox(height: 16),
                    _StarGrantSetupV3(
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
                    const SizedBox(height: 16),
                    _StarSelectionToolbarV3(
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
                    const SizedBox(height: 16),
                    if (students.isEmpty)
                      const _DocEmpty('لا يوجد طلاب مطابقون للفلاتر.')
                    else
                      ...students.map(
                        (student) => _StarStudentCardV3(
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
                  bottom: 16,
                  child: _StarBottomGrantBarV3(
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
}

class _StarGrantHeroV3 extends StatelessWidget {
  const _StarGrantHeroV3({
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.royalBlueDark,
            AppColors.royalBlue,
            AppColors.goldDeep,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -28,
            top: -28,
            child: Icon(
              Icons.stars_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'منح النجوم للطلاب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'اختر الطلاب ثم قم بمراجعة وتأكيد منح النقاط التحفيزية.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _StarHeroMetricV3(
                      label: 'المتاحون',
                      value: '$totalStudents',
                      icon: Icons.groups_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StarHeroMetricV3(
                      label: 'المحددون',
                      value: '$selectedCount',
                      icon: Icons.check_circle_rounded,
                      activeColor: selectedCount > 0 ? AppColors.gold : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StarHeroMetricV3(
                      label: 'إجمالي المنح',
                      value: '$totalStars',
                      icon: Icons.stars_rounded,
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

class _StarHeroMetricV3 extends StatelessWidget {
  const _StarHeroMetricV3({
    required this.label,
    required this.value,
    required this.icon,
    this.activeColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: activeColor ?? Colors.white70,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: activeColor ?? Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _StarSearchPanelV3 extends StatelessWidget {
  const _StarSearchPanelV3({
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
    int activeFilterCount = 0;
    if (subjectId != null) activeFilterCount++;
    if (majorId != null) activeFilterCount++;
    if (levelId != null) activeFilterCount++;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: search,
            onSubmitted: (_) => onSearch(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
            decoration: InputDecoration(
              hintText: 'بحث باسم الطالب أو رقم القيد...',
              hintStyle: const TextStyle(
                color: AppColors.slate400,
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.royalBlue),
              filled: true,
              fillColor: AppColors.slate50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixIcon: search.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        search.clear();
                        onSearch();
                      },
                      icon: const Icon(Icons.clear_rounded, color: AppColors.slate500),
                    )
                  : IconButton(
                      onPressed: onSearch,
                      icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.royalBlue),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onToggleExpanded,
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: expanded
                          ? AppColors.royalBlue
                          : AppColors.royalBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: expanded
                            ? AppColors.royalBlue
                            : AppColors.royalBlue.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          expanded ? Icons.tune_rounded : Icons.filter_alt_outlined,
                          size: 18,
                          color: expanded ? Colors.white : AppColors.royalBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          expanded ? 'إخفاء الفلاتر المتقدمة' : 'فلترة مخصصة للطلاب',
                          style: TextStyle(
                            color: expanded ? Colors.white : AppColors.royalBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        if (activeFilterCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: expanded ? Colors.white : AppColors.royalBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$activeFilterCount',
                              style: TextStyle(
                                color: expanded ? AppColors.royalBlue : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: onClearFilters,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                    foregroundColor: AppColors.danger,
                    fixedSize: const Size(46, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
                  tooltip: 'مسح الفلاتر',
                ),
              ],
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _starDropdown(
                              label: 'التخصص الاكاديمي',
                              value: majorId,
                              allLabel: 'كل التخصصات',
                              items: majors,
                              onChanged: onMajorChanged,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _starDropdown(
                              label: 'المستوى الدراسي',
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
                        label: 'المادة المسجلة',
                        value: subjectId,
                        allLabel: 'كل المواد الدراسية',
                        items: subjects,
                        onChanged: onSubjectChanged,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _starDropdown({
    required String label,
    required int? value,
    required String allLabel,
    required List<_Json> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      isExpanded: true,
      style: const TextStyle(
        color: AppColors.midnight,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        fontFamily: 'Cairo',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.slate500,
          fontSize: 12,
          fontFamily: 'Cairo',
        ),
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.slate100),
        ),
      ),
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

class _StarGrantSetupV3 extends StatelessWidget {
  const _StarGrantSetupV3({
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.goldDeep.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldDeep.withValues(alpha: 0.03),
            blurRadius: 16,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.goldDeep.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.goldDeep,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'إعداد نقاط التحفيز والسبب',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickAmounts.map((value) {
              final isSelected = currentAmount == value;
              return InkWell(
                onTap: () => onQuickAmount(value),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.goldDeep : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldDeep
                          : AppColors.goldDeep.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : AppColors.goldDeep,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$value نجوم',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.midnight,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 104,
                child: TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onAmountChanged(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                  decoration: InputDecoration(
                    labelText: 'العدد',
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: const Icon(Icons.stars_rounded, color: AppColors.goldDeep),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.slate100),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: description,
                  onChanged: (_) => onAmountChanged(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                  ),
                  decoration: InputDecoration(
                    labelText: 'سبب التحفيز',
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.slate400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.slate100),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickReasons.map((reason) {
              return InkWell(
                onTap: () => onQuickReason(reason),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: AppColors.slate500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reason,
                        style: const TextStyle(
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StarSelectionToolbarV3 extends StatelessWidget {
  const _StarSelectionToolbarV3({
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
              backgroundColor: AppColors.success.withValues(alpha: 0.05),
              foregroundColor: AppColors.success,
              side: BorderSide(
                color: AppColors.success.withValues(alpha: 0.18),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: Text(
              'تحديد جميع الطلاب ($visibleCount)',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.danger.withValues(alpha: 0.05),
              foregroundColor: AppColors.danger,
              side: BorderSide(
                color: AppColors.danger.withValues(alpha: 0.15),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.clear_rounded, size: 18),
            label: Text(
              selectedCount == 0 ? 'إلغاء التحديد' : 'إلغاء ($selectedCount)',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StarStudentCardV3 extends StatelessWidget {
  const _StarStudentCardV3({
    required this.student,
    required this.selected,
    required this.onChanged,
  });

  final _Json student;
  final bool selected;
  final ValueChanged<bool> onChanged;

  String _getInitials(String name) {
    if (name.isEmpty) return 'ط';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    final major = _docMap(student['major']);
    final level = _docMap(student['level']);
    final name = _docText(student['name'], 'طالب');
    final initials = _getInitials(name);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.goldDeep.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? AppColors.goldDeep.withValues(alpha: 0.35)
              : AppColors.slate100,
          width: selected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppColors.goldDeep.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.goldDeep
                          : AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.royalBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: AppColors.goldDeep,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _DocPill(
                          _docText(student['student_number'], '-'),
                          AppColors.royalBlue,
                          icon: Icons.badge_rounded,
                        ),
                        _DocPill(
                          _docText(major['name'], 'تخصص عام'),
                          AppColors.info,
                          icon: Icons.school_rounded,
                        ),
                        _DocPill(
                          _docText(level['name'], 'المستوى'),
                          AppColors.violet,
                          icon: Icons.layers_rounded,
                        ),
                        _DocPill(
                          '${_docText(student['stars_balance'], '0')} نجمة',
                          AppColors.goldDeep,
                          icon: Icons.stars_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? AppColors.goldDeep : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.goldDeep : AppColors.slate300,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarBottomGrantBarV3 extends StatelessWidget {
  const _StarBottomGrantBarV3({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.goldDeep.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.goldDeep.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppColors.goldDeep,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$selectedCount طلاب محددون',
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'لكل طالب: $amount نجمة | الإجمالي: $totalStars',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
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
              fixedSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'مسح التحديد',
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onGrant,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.goldDeep,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldDeep.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'منح الآن',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
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
