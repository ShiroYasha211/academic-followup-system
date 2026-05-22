import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _AdminMeta get _meta => _metaFor(widget.section);

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    return StaffShell(
      title: meta.title,
      currentRoute: meta.route,
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
                children: [
                  _AdminHero(meta: meta),
                  const SizedBox(height: 18),
                  _StatsRow(stats: _stats()),
                  const SizedBox(height: 18),
                  _Toolbar(
                    meta: meta,
                    searchController: _searchController,
                    hasCreate: widget.section != _AdminSection.delegates,
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

  bool get _showFilters =>
      widget.section == _AdminSection.subjects ||
      widget.section == _AdminSection.students ||
      widget.section == _AdminSection.delegates;

  List<Map<String, dynamic>> get _items {
    final data = _payload ?? const <String, dynamic>{};
    switch (widget.section) {
      case _AdminSection.majors:
        return _list(data['items']);
      case _AdminSection.subjects:
        return _list(data['subjects']);
      case _AdminSection.doctors:
        return _list(data['doctors']);
      case _AdminSection.students:
        return _list(data['students']);
      case _AdminSection.delegates:
        return _list(data['users']);
    }
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
            AppColors.violet,
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
            AppColors.goldDeep,
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
            AppColors.goldDeep,
          ),
          _AdminStat(
            'عملي',
            _int(stats['practical_delegates']).toString(),
            Icons.medical_services_rounded,
            AppColors.rose,
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
          onEdit: () => _openForm(item: item),
          onDelete: () => _confirmDelete(item),
        );
      case _AdminSection.students:
        return _StudentCard(
          item: item,
          onEdit: () => _openForm(item: item),
          onDelete: () => _confirmDelete(item),
        );
      case _AdminSection.delegates:
        return _DelegateCard(
          item: item,
          permissionsMeta: _map(_payload?['available_permissions']),
          onRole: () => _openRoleForm(item),
          onPermissions: _isDelegateRole(item['role'])
              ? () => _openPermissionsForm(item)
              : null,
        );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(_adminRepositoryProvider)
          .get(_meta.endpoint, query: _query());
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
    final query = <String, dynamic>{'page': _page};
    final search = _searchController.text.trim();
    if (search.isNotEmpty) query['search'] = search;
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
  });

  final _AdminSection section;
  final Map<String, dynamic>? item;
  final Map<String, dynamic> payload;
  final Color color;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

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
            _number('levels_count', 'عدد المستويات', min: 1, max: 8),
            _number('terms_count', 'عدد الأترام لكل مستوى', min: 1, max: 4),
            _number(
              'semesters_per_term',
              'عدد السيمسترات لكل ترم',
              min: 0,
              max: 10,
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
            (v) => setState(() => _hasSemesters = v),
          ),
        ];
      case _AdminSection.subjects:
        final terms = _list(widget.payload['terms']);
        final selectedTerm = terms.firstWhere(
          (term) => _int(term['id']) == _termId,
          orElse: () => const {},
        );
        final semesters = _list(selectedTerm['semesters']);
        return [
          _text('name', 'اسم المادة', required: true),
          _text('code', 'كود المادة', required: false),
          _text('description', 'وصف مختصر', required: false, maxLines: 3),
          _dropdown<int>(
            label: 'الترم',
            value: _termId == 0 ? null : _termId,
            items: terms
                .map((term) => _MenuItem(_int(term['id']), _termLabel(term)))
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
            label: 'الدكتور',
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
        ];
      case _AdminSection.doctors:
        return [
          _text('name', 'اسم الدكتور', required: true),
          _text(
            'email',
            'البريد الإلكتروني',
            required: true,
            keyboardType: TextInputType.emailAddress,
          ),
          _text(
            'password',
            widget.item == null ? 'كلمة المرور' : 'كلمة مرور جديدة (اختياري)',
            required: widget.item == null,
            obscure: true,
          ),
        ];
      case _AdminSection.students:
        return [
          _text('name', 'اسم الطالب', required: true),
          _text(
            'email',
            'البريد الإلكتروني',
            required: true,
            keyboardType: TextInputType.emailAddress,
          ),
          _text('student_number', 'رقم القيد', required: true),
          _text(
            'password',
            widget.item == null ? 'كلمة المرور' : 'كلمة مرور جديدة (اختياري)',
            required: widget.item == null,
            obscure: true,
          ),
          _dropdown<String>(
            label: 'الجنس',
            value: _gender,
            items: const [
              _MenuItem('male', 'ذكر'),
              _MenuItem('female', 'أنثى'),
            ],
            onChanged: (value) => setState(() => _gender = value ?? 'male'),
          ),
          _dropdown<int>(
            label: 'المستوى الدراسي',
            value: _levelId == 0 ? null : _levelId,
            items: _allLevels(widget.payload)
                .map(
                  (level) => _MenuItem(_int(level['id']), _levelLabel(level)),
                )
                .toList(),
            onChanged: (value) => setState(() => _levelId = value),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _number(
    String key,
    String label, {
    required int min,
    required int max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          final number = int.tryParse((value ?? '').trim());
          if (number == null) return 'أدخل رقمًا صحيحًا.';
          if (number < min || number > max) return 'القيمة بين $min و $max.';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
        DropdownButtonFormField<String>(
          initialValue: _role,
          decoration: InputDecoration(
            labelText: 'الدور',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          items: const [
            DropdownMenuItem(value: 'student', child: Text('طالب')),
            DropdownMenuItem(value: 'delegate', child: Text('مندوب دفعة')),
            DropdownMenuItem(
              value: 'practical_delegate',
              child: Text('مندوب عملي'),
            ),
          ],
          onChanged: (value) => setState(() => _role = value ?? 'student'),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSubmit(_role);
                  if (mounted) setState(() => _saving = false);
                },
          icon: const Icon(Icons.save_rounded),
          label: const Text('حفظ الدور'),
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
                Text(
                  resource.value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...actions.entries.map((action) {
                  final key = '${resource.key}.${action.key}';
                  return CheckboxListTile(
                    value: _selected.contains(key),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(key);
                        } else {
                          _selected.remove(key);
                        }
                      });
                    },
                    title: Text(action.value.toString()),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSubmit(_selected.toList());
                  if (mounted) setState(() => _saving = false);
                },
          icon: const Icon(Icons.save_rounded),
          label: const Text('حفظ الصلاحيات'),
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
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward_rounded),
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

  @override
  Widget build(BuildContext context) {
    final majors = _list(payload['majors']);
    final selectedMajor = majors.firstWhere(
      (major) => _int(major['id']) == majorFilter,
      orElse: () => const {},
    );
    final levels = section == _AdminSection.delegates && majorFilter != null
        ? _list(payload['levels'])
        : majorFilter == null
        ? _allLevels(payload)
        : _list(selectedMajor['levels']);
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
        if (section == _AdminSection.students ||
            section == _AdminSection.delegates)
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
        if (section == _AdminSection.subjects)
          _SmallDropdown<int>(
            label: 'الترم',
            value: termFilter,
            items: _list(
              payload['terms'],
            ).map((t) => _MenuItem(_int(t['id']), _termLabel(t))).toList(),
            onChanged: onTermChanged,
          ),
        if (section == _AdminSection.subjects)
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
    return _EntityCard(
      icon: Icons.account_tree_rounded,
      color: AppColors.teal,
      title: (item['name'] ?? '').toString(),
      subtitle: '${levels.length} مستوى دراسي',
      chips: [
        if (item['has_clinical'] == true) 'سريري',
        if (item['has_semesters'] == true) 'سيمسترات',
      ],
      onEdit: onEdit,
      onDelete: onDelete,
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
    return _EntityCard(
      icon: Icons.menu_book_rounded,
      color: AppColors.violet,
      title: (item['name'] ?? '').toString(),
      subtitle: [
        _map(item['major'])['name'],
        _map(item['level'])['name'],
        _map(item['term'])['name'],
      ].where((v) => v != null && v.toString().isNotEmpty).join(' / '),
      chips: [
        if ((item['code'] ?? '').toString().isNotEmpty) item['code'].toString(),
        'الدكتور: ${_map(item['doctor'])['name'] ?? 'غير محدد'}',
        if (_map(item['semester']).isNotEmpty)
          _map(item['semester'])['name'].toString(),
      ],
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subjects = _list(item['subjects']);
    return _EntityCard(
      icon: Icons.school_rounded,
      color: AppColors.royalBlue,
      title: (item['name'] ?? '').toString(),
      subtitle: (item['email'] ?? '').toString(),
      chips: ['${subjects.length} مادة'],
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _EntityCard(
      icon: Icons.person_rounded,
      color: _isDelegateRole(item['role'])
          ? AppColors.goldDeep
          : AppColors.teal,
      title: (item['name'] ?? '').toString(),
      subtitle: (item['email'] ?? '').toString(),
      chips: [
        'رقم القيد: ${item['student_number'] ?? '-'}',
        _roleLabel(item['role']),
        '${_map(item['major'])['name'] ?? '-'} / ${_map(item['level'])['name'] ?? '-'}',
      ],
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

class _DelegateCard extends StatelessWidget {
  const _DelegateCard({
    required this.item,
    required this.permissionsMeta,
    required this.onRole,
    required this.onPermissions,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic> permissionsMeta;
  final VoidCallback onRole;
  final VoidCallback? onPermissions;

  @override
  Widget build(BuildContext context) {
    final permissions = _list(item['delegate_permissions']);
    return _EntityCard(
      icon: Icons.admin_panel_settings_rounded,
      color: _isDelegateRole(item['role'])
          ? AppColors.goldDeep
          : AppColors.slate500,
      title: (item['name'] ?? '').toString(),
      subtitle:
          '${_map(item['major'])['name'] ?? '-'} / ${_map(item['level'])['name'] ?? '-'}',
      chips: [
        _roleLabel(item['role']),
        if (_isDelegateRole(item['role'])) '${permissions.length} صلاحية',
        item['student_number']?.toString() ?? '',
      ],
      customActions: [
        _IconAction(
          icon: Icons.manage_accounts_rounded,
          color: AppColors.goldDeep,
          onTap: onRole,
        ),
        if (onPermissions != null)
          _IconAction(
            icon: Icons.security_rounded,
            color: AppColors.royalBlue,
            onTap: onPermissions!,
          ),
      ],
    );
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.chips = const [],
    this.onEdit,
    this.onDelete,
    this.customActions,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<String> chips;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final List<Widget>? customActions;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? '-' : title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (customActions != null)
                Row(children: customActions!)
              else ...[
                if (onEdit != null)
                  _IconAction(
                    icon: Icons.edit_rounded,
                    color: AppColors.royalBlue,
                    onTap: onEdit!,
                  ),
                if (onDelete != null)
                  _IconAction(
                    icon: Icons.delete_rounded,
                    color: AppColors.danger,
                    onTap: onDelete!,
                  ),
              ],
            ],
          ),
          finalChips(chips),
        ],
      ),
    );
  }

  Widget finalChips(List<String> chips) {
    final clean = chips.where((chip) => chip.trim().isNotEmpty).toList();
    if (clean.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: clean
            .map(
              (chip) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  chip,
                  style: const TextStyle(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: color,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
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
        color: AppColors.violet,
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
        color: AppColors.goldDeep,
      );
  }
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

String _roleLabel(Object? role) {
  return switch ((role ?? '').toString()) {
    'delegate' => 'مندوب دفعة',
    'practical_delegate' => 'مندوب عملي',
    'doctor' => 'دكتور',
    _ => 'طالب',
  };
}

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
