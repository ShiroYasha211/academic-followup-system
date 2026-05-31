part of 'delegate_screens.dart';

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.child, this.height = 64});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _AsyncBody<T> extends StatelessWidget {
  const _AsyncBody({
    required this.state,
    required this.builder,
    required this.onRetry,
  });
  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _ErrorState(message: error.toString(), onRetry: onRetry),
      data: builder,
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.title,
    required this.subtitle,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.royalBlue,
            AppColors.royalBlueDark,
            const Color(0xFF1E3A8A),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -20,
            bottom: -30,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            fontFamily: 'Cairo',
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'أنت مندوب الدفعة المعتمد حالياً لمتابعة وتسيير شؤون الطلاب.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
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
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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



bool isTimeInRange(String startStr, String endStr) {
  if (startStr.isEmpty || endStr.isEmpty) return false;
  try {
    final now = DateTime.now();
    final today = dateOnly(now.toString());
    final start = DateTime.parse(
      '$today ${startStr.length == 5 ? "$startStr:00" : startStr}',
    );
    final end = DateTime.parse(
      '$today ${endStr.length == 5 ? "$endStr:00" : endStr}',
    );
    return now.isAfter(start) && now.isBefore(end);
  } catch (_) {
    return false;
  }
}

class _DelegateQrAttendanceCard extends StatelessWidget {
  const _DelegateQrAttendanceCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: const Color(0xFF0F766E),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Color(0xFF0F766E),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تحضير الطلاب السريع (QR)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        Text(
                          'اضغط لبدء رصد حضور الطلاب بالدفعة الآن',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionGrid extends ConsumerWidget {
  const _ActionGrid({
    required this.onStudentsTap,
    required this.onSubjectsTap,
    required this.onAttendanceTap,
    required this.onGradesTap,
    required this.onMessagesTap,
  });

  final VoidCallback onStudentsTap;
  final VoidCallback onSubjectsTap;
  final VoidCallback onAttendanceTap;
  final VoidCallback onGradesTap;
  final VoidCallback onMessagesTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _ActionData('الطلاب', Icons.groups_rounded, AppColors.teal, onStudentsTap),
      _ActionData('المواد', Icons.auto_stories_rounded, AppColors.royalBlue, onSubjectsTap),
      _ActionData('الحضور', Icons.how_to_reg_rounded, AppColors.info, onAttendanceTap),
      _ActionData('الدرجات', Icons.grade_rounded, AppColors.goldDeep, onGradesTap),
      _ActionData('الرسائل', Icons.forum_rounded, AppColors.violet, onMessagesTap),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'اختصارات سريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: action.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.slate100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(action.icon, color: action.color, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        action.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: AppColors.midnight,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActionData {
  _ActionData(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.royalBlue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.margin});
  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                  title.isEmpty ? 'بدون عنوان' : title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate600,
                    height: 1.45,
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

class _NewsCard extends ConsumerWidget {
  const _NewsCard({required this.item});
  final Object? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = asMap(item);
    final sender = asMap(map['sender']);
    final type = text(map, 'type');
    final isUnread = map['read_at'] == null;
    final color = _getNewsTypeColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showNewsDetails(context, ref, text(map, 'batch_id')),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getNewsTypeIcon(type), color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text(map, 'title', fallback: 'خبر جديد'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'من: ${text(sender, 'name', fallback: 'الإدارة')}',
                              style: const TextStyle(
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.rose,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Text(
                    text(map, 'message', fallback: text(map, 'content')),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeText(map),
                        style: const TextStyle(
                          color: AppColors.slate400,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'قراءة المزيد ←',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _getNewsTypeColor(String type) {
  switch (type) {
    case 'poll':
      return AppColors.violet;
    case 'exam':
      return AppColors.danger;
    case 'assignment':
      return AppColors.warning;
    case 'attendance':
      return AppColors.success;
    default:
      return AppColors.orange;
  }
}

IconData _getNewsTypeIcon(String type) {
  switch (type) {
    case 'poll':
      return Icons.poll_rounded;
    case 'exam':
      return Icons.fact_check_rounded;
    case 'assignment':
      return Icons.assignment_rounded;
    case 'attendance':
      return Icons.how_to_reg_rounded;
    default:
      return Icons.campaign_rounded;
  }
}

String _getNewsTypeTitle(String type) {
  switch (type) {
    case 'poll':
      return 'استطلاع رأي للدفعة';
    case 'exam':
      return 'تنبيه اختبار';
    case 'assignment':
      return 'تكليف دراسي جديد';
    case 'attendance':
      return 'تنبيه حضور وغياب';
    default:
      return 'تعميم رسمي للدفعة';
  }
}

Color _getRoleColor(String role) {
  final r = role.toLowerCase();
  if (r.contains('دكتور') || r.contains('doctor') || r.contains('أستاذ') || r.contains('طبيب') || r.contains('staff') || r.contains('تعليمي')) {
    return AppColors.royalBlue;
  }
  if (r.contains('مندوب') || r.contains('delegate')) {
    return AppColors.orange;
  }
  if (r.contains('إدارة') || r.contains('admin') || r.contains('مدير') || r.contains('كلية')) {
    return AppColors.goldDeep;
  }
  return AppColors.teal;
}

String _getSenderInitials(String name) {
  if (name.isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length > 1) {
    return '${parts[0][0]}${parts[parts.length - 1][0]}';
  }
  return parts[0].isNotEmpty ? parts[0][0] : '?';
}

Future<void> _showNewsDetails(
  BuildContext context,
  WidgetRef ref,
  String batchId,
) async {
  if (batchId.isEmpty) return;

  final messenger = ScaffoldMessenger.of(context);

  try {
    final data = await ref
        .read(delegateRepositoryProvider)
        .newsDetails(batchId);
    if (!context.mounted) return;

    final notification = asMap(data['notification']);
    final sender = asMap(notification['sender']);
    final type = text(notification, 'type');
    final pollOptions = asList(data['poll_options']);
    final hasVoted = data['has_voted'] == true;
    final userVote = asMap(data['user_vote']);

    final totalVotes = pollOptions.fold<int>(
      0,
      (sum, opt) => sum + number(asMap(opt), 'votes_count').toInt(),
    );

    final color = _getNewsTypeColor(type);
    final icon = _getNewsTypeIcon(type);
    final sheetTitle = _getNewsTypeTitle(type);

    final senderName = text(sender, 'name', fallback: 'الإدارة الكلية');
    final senderRole = text(sender, 'role', fallback: 'إدارة');
    final roleColor = _getRoleColor(senderRole);
    final initials = _getSenderInitials(senderName);

    showMoeenBottomSheet(
      context: context,
      title: sheetTitle,
      icon: icon,
      color: color,
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: roleColor.withValues(alpha: 0.1),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        senderRole,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: roleColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  timeText(notification),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              text(notification, 'title'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.slate200.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                text(notification, 'message', fallback: text(notification, 'content')),
                style: const TextStyle(
                  height: 1.6,
                  fontSize: 14,
                  color: AppColors.slate800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (type == 'poll') ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: AppColors.violet, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'شاركنا برأيك:',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.violet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final opt in pollOptions)
                _PollOptionTile(
                  option: asMap(opt),
                  isSelected:
                      number(userVote, 'poll_option_id').toInt() ==
                      number(opt, 'id').toInt(),
                  hasVoted: hasVoted,
                  votesCount: number(asMap(opt), 'votes_count').toInt(),
                  totalVotes: totalVotes,
                  onTap: () async {
                    if (hasVoted) return;
                    await _run(
                      context,
                      () => ref
                          .read(delegateRepositoryProvider)
                          .voteNews(
                            batchId: batchId,
                            optionId: number(opt, 'id').toInt(),
                          ),
                      after: () => ref.invalidate(_delegateNewsProvider),
                    );
                    Navigator.pop(context);
                    ref.invalidate(_delegateNewsProvider);
                  },
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
    // Mark as read locally after showing
    ref.invalidate(_delegateNewsProvider);
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
    );
  }
}

class _PollOptionTile extends StatelessWidget {
  const _PollOptionTile({
    required this.option,
    required this.isSelected,
    required this.hasVoted,
    required this.votesCount,
    required this.totalVotes,
    required this.onTap,
  });

  final Map<String, dynamic> option;
  final bool isSelected;
  final bool hasVoted;
  final int votesCount;
  final int totalVotes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double percent = totalVotes > 0 ? (votesCount / totalVotes) * 100 : 0.0;
    final color = isSelected
        ? AppColors.violet
        : (hasVoted ? AppColors.slate300 : AppColors.slate200);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? AppColors.violet.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: hasVoted ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (hasVoted)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return FractionallySizedBox(
                          widthFactor: percent / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.violet.withValues(alpha: 0.12)
                                  : AppColors.slate100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text(option, 'option_text'),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected ? AppColors.violet : AppColors.slate800,
                        ),
                      ),
                    ),
                    if (hasVoted) ...[
                      Text(
                        '${percent.toStringAsFixed(1)}% ($votesCount)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? AppColors.violet : AppColors.slate600,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.violet,
                        size: 20,
                      )
                    else if (hasVoted)
                      const SizedBox(width: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});
  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -10,
                  child: Icon(
                    item.icon,
                    size: 60,
                    color: item.color.withValues(alpha: 0.05),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.value,
                            style: const TextStyle(
                              color: AppColors.midnight,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
      },
    );
  }
}

class _SubjectsStrip extends StatelessWidget {
  const _SubjectsStrip({required this.subjects});
  final List<dynamic> subjects;

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty)
      return const _EmptyState('لا توجد مواد مرتبطة بالدفعة حالياً.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'مواد الدفعة',
          icon: Icons.library_books_rounded,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, index) {
              final item = asMap(subjects[index]);
              return _DashboardSubjectCard(item: item);
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardSubjectCard extends StatelessWidget {
  const _DashboardSubjectCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final doctor = asMap(item['doctor']);
    return Container(
      width: 160,
      margin: const EdgeInsetsDirectional.only(end: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.book_outlined,
              size: 18,
              color: AppColors.royalBlue,
            ),
          ),
          const Spacer(),
          Text(
            text(item, 'name'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text(doctor, 'name', fallback: 'دكتور المادة'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentsStrip extends StatelessWidget {
  const _StudentsStrip({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
    required this.empty,
  });
  final String title;
  final IconData icon;
  final List<dynamic> items;
  final Color color;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, icon: icon),
        const SizedBox(height: 14),
        if (items.isEmpty)
          _EmptyState(empty)
        else
          ...items
              .take(3)
              .map((raw) => _StudentStatusCard(item: asMap(raw), color: color)),
      ],
    );
  }
}

class _StudentStatusCard extends StatelessWidget {
  const _StudentStatusCard({required this.item, required this.color});
  final Map<String, dynamic> item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final student = asMap(item['student']);
    final studentName = text(student, 'name', fallback: text(item, 'name'));
    final initials = studentName.isNotEmpty
        ? studentName.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text(
              initials,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
                Text(
                  text(
                    asMap(item['subject']),
                    'name',
                    fallback: 'مادة غير محددة',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value(
                item,
                'absence_count',
                fallback: value(item, 'absence_rate'),
              ),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.icon);
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.royalBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.midnight,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.slate500,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Interaction sheets
