part of 'student_content_screens.dart';

class StudentRemindersScreen extends ConsumerWidget {
  const StudentRemindersScreen({super.key});

  static const route = '/student/reminders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_remindersProvider);
    return StudentShell(
      currentIndex: 13,
      title: 'الجدول الزمني الذكي',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_remindersProvider),
        builder: (data) {
          final reminders = asList(data['reminders']).map(asMap).toList();
          
          final now = DateTime.now();
          final todayReminders = reminders.where((r) {
            final date = DateTime.tryParse(text(r, 'event_date'));
            return date != null && date.year == now.year && date.month == now.month && date.day == now.day;
          }).toList();
          
          final tomorrowReminders = reminders.where((r) {
            final date = DateTime.tryParse(text(r, 'event_date'));
            final tomorrow = now.add(const Duration(days: 1));
            return date != null && date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
          }).toList();
          
          final upcomingReminders = reminders.where((r) {
            final date = DateTime.tryParse(text(r, 'event_date'));
            final dayAfterTomorrow = now.add(const Duration(days: 2));
            return date != null && date.isAfter(dayAfterTomorrow.subtract(const Duration(seconds: 1)));
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_remindersProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                _AchievementHero(count: reminders.length),
                const SizedBox(height: 24),
                if (reminders.isEmpty)
                  const EmptyState(message: 'لا توجد تذكيرات حالياً. استمتع بوقتك! 🎉')
                else ...[
                  if (todayReminders.isNotEmpty) ...[
                    const _TimelineSectionHeader(title: 'اليوم', icon: Icons.today_rounded, color: AppColors.rose),
                    ...todayReminders.map((item) => _ReminderCard(item)),
                    const SizedBox(height: 16),
                  ],
                  if (tomorrowReminders.isNotEmpty) ...[
                    const _TimelineSectionHeader(title: 'غداً', icon: Icons.event_available_rounded, color: AppColors.orange),
                    ...tomorrowReminders.map((item) => _ReminderCard(item)),
                    const SizedBox(height: 16),
                  ],
                  if (upcomingReminders.isNotEmpty) ...[
                    const _TimelineSectionHeader(title: 'قريباً', icon: Icons.upcoming_rounded, color: AppColors.royalBlue),
                    ...upcomingReminders.map((item) => _ReminderCard(item)),
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

class _AchievementHero extends StatelessWidget {
  const _AchievementHero({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.royalBlueDark, AppColors.royalBlue],
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
                  'لديك $count تذكيرات قادمة',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'خطط ليومك بذكاء وابقَ منظماً دائماً.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
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

class _TimelineSectionHeader extends StatelessWidget {
  const _TimelineSectionHeader({required this.title, required this.icon, required this.color});
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
            style: TextStyle(color: AppColors.midnight, fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: color.withValues(alpha: 0.1), thickness: 1.5)),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard(this.item);
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final title = text(item, 'title', fallback: 'تذكير');
    final desc = text(item, 'description', fallback: text(item, 'message'));
    final priority = text(item, 'priority', fallback: 'medium');
    final color = _priorityColor(priority);
    
    final iconData = _getIconForTitle(title);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(iconData, color: color, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(color: AppColors.midnight, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: const TextStyle(color: AppColors.slate600, fontSize: 13, height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.slate400),
                                const SizedBox(width: 6),
                                Text(
                                  _formatEventTime(text(item, 'event_date')),
                                  style: const TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    priority == 'high' ? 'عاجل' : (priority == 'medium' ? 'مهم' : 'عادي'),
                                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('اختبار') || t.contains('امتحان')) return Icons.menu_book_rounded;
    if (t.contains('تكليف') || t.contains('واجب')) return Icons.assignment_rounded;
    if (t.contains('محاضرة') || t.contains('درس')) return Icons.school_rounded;
    if (t.contains('تنبيه') || t.contains('هام')) return Icons.priority_high_rounded;
    return Icons.notifications_active_rounded;
  }

  String _formatEventTime(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateOnly(dateStr);
    // If today or tomorrow, just show time, otherwise date + time
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
