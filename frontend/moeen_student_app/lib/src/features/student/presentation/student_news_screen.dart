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
          final rawItems = asList(data['items']).map(asMap).toList();

          // Sort: pinned first, then by date
          final pinned = rawItems
              .where((i) => boolValue(i, 'is_pinned'))
              .toList();
          final regular = rawItems
              .where((i) => !boolValue(i, 'is_pinned'))
              .toList();

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
                        _NewsHero(total: rawItems.length.toString()),
                        const SizedBox(height: 20),
                        _NewsFilters(
                          value: _source,
                          stats: stats,
                          onChanged: (value) => setState(() => _source = value),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (rawItems.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message: 'لا توجد أخبار أو إعلانات حالياً.',
                    ),
                  )
                else ...[
                  // ── Pinned announcements section ──
                  if (pinned.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.push_pin_rounded,
                                size: 16,
                                color: AppColors.royalBlue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'إعلانات هامة ومثبتة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.royalBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Divider(
                                color: AppColors.royalBlue.withValues(
                                  alpha: 0.15,
                                ),
                                thickness: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      sliver: SliverList.builder(
                        itemCount: pinned.length,
                        itemBuilder: (context, index) => _EntryAnimation(
                          index: index,
                          child: _NewsCard(
                            pinned[index],
                            isLast:
                                index == pinned.length - 1 && regular.isEmpty,
                            isPinned: true,
                            onOpen: _markNewsRead,
                          ),
                        ),
                      ),
                    ),
                  ],
                  // ── Regular announcements section ──
                  if (regular.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.feed_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'آخر المستجدات والأخبار',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.midnight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Divider(
                                color: AppColors.slate200,
                                thickness: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      sliver: SliverList.builder(
                        itemCount: regular.length,
                        itemBuilder: (context, index) => _EntryAnimation(
                          index: pinned.length + index,
                          child: _NewsCard(
                            regular[index],
                            isLast: index == regular.length - 1,
                            onOpen: _markNewsRead,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _markNewsRead(Map<String, dynamic> item) async {
    final rawId = text(item, 'id');
    if (!rawId.startsWith('center-')) return;
    final id = int.tryParse(rawId.substring('center-'.length));
    if (id == null || id <= 0) return;
    try {
      await ref.read(studentContentRepositoryProvider).markNotificationRead(id);
      ref.invalidate(_newsProvider(_source));
      ref.invalidate(studentUnreadNotificationsCountProvider);
      ref.invalidate(studentUnreadScreenCountsProvider);
    } catch (_) {
      // Details still open if marking read fails.
    }
  }
}

class _NewsHero extends StatelessWidget {
  const _NewsHero({required this.total});

  final String total;

  String _formatTotalNews(int count) {
    if (count == 0) return 'لا توجد تحديثات جديدة';
    if (count == 1) return 'لديك تحديث واحد جديد';
    if (count == 2) return 'لديك تحديثان جديدان';
    if (count >= 3 && count <= 10) return 'لديك $count تحديثات جديدة';
    return 'لديك $count تحديثاً جديداً';
  }

  @override
  Widget build(BuildContext context) {
    final count = int.tryParse(total) ?? 0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF0F766E), // Deep luxury teal
            Color(0xFF14B8A6), // Vibrant modern teal
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -40,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -30,
            child: Icon(
              Icons.campaign_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.gold,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'مركز الأخبار الموحد',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipOval(
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.16),
                        child: InkWell(
                          onTap: () => context.push('/student/news/bookmarks'),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.bookmarks_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _formatTotalNews(count),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تابع آخر القرارات الصادرة والمستجدات الدراسية أولاً بأول.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.entries.map((entry) {
          final selected = entry.key == value;
          final color = _sourceColor(entry.key);
          final count = text(stats, entry.key, fallback: '0');

          return GestureDetector(
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsetsDirectional.only(end: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected 
                    ? color.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected 
                      ? color.withValues(alpha: 0.4) 
                      : AppColors.slate200.withValues(alpha: 0.8),
                  width: selected ? 1.8 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    entry.value.$2,
                    size: 16,
                    color: selected ? color : AppColors.slate500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.value.$1,
                    style: TextStyle(
                      color: selected ? color : AppColors.slate700,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  if (count != '0') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.15)
                            : AppColors.slate100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count,
                        style: TextStyle(
                          color: selected ? color : AppColors.slate600,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF0F766E), // Deep Teal
            Color(0xFF14B8A6), // Vibrant Teal
          ],
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

class StudentNewsDetailsScreen extends ConsumerStatefulWidget {
  const StudentNewsDetailsScreen({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  ConsumerState<StudentNewsDetailsScreen> createState() => _StudentNewsDetailsScreenState();
}

class _StudentNewsDetailsScreenState extends ConsumerState<StudentNewsDetailsScreen> {
  double _fontScale = 1.0;
  final ValueNotifier<double> _scrollProgress = ValueNotifier<double>(0.0);
  Map<String, dynamic>? _localPollData;
  bool _isPollLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item['poll_data'] != null) {
      _localPollData = Map<String, dynamic>.from(widget.item['poll_data']);
    }
  }

  @override
  void didUpdateWidget(covariant StudentNewsDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item['poll_data'] != null) {
      _localPollData = Map<String, dynamic>.from(widget.item['poll_data']);
    }
  }

  @override
  void dispose() {
    _scrollProgress.dispose();
    super.dispose();
  }

  String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url.split('?').first);
      final path = uri.path;
      final dotIndex = path.lastIndexOf('.');
      if (dotIndex != -1) {
        return path.substring(dotIndex + 1).toLowerCase();
      }
    } catch (_) {}
    return '';
  }

  IconData _attachmentIcon(String url) {
    final ext = _getFileExtension(url);
    if (ext.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (ext.contains('ppt')) return Icons.slideshow_rounded;
    if (ext.contains('doc')) return Icons.description_rounded;
    if (ext.contains('xls')) return Icons.table_chart_rounded;
    if (ext.contains('mp4') || ext.contains('mov') || ext.contains('video')) {
      return Icons.movie_rounded;
    }
    if (ext.contains('mp3') || ext.contains('wav') || ext.contains('audio')) {
      return Icons.audiotrack_rounded;
    }
    if (ext.contains('txt')) return Icons.notes_rounded;
    if (ext.contains('csv')) return Icons.table_rows_rounded;
    if (ext.contains('zip') || ext.contains('rar')) {
      return Icons.archive_rounded;
    }
    if (ext.contains('jpg') || ext.contains('png') || ext.contains('jpeg') || ext.contains('webp')) {
      return Icons.image_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _attachmentColor(String url) {
    final ext = _getFileExtension(url);
    if (ext.contains('pdf')) return const Color(0xFFE11D48); // Rose 600
    if (ext.contains('ppt')) return const Color(0xFFEA580C); // Orange 600
    if (ext.contains('doc')) return const Color(0xFF2563EB); // Blue 600
    if (ext.contains('xls')) return const Color(0xFF16A34A); // Green 600
    if (ext.contains('mp4') || ext.contains('mov') || ext.contains('video')) {
      return const Color(0xFFDB2777);
    }
    if (ext.contains('mp3') || ext.contains('wav') || ext.contains('audio')) {
      return const Color(0xFF0891B2);
    }
    if (ext.contains('txt') || ext.contains('csv')) return AppColors.teal;
    if (ext.contains('zip') || ext.contains('rar')) {
      return const Color(0xFF7C3AED); // Violet 600
    }
    if (ext.contains('jpg') || ext.contains('png') || ext.contains('jpeg') || ext.contains('webp')) {
      return const Color(0xFF8E24AA); // Purple
    }
    return AppColors.slate500;
  }

  String _attachmentTypeName(String url) {
    final ext = _getFileExtension(url);
    if (ext.contains('pdf')) return 'مستند PDF';
    if (ext.contains('doc')) return 'مستند Word';
    if (ext.contains('xls')) return 'جدول Excel';
    if (ext.contains('ppt')) return 'عرض PowerPoint';
    if (ext.contains('zip') || ext.contains('rar')) return 'ملف مضغوط';
    if (ext.contains('jpg') || ext.contains('png') || ext.contains('jpeg') || ext.contains('webp')) return 'صورة';
    if (ext.contains('mp3') || ext.contains('wav')) return 'ملف صوتي';
    if (ext.contains('mp4') || ext.contains('mov')) return 'ملف فيديو';
    return ext.isEmpty ? 'ملف مرفق' : 'ملف ${ext.toUpperCase()}';
  }

  void _quickPreviewFile(BuildContext context, String url, String title) async {
    final ext = _getFileExtension(url);
    if (ext.contains('jpg') || ext.contains('png') || ext.contains('jpeg') || ext.contains('webp')) {
      MoeenDialogs.showImage(context, url);
      return;
    }

    if (ext.contains('pdf')) {
      final fileName = _downloadFileName(url, title);
      MoeenDialogs.showLoading(context, message: 'جاري تحميل ومعاينة الملف...');
      try {
        final cachedPath = await DownloadService.findMoeenFile(fileName: fileName, section: 'StudentNews');
        if (cachedPath != null) {
          Navigator.pop(context); // close loading
          await DownloadService.openPath(cachedPath);
          return;
        }

        final savedPath = await DownloadService.downloadUrlToMoeenFolder(
          url: url,
          fileName: fileName,
          section: 'StudentNews',
        );
        Navigator.pop(context); // close loading
        if (savedPath != null) {
          await DownloadService.openPath(savedPath);
        }
      } catch (e) {
        Navigator.pop(context); // close loading
        MoeenDialogs.showError(context, message: 'تعذر فتح ملف الـ PDF: ${e.toString()}');
      }
      return;
    }

    // Fallback to standard save download for other files
    _downloadUrlToFile(context, url, title, section: 'StudentNews');
  }

  Future<void> _castVote(int optionId) async {
    final rawId = text(widget.item, 'id');
    if (!rawId.startsWith('center-')) return;
    final notificationId = int.tryParse(rawId.substring('center-'.length));
    if (notificationId == null) return;

    setState(() {
      _isPollLoading = true;
    });
    try {
      await ref.read(studentContentRepositoryProvider).voteNotification(
        notificationId: notificationId,
        optionId: optionId,
      );

      // Update local state to reflect the vote
      setState(() {
        if (_localPollData != null) {
          final options = List<Map<String, dynamic>>.from(
            asList(_localPollData!['options']).map(asMap),
          );

          for (var i = 0; i < options.length; i++) {
            final opt = Map<String, dynamic>.from(options[i]);
            if (number(opt, 'id').toInt() == optionId) {
              opt['votes_count'] = (number(opt, 'votes_count').toInt() + 1);
            }
            options[i] = opt;
          }

          _localPollData!['options'] = options;
          _localPollData!['has_voted'] = true;
          _localPollData!['voted_option_id'] = optionId;
        }
        _isPollLoading = false;
      });

      // Invalidate providers to refresh lists in background
      ref.invalidate(_newsProvider('all'));
      ref.invalidate(_newsProvider('administration'));
      ref.invalidate(_newsProvider('doctor'));
      ref.invalidate(_newsProvider('delegate'));
      ref.invalidate(studentUnreadNotificationsCountProvider);

      MoeenDialogs.showSuccess(context, message: 'تم تسجيل صوتك بنجاح.');
    } catch (e) {
      setState(() {
        _isPollLoading = false;
      });
      MoeenDialogs.showError(context, message: 'فشل التصويت: ${e.toString()}');
    }
  }

  Future<void> _retractVote() async {
    final rawId = text(widget.item, 'id');
    if (!rawId.startsWith('center-')) return;
    final notificationId = int.tryParse(rawId.substring('center-'.length));
    if (notificationId == null) return;

    setState(() {
      _isPollLoading = true;
    });
    try {
      await ref.read(studentContentRepositoryProvider).retractVoteNotification(
        notificationId: notificationId,
      );

      // Update local state to reflect retracting the vote
      setState(() {
        if (_localPollData != null) {
          final options = List<Map<String, dynamic>>.from(
            asList(_localPollData!['options']).map(asMap),
          );
          final votedOptionId = number(_localPollData!, 'voted_option_id').toInt();

          for (var i = 0; i < options.length; i++) {
            final opt = Map<String, dynamic>.from(options[i]);
            if (number(opt, 'id').toInt() == votedOptionId) {
              opt['votes_count'] = (number(opt, 'votes_count').toInt() - 1).clamp(0, 99999);
            }
            options[i] = opt;
          }

          _localPollData!['options'] = options;
          _localPollData!['has_voted'] = false;
          _localPollData!['voted_option_id'] = 0;
        }
        _isPollLoading = false;
      });

      // Invalidate news providers to refresh lists in the background
      ref.invalidate(_newsProvider('all'));
      ref.invalidate(_newsProvider('administration'));
      ref.invalidate(_newsProvider('doctor'));
      ref.invalidate(_newsProvider('delegate'));
      ref.invalidate(studentUnreadNotificationsCountProvider);

      MoeenDialogs.showSuccess(context, message: 'تم سحب صوتك بنجاح.');
    } catch (e) {
      setState(() {
        _isPollLoading = false;
      });
      MoeenDialogs.showError(context, message: 'فشل سحب التصويت: ${e.toString()}');
    }
  }

  Widget _buildPollWidget(Color color) {
    if (_localPollData == null) return const SizedBox.shrink();

    final options = List<Map<String, dynamic>>.from(
      asList(_localPollData!['options']).map(asMap),
    );
    final hasVoted = boolValue(_localPollData!, 'has_voted');
    final votedId = number(_localPollData!, 'voted_option_id').toInt();

    final totalVotes = options.fold<int>(
      0,
      (sum, item) => sum + number(item, 'votes_count').toInt(),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.analytics_rounded, size: 18, color: color),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'استبيان تصويت',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasVoted ? 'شكراً لمشاركتك في هذا التصويت' : 'شاركنا برأيك في الاستبيان أدناه',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$totalVotes صوت',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...options.map((option) {
                final id = number(option, 'id').toInt();
                final selected = id == votedId;
                final votes = number(option, 'votes_count').toInt();
                final percent = totalVotes == 0 ? 0.0 : (votes / totalVotes);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? color : AppColors.slate200,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          if (hasVoted)
                            Positioned.fill(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: percent),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (context, animPercent, child) {
                                  return Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: FractionallySizedBox(
                                      widthFactor: animPercent,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: selected ? 0.16 : 0.07),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isPollLoading || hasVoted ? null : () => _castVote(id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    if (hasVoted) ...[
                                      if (selected)
                                        Icon(Icons.check_circle_rounded, color: color, size: 20)
                                      else
                                        const SizedBox(width: 20),
                                    ] else ...[
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: color.withValues(alpha: 0.6),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        text(option, 'text'),
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                                          fontSize: 13,
                                          color: selected ? AppColors.midnight : AppColors.slate700,
                                        ),
                                      ),
                                    ),
                                    if (hasVoted)
                                      Text(
                                        '${(percent * 100).toInt()}%',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          color: selected ? color : AppColors.slate600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (hasVoted) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: _isPollLoading ? null : _retractVote,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      textStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    icon: const Icon(Icons.undo_rounded, size: 16),
                    label: const Text('سحب التصويت / تغيير الاختيار'),
                  ),
                ),
              ],
            ],
          ),
          if (_isPollLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white24,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(
    BuildContext context,
    String attachment,
    String title,
    Color sourceColor,
  ) {
    final fileColor = _attachmentColor(attachment);
    final fileIcon = _attachmentIcon(attachment);
    final fileTypeName = _attachmentTypeName(attachment);
    final ext = _getFileExtension(attachment);
    final isPreviewable = ext.contains('pdf') ||
        ext.contains('jpg') ||
        ext.contains('png') ||
        ext.contains('jpeg') ||
        ext.contains('webp');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fileColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fileColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: fileColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(fileIcon, color: fileColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileTypeName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'انقر للمعاينة السريعة أو التحميل المباشر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.slate500,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isPreviewable) ...[
            GestureDetector(
              onTap: () => _quickPreviewFile(context, attachment, title),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: fileColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_rounded, color: fileColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'معاينة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: fileColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () => _downloadUrlToFile(
              context,
              attachment,
              title,
              section: 'StudentNews',
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: fileColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: fileColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.file_download_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'تحميل',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final itemId = text(item, 'id');
    final attachment = absoluteUrl(text(item, 'attachment_url'));
    final source = text(item, 'source');
    final color = _sourceColor(source);
    final isImage = attachment.isNotEmpty && isImageUrl(attachment);
    final title = text(item, 'title', fallback: 'إعلان جديد');
    final body = text(item, 'body', fallback: text(item, 'excerpt'));
    final authorName = text(item, 'author_name', fallback: 'النظام');
    final createdAt = text(item, 'created_at');

    final isBookmarked = ref.watch(newsBookmarksProvider).any((b) => text(b, 'id') == itemId);

    final IconData publisherIcon = switch (source) {
      'doctor' => Icons.school_rounded,
      'delegate' => Icons.groups_rounded,
      _ => Icons.account_balance_rounded,
    };

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: isImage ? 320.0 : 120.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: isImage ? Colors.transparent : color,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isImage
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isImage ? AppColors.slate900 : Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isImage
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isBookmarked
                            ? AppColors.teal
                            : (isImage ? AppColors.slate900 : Colors.white),
                        size: 20,
                      ),
                      onPressed: () {
                        ref.read(newsBookmarksProvider.notifier).toggleBookmark(item);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isImage
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.remove_rounded,
                          color: isImage ? AppColors.slate900 : Colors.white,
                          size: 16,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_fontScale > 0.8) _fontScale -= 0.15;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isImage ? AppColors.slate900 : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.add_rounded,
                          color: isImage ? AppColors.slate900 : Colors.white,
                          size: 16,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_fontScale < 1.6) _fontScale += 0.15;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: ValueListenableBuilder<double>(
                  valueListenable: _scrollProgress,
                  builder: (context, progress, child) {
                    final isRtl = Directionality.of(context) == TextDirection.rtl;
                    return Align(
                      alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        height: 3.0,
                        width: MediaQuery.of(context).size.width * progress,
                        decoration: BoxDecoration(
                          color: isImage ? color : Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(1.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: isImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'news-image-$itemId',
                            child: Image.network(
                              attachment,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _NewsImageFallback(height: 320),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.0),
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 24,
                            child: GestureDetector(
                              onTap: () =>
                                  MoeenDialogs.showImage(context, attachment),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.zoom_out_map_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'تكبير وعرض',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              color,
                              color.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: -20,
                              bottom: -20,
                              child: Icon(
                                Icons.campaign_rounded,
                                size: 180,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ];
        },
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification.depth == 0 && notification is ScrollUpdateNotification) {
                final metrics = notification.metrics;
                if (metrics.maxScrollExtent > 0) {
                  final progress = (metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0);
                  _scrollProgress.value = progress;
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (Primary Hero)
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Unified Publisher Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate200.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                publisherIcon,
                                color: color,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: AppColors.midnight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      _sourceLabel(source),
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        color: AppColors.slate400,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      timeAgo(createdAt),
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        color: AppColors.slate500,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 24),

                    // Paragraphs of Body Text with optimized styling
                    ...body.split(RegExp(r'\n\s*\n+')).map((p) {
                      final trimmed = p.trim();
                      if (trimmed.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          trimmed,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15 * _fontScale,
                            height: 1.65,
                            color: AppColors.slate800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),

                    // Poll (if exists)
                    if (_localPollData != null) ...[
                      const SizedBox(height: 28),
                      _buildPollWidget(color),
                    ],

                    // Attachment Card (if exists)
                    if (attachment.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildAttachmentCard(context, attachment, title, color),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StudentNewsBookmarksScreen extends ConsumerWidget {
  const StudentNewsBookmarksScreen({super.key});

  static const route = '/student/news/bookmarks';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(newsBookmarksProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'الإشارات المرجعية',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.midnight,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.midnight),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: bookmarks.isEmpty
          ? const Center(
              child: EmptyState(
                message: 'لا توجد إشارات مرجعية محفوظة حالياً.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                return _NewsCard(
                  bookmarks[index],
                  isLast: index == bookmarks.length - 1,
                  isPinned: false,
                );
              },
            ),
    );
  }
}

final newsBookmarksStoreProvider = Provider<NewsBookmarksLocalStore>((ref) {
  return const NewsBookmarksLocalStore();
});

final newsBookmarksProvider = StateNotifierProvider<NewsBookmarksNotifier, List<Map<String, dynamic>>>((ref) {
  final store = ref.watch(newsBookmarksStoreProvider);
  return NewsBookmarksNotifier(store);
});

class NewsBookmarksNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  NewsBookmarksNotifier(this._store) : super(const []) {
    _load();
  }

  final NewsBookmarksLocalStore _store;

  Future<void> _load() async {
    state = await _store.load();
  }

  Future<void> toggleBookmark(Map<String, dynamic> item) async {
    final itemId = text(item, 'id');
    final contains = state.any((element) => text(element, 'id') == itemId);
    List<Map<String, dynamic>> newState;
    if (contains) {
      newState = state.where((element) => text(element, 'id') != itemId).toList();
    } else {
      newState = [...state, item];
    }
    state = newState;
    await _store.save(newState);
  }

  bool isBookmarked(String itemId) {
    return state.any((element) => text(element, 'id') == itemId);
  }
}

class NewsBookmarksLocalStore {
  const NewsBookmarksLocalStore();

  Future<List<Map<String, dynamic>>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return [];
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Map<String, dynamic>> items) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(items), flush: true);
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/moeen_news/bookmarks.json');
  }
}
