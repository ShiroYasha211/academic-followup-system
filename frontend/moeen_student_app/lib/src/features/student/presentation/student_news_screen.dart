part of 'student_content_screens.dart';

class StudentNewsScreen extends ConsumerStatefulWidget {
  const StudentNewsScreen({super.key});

  static const route = '/student/news';

  @override
  ConsumerState<StudentNewsScreen> createState() => _StudentNewsScreenState();
}

class _StudentNewsScreenState extends ConsumerState<StudentNewsScreen> {
  String _source = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_newsProvider(_source));
    return StudentShell(
      currentIndex: 6,
      title: 'الأخبار والإعلانات',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_newsProvider(_source)),
        loading: ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: 5,
          itemBuilder: (_, __) => const _NewsSkeleton(),
        ),
        builder: (data) {
          final stats = asMap(data['stats']);
          final items = asList(data['items']).map(asMap).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_newsProvider(_source)),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NewsHero(total: items.length.toString()),
                        const SizedBox(height: 20),
                        _NewsFilters(
                          value: _source,
                          stats: stats,
                          onChanged: (value) => setState(() => _source = value),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'آخر التحديثات',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message: 'لا توجد أخبار أو إعلانات حالياً.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) => _EntryAnimation(
                        index: index,
                        child: _NewsCard(
                          items[index],
                          isLast: index == items.length - 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NewsHero extends StatelessWidget {
  const _NewsHero({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.royalBlue,
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.royalBlue,
            AppColors.royalBlueDark.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -20,
            bottom: -20,
            child: Icon(
              Icons.campaign_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'مركز الأخبار الموحد',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'لديك $total تحديثات جديدة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'تابع آخر المستجدات من الإدارة والدكاترة.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _NewsFilters extends StatelessWidget {
  const _NewsFilters({
    required this.value,
    required this.stats,
    required this.onChanged,
  });

  final String value;
  final Map<String, dynamic> stats;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = {
      'all': ('الكل', Icons.grid_view_rounded),
      'administration': ('الإدارة', Icons.account_balance_rounded),
      'doctor': ('الدكاترة', Icons.school_rounded),
      'delegate': ('المندوبين', Icons.groups_rounded),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries.map((entry) {
          final selected = entry.key == value;
          final color = _sourceColor(entry.key);
          final count = text(stats, entry.key, fallback: '0');

          return GestureDetector(
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsetsDirectional.only(end: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? color : AppColors.slate200,
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    entry.value.$2,
                    size: 18,
                    color: selected ? Colors.white : color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.value.$1,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.slate700,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  if (count != '0') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.2)
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        count,
                        style: TextStyle(
                          color: selected ? Colors.white : color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NewsImageFallback extends StatelessWidget {
  const _NewsImageFallback({this.height = 170});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.royalBlue, AppColors.goldDeep],
        ),
      ),
      child: Icon(
        Icons.campaign_rounded,
        size: 74,
        color: Colors.white.withValues(alpha: 0.82),
      ),
    );
  }
}
