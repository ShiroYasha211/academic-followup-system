// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class StudentFlashcardStoreScreen extends ConsumerStatefulWidget {
  const StudentFlashcardStoreScreen({super.key});

  static const route = '/student/flashcards-store';

  @override
  ConsumerState<StudentFlashcardStoreScreen> createState() =>
      _StudentFlashcardStoreScreenState();
}

class _StudentFlashcardStoreScreenState
    extends ConsumerState<StudentFlashcardStoreScreen> {
  final _search = TextEditingController();
  final Set<int> _cloningIds = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_flashcardStoreProvider);
    final userPacksState = ref.watch(_flashcardsProvider);
    final userPacks = userPacksState.valueOrNull != null
        ? asList(userPacksState.valueOrNull!['packs']).map(asMap).toList()
        : const <Map<String, dynamic>>[];

    return StudentShell(
      currentIndex: 15,
      title: 'متجر One Line',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardStoreProvider),
        builder: (data) {
          final page = asMap(data['store_items']);
          final items = asList(page['data']).map(asMap).toList();

          final query = _search.text.trim().toLowerCase();
          final filteredItems = items.where((store) {
            final pack = asMap(store['pack']);
            final title = text(pack, 'title').toLowerCase();
            final description = text(pack, 'description').toLowerCase();
            return query.isEmpty ||
                title.contains(query) ||
                description.contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_flashcardStoreProvider);
              ref.invalidate(_flashcardsProvider);
              try {
                await ref.read(_flashcardStoreProvider.future);
                await ref.read(_flashcardsProvider.future);
              } catch (_) {}
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _StoreHero(itemsCount: items.length),
                const SizedBox(height: 16),
                _ShotPanel(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      labelText: 'بحث عن حزم الكروت العامة',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 20),
                _ShotSectionHeader(
                  title: 'الحزم العامة المتاحة',
                  subtitle: 'تصفح وحمّل الحزم المتاحة للمجتمع',
                  icon: Icons.storefront_rounded,
                  color: AppColors.royalBlue,
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const EmptyState(message: 'لا توجد حزم في المتجر.')
                else if (filteredItems.isEmpty)
                  const EmptyState(message: 'لا توجد حزم مطابقة للبحث.')
                else
                  ...filteredItems.map((store) {
                    final pack = asMap(store['pack']);
                    final packId = number(pack, 'id').toInt();
                    final isOwned = userPacks.any(
                      (p) => number(p, 'source_pack_id').toInt() == packId,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StorePackCard(
                        pack: pack,
                        isOwned: isOwned,
                        isCloning: _cloningIds.contains(packId),
                        onClone: () => _clone(pack),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _clone(Map<String, dynamic> pack) async {
    final id = number(pack, 'id').toInt();
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

class _StoreHero extends StatelessWidget {
  const _StoreHero({required this.itemsCount});

  final int itemsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.midnight, AppColors.royalBlue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 12),
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
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'متجر الحزم العامة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'حمل كروت مراجعة جاهزة تم إنشاؤها ومشاركتها بواسطة مجتمع معين لتوفير الوقت والجهد',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.inventory_2_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'يتوفر $itemsCount حزمة عامة جاهزة للإضافة',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorePackCard extends ConsumerWidget {
  const _StorePackCard({
    required this.pack,
    required this.isOwned,
    required this.isCloning,
    required this.onClone,
  });

  final Map<String, dynamic> pack;
  final bool isOwned;
  final bool isCloning;
  final VoidCallback onClone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorHex = text(pack, 'color', fallback: '#4338ca');
    final color = Color(_parseHex(colorHex));
    final count = number(pack, 'items_count').toInt();
    final displayMode = text(pack, 'display_mode', fallback: 'one_line');
    final title = text(pack, 'title', fallback: 'حزمة مراجعة');
    final description = text(pack, 'description', fallback: '');

    return _ShotPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                child: Icon(_modeIcon(displayMode), color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$count كرت',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.slate300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _typeLabel(displayMode),
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwned) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'في الحساب',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.slate600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final id = number(pack, 'id').toInt();
                  context.push(StudentFlashcardsScreen.detailsPath(id));
                },
                icon: Icon(
                  Icons.remove_red_eye_rounded,
                  size: 16,
                  color: color,
                ),
                label: Text(
                  'معاينة التفاصيل',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(120, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              isCloning
                  ? const SizedBox(
                      width: 120,
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.royalBlue,
                            ),
                          ),
                        ),
                      ),
                    )
                  : isOwned
                  ? OutlinedButton.icon(
                      onPressed: () {
                        showMoeenInfoDialog(
                          context: context,
                          title: 'الحزمة ممتلكة بالفعل',
                          message: 'هذه الحزمة موجودة بالفعل في حسابك.',
                          buttonLabel: 'حسناً',
                          icon: Icons.info_outline_rounded,
                          color: AppColors.royalBlue,
                        );
                      },
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                      label: const Text(
                        'ممتلكة',
                        style: TextStyle(
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.slate300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: const Size(120, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: onClone,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('إضافة للمكتبة'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: const Size(120, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlashcardPackMenu extends ConsumerWidget {
  const _FlashcardPackMenu({
    required this.pack,
    this.isDark = false,
    this.onDeleted,
  });

  final Map<String, dynamic> pack;
  final bool isDark;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'إجراءات الحزمة',
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDark ? Colors.white70 : AppColors.slate500,
      ),
      padding: EdgeInsets.zero,
      onSelected: (value) async {
        final id = number(pack, 'id').toInt();
        if (value == 'review') {
          context.push(StudentFlashcardsScreen.reviewPath(id));
          return;
        }
        if (value == 'edit') {
          _showEditPack(context, ref, pack);
          return;
        }
        if (value == 'toggle') {
          await _runSnack(
            context,
            () => ref
                .read(studentContentRepositoryProvider)
                .toggleFlashcardPack(id),
            onDone: () => ref.invalidate(_flashcardsProvider),
          );
          return;
        }
        if (value == 'delete') {
          final ok = await showMoeenConfirmDialog(
            context: context,
            title: 'حذف الحزمة',
            message:
                'سيتم حذف الحزمة بكامل عناصرها وحزمها الفرعية من مكتبتك. هل تريد المتابعة؟',
            danger: true,
            confirmLabel: 'حذف',
            icon: Icons.delete_rounded,
          );
          if (!ok || !context.mounted) return;
          await _runSnack(
            context,
            () => ref
                .read(studentContentRepositoryProvider)
                .deleteFlashcardPack(id),
            onDone: () {
              ref.invalidate(_flashcardsProvider);
              ref.invalidate(_flashcardDailyQueueProvider);
              ref.invalidate(_flashcardOneLineNotificationsProvider);
              ref.invalidate(_flashcardUpcomingProvider);
              unawaited(
                ref.read(oneLineNotificationSchedulerProvider).sync().catchError((
                  Object error,
                  StackTrace stack,
                ) {
                  debugPrint(
                    'Text schedule refresh after pack deletion failed: $error',
                  );
                  debugPrintStack(stackTrace: stack);
                  return 0;
                }),
              );
              onDeleted?.call();
            },
          );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'review', child: Text('بدء المراجعة')),
        PopupMenuItem(value: 'edit', child: Text('تعديل الحزمة')),
        PopupMenuItem(value: 'toggle', child: Text('تفعيل / إيقاف')),
        PopupMenuItem(value: 'delete', child: Text('حذف')),
      ],
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  const _ColorPickerRow({required this.selectedColor, required this.onChanged});

  final String selectedColor;
  final ValueChanged<String> onChanged;

  static const colors = [
    ('#4338ca', 'أزرق ملكي'),
    ('#0f766e', 'أخضر عشبي'),
    ('#ea580c', 'برتقالي'),
    ('#be123c', 'أحمر وردي'),
    ('#0369a1', 'أزرق سماوي'),
    ('#7c3aed', 'بنفسجي'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اللون المميز للمجموعة',
          style: TextStyle(
            color: AppColors.midnight,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = colors[index];
              final hex = item.$1;
              final label = item.$2;
              final isSelected =
                  selectedColor.toLowerCase() == hex.toLowerCase();
              final colorVal = Color(int.parse(hex.replaceFirst('#', '0xff')));
              return Tooltip(
                message: label,
                child: GestureDetector(
                  onTap: () => onChanged(hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorVal,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.midnight, width: 3)
                          : Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: colorVal.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
