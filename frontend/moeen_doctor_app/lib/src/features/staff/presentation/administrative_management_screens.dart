import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../../shared/widgets/status_message.dart';
import '../data/staff_repository.dart';
import 'staff_shell.dart';

final _adminRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(authenticatedApiClientProvider));
});

enum _AdminSection { majors, subjects, doctors, students, delegates }

class AdministrativeMajorsScreen extends StatelessWidget {
  const AdministrativeMajorsScreen({super.key});

  static const route = '/administrative/majors';

  @override
  Widget build(BuildContext context) {
    return const _AdministrativeManagementScreen(section: _AdminSection.majors);
  }
}

class AdministrativeSubjectsScreen extends StatelessWidget {
  const AdministrativeSubjectsScreen({super.key});

  static const route = '/administrative/subjects';

  @override
  Widget build(BuildContext context) {
    return const _AdministrativeManagementScreen(
      section: _AdminSection.subjects,
    );
  }
}

class AdministrativeDoctorsScreen extends StatelessWidget {
  const AdministrativeDoctorsScreen({super.key});

  static const route = '/administrative/doctors';

  @override
  Widget build(BuildContext context) {
    return const _AdministrativeManagementScreen(
      section: _AdminSection.doctors,
    );
  }
}

class AdministrativeStudentsScreen extends StatelessWidget {
  const AdministrativeStudentsScreen({super.key});

  static const route = '/administrative/students';

  @override
  Widget build(BuildContext context) {
    return const _AdministrativeManagementScreen(
      section: _AdminSection.students,
    );
  }
}

class AdministrativeDelegatesScreen extends StatelessWidget {
  const AdministrativeDelegatesScreen({super.key});

  static const route = '/administrative/delegates';

  @override
  Widget build(BuildContext context) {
    return const _AdministrativeManagementScreen(
      section: _AdminSection.delegates,
    );
  }
}

class _AdministrativeManagementScreen extends ConsumerStatefulWidget {
  const _AdministrativeManagementScreen({required this.section});

  final _AdminSection section;

  @override
  ConsumerState<_AdministrativeManagementScreen> createState() =>
      _AdministrativeManagementScreenState();
}

class _AdministrativeManagementScreenState
    extends ConsumerState<_AdministrativeManagementScreen> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _payload;
  Object? _error;
  bool _loading = true;
  int _page = 1;
  String? _roleFilter;
  int? _majorFilter;
  int? _levelFilter;
  int? _termFilter;
  int? _doctorFilter;
  int? _selectedMajorIdForSubjects;
  Map<String, dynamic>? _selectedMajorMapForSubjects;
  int? _selectedMajorIdForStudents;
  Map<String, dynamic>? _selectedMajorMapForStudents;
  int? _selectedMajorIdForDelegates;
  Map<String, dynamic>? _selectedMajorMapForDelegates;

  void _selectMajor(Map<String, dynamic> major) {
    _searchController.clear();
    setState(() {
      _selectedMajorMapForSubjects = major;
      _selectedMajorIdForSubjects = _int(major['id']);
      _page = 1;
      _payload = null;
    });
    _load();
  }

  void _clearMajor() {
    _searchController.clear();
    setState(() {
      _selectedMajorMapForSubjects = null;
      _selectedMajorIdForSubjects = null;
      _page = 1;
      _payload = null;
    });
    _load();
  }

  void _selectMajorForStudents(Map<String, dynamic> major) {
    _searchController.clear();
    setState(() {
      _selectedMajorMapForStudents = major;
      _selectedMajorIdForStudents = _int(major['id']);
      _page = 1;
      _payload = null;
    });
    _load();
  }

  void _clearMajorForStudents() {
    _searchController.clear();
    setState(() {
      _selectedMajorMapForStudents = null;
      _selectedMajorIdForStudents = null;
      _page = 1;
      _payload = null;
    });
    _load();
  }

  void _selectMajorForDelegates(Map<String, dynamic> major) {
    _searchController.clear();
    setState(() {
      _selectedMajorMapForDelegates = major;
      _selectedMajorIdForDelegates = _int(major['id']);
      _page = 1;
      _payload = null;
    });
    _load();
  }

  void _clearMajorForDelegates() {
    _searchController.clear();
    setState(() {
      _selectedMajorMapForDelegates = null;
      _selectedMajorIdForDelegates = null;
      _page = 1;
      _payload = null;
    });
    _load();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed() async {
    if (widget.section == _AdminSection.subjects &&
        _selectedMajorIdForSubjects != null) {
      _clearMajor();
      return true;
    }
    if (widget.section == _AdminSection.students &&
        _selectedMajorIdForStudents != null) {
      _clearMajorForStudents();
      return true;
    }
    if (widget.section == _AdminSection.delegates &&
        _selectedMajorIdForDelegates != null) {
      _clearMajorForDelegates();
      return true;
    }
    return false;
  }

  _AdminMeta get _meta => _metaFor(widget.section);

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final isSubjectsMajorSelect =
        widget.section == _AdminSection.subjects &&
        _selectedMajorIdForSubjects == null;
    final isStudentsMajorSelect =
        widget.section == _AdminSection.students &&
        _selectedMajorIdForStudents == null;
    final isDelegatesMajorSelect =
        widget.section == _AdminSection.delegates &&
        _selectedMajorIdForDelegates == null;
    final isMajorSelectMode =
        isSubjectsMajorSelect ||
        isStudentsMajorSelect ||
        isDelegatesMajorSelect;

    return StaffShell(
      title: isMajorSelectMode ? 'اختيار التخصص' : meta.title,
      currentRoute: meta.route,
      onBackPressed: _onBackPressed,
      floatingActionButton:
          (widget.section == _AdminSection.delegates || isMajorSelectMode)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: meta.color,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              label: Text(
                'إضافة ${meta.singleLabel}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? StatusMessage(
              title: 'تعذر تحميل البيانات',
              message: _error is ApiException
                  ? (_error as ApiException).message
                  : 'حدث خطأ أثناء تحميل الصفحة.',
              icon: Icons.error_outline_rounded,
              action: FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: isMajorSelectMode
                    ? [
                        _AdminHero(
                          meta: _AdminMeta(
                            title: 'اختيار التخصص',
                            singleLabel: 'تخصص',
                            subtitle: isSubjectsMajorSelect
                                ? 'حدد التخصص الدراسي أولاً لعرض وإدارة المواد الدراسية الخاصة به.'
                                : isStudentsMajorSelect
                                ? 'حدد التخصص الدراسي أولاً لعرض وإدارة الطلاب الخاصين به.'
                                : 'حدد التخصص الدراسي أولاً لعرض وإدارة المندوبين الخاصين به.',
                            route: widget.section == _AdminSection.subjects
                                ? AdministrativeSubjectsScreen.route
                                : widget.section == _AdminSection.students
                                ? AdministrativeStudentsScreen.route
                                : AdministrativeDelegatesScreen.route,
                            endpoint: '/administrative/majors',
                            icon: Icons.account_tree_rounded,
                            color: isSubjectsMajorSelect
                                ? AppColors.royalBlue
                                : isStudentsMajorSelect
                                ? AppColors.teal
                                : AppColors.royalBlue,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _Toolbar(
                          meta: meta,
                          searchController: _searchController,
                          hasCreate: false,
                          onSearch: () {},
                          onCreate: () {},
                        ),
                        const SizedBox(height: 18),
                        if (_items.isEmpty)
                          const _EmptyState()
                        else
                          ..._items.map(
                            (major) => _SubjectMajorCard(
                              major: major,
                              color: isSubjectsMajorSelect
                                  ? AppColors.royalBlue
                                  : isStudentsMajorSelect
                                  ? AppColors.teal
                                  : AppColors.royalBlue,
                              onTap: () => isSubjectsMajorSelect
                                  ? _selectMajor(major)
                                  : isStudentsMajorSelect
                                  ? _selectMajorForStudents(major)
                                  : _selectMajorForDelegates(major),
                            ),
                          ),
                      ]
                    : [
                        _AdminHero(meta: meta),
                        const SizedBox(height: 18),
                        if ((widget.section == _AdminSection.subjects &&
                                _selectedMajorIdForSubjects != null) ||
                            (widget.section == _AdminSection.students &&
                                _selectedMajorIdForStudents != null) ||
                            (widget.section == _AdminSection.delegates &&
                                _selectedMajorIdForDelegates != null)) ...[
                          _buildMajorHeader(context),
                          const SizedBox(height: 18),
                        ],
                        _StatsRow(stats: _stats()),
                        const SizedBox(height: 18),
                        _Toolbar(
                          meta: meta,
                          searchController: _searchController,
                          hasCreate: false,
                          onSearch: () {
                            _page = 1;
                            _load();
                          },
                          onCreate: () => _openForm(),
                        ),
                        if (_showFilters) ...[
                          const SizedBox(height: 12),
                          _FiltersBar(
                            section: widget.section,
                            payload: _payload ?? const {},
                            roleFilter: _roleFilter,
                            majorFilter: _majorFilter,
                            levelFilter: _levelFilter,
                            termFilter: _termFilter,
                            doctorFilter: _doctorFilter,
                            selectedMajorForSubjects:
                                _selectedMajorMapForSubjects,
                            selectedMajorForStudents:
                                _selectedMajorMapForStudents,
                            selectedMajorForDelegates:
                                _selectedMajorMapForDelegates,
                            onRoleChanged: (value) {
                              _roleFilter = value;
                              _page = 1;
                              _load();
                            },
                            onMajorChanged: (value) {
                              _majorFilter = value;
                              _levelFilter = null;
                              _page = 1;
                              _load();
                            },
                            onLevelChanged: (value) {
                              _levelFilter = value;
                              _termFilter = null;
                              _page = 1;
                              _load();
                            },
                            onTermChanged: (value) {
                              _termFilter = value;
                              _page = 1;
                              _load();
                            },
                            onDoctorChanged: (value) {
                              _doctorFilter = value;
                              _page = 1;
                              _load();
                            },
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (_items.isEmpty)
                          const _EmptyState()
                        else
                          ..._items.map(_entityCard),
                        const SizedBox(height: 12),
                        _Pagination(
                          pagination: _pagination,
                          onPrevious: _page > 1
                              ? () {
                                  _page--;
                                  _load();
                                }
                              : null,
                          onNext: _page < _pagination.lastPage
                              ? () {
                                  _page++;
                                  _load();
                                }
                              : null,
                        ),
                      ],
              ),
            ),
    );
  }

  Widget _buildMajorHeader(BuildContext context) {
    final isStudents = widget.section == _AdminSection.students;
    final isDelegates = widget.section == _AdminSection.delegates;
    final major =
        (isStudents
            ? _selectedMajorMapForStudents
            : isDelegates
            ? _selectedMajorMapForDelegates
            : _selectedMajorMapForSubjects) ??
        const {};
    final name = (major['name'] ?? '').toString();
    final color = isStudents
        ? AppColors.teal
        : isDelegates
        ? AppColors.royalBlue
        : AppColors.royalBlue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التخصص النشط حالياً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: isStudents
                ? _clearMajorForStudents
                : isDelegates
                ? _clearMajorForDelegates
                : _clearMajor,
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text(
              'تغيير التخصص',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _showFilters =>
      widget.section == _AdminSection.subjects ||
      widget.section == _AdminSection.students ||
      widget.section == _AdminSection.delegates;

  List<Map<String, dynamic>> get _items {
    final data = _payload ?? const <String, dynamic>{};
    List<Map<String, dynamic>> list;
    if ((widget.section == _AdminSection.subjects &&
            _selectedMajorIdForSubjects == null) ||
        (widget.section == _AdminSection.students &&
            _selectedMajorIdForStudents == null) ||
        (widget.section == _AdminSection.delegates &&
            _selectedMajorIdForDelegates == null)) {
      list = _list(data['items']);
    } else {
      switch (widget.section) {
        case _AdminSection.majors:
          list = _list(data['items']);
          break;
        case _AdminSection.subjects:
          list = _list(data['subjects']);
          break;
        case _AdminSection.doctors:
          list = _list(data['doctors']);
          break;
        case _AdminSection.students:
          list = _list(data['students']);
          break;
        case _AdminSection.delegates:
          list = _list(data['users']);
          break;
      }
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return list;

    return list.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final email = (item['email'] ?? '').toString().toLowerCase();
      final studentNumber = (item['student_number'] ?? '')
          .toString()
          .toLowerCase();
      final code = (item['code'] ?? '').toString().toLowerCase();
      final description = (item['description'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          studentNumber.contains(query) ||
          code.contains(query) ||
          description.contains(query);
    }).toList();
  }

  _PageInfo get _pagination {
    final pagination = _map(_payload?['pagination']);
    if (pagination.isEmpty) return _PageInfo(1, 1, _items.length);
    return _PageInfo(
      _int(pagination['current_page'], fallback: 1),
      _int(pagination['last_page'], fallback: 1),
      _int(pagination['total']),
    );
  }

  List<_AdminStat> _stats() {
    switch (widget.section) {
      case _AdminSection.majors:
        final majors = _items;
        final levels = majors.fold<int>(
          0,
          (sum, item) => sum + _int(item['levels_count']),
        );
        return [
          _AdminStat(
            'التخصصات',
            majors.length.toString(),
            Icons.account_tree_rounded,
            AppColors.teal,
          ),
          _AdminStat(
            'المستويات',
            levels.toString(),
            Icons.layers_rounded,
            AppColors.royalBlue,
          ),
          _AdminStat(
            'سريري',
            majors.where((m) => m['has_clinical'] == true).length.toString(),
            Icons.local_hospital_rounded,
            AppColors.rose,
          ),
        ];
      case _AdminSection.subjects:
        return [
          _AdminStat(
            'المواد',
            _pagination.total.toString(),
            Icons.menu_book_rounded,
            AppColors.royalBlue,
          ),
          _AdminStat(
            'الدكاترة',
            _list(_payload?['doctors']).length.toString(),
            Icons.school_rounded,
            AppColors.royalBlue,
          ),
          _AdminStat(
            'الأترام',
            _list(_payload?['terms']).length.toString(),
            Icons.calendar_month_rounded,
            AppColors.teal,
          ),
        ];
      case _AdminSection.doctors:
        return [
          _AdminStat(
            'الدكاترة',
            _pagination.total.toString(),
            Icons.school_rounded,
            AppColors.royalBlue,
          ),
          _AdminStat(
            'بمواد',
            _items
                .where((d) => _list(d['subjects']).isNotEmpty)
                .length
                .toString(),
            Icons.menu_book_rounded,
            AppColors.violet,
          ),
          _AdminStat(
            'نشط',
            _items
                .where((d) => (d['status'] ?? 'active') == 'active')
                .length
                .toString(),
            Icons.verified_rounded,
            AppColors.success,
          ),
        ];
      case _AdminSection.students:
        return [
          _AdminStat(
            'الطلاب',
            _pagination.total.toString(),
            Icons.groups_rounded,
            AppColors.teal,
          ),
          _AdminStat(
            'مندوبين',
            _items.where((s) => s['role'] == 'delegate').length.toString(),
            Icons.admin_panel_settings_rounded,
            AppColors.royalBlue,
          ),
          _AdminStat(
            'تخصصات',
            _list(_payload?['majors']).length.toString(),
            Icons.account_tree_rounded,
            AppColors.royalBlue,
          ),
        ];
      case _AdminSection.delegates:
        final stats = _map(_payload?['stats']);
        return [
          _AdminStat(
            'الطلاب',
            _int(stats['total_students']).toString(),
            Icons.groups_rounded,
            AppColors.teal,
          ),
          _AdminStat(
            'مندوبين',
            _int(stats['academic_delegates']).toString(),
            Icons.admin_panel_settings_rounded,
            AppColors.royalBlue,
          ),
          _AdminStat(
            'عملي',
            _int(stats['practical_delegates']).toString(),
            Icons.medical_services_rounded,
            AppColors.teal,
          ),
        ];
    }
  }

  Widget _entityCard(Map<String, dynamic> item) {
    switch (widget.section) {
      case _AdminSection.majors:
        return _MajorCard(
          item: item,
          onEdit: () => _openForm(item: item),
          onDelete: () => _confirmDelete(item),
        );
      case _AdminSection.subjects:
        return _SubjectCard(
          item: item,
          onEdit: () => _openForm(item: item),
          onDelete: () => _confirmDelete(item),
        );
      case _AdminSection.doctors:
        return _DoctorCard(
          item: item,
          onDetails: () => _showDoctorDetails(item),
          onManageStars: () => _openDoctorStarWallet(item),
          onEdit: () => _openForm(item: item),
          onDelete: () => _confirmDelete(item),
        );
      case _AdminSection.students:
        return _StudentCard(
          item: item,
          onDetails: () => _showStudentDetails(item),
          onEdit: () => _openForm(item: item),
          onDelete: () => _confirmDelete(item),
        );
      case _AdminSection.delegates:
        return _DelegateCard(
          item: item,
          permissionsMeta: _map(_payload?['available_permissions']),
          onDetails: () => _showDelegateDetails(item),
          onRole: () => _openRoleForm(item),
          onPermissions: _isDelegateRole(item['role'])
              ? () => _openPermissionsForm(item)
              : null,
        );
    }
  }

  Future<void> _showDoctorDetails(Map<String, dynamic> item) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الدكتور',
      icon: Icons.school_rounded,
      color: AppColors.royalBlue,
      child: _DoctorDetailsSheet(
        item: item,
        onManageStars: () {
          Navigator.of(context).pop();
          _openDoctorStarWallet(item);
        },
      ),
    );
  }

  Future<void> _openDoctorStarWallet(Map<String, dynamic> item) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: 'إدارة رصيد منح النجوم',
      icon: Icons.stars_rounded,
      color: AppColors.goldDeep,
      fullScreen: true,
      child: _DoctorStarWalletSheet(
        doctor: item,
        repository: ref.read(_adminRepositoryProvider),
        onUpdated: _load,
      ),
    );
  }

  Future<void> _showStudentDetails(Map<String, dynamic> item) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الطالب',
      icon: Icons.person_rounded,
      color: AppColors.royalBlue,
      child: _StudentDetailsSheet(item: item),
    );
  }

  Future<void> _showDelegateDetails(Map<String, dynamic> item) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل المندوب',
      icon: Icons.admin_panel_settings_rounded,
      color: AppColors.royalBlue,
      child: _DelegateDetailsSheet(
        item: item,
        permissionsMeta: _map(_payload?['available_permissions']),
        onRole: () {
          Navigator.of(context).pop();
          _openRoleForm(item);
        },
        onPermissions: _isDelegateRole(item['role'])
            ? () {
                Navigator.of(context).pop();
                _openPermissionsForm(item);
              }
            : null,
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final String endpoint;
      final Map<String, dynamic> query;

      if ((widget.section == _AdminSection.subjects &&
              _selectedMajorIdForSubjects == null) ||
          (widget.section == _AdminSection.students &&
              _selectedMajorIdForStudents == null) ||
          (widget.section == _AdminSection.delegates &&
              _selectedMajorIdForDelegates == null)) {
        endpoint = '/administrative/majors';
        query = {'page': 1, 'per_page': 100};
      } else {
        endpoint = _meta.endpoint;
        query = _query();
      }

      final response = await ref
          .read(_adminRepositoryProvider)
          .get(endpoint, query: query);
      final data = response['data'];
      final payload = data is List
          ? {'items': data}
          : data is Map
          ? data.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() => _payload = payload);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _query() {
    final query = <String, dynamic>{'page': _page, 'per_page': 100};
    if (widget.section == _AdminSection.subjects &&
        _selectedMajorIdForSubjects != null) {
      query['major_id'] = _selectedMajorIdForSubjects;
    }
    if (widget.section == _AdminSection.students &&
        _selectedMajorIdForStudents != null) {
      query['major_id'] = _selectedMajorIdForStudents;
    }
    if (widget.section == _AdminSection.delegates &&
        _selectedMajorIdForDelegates != null) {
      query['major_id'] = _selectedMajorIdForDelegates;
    }
    if (_roleFilter != null && _roleFilter != 'all') {
      query['role'] = _roleFilter;
    }
    if (_majorFilter != null) query['major_id'] = _majorFilter;
    if (_levelFilter != null) query['level_id'] = _levelFilter;
    if (_termFilter != null) query['term_id'] = _termFilter;
    if (_doctorFilter != null) query['doctor_id'] = _doctorFilter;
    return query;
  }

  Future<void> _openForm({Map<String, dynamic>? item}) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: item == null
          ? 'إضافة ${_meta.singleLabel}'
          : 'تعديل ${_meta.singleLabel}',
      icon: item == null ? Icons.add_rounded : Icons.edit_rounded,
      color: _meta.color,
      fullScreen: true,
      child: _EntityForm(
        section: widget.section,
        item: item,
        payload: _payload ?? const {},
        color: _meta.color,
        selectedMajor: widget.section == _AdminSection.subjects
            ? _selectedMajorMapForSubjects
            : widget.section == _AdminSection.students
            ? _selectedMajorMapForStudents
            : null,
        onSubmit: (data) => _save(data, item: item),
      ),
    );
  }

  Future<void> _save(
    Map<String, dynamic> data, {
    Map<String, dynamic>? item,
  }) async {
    try {
      final repository = ref.read(_adminRepositoryProvider);
      final response = item == null
          ? await repository.post(_meta.endpoint, data)
          : await repository.put('${_meta.endpoint}/${item['id']}', data);
      if (!mounted) return;
      Navigator.of(context).pop();
      await showMoeenInfoDialog(
        context: context,
        title: 'تم الحفظ',
        message: (response['message'] ?? 'تم حفظ البيانات بنجاح.').toString(),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذر الحفظ',
        message: error.message,
        icon: Icons.error_rounded,
        color: AppColors.danger,
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final approved = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد الحذف',
      message:
          'هل تريد حذف "${_titleOf(item)}"؟ لا يمكن التراجع عن هذه العملية.',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!approved) return;
    try {
      final response = await ref
          .read(_adminRepositoryProvider)
          .delete('${_meta.endpoint}/${item['id']}');
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم الحذف',
        message: (response['message'] ?? 'تم حذف العنصر بنجاح.').toString(),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذر الحذف',
        message: error.message,
        icon: Icons.error_rounded,
        color: AppColors.danger,
      );
    }
  }

  Future<void> _openRoleForm(Map<String, dynamic> item) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: 'تعديل دور الطالب',
      icon: Icons.manage_accounts_rounded,
      color: AppColors.goldDeep,
      child: _DelegateRoleForm(
        item: item,
        onSubmit: (role) async {
          try {
            final response = await ref.read(_adminRepositoryProvider).patch(
              '/administrative/delegates/${item['id']}/role',
              {'role': role},
            );
            if (!mounted) return;
            Navigator.of(context).pop();
            await showMoeenInfoDialog(
              context: context,
              title: 'تم تحديث الدور',
              message: (response['message'] ?? 'تم تحديث دور المستخدم بنجاح.')
                  .toString(),
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            );
            await _load();
          } on ApiException catch (error) {
            if (!mounted) return;
            await showMoeenInfoDialog(
              context: context,
              title: 'تعذر تحديث الدور',
              message: error.message,
              icon: Icons.error_rounded,
              color: AppColors.danger,
            );
          }
        },
      ),
    );
  }

  Future<void> _openPermissionsForm(Map<String, dynamic> item) {
    return showMoeenBottomSheet<void>(
      context: context,
      title: 'صلاحيات المندوب',
      icon: Icons.admin_panel_settings_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _DelegatePermissionsForm(
        item: item,
        meta: _map(_payload?['available_permissions']),
        onSubmit: (permissions) async {
          try {
            final response = await ref.read(_adminRepositoryProvider).post(
              '/administrative/delegates/${item['id']}/permissions',
              {'permissions': permissions},
            );
            if (!mounted) return;
            Navigator.of(context).pop();
            await showMoeenInfoDialog(
              context: context,
              title: 'تم تحديث الصلاحيات',
              message:
                  (response['message'] ?? 'تم تحديث صلاحيات المندوب بنجاح.')
                      .toString(),
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            );
            await _load();
          } on ApiException catch (error) {
            if (!mounted) return;
            await showMoeenInfoDialog(
              context: context,
              title: 'تعذر تحديث الصلاحيات',
              message: error.message,
              icon: Icons.error_rounded,
              color: AppColors.danger,
            );
          }
        },
      ),
    );
  }
}

class _EntityForm extends StatefulWidget {
  const _EntityForm({
    required this.section,
    required this.item,
    required this.payload,
    required this.color,
    required this.onSubmit,
    this.selectedMajor,
  });

  final _AdminSection section;
  final Map<String, dynamic>? item;
  final Map<String, dynamic> payload;
  final Color color;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;
  final Map<String, dynamic>? selectedMajor;

  @override
  State<_EntityForm> createState() => _EntityFormState();
}

class _EntityFormState extends State<_EntityForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  bool _hasClinical = false;
  bool _hasSemesters = false;
  String _gender = 'male';
  int? _levelId;
  int? _termId;
  int? _semesterId;
  int? _doctorId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item ?? const <String, dynamic>{};
    for (final key in [
      'name',
      'email',
      'password',
      'student_number',
      'code',
      'description',
      'levels_count',
      'terms_count',
      'semesters_per_term',
    ]) {
      _controllers[key] = TextEditingController(
        text: (item[key] ?? '').toString(),
      );
    }
    _hasClinical = item['has_clinical'] == true;
    _hasSemesters = item['has_semesters'] == true;
    _gender = (item['gender'] ?? 'male').toString();
    _levelId = _int(
      _map(item['level'])['id'],
      fallback: _int(item['level_id']),
    );
    _termId = _int(_map(item['term'])['id'], fallback: _int(item['term_id']));
    _semesterId = _int(
      _map(item['semester'])['id'],
      fallback: _int(item['semester_id']),
    );
    _doctorId = _int(
      _map(item['doctor'])['id'],
      fallback: _int(item['doctor_id']),
    );
    if (widget.item == null && widget.section == _AdminSection.majors) {
      _controllers['levels_count']!.text = '4';
      _controllers['terms_count']!.text = '2';
      _controllers['semesters_per_term']!.text = '0';
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
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
          ..._fields(),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: widget.color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _submitting
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
              _submitting ? 'جاري الحفظ...' : 'حفظ البيانات',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _fields() {
    switch (widget.section) {
      case _AdminSection.majors:
        return [
          _text('name', 'اسم التخصص', required: true),
          if (widget.item == null) ...[
            _stepper(
              'levels_count',
              'عدد المستويات',
              min: 1,
              max: 8,
              icon: Icons.layers_rounded,
            ),
            _stepper(
              'terms_count',
              'عدد الأترام لكل مستوى',
              min: 1,
              max: 4,
              icon: Icons.calendar_month_rounded,
            ),
            if (_hasSemesters)
              _stepper(
                'semesters_per_term',
                'عدد السيمسترات لكل ترم',
                min: 1,
                max: 10,
                icon: Icons.view_week_rounded,
              ),
          ],
          _switch(
            'تخصص سريري',
            _hasClinical,
            (v) => setState(() => _hasClinical = v),
          ),
          _switch(
            'يدعم السيمسترات',
            _hasSemesters,
            (v) => setState(() {
              _hasSemesters = v;
              if (v) {
                if (_controllers['semesters_per_term']?.text == '0') {
                  _controllers['semesters_per_term']?.text = '2';
                }
              } else {
                _controllers['semesters_per_term']?.text = '0';
              }
            }),
          ),
        ];
      case _AdminSection.subjects:
        final levels = widget.selectedMajor != null
            ? _list(widget.selectedMajor!['levels'])
            : <Map<String, dynamic>>[];

        List<Map<String, dynamic>> filteredTerms = [];
        if (_levelId != null && _levelId != 0) {
          final selectedLevel = levels.firstWhere(
            (l) => _int(l['id']) == _levelId,
            orElse: () => const {},
          );
          filteredTerms = _list(selectedLevel['terms']);
        } else {
          for (final l in levels) {
            filteredTerms.addAll(_list(l['terms']));
          }
        }

        final selectedTerm = filteredTerms.firstWhere(
          (term) => _int(term['id']) == _termId,
          orElse: () => const {},
        );
        final semesters = _list(selectedTerm['semesters']);

        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.violet,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'معلومات المادة الدراسية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.midnight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _text('name', 'اسم المادة', required: true),
                _text('code', 'كود المادة', required: false),
                _text('description', 'وصف مختصر', required: false, maxLines: 3),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      color: AppColors.violet,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'الارتباط الأكاديمي والتدريس',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.midnight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _dropdown<int>(
                  label: 'المستوى',
                  value: _levelId == 0 ? null : _levelId,
                  required: true,
                  items: levels
                      .map(
                        (l) => _MenuItem(
                          _int(l['id']),
                          (l['name'] ?? '').toString(),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _levelId = value;
                    _termId = null;
                    _semesterId = null;
                  }),
                ),
                _dropdown<int>(
                  label: 'الترم',
                  value: _termId == 0 ? null : _termId,
                  required: true,
                  items: filteredTerms
                      .map(
                        (term) => _MenuItem(_int(term['id']), _termLabel(term)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _termId = value;
                    _semesterId = null;
                  }),
                ),
                if (semesters.isNotEmpty)
                  _dropdown<int>(
                    label: 'السيمستر',
                    value: _semesterId == 0 ? null : _semesterId,
                    required: false,
                    items: semesters
                        .map(
                          (sem) => _MenuItem(
                            _int(sem['id']),
                            (sem['name'] ?? '').toString(),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _semesterId = value),
                  ),
                _dropdown<int>(
                  label: 'الدكتور المسؤول',
                  value: _doctorId == 0 ? null : _doctorId,
                  required: false,
                  items: _list(widget.payload['doctors'])
                      .map(
                        (doctor) => _MenuItem(
                          _int(doctor['id']),
                          (doctor['name'] ?? '').toString(),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _doctorId = value),
                ),
              ],
            ),
          ),
        ];
      case _AdminSection.doctors:
        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: AppColors.royalBlue,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'بيانات الطبيب / الدكتور',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.midnight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _text(
                  'name',
                  'اسم الدكتور',
                  required: true,
                  icon: Icons.person_rounded,
                ),
                _text(
                  'email',
                  'البريد الإلكتروني',
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_rounded,
                ),
                _text(
                  'password',
                  widget.item == null
                      ? 'كلمة المرور'
                      : 'كلمة مرور جديدة (اختياري)',
                  required: widget.item == null,
                  obscure: true,
                  icon: Icons.lock_rounded,
                ),
              ],
            ),
          ),
        ];
      case _AdminSection.students:
        final levels = widget.selectedMajor != null
            ? _list(widget.selectedMajor!['levels'])
            : _allLevels(widget.payload);
        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: widget.color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'البيانات الأساسية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.midnight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _text(
                  'name',
                  'اسم الطالب',
                  required: true,
                  icon: Icons.person_rounded,
                ),
                _text(
                  'email',
                  'البريد الإلكتروني',
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_rounded,
                ),
                _text(
                  'student_number',
                  'رقم القيد',
                  required: true,
                  icon: Icons.badge_rounded,
                ),
                _text(
                  'password',
                  widget.item == null
                      ? 'كلمة المرور'
                      : 'كلمة مرور جديدة (اختياري)',
                  required: widget.item == null,
                  obscure: true,
                  icon: Icons.lock_rounded,
                ),
                _dropdown<String>(
                  label: 'الجنس',
                  value: _gender,
                  items: const [
                    _MenuItem('male', 'ذكر'),
                    _MenuItem('female', 'أنثى'),
                  ],
                  onChanged: (value) =>
                      setState(() => _gender = value ?? 'male'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school_rounded, color: widget.color, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'الارتباط الأكاديمي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.midnight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _dropdown<int>(
                  label: 'المستوى الدراسي',
                  value: _levelId == 0 ? null : _levelId,
                  items: levels
                      .map(
                        (level) =>
                            _MenuItem(_int(level['id']), _levelLabel(level)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _levelId = value),
                ),
              ],
            ),
          ),
        ];
      case _AdminSection.delegates:
        return const [];
    }
  }

  Widget _text(
    String key,
    String label, {
    bool required = true,
    bool obscure = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        keyboardType: keyboardType,
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'هذا الحقل مطلوب.';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: widget.color) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _stepper(
    String key,
    String label, {
    required int min,
    required int max,
    required IconData icon,
    int step = 1,
  }) {
    final controller = _controllers[key]!;
    void adjust(int delta) {
      final current = int.tryParse(controller.text) ?? min;
      final newValue = (current + delta).clamp(min, max);
      controller.text = newValue.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: widget.color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.midnight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => adjust(-step),
                  icon: const Icon(Icons.remove_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: widget.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.slate200),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.midnight,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    validator: (value) {
                      final number = int.tryParse((value ?? '').trim());
                      if (number == null) return 'مطلوب';
                      if (number < min || number > max) return '$min-$max';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => adjust(step),
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: widget.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.slate200),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      activeThumbColor: widget.color,
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<_MenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool required = true,
  }) {
    final values = items.map((item) => item.value).toSet();
    final safeValue = values.contains(value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        validator: required
            ? (value) => value == null ? 'هذا الحقل مطلوب.' : null
            : null,
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item.value,
                child: Text(item.label, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await widget.onSubmit(_data());
    if (mounted) setState(() => _submitting = false);
  }

  Map<String, dynamic> _data() {
    switch (widget.section) {
      case _AdminSection.majors:
        final data = {
          'name': _controllers['name']!.text.trim(),
          'has_clinical': _hasClinical,
          'has_semesters': _hasSemesters,
        };
        if (widget.item == null) {
          data.addAll({
            'levels_count': int.parse(_controllers['levels_count']!.text),
            'terms_count': int.parse(_controllers['terms_count']!.text),
            'semesters_per_term': int.parse(
              _controllers['semesters_per_term']!.text,
            ),
          });
        }
        return data;
      case _AdminSection.subjects:
        return {
          'name': _controllers['name']!.text.trim(),
          'code': _nullable(_controllers['code']!.text),
          'description': _nullable(_controllers['description']!.text),
          'term_id': _termId,
          'semester_id': _semesterId,
          'doctor_id': _doctorId,
        };
      case _AdminSection.doctors:
        return {
          'name': _controllers['name']!.text.trim(),
          'email': _controllers['email']!.text.trim(),
          if (_controllers['password']!.text.trim().isNotEmpty)
            'password': _controllers['password']!.text.trim(),
        };
      case _AdminSection.students:
        return {
          'name': _controllers['name']!.text.trim(),
          'email': _controllers['email']!.text.trim(),
          'student_number': _controllers['student_number']!.text.trim(),
          if (_controllers['password']!.text.trim().isNotEmpty)
            'password': _controllers['password']!.text.trim(),
          'gender': _gender,
          'level_id': _levelId,
        };
      case _AdminSection.delegates:
        return const {};
    }
  }
}

class _DelegateRoleForm extends StatefulWidget {
  const _DelegateRoleForm({required this.item, required this.onSubmit});

  final Map<String, dynamic> item;
  final Future<void> Function(String role) onSubmit;

  @override
  State<_DelegateRoleForm> createState() => _DelegateRoleFormState();
}

class _DelegateRoleFormState extends State<_DelegateRoleForm> {
  late String _role = (widget.item['role'] ?? 'student').toString();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.manage_accounts_rounded,
                    color: AppColors.goldDeep,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'تعديل دور المستخدم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.midnight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(
                  labelText: 'الدور الجديد',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('طالب')),
                  DropdownMenuItem(
                    value: 'delegate',
                    child: Text('مندوب دفعة'),
                  ),
                  DropdownMenuItem(
                    value: 'practical_delegate',
                    child: Text('مندوب عملي'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _role = value ?? 'student'),
              ),
              const SizedBox(height: 10),
              const Text(
                'تغيير دور المستخدم يؤثر مباشرة على صلاحياته والوظائف المتاحة له في التطبيق.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSubmit(_role);
                  if (mounted) setState(() => _saving = false);
                },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.goldDeep,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
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
            _saving ? 'جاري حفظ التغييرات...' : 'حفظ الدور الجديد',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DelegatePermissionsForm extends StatefulWidget {
  const _DelegatePermissionsForm({
    required this.item,
    required this.meta,
    required this.onSubmit,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic> meta;
  final Future<void> Function(List<String> permissions) onSubmit;

  @override
  State<_DelegatePermissionsForm> createState() =>
      _DelegatePermissionsFormState();
}

class _DelegatePermissionsFormState extends State<_DelegatePermissionsForm> {
  late final Set<String> _selected = _list(widget.item['delegate_permissions'])
      .map((permission) => '${permission['resource']}.${permission['action']}')
      .toSet();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final resources = _map(widget.meta['resources']);
    final actions = _map(widget.meta['actions']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...resources.entries.map((resource) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      color: AppColors.royalBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      resource.value.toString(),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...actions.entries.map((action) {
                  final key = '${resource.key}.${action.key}';
                  return CheckboxListTile(
                    value: _selected.contains(key),
                    activeColor: AppColors.royalBlue,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(key);
                        } else {
                          _selected.remove(key);
                        }
                      });
                    },
                    title: Text(
                      action.value.toString(),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.slate700,
                      ),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSubmit(_selected.toList());
                  if (mounted) setState(() => _saving = false);
                },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.royalBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
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
            _saving ? 'جاري حفظ التغييرات...' : 'حفظ الصلاحيات الممنوحة',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({required this.meta});

  final _AdminMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [meta.color, meta.color.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: meta.color.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(meta.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  meta.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final List<_AdminStat> stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: stats
          .map(
            (stat) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 60) / 3,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(stat.icon, color: stat.color),
                    const SizedBox(height: 10),
                    Text(
                      stat.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      stat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.meta,
    required this.searchController,
    required this.hasCreate,
    required this.onSearch,
    required this.onCreate,
  });

  final _AdminMeta meta;
  final TextEditingController searchController;
  final bool hasCreate;
  final VoidCallback onSearch;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'بحث...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchController,
                builder: (context, value, child) {
                  if (value.text.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: AppColors.slate400,
                      ),
                      onPressed: () {
                        searchController.clear();
                        onSearch();
                      },
                    );
                  }
                  return const Icon(
                    Icons.search_rounded,
                    color: AppColors.slate300,
                  );
                },
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.slate200),
              ),
            ),
          ),
        ),
        if (hasCreate) ...[
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: meta.color,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ],
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.section,
    required this.payload,
    required this.roleFilter,
    required this.majorFilter,
    required this.levelFilter,
    required this.termFilter,
    required this.doctorFilter,
    required this.onRoleChanged,
    required this.onMajorChanged,
    required this.onLevelChanged,
    required this.onTermChanged,
    required this.onDoctorChanged,
    this.selectedMajorForSubjects,
    this.selectedMajorForStudents,
    this.selectedMajorForDelegates,
  });

  final _AdminSection section;
  final Map<String, dynamic> payload;
  final String? roleFilter;
  final int? majorFilter;
  final int? levelFilter;
  final int? termFilter;
  final int? doctorFilter;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<int?> onMajorChanged;
  final ValueChanged<int?> onLevelChanged;
  final ValueChanged<int?> onTermChanged;
  final ValueChanged<int?> onDoctorChanged;
  final Map<String, dynamic>? selectedMajorForSubjects;
  final Map<String, dynamic>? selectedMajorForStudents;
  final Map<String, dynamic>? selectedMajorForDelegates;

  @override
  Widget build(BuildContext context) {
    final majors = _list(payload['majors']);
    final selectedMajor = majors.firstWhere(
      (major) => _int(major['id']) == majorFilter,
      orElse: () => const {},
    );
    final levels =
        section == _AdminSection.delegates && selectedMajorForDelegates != null
        ? _list(selectedMajorForDelegates!['levels'])
        : section == _AdminSection.delegates && majorFilter != null
        ? _list(payload['levels'])
        : section == _AdminSection.subjects && selectedMajorForSubjects != null
        ? _list(selectedMajorForSubjects!['levels'])
        : section == _AdminSection.students && selectedMajorForStudents != null
        ? _list(selectedMajorForStudents!['levels'])
        : majorFilter == null
        ? _allLevels(payload)
        : _list(selectedMajor['levels']);

    List<Map<String, dynamic>> terms = [];
    if (section == _AdminSection.subjects) {
      if (levelFilter != null) {
        final selectedLevel = levels.firstWhere(
          (l) => _int(l['id']) == levelFilter,
          orElse: () => const {},
        );
        terms = _list(selectedLevel['terms']);
      } else {
        for (final l in levels) {
          terms.addAll(_list(l['terms']));
        }
      }
    } else {
      terms = _list(payload['terms']);
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (section == _AdminSection.students ||
            section == _AdminSection.delegates)
          _SmallDropdown<String>(
            label: 'الدور',
            value: roleFilter ?? 'all',
            items: const [
              _MenuItem('all', 'الكل'),
              _MenuItem('student', 'طالب'),
              _MenuItem('delegate', 'مندوب'),
              _MenuItem('practical_delegate', 'مندوب عملي'),
            ],
            onChanged: onRoleChanged,
          ),
        if (section == _AdminSection.delegates &&
            selectedMajorForDelegates == null)
          _SmallDropdown<int>(
            label: 'التخصص',
            value: majorFilter,
            items: majors
                .map(
                  (m) => _MenuItem(_int(m['id']), (m['name'] ?? '').toString()),
                )
                .toList(),
            onChanged: onMajorChanged,
          ),
        if (section == _AdminSection.students ||
            section == _AdminSection.delegates)
          _SmallDropdown<int>(
            label: 'المستوى',
            value: levelFilter,
            items: levels
                .map(
                  (l) => _MenuItem(_int(l['id']), (l['name'] ?? '').toString()),
                )
                .toList(),
            onChanged: onLevelChanged,
          ),
        if (section == _AdminSection.subjects) ...[
          _SmallDropdown<int>(
            label: 'المستوى',
            value: levelFilter,
            items: levels
                .map(
                  (l) => _MenuItem(_int(l['id']), (l['name'] ?? '').toString()),
                )
                .toList(),
            onChanged: onLevelChanged,
          ),
          _SmallDropdown<int>(
            label: 'الترم',
            value: termFilter,
            items: terms
                .map((t) => _MenuItem(_int(t['id']), _termLabel(t)))
                .toList(),
            onChanged: onTermChanged,
          ),
          _SmallDropdown<int>(
            label: 'الدكتور',
            value: doctorFilter,
            items: _list(payload['doctors'])
                .map(
                  (d) => _MenuItem(_int(d['id']), (d['name'] ?? '').toString()),
                )
                .toList(),
            onChanged: onDoctorChanged,
          ),
        ],
      ],
    );
  }
}

class _SmallDropdown<T> extends StatelessWidget {
  const _SmallDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<_MenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = items.map((item) => item.value).toSet();
    final safeValue = values.contains(value) ? value : null;
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 50) / 2,
      child: DropdownButtonFormField<T>(
        initialValue: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        items: [
          if (T != String)
            DropdownMenuItem<T>(value: null, child: const Text('الكل')),
          ...items.map(
            (item) => DropdownMenuItem<T>(
              value: item.value,
              child: Text(item.label, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _MajorCard extends StatelessWidget {
  const _MajorCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final levels = _list(item['levels']);
    final levelsCount = _int(item['levels_count']);
    final hasClinical = item['has_clinical'] == true;
    final hasSemesters = item['has_semesters'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Accent
          Container(height: 4, color: AppColors.teal),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    color: AppColors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['name'] ?? '').toString(),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.midnight,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${levels.length} مستوى دراسي مسجل',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.slate500,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.slate400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: AppColors.royalBlue,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'تعديل التخصص',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'حذف التخصص',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMajorPill(
                  'المستويات المتاحة: $levelsCount',
                  AppColors.royalBlue,
                  icon: Icons.layers_rounded,
                ),
                _buildMajorPill(
                  hasClinical ? 'مسار سريري' : 'مسار أكاديمي عادي',
                  hasClinical ? AppColors.rose : AppColors.slate500,
                  icon: hasClinical
                      ? Icons.local_hospital_rounded
                      : Icons.school_rounded,
                ),
                _buildMajorPill(
                  hasSemesters ? 'يدعم نظام السيمسترات' : 'نظام أترام سنوي',
                  hasSemesters ? AppColors.violet : AppColors.slate500,
                  icon: hasSemesters
                      ? Icons.view_week_rounded
                      : Icons.calendar_month_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMajorPill(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] ?? '').toString();
    final levelName = _map(item['level'])['name']?.toString() ?? '';
    final termName = _map(item['term'])['name']?.toString() ?? '';
    final code = (item['code'] ?? '').toString();
    final doctorName = _map(item['doctor'])['name']?.toString() ?? 'غير محدد';
    final semesterName = _map(item['semester'])['name']?.toString() ?? '';
    final description = (item['description'] ?? '').toString();

    final subtitleParts = [
      if (levelName.isNotEmpty) levelName,
      if (termName.isNotEmpty) termName,
    ].join(' / ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: AppColors.violet),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.violet.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.violet,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.midnight,
                          height: 1.25,
                        ),
                      ),
                      if (subtitleParts.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitleParts,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.slate400,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.slate400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: AppColors.royalBlue,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'تعديل المادة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'حذف المادة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSubjectPill(
                  'الدكتور: $doctorName',
                  AppColors.royalBlue,
                  icon: Icons.person_rounded,
                ),
                if (code.isNotEmpty)
                  _buildSubjectPill(
                    'الكود: $code',
                    AppColors.goldDeep,
                    icon: Icons.tag_rounded,
                  ),
                if (semesterName.isNotEmpty)
                  _buildSubjectPill(
                    semesterName,
                    AppColors.teal,
                    icon: Icons.view_week_rounded,
                  ),
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.description_rounded,
                      color: AppColors.slate400,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.slate600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSubjectPill(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectMajorCard extends StatelessWidget {
  const _SubjectMajorCard({
    required this.major,
    required this.onTap,
    required this.color,
  });

  final Map<String, dynamic> major;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final levelsCount = _int(major['levels_count']);
    final hasClinical = major['has_clinical'] == true;
    final hasSemesters = major['has_semesters'] == true;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: color),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.account_tree_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (major['name'] ?? '').toString(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.midnight,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'اضغط لاستعراض وإدارة المواد الدراسية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.slate400,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.slate300,
                    size: 16,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMajorPill(
                    'المستويات المتاحة: $levelsCount',
                    AppColors.royalBlue,
                    icon: Icons.layers_rounded,
                  ),
                  _buildMajorPill(
                    hasClinical ? 'مسار سريري' : 'مسار أكاديمي عادي',
                    hasClinical ? AppColors.rose : AppColors.slate500,
                    icon: hasClinical
                        ? Icons.local_hospital_rounded
                        : Icons.school_rounded,
                  ),
                  _buildMajorPill(
                    hasSemesters ? 'يدعم نظام السيمسترات' : 'نظام أترام سنوي',
                    hasSemesters ? AppColors.violet : AppColors.slate500,
                    icon: hasSemesters
                        ? Icons.view_week_rounded
                        : Icons.calendar_month_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMajorPill(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.item,
    required this.onDetails,
    required this.onManageStars,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onDetails;
  final VoidCallback onManageStars;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] ?? '').toString();
    final email = (item['email'] ?? '').toString();
    final subjects = _list(item['subjects']);
    final wallet = _map(item['doctor_star_wallet'] ?? item['doctorStarWallet']);
    final walletBalance = _int(wallet['balance']);

    return InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: AppColors.royalBlue),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.royalBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.midnight,
                            height: 1.25,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.slate500,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.slate400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'stars') {
                        onManageStars();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'stars',
                        child: Row(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 18,
                              color: AppColors.goldDeep,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'إدارة رصيد النجوم',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: AppColors.royalBlue,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'تعديل الطبيب/الدكتور',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'حذف الدكتور',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDoctorPill(
                    '$walletBalance نجمة متاحة',
                    AppColors.goldDeep,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  if (subjects.isEmpty)
                    _buildDoctorPill(
                      'لا يوجد مواد مسندة بعد',
                      AppColors.slate400,
                      icon: Icons.info_outline_rounded,
                    )
                  else ...[
                    ...subjects
                        .take(3)
                        .map(
                          (sub) => _buildDoctorPill(
                            (sub['name'] ?? '').toString(),
                            AppColors.violet,
                            icon: Icons.menu_book_rounded,
                          ),
                        ),
                    if (subjects.length > 3)
                      _buildDoctorPill(
                        '+${subjects.length - 3} مواد أخرى',
                        AppColors.royalBlue,
                        icon: Icons.more_horiz_rounded,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorPill(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.item,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] ?? '').toString();
    final email = (item['email'] ?? '').toString();
    final studentNumber = (item['student_number'] ?? '-').toString();
    final role = (item['role'] ?? 'student').toString();
    final gender = (item['gender'] ?? 'male').toString() == 'male'
        ? 'ذكر'
        : 'أنثى';
    final levelName = (_map(item['level'])['name'] ?? '-').toString();

    // Role styling
    final Color roleColor;
    final Color roleBgColor;
    final String roleText;

    if (role == 'delegate') {
      roleColor = AppColors.royalBlue;
      roleBgColor = AppColors.royalBlue.withValues(alpha: 0.08);
      roleText = 'مندوب دفعة';
    } else if (role == 'practical_delegate') {
      roleColor = AppColors.teal;
      roleBgColor = AppColors.teal.withValues(alpha: 0.08);
      roleText = 'مندوب عملي';
    } else {
      roleColor = AppColors.slate700;
      roleBgColor = AppColors.slate100;
      roleText = 'طالب';
    }

    return InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? '-' : name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.midnight,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.slate500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: AppColors.royalBlue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'تعديل البيانات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'حذف الطالب',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Chips/Badges section
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: roleBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: roleColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    roleText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: roleColor,
                    ),
                  ),
                ),
                // Student Number Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    'رقم القيد: $studentNumber',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate700,
                    ),
                  ),
                ),
                // Level Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    levelName,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate700,
                    ),
                  ),
                ),
                // Gender Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    gender,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DelegateCard extends StatelessWidget {
  const _DelegateCard({
    required this.item,
    required this.permissionsMeta,
    required this.onDetails,
    required this.onRole,
    required this.onPermissions,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic> permissionsMeta;
  final VoidCallback onDetails;
  final VoidCallback onRole;
  final VoidCallback? onPermissions;

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] ?? '').toString();
    final permissions = _list(item['delegate_permissions']);
    final studentNumber = (item['student_number'] ?? '-').toString();
    final role = (item['role'] ?? 'student').toString();
    final majorName = (_map(item['major'])['name'] ?? '-').toString();
    final levelName = (_map(item['level'])['name'] ?? '-').toString();

    // Role styling
    final Color roleColor;
    final Color roleBgColor;
    final String roleText;

    if (role == 'delegate') {
      roleColor = AppColors.royalBlue;
      roleBgColor = AppColors.royalBlue.withValues(alpha: 0.08);
      roleText = 'مندوب دفعة';
    } else if (role == 'practical_delegate') {
      roleColor = AppColors.teal;
      roleBgColor = AppColors.teal.withValues(alpha: 0.08);
      roleText = 'مندوب عملي';
    } else {
      roleColor = AppColors.slate700;
      roleBgColor = AppColors.slate100;
      roleText = 'طالب';
    }

    return InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent line at the top
            Container(
              height: 4,
              color: AppColors.royalBlue.withValues(alpha: 0.78),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.royalBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? '-' : name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.midnight,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$majorName / $levelName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.slate500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'role',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.manage_accounts_rounded,
                                  size: 18,
                                  color: AppColors.goldDeep,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'تعديل الدور',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onPermissions != null)
                            const PopupMenuItem(
                              value: 'permissions',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.security_rounded,
                                    size: 18,
                                    color: AppColors.royalBlue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'تعديل الصلاحيات',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (value) {
                          if (value == 'role') {
                            onRole();
                          } else if (value == 'permissions') {
                            onPermissions?.call();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: roleBgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          roleText,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: roleColor,
                          ),
                        ),
                      ),
                      // Permissions Count Badge
                      if (_isDelegateRole(role))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: permissions.isNotEmpty
                                ? AppColors.royalBlue.withValues(alpha: 0.08)
                                : AppColors.slate100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: permissions.isNotEmpty
                                  ? AppColors.royalBlue.withValues(alpha: 0.15)
                                  : AppColors.slate200,
                            ),
                          ),
                          child: Text(
                            permissions.isNotEmpty
                                ? '${permissions.length} صلاحيات نشطة'
                                : 'بدون صلاحيات',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: permissions.isNotEmpty
                                  ? AppColors.royalBlue
                                  : AppColors.slate600,
                            ),
                          ),
                        ),
                      // Student Registration Number Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        child: Text(
                          'رقم القيد: $studentNumber',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate700,
                          ),
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
    );
  }
}

class _StudentDetailsSheet extends StatelessWidget {
  const _StudentDetailsSheet({required this.item});

  final Map<String, dynamic> item;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || name.isEmpty) return '؟';
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0] : '؟';
    return '${parts[0][0]}${parts[1][0]}';
  }

  @override
  Widget build(BuildContext context) {
    final major = _map(item['major']);
    final level = _map(item['level']);
    final role = (item['role'] ?? 'student').toString();
    final name = (item['name'] ?? '-').toString();
    final email = (item['email'] ?? '').toString();
    final number = (item['student_number'] ?? '-').toString();
    final gender = (item['gender'] ?? '').toString() == 'male' ? 'ذكر' : 'أنثى';
    final genderIcon = gender == 'ذكر'
        ? Icons.male_rounded
        : Icons.female_rounded;
    final genderColor = gender == 'ذكر' ? AppColors.royalBlue : AppColors.rose;
    final roleColor = _roleColor(role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Identity Card Header ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B3E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D1B3E).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Glow circle
              Positioned(
                top: -24,
                right: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Top accent line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.royalBlue.withValues(alpha: 0),
                        AppColors.royalBlue,
                        AppColors.royalBlue.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  // Avatar with initials
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.royalBlue.withValues(alpha: 0.3),
                          AppColors.royalBlue.withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                              color: AppColors.slate400,
                            ),
                          ),
                        const SizedBox(height: 10),
                        // Badges row
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _SheetBadge(
                              label: _roleLabel(role),
                              icon: Icons.school_rounded,
                              color: roleColor,
                            ),
                            _SheetBadge(
                              label: gender,
                              icon: genderIcon,
                              color: genderColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Section: بيانات التسجيل ────────────────────────────────
        _SheetSection(
          title: 'بيانات التسجيل',
          icon: Icons.badge_rounded,
          color: AppColors.royalBlue,
          children: [
            _SheetInfoRow(
              icon: Icons.tag_rounded,
              label: 'رقم القيد',
              value: number,
              valueColor: AppColors.royalBlue,
              bold: true,
            ),
            if (email.isNotEmpty)
              _SheetInfoRow(
                icon: Icons.email_outlined,
                label: 'البريد الإلكتروني',
                value: email,
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Section: البيانات الأكاديمية ─────────────────────────────
        _SheetSection(
          title: 'البيانات الأكاديمية',
          icon: Icons.school_rounded,
          color: AppColors.goldDeep,
          children: [
            _SheetInfoRow(
              icon: Icons.account_tree_rounded,
              label: 'التخصص',
              value: (major['name'] ?? '-').toString(),
            ),
            _SheetInfoRow(
              icon: Icons.layers_rounded,
              label: 'المستوى',
              value: (level['name'] ?? '-').toString(),
            ),
            _SheetInfoRow(
              icon: Icons.manage_accounts_rounded,
              label: 'الدور',
              value: _roleLabel(role),
              valueColor: roleColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _DoctorDetailsSheet extends StatelessWidget {
  const _DoctorDetailsSheet({required this.item, required this.onManageStars});

  final Map<String, dynamic> item;
  final VoidCallback onManageStars;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || name.isEmpty) return '؟';
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0] : '؟';
    return '${parts[0][0]}${parts[1][0]}';
  }

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] ?? '-').toString();
    final email = (item['email'] ?? '').toString();
    final subjects = _list(item['subjects']);
    final wallet = _map(item['doctor_star_wallet'] ?? item['doctorStarWallet']);
    final walletBalance = _int(wallet['balance']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Identity Card Header ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B3E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D1B3E).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Glow circle
              Positioned(
                top: -24,
                right: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Top accent line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.royalBlue.withValues(alpha: 0),
                        AppColors.royalBlue,
                        AppColors.royalBlue.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  // Avatar with initials
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.royalBlue.withValues(alpha: 0.3),
                          AppColors.royalBlue.withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Badges row
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _SheetBadge(
                              label: 'عضو هيئة التدريس',
                              icon: Icons.school_rounded,
                              color: AppColors.royalBlue,
                            ),
                            _SheetBadge(
                              label: subjects.isEmpty
                                  ? 'لا يوجد مواد مسندة'
                                  : '${subjects.length} مواد مسندة',
                              icon: Icons.menu_book_rounded,
                              color: subjects.isEmpty
                                  ? AppColors.slate400
                                  : AppColors.violet,
                            ),
                            _SheetBadge(
                              label: '$walletBalance نجمة متاحة',
                              icon: Icons.stars_rounded,
                              color: AppColors.goldDeep,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Section: بيانات الحساب ───────────────────────────────────
        _SheetSection(
          title: 'بيانات الحساب والاتصال',
          icon: Icons.badge_rounded,
          color: AppColors.royalBlue,
          children: [
            _SheetInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'الاسم الكامل',
              value: name,
            ),
            if (email.isNotEmpty)
              _SheetInfoRow(
                icon: Icons.email_outlined,
                label: 'البريد الإلكتروني',
                value: email,
                valueColor: AppColors.royalBlue,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Section: المواد الدراسية المسندة ─────────────────────────
        _SheetSection(
          title: 'المواد الدراسية المسندة',
          icon: Icons.menu_book_rounded,
          color: AppColors.violet,
          children: subjects.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: _AdminEmptyDetailsNote(
                      icon: Icons.info_outline_rounded,
                      message: 'لا توجد مواد مسندة لهذا الدكتور حاليًا.',
                    ),
                  ),
                ]
              : subjects.asMap().entries.map((entry) {
                  final isLast = entry.key == subjects.length - 1;
                  final sub = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.violet.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.violet,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                (sub['name'] ?? '-').toString(),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.midnight,
                                ),
                              ),
                            ),
                            if (sub['code'] != null &&
                                sub['code'].toString().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _AdminChip(
                                label: sub['code'].toString(),
                                color: AppColors.goldDeep,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.slate100,
                        ),
                    ],
                  );
                }).toList(),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onManageStars,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.goldDeep,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.account_balance_wallet_rounded),
          label: const Text(
            'إدارة رصيد منح النجوم',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _DoctorStarWalletSheet extends StatefulWidget {
  const _DoctorStarWalletSheet({
    required this.doctor,
    required this.repository,
    required this.onUpdated,
  });

  final Map<String, dynamic> doctor;
  final StaffRepository repository;
  final Future<void> Function() onUpdated;

  @override
  State<_DoctorStarWalletSheet> createState() => _DoctorStarWalletSheetState();
}

class _DoctorStarWalletSheetState extends State<_DoctorStarWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  Map<String, dynamic>? _data;
  Object? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await widget.repository.get(
        '/administrative/doctors/${widget.doctor['id']}/star-wallet',
      );
      if (!mounted) return;
      setState(() => _data = _map(response['data']));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final response = await widget.repository.post(
        '/administrative/doctors/${widget.doctor['id']}/star-wallet/top-up',
        {
          'amount': int.parse(_amount.text.trim()),
          'reason': _reason.text.trim(),
        },
      );
      _amount.clear();
      _reason.clear();
      await _load();
      await widget.onUpdated();
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تمت إضافة الرصيد',
        message: (response['message'] ?? 'تم تحديث رصيد الدكتور بنجاح.')
            .toString(),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذرت إضافة الرصيد',
        message: error.message,
        icon: Icons.error_rounded,
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 36,
              ),
              const SizedBox(height: 10),
              const Text(
                'تعذر تحميل محفظة النجوم.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final wallet = _map(_data?['wallet']);
    final transactions = _list(_data?['transactions']);
    final doctorName = (widget.doctor['name'] ?? 'الدكتور').toString();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B3E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DoctorWalletMetric(
                        label: 'المتاح',
                        value: _int(wallet['balance']),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DoctorWalletMetric(
                        label: 'المخصص',
                        value: _int(wallet['total_allocated']),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DoctorWalletMetric(
                        label: 'الممنوح',
                        value: _int(wallet['total_spent']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'إضافة رصيد جديد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'عدد النجوم',
                    prefixIcon: Icon(Icons.stars_rounded),
                  ),
                  validator: (value) {
                    final amount = int.tryParse((value ?? '').trim());
                    if (amount == null || amount < 1) {
                      return 'أدخل عددًا صحيحًا أكبر من صفر.';
                    }
                    if (amount > 1000000) {
                      return 'الحد الأعلى للعملية 1000000 نجمة.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reason,
                  maxLength: 255,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'سبب إضافة الرصيد',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'سبب الإضافة مطلوب لأغراض التدقيق.'
                      : null,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.goldDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded),
                  label: const Text(
                    'إضافة الرصيد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'آخر حركات الرصيد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 10),
          if (transactions.isEmpty)
            const _AdminEmptyDetailsNote(
              icon: Icons.receipt_long_rounded,
              message: 'لا توجد حركات مسجلة بعد.',
            )
          else
            ...transactions.map((transaction) {
              final amount = _int(transaction['amount']);
              final performer = _map(transaction['performer']);
              final createdAt = (transaction['created_at'] ?? '').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            (amount >= 0
                                    ? AppColors.success
                                    : AppColors.goldDeep)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        amount >= 0
                            ? Icons.add_rounded
                            : Icons.arrow_outward_rounded,
                        color: amount >= 0
                            ? AppColors.success
                            : AppColors.goldDeep,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (transaction['description'] ?? 'حركة رصيد')
                                .toString(),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              if ((performer['name'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                performer['name'],
                              if (createdAt.length >= 10)
                                createdAt.substring(0, 10),
                            ].join(' • '),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.5,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${amount >= 0 ? '+' : ''}$amount',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        color: amount >= 0
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DoctorWalletMetric extends StatelessWidget {
  const _DoctorWalletMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Cairo',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sheet Badge
// ────────────────────────────────────────────────────────────────────────────
class _SheetBadge extends StatelessWidget {
  const _SheetBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sheet Section — labeled group with icon
// ────────────────────────────────────────────────────────────────────────────
class _SheetSection extends StatelessWidget {
  const _SheetSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Section rows
          ...children.asMap().entries.map((entry) {
            final isLast = entry.key == children.length - 1;
            return Column(
              children: [
                entry.value,
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.slate100,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sheet Info Row — single labeled field with icon
// ────────────────────────────────────────────────────────────────────────────
class _SheetInfoRow extends StatelessWidget {
  const _SheetInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.slate400),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.slate500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
                color: valueColor ?? AppColors.midnight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DelegateDetailsSheet extends StatelessWidget {
  const _DelegateDetailsSheet({
    required this.item,
    required this.permissionsMeta,
    required this.onRole,
    required this.onPermissions,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic> permissionsMeta;
  final VoidCallback onRole;
  final VoidCallback? onPermissions;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || name.isEmpty) return '؟';
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0] : '؟';
    return '${parts[0][0]}${parts[1][0]}';
  }

  @override
  Widget build(BuildContext context) {
    final major = _map(item['major']);
    final level = _map(item['level']);
    final role = (item['role'] ?? 'student').toString();
    final name = (item['name'] ?? '-').toString();
    final email = (item['email'] ?? '').toString();
    final number = (item['student_number'] ?? '-').toString();
    final permissions = _list(item['delegate_permissions']);
    final roleColor = _roleColor(role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Identity Card Header ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B3E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D1B3E).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Glow circle
              Positioned(
                top: -24,
                right: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Top accent line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.royalBlue.withValues(alpha: 0),
                        AppColors.royalBlue,
                        AppColors.royalBlue.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  // Avatar with initials
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.royalBlue.withValues(alpha: 0.3),
                          AppColors.royalBlue.withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Badges row
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _SheetBadge(
                              label: _roleLabel(role),
                              icon: Icons.admin_panel_settings_rounded,
                              color: roleColor,
                            ),
                            _SheetBadge(
                              label: permissions.isEmpty
                                  ? 'بدون صلاحيات'
                                  : '${permissions.length} صلاحيات نشطة',
                              icon: Icons.security_rounded,
                              color: permissions.isEmpty
                                  ? AppColors.slate400
                                  : AppColors.royalBlue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Section: بيانات التسجيل والأكاديمية ───────────────────────
        _SheetSection(
          title: 'البيانات الأكاديمية والتسجيل',
          icon: Icons.school_rounded,
          color: AppColors.royalBlue,
          children: [
            _SheetInfoRow(
              icon: Icons.tag_rounded,
              label: 'رقم القيد',
              value: number,
              valueColor: AppColors.royalBlue,
              bold: true,
            ),
            _SheetInfoRow(
              icon: Icons.account_tree_rounded,
              label: 'التخصص',
              value: (major['name'] ?? '-').toString(),
            ),
            _SheetInfoRow(
              icon: Icons.layers_rounded,
              label: 'المستوى',
              value: (level['name'] ?? '-').toString(),
            ),
            _SheetInfoRow(
              icon: Icons.manage_accounts_rounded,
              label: 'الدور الحالي',
              value: _roleLabel(role),
              valueColor: roleColor,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Section: صلاحيات المندوب ─────────────────────────────────
        _SheetSection(
          title: 'الصلاحيات والتراخيص الممنوحة',
          icon: Icons.security_rounded,
          color: AppColors.teal,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: permissions.isEmpty
                  ? const _AdminEmptyDetailsNote(
                      icon: Icons.lock_outline_rounded,
                      message: 'لا توجد صلاحيات مفعلة لهذا المندوب حاليًا.',
                    )
                  : _PermissionsPreview(
                      permissions: permissions,
                      permissionsMeta: permissionsMeta,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Action Buttons for Change Role / Change Permissions ─────
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onRole,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.goldDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.goldDeep.withValues(alpha: 0.3),
                ),
                icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                label: const Text(
                  'تغيير الدور',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (onPermissions != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPermissions,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                    shadowColor: AppColors.royalBlue.withValues(alpha: 0.3),
                  ),
                  icon: const Icon(Icons.security_rounded, size: 18),
                  label: const Text(
                    'تعديل الصلاحيات',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AdminChip extends StatelessWidget {
  const _AdminChip({required this.label, this.color = AppColors.slate700});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _AdminEmptyDetailsNote extends StatelessWidget {
  const _AdminEmptyDetailsNote({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.slate500, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionsPreview extends StatelessWidget {
  const _PermissionsPreview({
    required this.permissions,
    required this.permissionsMeta,
  });

  final List<Map<String, dynamic>> permissions;
  final Map<String, dynamic> permissionsMeta;

  @override
  Widget build(BuildContext context) {
    final resources = _map(permissionsMeta['resources']);
    final actions = _map(permissionsMeta['actions']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الصلاحيات المفعلة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: permissions.map((permission) {
              final resource = (permission['resource'] ?? '').toString();
              final action = (permission['action'] ?? '').toString();
              final label =
                  [resources[resource] ?? resource, actions[action] ?? action]
                      .where(
                        (value) => value != null && value.toString().isNotEmpty,
                      )
                      .join(' - ');
              return _AdminChip(
                label: label.isEmpty ? 'صلاحية' : label,
                color: AppColors.royalBlue,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.pagination,
    required this.onPrevious,
    required this.onNext,
  });

  final _PageInfo pagination;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (pagination.lastPage <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        Text(
          '${pagination.currentPage} / ${pagination.lastPage}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, color: AppColors.slate400, size: 44),
          SizedBox(height: 8),
          Text(
            'لا توجد بيانات مطابقة حاليًا.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AdminMeta {
  const _AdminMeta({
    required this.title,
    required this.singleLabel,
    required this.subtitle,
    required this.route,
    required this.endpoint,
    required this.icon,
    required this.color,
  });

  final String title;
  final String singleLabel;
  final String subtitle;
  final String route;
  final String endpoint;
  final IconData icon;
  final Color color;
}

class _AdminStat {
  const _AdminStat(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _PageInfo {
  const _PageInfo(this.currentPage, this.lastPage, this.total);

  final int currentPage;
  final int lastPage;
  final int total;
}

class _MenuItem<T> {
  const _MenuItem(this.value, this.label);

  final T value;
  final String label;
}

_AdminMeta _metaFor(_AdminSection section) {
  switch (section) {
    case _AdminSection.majors:
      return const _AdminMeta(
        title: 'إدارة التخصصات',
        singleLabel: 'تخصص',
        subtitle:
            'إعداد التخصصات الأكاديمية وبناء المستويات والأترام والسيمسترات.',
        route: AdministrativeMajorsScreen.route,
        endpoint: '/administrative/majors',
        icon: Icons.account_tree_rounded,
        color: AppColors.teal,
      );
    case _AdminSection.subjects:
      return const _AdminMeta(
        title: 'إدارة المواد الدراسية',
        singleLabel: 'مادة',
        subtitle: 'تثبيت المواد وربطها بالترم والدكتور المسؤول عنها.',
        route: AdministrativeSubjectsScreen.route,
        endpoint: '/administrative/subjects',
        icon: Icons.menu_book_rounded,
        color: AppColors.royalBlue,
      );
    case _AdminSection.doctors:
      return const _AdminMeta(
        title: 'إدارة الدكاترة',
        singleLabel: 'دكتور',
        subtitle: 'إدارة حسابات الكادر التعليمي داخل الكلية.',
        route: AdministrativeDoctorsScreen.route,
        endpoint: '/administrative/doctors',
        icon: Icons.school_rounded,
        color: AppColors.royalBlue,
      );
    case _AdminSection.students:
      return const _AdminMeta(
        title: 'إدارة الطلاب',
        singleLabel: 'طالب',
        subtitle: 'إضافة الطلاب وتحديث بياناتهم وربطهم بالتخصص والمستوى.',
        route: AdministrativeStudentsScreen.route,
        endpoint: '/administrative/students',
        icon: Icons.groups_rounded,
        color: AppColors.teal,
      );
    case _AdminSection.delegates:
      return const _AdminMeta(
        title: 'إدارة المندوبين والصلاحيات',
        singleLabel: 'مندوب',
        subtitle: 'ترقية الطلاب إلى مندوبين وتحديد ما يمكنهم إدارته بالضبط.',
        route: AdministrativeDelegatesScreen.route,
        endpoint: '/administrative/delegates',
        icon: Icons.admin_panel_settings_rounded,
        color: AppColors.royalBlue,
      );
  }
}

Color _roleColor(String role) {
  if (role == 'delegate') return AppColors.royalBlue;
  if (role == 'practical_delegate') return AppColors.teal;
  return AppColors.slate700;
}

String _roleLabel(String role) {
  if (role == 'delegate') return 'مندوب دفعة';
  if (role == 'practical_delegate') return 'مندوب عملي';
  return 'طالب';
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.slate200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _titleOf(Map<String, dynamic> item) => (item['name'] ?? '-').toString();

bool _isDelegateRole(Object? role) {
  final value = (role ?? '').toString();
  return value == 'delegate' || value == 'practical_delegate';
}

String _termLabel(Map<String, dynamic> term) {
  final level = _map(term['level']);
  final major = _map(level['major']);
  return [
    major['name'],
    level['name'],
    term['name'],
  ].where((value) => value != null && value.toString().isNotEmpty).join(' / ');
}

String _levelLabel(Map<String, dynamic> level) {
  final major = _map(level['major']);
  final majorName = major['name']?.toString();
  final levelName = (level['name'] ?? '').toString();
  return majorName == null || majorName.isEmpty
      ? levelName
      : '$majorName / $levelName';
}

List<Map<String, dynamic>> _allLevels(Map<String, dynamic> payload) {
  final levels = <Map<String, dynamic>>[];
  for (final major in _list(payload['majors'])) {
    for (final level in _list(major['levels'])) {
      levels.add({...level, 'major': major});
    }
  }
  return levels;
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is List) {
    return value.whereType<Map>().map(_map).toList();
  }
  return const [];
}

int _int(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}
