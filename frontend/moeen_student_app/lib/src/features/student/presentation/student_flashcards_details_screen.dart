// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class StudentFlashcardDetailsScreen extends ConsumerStatefulWidget {
  const StudentFlashcardDetailsScreen({super.key, required this.packId});

  final int packId;

  @override
  ConsumerState<StudentFlashcardDetailsScreen> createState() =>
      _StudentFlashcardDetailsScreenState();
}

class _StudentFlashcardDetailsScreenState
    extends ConsumerState<StudentFlashcardDetailsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedPriority;
  final Set<int> _cloningIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_flashcardDetailsProvider(widget.packId));
    final userPacksState = ref.watch(_flashcardsProvider);
    final userPacks = userPacksState.valueOrNull != null
        ? asList(userPacksState.valueOrNull!['packs']).map(asMap).toList()
        : const <Map<String, dynamic>>[];

    final packColor =
        state.whenOrNull(
          data: (data) {
            final pack = asMap(data['pack']);
            return Color(_parseHex(text(pack, 'color', fallback: '#4338ca')));
          },
        ) ??
        AppColors.royalBlue;

    final isPublic =
        state.whenOrNull(
          data: (data) => boolValue(asMap(data['pack']), 'is_public'),
        ) ??
        false;
    final canManageItems =
        state.whenOrNull(
          data: (data) {
            if (data.containsKey('can_manage_items'))
              return data['can_manage_items'] == true;
            final pack = asMap(data['pack']);
            return !boolValue(pack, 'is_public') &&
                !boolValue(pack, 'is_assigned');
          },
        ) ??
        false;

    return StudentShell(
      currentIndex: 15,
      title: 'تفاصيل الحزمة',
      floatingActionButton: !canManageItems
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddItem(context, ref),
              backgroundColor: packColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'عنصر',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardDetailsProvider(widget.packId)),
        builder: (data) {
          final pack = asMap(data['pack']);
          final items = asList(data['items']).map(asMap).toList();
          final children = asList(data['child_packs']).map(asMap).toList();

          final myClonedPack = userPacks.firstWhere(
            (p) => number(p, 'source_pack_id').toInt() == widget.packId,
            orElse: () => const <String, dynamic>{},
          );
          final isOwned = myClonedPack.isNotEmpty;

          // Filter elements in memory
          final filteredItems = items.where((item) {
            final front = text(item, 'front_content').toLowerCase();
            final back = text(item, 'back_content').toLowerCase();
            final query = _searchQuery.toLowerCase();
            if (query.isNotEmpty &&
                !front.contains(query) &&
                !back.contains(query)) {
              return false;
            }
            final itemType = text(item, 'item_type');
            if (_selectedType != null && itemType != _selectedType) {
              return false;
            }
            final priority = text(item, 'priority');
            if (_selectedPriority != null && priority != _selectedPriority) {
              return false;
            }
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
            children: [
              if (data['can_manage_pack'] == true ||
                  (!data.containsKey('can_manage_pack') && !isPublic))
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _FlashcardPackMenu(
                    pack: pack,
                    onDeleted: () => context.go(StudentFlashcardsScreen.route),
                  ),
                ),
              if (isPublic) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.royalBlue.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.royalBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOwned
                              ? 'أنت تستعرض النسخة العامة من هذه الحزمة، وهي ممتلكة بالفعل في حسابك.'
                              : 'أنت تستعرض نسخة عامة للمعاينة فقط. يمكنك تحميلها للمكتبة لبدء المراجعة.',
                          style: const TextStyle(
                            color: AppColors.royalBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              _PackDetailsHero(
                pack: pack,
                itemsCount: items.length,
                childPacksCount: children.length,
              ),
              const SizedBox(height: 16),
              if (isPublic) ...[
                Row(
                  children: [
                    if (isOwned) ...[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            final clonedId = number(myClonedPack, 'id').toInt();
                            context.push(
                              StudentFlashcardsScreen.reviewPath(clonedId),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: packColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text(
                            'بدء مراجعة حزمتك',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final clonedId = number(myClonedPack, 'id').toInt();
                            context.push(
                              StudentFlashcardsScreen.detailsPath(clonedId),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: packColor.withValues(alpha: 0.5),
                            ),
                            foregroundColor: packColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.folder_open_rounded, size: 20),
                          label: const Text(
                            'انتقل لحزمتك',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: _cloningIds.contains(widget.packId)
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.royalBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: () =>
                                    _clonePackInDetails(context, pack),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.royalBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text(
                                  'إضافة الحزمة للمكتبة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          StudentFlashcardsScreen.reviewPath(widget.packId),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: packColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text(
                          'بدء المراجعة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (canManageItems)
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showAddChildPack(context, ref, pack),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: packColor.withValues(alpha: 0.5),
                            ),
                            foregroundColor: packColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(
                            Icons.account_tree_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'حزمة فرعية',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: () => _showEditPack(
                        context,
                        ref,
                        pack,
                        onDone: () => ref.invalidate(
                          _flashcardDetailsProvider(widget.packId),
                        ),
                      ),
                      style: IconButton.styleFrom(
                        side: BorderSide(
                          color: packColor.withValues(alpha: 0.3),
                        ),
                        foregroundColor: packColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),
                if (canManageItems) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showFlashcardImport(
                            context: context,
                            ref: ref,
                            packId: widget.packId,
                            packColor: packColor,
                            onDone: () => _refreshItemData(ref),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: packColor,
                            side: BorderSide(
                              color: packColor.withValues(alpha: 0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text(
                            'استيراد من Excel / CSV',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'تنزيل قالب الاستيراد',
                        child: IconButton.outlined(
                          onPressed: () => _downloadFlashcardImportTemplate(
                            context: context,
                            ref: ref,
                          ),
                          style: IconButton.styleFrom(
                            foregroundColor: packColor,
                            side: BorderSide(
                              color: packColor.withValues(alpha: 0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(13),
                          ),
                          icon: const Icon(Icons.download_rounded),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 16),
              if (children.isNotEmpty) ...[
                StudentSection(
                  title: 'الحزم الداخلية',
                  icon: Icons.account_tree_rounded,
                  child: SizedBox(
                    height: 135,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: children.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _ChildPackCompactCard(children[index]);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              StudentSection(
                title: 'العناصر',
                icon: Icons.list_alt_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFilterBar(packColor),
                    const SizedBox(height: 14),
                    if (filteredItems.isEmpty)
                      const EmptyState(
                        message: 'لا توجد عناصر مطابقة لخيارات التصفية.',
                      )
                    else
                      ...filteredItems.map(
                        (item) => _FlashcardItemTile(
                          item,
                          onEdit: !canManageItems
                              ? null
                              : () => _showItemForm(context, ref, item: item),
                          onDelete: !canManageItems
                              ? null
                              : () => _deleteItem(context, ref, item),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(Color packColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'البحث في العناصر...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.slate500.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('الكل', null, _selectedType == null, packColor, (
                val,
              ) {
                setState(() => _selectedType = null);
              }),
              const SizedBox(width: 6),
              _buildFilterChip(
                'One Line',
                'one_line',
                _selectedType == 'one_line',
                packColor,
                (val) {
                  setState(() => _selectedType = val);
                },
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                'بطاقة مراجعة',
                'flash_card',
                _selectedType == 'flash_card',
                packColor,
                (val) {
                  setState(() => _selectedType = val);
                },
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                'سؤال وجواب',
                'qa',
                _selectedType == 'qa',
                packColor,
                (val) {
                  setState(() => _selectedType = val);
                },
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                'اختيار متعدد',
                'mcq',
                _selectedType == 'mcq',
                packColor,
                (val) {
                  setState(() => _selectedType = val);
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                width: 1,
                color: AppColors.slate500.withValues(alpha: 0.2),
              ),
              _buildFilterChip(
                'كل الأولويات',
                null,
                _selectedPriority == null,
                packColor,
                (val) {
                  setState(() => _selectedPriority = null);
                },
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                'عادي',
                'normal',
                _selectedPriority == 'normal',
                packColor,
                (val) {
                  setState(() => _selectedPriority = val);
                },
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                'متوسط',
                'high',
                _selectedPriority == 'high',
                packColor,
                (val) {
                  setState(() => _selectedPriority = val);
                },
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                'صعب',
                'critical',
                _selectedPriority == 'critical',
                packColor,
                (val) {
                  setState(() => _selectedPriority = val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    bool selected,
    Color packColor,
    void Function(String?) onTap,
  ) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: selected ? Colors.white : AppColors.midnight,
        ),
      ),
      selected: selected,
      selectedColor: packColor,
      backgroundColor: Colors.transparent,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : AppColors.slate500.withValues(alpha: 0.25),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (b) {
        if (b) onTap(value);
      },
    );
  }

  Future<void> _showAddItem(BuildContext context, WidgetRef ref) =>
      _showItemForm(context, ref);

  Future<void> _showItemForm(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? item,
  }) async {
    final formKey = GlobalKey<FormState>();
    final front = TextEditingController(
      text: item?['front_content']?.toString(),
    );
    final back = TextEditingController(text: item?['back_content']?.toString());
    final existingOptions = item == null ? <String>[] : _flashcardOptions(item);
    final optionControllers = List.generate(
      6,
      (index) => TextEditingController(
        text: index < existingOptions.length ? existingOptions[index] : '',
      ),
    );
    String type = item == null ? 'one_line' : _itemType(item);
    String priority = item == null
        ? 'normal'
        : text(item, 'priority', fallback: 'normal');
    int correctOption = item == null
        ? 0
        : _correctOptionIndex(item).clamp(0, 5);
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'عنصر جديد' : 'تعديل العنصر',
      icon: Icons.note_add_rounded,
      color: AppColors.goldDeep,
      child: _FlashcardEditorBody(
        controllers: [front, back, ...optionControllers],
        child: StatefulBuilder(
          builder: (sheetContext, setLocal) => Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: front,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اكتب نص البطاقة.'
                      : null,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'النص / السؤال'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'نوع العنصر',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TypeSelectorCard(
                      label: 'One Line',
                      icon: Icons.article_rounded,
                      value: 'one_line',
                      groupValue: type,
                      onChanged: (val) => setLocal(() {
                        type = val;
                        correctOption = 0;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TypeSelectorCard(
                      label: 'Flash Card',
                      icon: Icons.flip_to_front_rounded,
                      value: 'flash_card',
                      groupValue: type,
                      onChanged: (val) => setLocal(() {
                        type = val;
                        correctOption = 0;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TypeSelectorCard(
                      label: 'Q/A',
                      icon: Icons.question_answer_rounded,
                      value: 'qa',
                      groupValue: type,
                      onChanged: (val) => setLocal(() {
                        type = val;
                        correctOption = 0;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TypeSelectorCard(
                      label: 'MCQ',
                      icon: Icons.checklist_rounded,
                      value: 'mcq',
                      groupValue: type,
                      onChanged: (val) => setLocal(() {
                        type = val;
                        correctOption = 0;
                      }),
                    ),
                  ],
                ),
                if (type == 'mcq') ...[
                  const SizedBox(height: 16),
                  ...optionControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: entry.value,
                        validator: (value) {
                          final filledCount = optionControllers
                              .where(
                                (controller) =>
                                    controller.text.trim().isNotEmpty,
                              )
                              .length;
                          if (index < 2 &&
                              (value == null || value.trim().isEmpty)) {
                            return 'اكتب خيارين على الأقل.';
                          }
                          if (index == correctOption &&
                              (value == null || value.trim().isEmpty)) {
                            return 'اكتب الإجابة الصحيحة.';
                          }
                          if (filledCount < 2) {
                            return 'اكتب خيارين على الأقل.';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'الخيار ${index + 1}',
                          suffixIcon: Radio<int>(
                            value: index,
                            groupValue: correctOption,
                            onChanged: (value) {
                              if (value == null) return;
                              setLocal(() => correctOption = value);
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                  Text(
                    'حدد الإجابة الصحيحة من علامة الاختيار بجانب الخيار.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else if (type != 'one_line') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: back,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'اكتب الإجابة.'
                        : null,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'الإجابة'),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'الأولوية',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PrioritySelectorChip(
                      label: 'سهل',
                      value: 'normal',
                      badgeColor: AppColors.slate500,
                      groupValue: priority,
                      onChanged: (val) => setLocal(() => priority = val),
                    ),
                    const SizedBox(width: 8),
                    _PrioritySelectorChip(
                      label: 'متوسط',
                      value: 'high',
                      badgeColor: AppColors.goldDeep,
                      groupValue: priority,
                      onChanged: (val) => setLocal(() => priority = val),
                    ),
                    const SizedBox(width: 8),
                    _PrioritySelectorChip(
                      label: 'صعب',
                      value: 'critical',
                      badgeColor: AppColors.rose,
                      groupValue: priority,
                      onChanged: (val) => setLocal(() => priority = val),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(sheetContext, true);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final selectedOptions = optionControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .toList();
    final correctIndex = selectedOptions.indexOf(
      optionControllers[correctOption.clamp(0, 5)],
    );
    final payload = <String, dynamic>{
      'item_type': type,
      'front_content': front.text.trim(),
      if (type == 'mcq')
        'options': selectedOptions
            .map((controller) => controller.text.trim())
            .toList(),
      if (type == 'mcq') 'correct_option': correctIndex,
      if (type != 'one_line' && type != 'mcq') 'back_content': back.text.trim(),
      'priority': priority,
    };
    if (ok != true || !context.mounted) return;
    final repository = ref.read(studentContentRepositoryProvider);
    await _runSnack(
      context,
      () => item == null
          ? repository.createFlashcardItem(widget.packId, payload)
          : repository.updateFlashcardItem(number(item, 'id').toInt(), payload),
      onDone: () => _refreshItemData(ref),
    );
  }

  Future<void> _showAddChildPack(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> parent,
  ) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final description = TextEditingController();
    String mode = 'one_line';
    String color = text(parent, 'color', fallback: '#4338ca');
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'حزمة داخلية',
      icon: Icons.account_tree_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (sheetContext, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: title,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اكتب اسم الحزمة.'
                    : null,
                decoration: const InputDecoration(labelText: 'اسم الحزمة'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'وصف مختصر'),
              ),
              const SizedBox(height: 16),
              if (false)
                const Text(
                  'نوع البطاقات',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 8),
              if (false)
                Row(
                  children: [
                    _TypeSelectorCard(
                      label: 'One Line',
                      icon: Icons.article_rounded,
                      value: 'one_line',
                      groupValue: mode,
                      onChanged: (val) => setLocal(() => mode = val),
                    ),
                    const SizedBox(width: 8),
                    _TypeSelectorCard(
                      label: 'Flash Card',
                      icon: Icons.flip_to_front_rounded,
                      value: 'flash_card',
                      groupValue: mode,
                      onChanged: (val) => setLocal(() => mode = val),
                    ),
                    const SizedBox(width: 8),
                    _TypeSelectorCard(
                      label: 'Q/A',
                      icon: Icons.question_answer_rounded,
                      value: 'qa',
                      groupValue: mode,
                      onChanged: (val) => setLocal(() => mode = val),
                    ),
                    const SizedBox(width: 8),
                    _TypeSelectorCard(
                      label: 'MCQ',
                      icon: Icons.checklist_rounded,
                      value: 'mcq',
                      groupValue: mode,
                      onChanged: (val) => setLocal(() => mode = val),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              _ColorPickerRow(
                selectedColor: color,
                onChanged: (val) => setLocal(() => color = val),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(sheetContext, true);
                },
                child: const Text('إنشاء'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    if (!context.mounted) return;
    await _runSnack(
      context,
      () => ref.read(studentContentRepositoryProvider).createFlashcardPack({
        'title': title.text.trim(),
        'description': description.text.trim(),
        'color': color,
        'display_mode': 'one_line',
        'parent_pack_id': widget.packId,
        'notifications_enabled': true,
        ..._packSchedulePayload(
          scheduleMode: 'daily',
          scheduleWeekdays: const {},
          packPriority: 'medium',
          smartReviewEnabled: true,
          restartMode: 'none',
        ),
      }),
      onDone: () => _refreshItemData(ref),
    );
  }

  void _refreshItemData(WidgetRef ref) {
    ref.invalidate(_flashcardDetailsProvider(widget.packId));
    ref.invalidate(_flashcardsProvider);
    ref.invalidate(_flashcardDailyQueueProvider);
    ref.invalidate(_flashcardUpcomingProvider);
    ref.invalidate(_flashcardOneLineNotificationsProvider);
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف العنصر',
      message: 'هل تريد حذف هذا العنصر؟',
      danger: true,
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
    );
    if (!ok) return;
    if (!context.mounted) return;
    await _runSnack(
      context,
      () => ref
          .read(studentContentRepositoryProvider)
          .deleteFlashcardItem(number(item, 'id').toInt()),
      onDone: () => _refreshItemData(ref),
    );
  }

  Future<void> _clonePackInDetails(
    BuildContext context,
    Map<String, dynamic> pack,
  ) async {
    final id = widget.packId;
    if (_cloningIds.contains(id)) return;
    setState(() => _cloningIds.add(id));
    try {
      final message = await ref
          .read(studentContentRepositoryProvider)
          .cloneFlashcardPack(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
        ref.invalidate(_flashcardsProvider);
      }
    } on ApiException catch (error) {
      if (mounted) {
        final errMsg = error.message.toLowerCase();
        if (errMsg.contains('already in your account') ||
            error.statusCode == 409) {
          await showMoeenInfoDialog(
            context: context,
            title: 'الحزمة ممتلكة بالفعل',
            message: 'هذه الحزمة موجودة بالفعل في حسابك.',
            buttonLabel: 'حسناً',
            icon: Icons.info_outline_rounded,
            color: AppColors.royalBlue,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cloningIds.remove(id));
      }
    }
  }
}

class _FlashcardEditorBody extends StatefulWidget {
  const _FlashcardEditorBody({required this.controllers, required this.child});

  final List<TextEditingController> controllers;
  final Widget child;

  @override
  State<_FlashcardEditorBody> createState() => _FlashcardEditorBodyState();
}

class _FlashcardEditorBodyState extends State<_FlashcardEditorBody> {
  @override
  void dispose() {
    // The closing animation still uses these fields after Navigator.pop resolves.
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
