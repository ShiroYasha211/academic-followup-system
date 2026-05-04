part of 'delegate_screens.dart';

class DelegateLibraryImportScreen extends ConsumerStatefulWidget {
  const DelegateLibraryImportScreen({super.key});
  static const route = DelegateRoutes.libraryImport;

  @override
  ConsumerState<DelegateLibraryImportScreen> createState() =>
      _DelegateLibraryImportScreenState();
}

class _DelegateLibraryImportScreenState
    extends ConsumerState<DelegateLibraryImportScreen> {
  final _search = TextEditingController();
  String _category = 'all';
  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _load() {
    return ref.read(delegateRepositoryProvider).searchLibrary(
          query: _search.text.trim(),
          category: _category,
        );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DelegateShell(
      currentIndex: 9,
      title: 'المكتبة المشتركة',
      child: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final items = (snapshot.data ?? const []).map(asMap).toList();

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                _HeroPanel(
                  title: 'استيراد من المكتبة',
                  subtitle:
                      'ابحث في الملفات المشتركة واستورد المناسب منها إلى مواد الدفعة.',
                  icon: Icons.library_add_rounded,
                  colors: const [AppColors.teal, AppColors.royalBlue],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onSubmitted: (_) => _refresh(),
                        decoration: const InputDecoration(
                          labelText: 'بحث',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: _refresh,
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FilterChips(
                  value: _category,
                  options: const {
                    'all': 'الكل',
                    'book': 'كتب',
                    'lecture': 'محاضرات',
                    'summary': 'ملخصات',
                    'other': 'أخرى',
                  },
                  onChanged: (value) {
                    setState(() {
                      _category = value;
                      _future = _load();
                    });
                  },
                ),
                const SizedBox(height: 18),
                if (items.isEmpty)
                  const _EmptyState('لا توجد ملفات مطابقة في المكتبة المشتركة.')
                else
                  for (final item in items)
                    _DataCard(
                      title: text(item, 'title', fallback: 'ملف'),
                      subtitle: text(
                        asMap(item['subject']),
                        'name',
                        fallback: text(item, 'category', fallback: 'مورد مشترك'),
                      ),
                      icon: Icons.insert_drive_file_rounded,
                      color: _getCategoryColor(text(item, 'category')),
                      actions: [
                        IconButton(
                          onPressed: () => _importResourceSheet(
                            context,
                            ref,
                            item,
                          ),
                          icon: const Icon(Icons.download_done_rounded),
                        ),
                      ],
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DelegateRemindersScreen extends ConsumerWidget {
  const DelegateRemindersScreen({super.key});
  static const route = DelegateRoutes.reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_delegateRemindersProvider('all'));

    return DelegateShell(
      currentIndex: 10,
      title: 'الجدول الزمني الذكي',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _reminderSheet(context, ref),
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('إضافة تذكير'),
        backgroundColor: AppColors.royalBlue,
      ),
      child: _AsyncBody<Map<String, dynamic>>(
        state: state,
        onRetry: () => ref.invalidate(_delegateRemindersProvider('all')),
        builder: (data) {
          final reminders = asList(data['reminders']).map(asMap).toList();

          final now = DateTime.now();
          final today = reminders.where((r) {
            final date = DateTime.tryParse(text(r, 'event_date'));
            return date != null &&
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
          }).toList();

          final tomorrowDate = now.add(const Duration(days: 1));
          final tomorrow = reminders.where((r) {
            final date = DateTime.tryParse(text(r, 'event_date'));
            return date != null &&
                date.year == tomorrowDate.year &&
                date.month == tomorrowDate.month &&
                date.day == tomorrowDate.day;
          }).toList();

          final upcoming = reminders.where((r) {
            final date = DateTime.tryParse(text(r, 'event_date'));
            final dayAfterTomorrow = now.add(const Duration(days: 2));
            return date != null &&
                date.isAfter(
                    dayAfterTomorrow.subtract(const Duration(seconds: 1)));
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_delegateRemindersProvider('all')),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                _RemindersHero(count: reminders.length),
                const SizedBox(height: 24),
                if (reminders.isEmpty)
                  const _EmptyState('لا توجد تذكيرات حالياً. استمتع بوقتك! 🎉')
                else ...[
                  if (today.isNotEmpty) ...[
                    const _TimelineSection(
                        title: 'اليوم', icon: Icons.today_rounded, color: AppColors.rose),
                    ...today.map((r) => _DelegateReminderCard(item: r)),
                    const SizedBox(height: 16),
                  ],
                  if (tomorrow.isNotEmpty) ...[
                    const _TimelineSection(
                        title: 'غداً',
                        icon: Icons.event_available_rounded,
                        color: AppColors.orange),
                    ...tomorrow.map((r) => _DelegateReminderCard(item: r)),
                    const SizedBox(height: 16),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    const _TimelineSection(
                        title: 'قريباً',
                        icon: Icons.upcoming_rounded,
                        color: AppColors.royalBlue),
                    ...upcoming.map((r) => _DelegateReminderCard(item: r)),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RemindersHero extends StatelessWidget {
  const _RemindersHero({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.royalBlue, AppColors.royalBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لديك $count تذكيرات مجدولة',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'نظم مهام الدفعة وابقَ على اطلاع دائم بكل جديد.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 32),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection(
      {required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                color: AppColors.midnight, fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Divider(color: color.withValues(alpha: 0.1), thickness: 1.5)),
        ],
      ),
    );
  }
}

class _DelegateReminderCard extends ConsumerWidget {
  const _DelegateReminderCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = text(item, 'title', fallback: 'تذكير');
    final desc = text(item, 'description');
    final priority = text(item, 'priority', fallback: 'medium');
    final color = _getPriorityColor(priority);
    final icon = _getReminderIcon(title);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: AppColors.midnight)),
                            if (desc.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(desc,
                                    style: const TextStyle(
                                        color: AppColors.slate500, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 14, color: AppColors.slate400),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(text(item, 'event_date')),
                                  style: const TextStyle(
                                      color: AppColors.slate500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _reminderSheet(context, ref, item: item),
                            icon: const Icon(Icons.edit_rounded,
                                size: 18, color: AppColors.slate400),
                          ),
                          IconButton(
                            onPressed: () => _delete(
                              context,
                              () => ref
                                  .read(delegateRepositoryProvider)
                                  .deleteReminder(number(item, 'id').toInt()),
                              () => ref.invalidate(_delegateRemindersProvider('all')),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.danger),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String p) => switch (p) {
        'high' => AppColors.danger,
        'medium' => AppColors.orange,
        _ => AppColors.success,
      };

  IconData _getReminderIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('اختبار') || t.contains('امتحان')) return Icons.menu_book_rounded;
    if (t.contains('تكليف') || t.contains('واجب')) return Icons.assignment_rounded;
    if (t.contains('محاضرة') || t.contains('درس')) return Icons.school_rounded;
    return Icons.notifications_active_rounded;
  }

  String _formatTime(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class DelegateAnnouncementsScreen extends ConsumerWidget {
  const DelegateAnnouncementsScreen({super.key});
  static const route = DelegateRoutes.announcements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen<List<dynamic>>(
      title: 'إعلانات الدفعة',
      index: 11,
      state: ref.watch(_delegateAnnouncementsProvider),
      onRetry: () => ref.invalidate(_delegateAnnouncementsProvider),
      icon: Icons.campaign_rounded,
      colors: const [AppColors.orange, AppColors.rose],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newsSheet(context, ref),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('نشر'),
      ),
      extractor: (data) => data,
      itemBuilder: (item) => _DataCard(
        title: text(item, 'title'),
        subtitle: text(
          item,
          'content',
          fallback: text(item, 'category', fallback: 'إعلان'),
        ),
        icon: Icons.campaign_rounded,
        color: AppColors.orange,
        actions: [
          IconButton(
            onPressed: () =>
                _newsSheet(context, ref, item: asMap(item)),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: () => _delete(
              context,
              () => ref
                  .read(delegateRepositoryProvider)
                  .deleteAnnouncement(number(item, 'id').toInt()),
              () => ref.invalidate(_delegateAnnouncementsProvider),
            ),
            icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
