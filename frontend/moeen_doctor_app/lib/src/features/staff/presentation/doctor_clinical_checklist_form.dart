part of 'staff_screens.dart';

class DoctorChecklistFormScreen extends ConsumerStatefulWidget {
  const DoctorChecklistFormScreen({
    super.key,
    this.checklistId,
    this.initialChecklist,
  });

  static const createRoute = '/doctor/clinical/evaluations/checklists/create';
  static const editRoute =
      '/doctor/clinical/evaluations/checklists/:checklistId/edit';

  final int? checklistId;
  final Map<String, dynamic>? initialChecklist;

  @override
  ConsumerState<DoctorChecklistFormScreen> createState() =>
      _DoctorChecklistFormScreenState();
}

class _DoctorChecklistFormScreenState
    extends ConsumerState<DoctorChecklistFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _minutes = TextEditingController(text: '15');
  final List<_ChecklistItemDraft> _items = [];

  Future<void>? _loadFuture;
  String _skillType = 'history_taking';
  String _timerType = 'fixed';
  bool _practiceAllowed = true;
  bool _trackAdminUpdates = true;
  bool _submitting = false;
  bool _loaded = false;
  bool _isStandard = false;

  bool get _isEditing => widget.checklistId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadFuture = _loadChecklist();
    } else {
      _populate(null);
    }
  }

  Future<void> _loadChecklist() async {
    if (widget.initialChecklist != null &&
        _docList(widget.initialChecklist!['items']).isNotEmpty) {
      _populate(widget.initialChecklist);
      return;
    }

    final response = await ref
        .read(staffRepositoryProvider)
        .get('/doctor/clinical/evaluations/checklists/${widget.checklistId}');
    final data = _docMap(_docData(response));
    _populate(data);
  }

  void _populate(Map<String, dynamic>? raw) {
    if (_loaded) return;
    _loaded = true;
    final item = raw == null ? const <String, dynamic>{} : _docMap(raw);
    _title.text = _docText(item['title']);
    _description.text = _docText(item['description']);
    _skillType = _docText(item['skill_type'], 'history_taking');
    _practiceAllowed = raw == null
        ? true
        : _docBool(item['is_practice_allowed']);
    _trackAdminUpdates = raw == null
        ? true
        : item.containsKey('tracks_admin_updates')
            ? _docBool(item['tracks_admin_updates'])
            : true;
    _isStandard =
        _docBool(item['is_standard']) ||
        (_isEditing && _docText(item['doctor_id']).isEmpty);

    final timeLimit = _docInt(item['time_limit_minutes']);
    _timerType = timeLimit > 0 ? 'fixed' : 'open';
    _minutes.text = timeLimit > 0 ? '$timeLimit' : '15';

    for (final draft in _items) {
      draft.dispose();
    }
    _items
      ..clear()
      ..addAll(_draftsFromChecklist(item));
    if (_items.isEmpty) _items.add(_ChecklistItemDraft());
  }

  List<_ChecklistItemDraft> _draftsFromChecklist(Map<String, dynamic> item) {
    final tree = _docList(item['items_tree']).isNotEmpty
        ? _docList(item['items_tree'])
        : _docList(item['items']);
    if (tree.isEmpty) return [];

    final looksNested = tree.any((entry) => entry.containsKey('sub_items'));
    if (looksNested) {
      return tree
          .where((entry) {
            final parent = _docText(entry['parent_id']);
            return parent.isEmpty || parent == '0';
          })
          .map(
            (entry) => _ChecklistItemDraft(
              description: _docText(entry['description']),
              marks: _docText(entry['marks'], '1'),
              subItems: _docList(entry['sub_items'])
                  .map(
                    (sub) => _ChecklistSubItemDraft(
                      description: _docText(sub['description']),
                      marks: _docText(sub['marks'], '1'),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
    }

    final flat = tree;
    return flat
        .where((entry) {
          final parent = _docText(entry['parent_id']);
          return parent.isEmpty || parent == '0';
        })
        .map((entry) {
          final id = _docText(entry['id']);
          return _ChecklistItemDraft(
            description: _docText(entry['description']),
            marks: _docText(entry['marks'], '1'),
            subItems: flat
                .where((sub) => _docText(sub['parent_id']) == id)
                .map(
                  (sub) => _ChecklistSubItemDraft(
                    description: _docText(sub['description']),
                    marks: _docText(sub['marks'], '1'),
                  ),
                )
                .toList(),
          );
        })
        .toList();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _minutes.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int get _totalMarks => _items.fold<int>(0, (sum, item) => sum + item.marks);
  int get _subItemsCount =>
      _items.fold<int>(0, (sum, item) => sum + item.subItems.length);

  @override
  Widget build(BuildContext context) {
    if (_loadFuture != null && !_loaded) {
      return StaffShell(
        title: 'قائمة تقييم OSCE',
        currentRoute: DoctorClinicalSectionScreen.path('checklists'),
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
            return _buildForm();
          },
        ),
      );
    }

    return StaffShell(
      title: _isEditing ? 'تعديل قائمة تقييم' : 'إضافة قائمة تقييم',
      currentRoute: DoctorClinicalSectionScreen.path('checklists'),
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 110;
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          _buildBasicsCard(),
          const SizedBox(height: 14),
          _buildScoreSummary(),
          const SizedBox(height: 14),
          _buildItemsBuilder(),
          const SizedBox(height: 18),
          _buildPreviewCard(),
          const SizedBox(height: 20),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.royalBlue.withValues(alpha: 0.85),
            AppColors.midnight,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'تعديل قائمة OSCE' : 'إنشاء قائمة OSCE',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing
                          ? 'راجع البيانات والعناصر ثم احفظ النسخة المحدثة.'
                          : 'ابن قائمة تقييم واضحة قابلة للاستخدام في الاختبار والتدريب السريري.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isStandard) ...[
            const SizedBox(height: 16),
            _HeroNotice(
              text:
                  'هذه قائمة أساسية. عند حفظ التعديل سيتم إنشاء نسخة مخصصة لك دون تغيير الأصل.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicsCard() {
    return _FormSectionCard(
      title: 'بيانات القائمة',
      subtitle: 'المعلومات التي تظهر للدكتور والطالب عند بدء التقييم.',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _title,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'عنوان القائمة',
              hintText: 'مثال: فحص الجهاز التنفسي',
              prefixIcon: Icon(Icons.title_rounded),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'العنوان مطلوب.' : null,
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'نوع المهارة السريرية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              _buildSkillChoice(
                type: 'history_taking',
                title: 'أخذ قصة مرضية',
                icon: Icons.forum_rounded,
                color: AppColors.royalBlue,
              ),
              _buildSkillChoice(
                type: 'clinical_examination',
                title: 'فحص سريري',
                icon: Icons.healing_rounded,
                color: AppColors.teal,
              ),
              _buildSkillChoice(
                type: 'procedure',
                title: 'إجراء طبي',
                icon: Icons.vaccines_rounded,
                color: AppColors.goldDeep,
              ),
              _buildSkillChoice(
                type: 'communication',
                title: 'مهارات تواصل',
                icon: Icons.record_voice_over_rounded,
                color: AppColors.orange,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'وصف مختصر',
              hintText: 'اكتب ملاحظات أو هدف القائمة إن وجد.',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 14),
          _TimerModePicker(
            value: _timerType,
            onChanged: (value) => setState(() => _timerType = value),
          ),
          if (_timerType == 'fixed') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'المدة بالدقائق',
                hintText: '15',
                prefixIcon: Icon(Icons.timer_rounded),
              ),
              validator: (value) {
                if (_timerType != 'fixed') return null;
                final number = int.tryParse(value?.trim() ?? '');
                if (number == null) return 'اكتب مدة صحيحة.';
                if (number < 1 || number > 120) {
                  return 'المدة يجب أن تكون بين 1 و 120 دقيقة.';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _practiceAllowed,
            onChanged: (value) => setState(() => _practiceAllowed = value),
            title: const Text(
              'السماح للطلاب بالتدريب',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: const Text(
              'عند تفعيلها يستطيع الطالب استخدام القائمة في وضع التدريب.',
              style: TextStyle(fontFamily: 'Cairo', height: 1.35),
            ),
          ),
          if (_isStandard) ...[
            const Divider(height: 18),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _trackAdminUpdates,
              onChanged: (value) =>
                  setState(() => _trackAdminUpdates = value),
              title: const Text(
                'تلقي تحديثات الأدمن لهذه القائمة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: const Text(
                'عند تفعيلها سيظهر لك تنبيه إذا نشر الأدمن نسخة أحدث من القائمة الأصلية. عند تعطيلها ستبقى نسختك مستقلة ولن تظهر تنبيهات التحديث.',
                style: TextStyle(fontFamily: 'Cairo', height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillChoice({
    required String type,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final active = _skillType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _skillType = type),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.08)
                : AppColors.slate50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? color : AppColors.slate100,
              width: active ? 1.5 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: active ? color.withValues(alpha: 0.12) : AppColors.slate100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: active ? color : AppColors.slate400,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: active ? color : AppColors.midnight,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSummary() {
    final invalidCount = _items
        .where((item) => item.hasSubScoreMismatch)
        .length;
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'إجمالي الدرجات',
            value: '$_totalMarks',
            icon: Icons.functions_rounded,
            color: AppColors.royalBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            label: 'البنود',
            value: '${_items.length}',
            icon: Icons.checklist_rounded,
            color: AppColors.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            label: 'الفرعيات',
            value: '$_subItemsCount',
            icon: invalidCount > 0
                ? Icons.warning_rounded
                : Icons.account_tree_rounded,
            color: invalidCount > 0 ? AppColors.danger : AppColors.goldDeep,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsBuilder() {
    return _FormSectionCard(
      title: 'عناصر التقييم',
      subtitle:
          'كل عنصر رئيسي يمكن أن يحتوي معايير فرعية. مجموع الفرعيات يجب أن يساوي درجة العنصر.',
      icon: Icons.account_tree_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._items.asMap().entries.map(
            (entry) => _ChecklistMainItemEditor(
              index: entry.key,
              item: entry.value,
              canDelete: _items.length > 1,
              onChanged: () => setState(() {}),
              onDelete: () {
                setState(() {
                  _items.removeAt(entry.key).dispose();
                });
              },
              onDuplicate: () {
                setState(() {
                  _items.insert(entry.key + 1, entry.value.copy());
                });
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() => _items.add(_ChecklistItemDraft())),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'إضافة عنصر رئيسي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return _FormSectionCard(
      title: 'معاينة قبل الحفظ',
      subtitle: 'ملخص سريع لما سيستخدم في جلسة التقييم.',
      icon: Icons.visibility_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PreviewRow(
            label: 'العنوان',
            value: _title.text.trim().isEmpty ? '-' : _title.text.trim(),
          ),
          _PreviewRow(label: 'نوع المهارة', value: _skillLabel(_skillType)),
          _PreviewRow(
            label: 'المؤقت',
            value: _timerType == 'fixed'
                ? '${_minutes.text.trim().isEmpty ? '0' : _minutes.text.trim()} دقيقة'
                : 'وقت مفتوح',
          ),
          _PreviewRow(
            label: 'التدريب',
            value: _practiceAllowed ? 'متاح للطلاب' : 'غير متاح للطلاب',
          ),
          _PreviewRow(label: 'إجمالي الدرجات', value: '$_totalMarks درجة'),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _submitting ? null : () => context.pop(false),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(
              'رجوع',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
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
              _isEditing ? 'حفظ التعديل' : 'حفظ القائمة',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final fieldOk = _formKey.currentState?.validate() == true;
    final errors = _validateDraft();
    if (!fieldOk || errors.isNotEmpty) {
      await showMoeenInfoDialog(
        context: context,
        title: 'راجع بيانات القائمة',
        message: errors.isEmpty
            ? 'توجد حقول مطلوبة لم تكتمل.'
            : errors.join('\n'),
        icon: Icons.error_rounded,
        color: AppColors.danger,
      );
      return;
    }

    if (_isStandard) {
      final approved = await showMoeenConfirmDialog(
        context: context,
        title: 'إنشاء نسخة مخصصة',
        message:
            'هذه قائمة أساسية. عند الحفظ سيتم إنشاء نسخة مخصصة لك وإخفاء الأصل من قائمتك.',
        confirmLabel: 'حفظ كنسخة',
        cancelLabel: 'إلغاء',
        icon: Icons.copy_rounded,
        color: AppColors.royalBlue,
      );
      if (!approved) return;
    }

    setState(() => _submitting = true);
    try {
      final payload = {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'skill_type': _skillType,
        'time_limit_minutes': _timerType == 'fixed'
            ? int.tryParse(_minutes.text.trim())
            : null,
        'is_practice_allowed': _practiceAllowed,
        if (_isStandard) 'tracks_admin_updates': _trackAdminUpdates,
        'items': _items.map((item) => item.toPayload()).toList(),
      };

      if (_isEditing) {
        await ref
            .read(staffRepositoryProvider)
            .put(
              '/doctor/clinical/evaluations/checklists/${widget.checklistId}',
              payload,
            );
      } else {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/clinical/evaluations/checklists', payload);
      }

      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: _isEditing ? 'تم حفظ التعديل' : 'تم إنشاء القائمة',
        message: 'تم حفظ قائمة التقييم بنجاح.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<String> _validateDraft() {
    final errors = <String>[];
    if (_items.isEmpty) errors.add('أضف عنصر تقييم واحد على الأقل.');
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      final name = item.description.text.trim();
      if (name.isEmpty) errors.add('العنصر ${i + 1}: وصف العنصر مطلوب.');
      if (item.marks <= 0) errors.add('العنصر ${i + 1}: الدرجة غير صحيحة.');
      for (var j = 0; j < item.subItems.length; j++) {
        final sub = item.subItems[j];
        if (sub.description.text.trim().isEmpty) {
          errors.add('العنصر ${i + 1}.${j + 1}: وصف المعيار الفرعي مطلوب.');
        }
        if (sub.marks <= 0) {
          errors.add(
            'العنصر ${i + 1}.${j + 1}: درجة المعيار الفرعي غير صحيحة.',
          );
        }
      }
      if (item.hasSubScoreMismatch) {
        errors.add(
          'العنصر "$name": مجموع الفرعيات ${item.subMarks} لا يساوي درجة العنصر ${item.marks}.',
        );
      }
    }
    return errors;
  }

  String _skillLabel(String value) {
    return switch (value) {
      'history_taking' => 'أخذ قصة مرضية',
      'clinical_examination' => 'فحص سريري',
      'procedure' => 'إجراء طبي',
      'communication' => 'مهارات تواصل',
      _ => 'مهارة أخرى',
    };
  }
}

class _ChecklistItemDraft {
  _ChecklistItemDraft({
    String description = '',
    String marks = '1',
    List<_ChecklistSubItemDraft>? subItems,
  }) : description = TextEditingController(text: description),
       marksController = TextEditingController(text: marks),
       subItems = subItems ?? [];

  final TextEditingController description;
  final TextEditingController marksController;
  final List<_ChecklistSubItemDraft> subItems;

  int get marks => int.tryParse(marksController.text.trim()) ?? 0;
  int get subMarks => subItems.fold<int>(0, (sum, item) => sum + item.marks);
  bool get hasSubScoreMismatch => subItems.isNotEmpty && subMarks != marks;

  _ChecklistItemDraft copy() {
    return _ChecklistItemDraft(
      description: description.text,
      marks: marksController.text,
      subItems: subItems.map((item) => item.copy()).toList(),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'description': description.text.trim(),
      'marks': marks,
      if (subItems.isNotEmpty)
        'sub_items': subItems.map((item) => item.toPayload()).toList(),
    };
  }

  void dispose() {
    description.dispose();
    marksController.dispose();
    for (final item in subItems) {
      item.dispose();
    }
  }
}

class _ChecklistSubItemDraft {
  _ChecklistSubItemDraft({String description = '', String marks = '1'})
    : description = TextEditingController(text: description),
      marksController = TextEditingController(text: marks);

  final TextEditingController description;
  final TextEditingController marksController;

  int get marks => int.tryParse(marksController.text.trim()) ?? 0;

  _ChecklistSubItemDraft copy() => _ChecklistSubItemDraft(
    description: description.text,
    marks: marksController.text,
  );

  Map<String, dynamic> toPayload() => {
    'description': description.text.trim(),
    'marks': marks,
  };

  void dispose() {
    description.dispose();
    marksController.dispose();
  }
}

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.04),
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
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.royalBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChecklistMainItemEditor extends StatelessWidget {
  const _ChecklistMainItemEditor({
    required this.index,
    required this.item,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
  });

  final int index;
  final _ChecklistItemDraft item;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final mismatch = item.hasSubScoreMismatch;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mismatch
            ? AppColors.danger.withValues(alpha: 0.03)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: mismatch
              ? AppColors.danger.withValues(alpha: 0.35)
              : AppColors.slate200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (mismatch ? AppColors.danger : AppColors.midnight).withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: mismatch ? AppColors.danger : AppColors.royalBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'العنصر الرئيسي',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: mismatch ? AppColors.danger : AppColors.midnight,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'تكرار العنصر',
                onPressed: onDuplicate,
                icon: const Icon(Icons.copy_rounded, size: 19),
              ),
              if (canDelete)
                IconButton(
                  tooltip: 'حذف العنصر',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.danger,
                    size: 19,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: item.description,
            minLines: 1,
            maxLines: 3,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'وصف العنصر الرئيسي',
              hintText: 'مثال: فحص الصدر بالنظر واللمس',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: item.marksController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'درجة العنصر',
              prefixIcon: Icon(Icons.score_rounded),
            ),
          ),
          if (item.subItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'المعايير الفرعية المستهدفة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: mismatch ? AppColors.danger : AppColors.slate700,
                    ),
                  ),
                ),
                _InlineBadge(
                  text: '${item.subMarks} من ${item.marks} درجات',
                  color: mismatch ? AppColors.danger : AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...item.subItems.asMap().entries.map(
              (entry) => _ChecklistSubItemEditor(
                index: entry.key,
                item: entry.value,
                onChanged: onChanged,
                onDelete: () {
                  item.subItems.removeAt(entry.key).dispose();
                  onChanged();
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                item.subItems.add(_ChecklistSubItemDraft());
                onChanged();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'إضافة معيار فرعي',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: mismatch ? AppColors.danger : AppColors.royalBlue,
              ),
            ),
          ),
          if (mismatch)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: AppColors.danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'مجموع درجات المعايير الفرعية (${item.subMarks}) يجب أن يساوي درجة العنصر الرئيسي (${item.marks}).',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                        height: 1.45,
                      ),
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

class _ChecklistSubItemEditor extends StatelessWidget {
  const _ChecklistSubItemEditor({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final _ChecklistSubItemDraft item;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(
              Icons.subdirectory_arrow_left_rounded,
              color: AppColors.slate400,
              size: 16,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: item.description,
                        onChanged: (_) => onChanged(),
                        decoration: const InputDecoration(
                          labelText: 'وصف المعيار الفرعي',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'حذف المعيار',
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: item.marksController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'درجة المعيار الفرعي',
                    isDense: true,
                    prefixIcon: Icon(Icons.score_rounded, size: 16),
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

class _TimerModePicker extends StatelessWidget {
  const _TimerModePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimerChoice(
            active: value == 'fixed',
            title: 'وقت محدد',
            subtitle: 'مناسب لاختبار OSCE',
            icon: Icons.timer_rounded,
            onTap: () => onChanged('fixed'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TimerChoice(
            active: value == 'open',
            title: 'وقت مفتوح',
            subtitle: 'تقييم مراقب بدون عداد',
            icon: Icons.all_inclusive_rounded,
            onTap: () => onChanged('open'),
          ),
        ),
      ],
    );
  }
}

class _TimerChoice extends StatelessWidget {
  const _TimerChoice({
    required this.active,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.royalBlue.withValues(alpha: 0.08)
                : AppColors.slate50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.royalBlue : AppColors.slate100,
              width: active ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: active ? AppColors.royalBlue : AppColors.slate400,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: active ? AppColors.royalBlue : AppColors.midnight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 98,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.slate500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineBadge extends StatelessWidget {
  const _InlineBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _HeroNotice extends StatelessWidget {
  const _HeroNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
