part of 'delegate_screens.dart';

class DelegateNewsScreen extends ConsumerWidget {
  const DelegateNewsScreen({super.key});
  static const route = DelegateRoutes.news;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SimpleListScreen(
      title: 'أخبار الدفعة',
      index: 1,
      state: ref.watch(_delegateNewsProvider),
      onRetry: () => ref.invalidate(_delegateNewsProvider),
      icon: Icons.newspaper_rounded,
      colors: const [AppColors.orange, AppColors.goldDeep],
      extractor: (data) =>
          asList(asMap(data['data']).isNotEmpty ? data['data'] : data),
      itemBuilder: (item) => _NewsCard(item: item),
    );
  }
}

class DelegateNotificationsScreen extends ConsumerWidget {
  const DelegateNotificationsScreen({super.key});
  static const route = DelegateRoutes.notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_delegateNotificationsProvider);
    return _SimpleListScreen(
      title: 'التنبيهات',
      index: 2,
      state: state,
      onRetry: () => ref.invalidate(_delegateNotificationsProvider),
      icon: Icons.notifications_active_rounded,
      colors: const [AppColors.royalBlue, AppColors.info],
      extractor: (data) => [
        ...asList(data['sent_warnings']),
        ...asList(data['notifications']),
      ],
      itemBuilder: (item) => _DataCard(
        title: text(
          item,
          'title',
          fallback: text(item, 'subject_name', fallback: 'تنبيه'),
        ),
        subtitle: text(item, 'message', fallback: text(item, 'student_name')),
        icon: Icons.notification_important_rounded,
        color: AppColors.warning,
      ),
    );
  }
}
