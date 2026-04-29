part of 'student_content_screens.dart';

class StudentInquiriesScreen extends ConsumerStatefulWidget {
  const StudentInquiriesScreen({super.key});

  static const route = '/student/inquiries';
  static String detailsPath(int id) => '/student/inquiries/$id';

  @override
  ConsumerState<StudentInquiriesScreen> createState() =>
      _StudentInquiriesScreenState();
}

class _StudentInquiriesScreenState
    extends ConsumerState<StudentInquiriesScreen> {
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_inquiriesProvider(_status));
    return StudentShell(
      currentIndex: 17,
      title: 'استفسارات الدكتور',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateInquiry(context, ref),
        backgroundColor: AppColors.royalBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('استفسار جديد', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_inquiriesProvider(_status)),
        builder: (data) {
          final stats = asMap(data['stats']);
          final page = asMap(data['inquiries']);
          final inquiries = asList(page['data']).map(asMap).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_inquiriesProvider(_status)),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _InquiryHeader(stats: stats),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _InquiryFilters(
                      selected: _status,
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ),
                ),
                if (inquiries.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(message: 'لا توجد استفسارات في هذا التصنيف.'),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverList.builder(
                      itemCount: inquiries.length,
                      itemBuilder: (context, index) {
                        return _EntryAnimation(
                          index: index,
                          child: _InquiryCard(item: inquiries[index]),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateInquiry(BuildContext context, WidgetRef ref) async {
    final optionsState = await ref.read(_inquiryOptionsProvider.future);
    if (!context.mounted) return;
    final options = asList(optionsState['options']).map(asMap).toList();
    if (options.isEmpty) {
      await showMoeenInfoDialog(
        context: context,
        title: 'لا توجد مواد متاحة',
        message: 'لا توجد مادة مرتبطة بدكتور يمكن إرسال استفسار له حالياً.',
        icon: Icons.info_rounded,
        color: AppColors.goldDeep,
      );
      return;
    }

    final title = TextEditingController();
    final question = TextEditingController();
    int selectedSubject = number(options.first, 'subject_id').toInt();
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'استفسار جديد',
      icon: Icons.add_comment_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (sheetContext, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedSubject,
              decoration: const InputDecoration(
                labelText: 'الدكتور والمادة',
                prefixIcon: Icon(Icons.school_rounded),
              ),
              items: options.map((option) {
                final enabled = boolValue(option, 'can_receive_inquiries');
                return DropdownMenuItem(
                  value: number(option, 'subject_id').toInt(),
                  enabled: enabled,
                  child: Text(
                    text(
                      option,
                      'display_label',
                      fallback: text(option, 'label'),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setLocal(() => selectedSubject = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'عنوان الاستفسار',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: question,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'نص السؤال',
                prefixIcon: Icon(Icons.question_answer_rounded),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.pop(sheetContext, true),
              icon: const Icon(Icons.send_rounded),
              label: const Text('إرسال الاستفسار'),
            ),
          ],
        ),
      ),
    );
    if (ok != true ||
        title.text.trim().isEmpty ||
        question.text.trim().isEmpty) {
      return;
    }
    if (!context.mounted) return;
    await _runSnack(
      context,
      () => ref
          .read(studentContentRepositoryProvider)
          .createInquiry(
            subjectId: selectedSubject,
            title: title.text.trim(),
            question: question.text.trim(),
          ),
      onDone: () {
        ref.invalidate(_inquiriesProvider(_status));
        ref.invalidate(_inquiryOptionsProvider);
      },
    );
  }
}

class StudentInquiryDetailsScreen extends ConsumerWidget {
  const StudentInquiryDetailsScreen({super.key, required this.inquiryId});
  final int inquiryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_inquiryDetailsProvider(inquiryId));
    return StudentShell(
      currentIndex: 17,
      title: 'تفاصيل الاستفسار',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_inquiryDetailsProvider(inquiryId)),
        builder: (data) {
          final inquiry = asMap(data['inquiry']);
          final subject = asMap(inquiry['subject']);
          final doctor = asMap(subject['doctor']);
          final color = _hexColor(text(inquiry, 'status_color'), AppColors.royalBlue);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _DetailsHeader(inquiry: inquiry, subject: subject, doctor: doctor, color: color),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(18),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionCard(
                      title: 'نص السؤال',
                      icon: Icons.help_outline_rounded,
                      color: AppColors.royalBlue,
                      child: Text(
                        text(inquiry, 'question'),
                        style: const TextStyle(fontSize: 15, height: 1.8, fontWeight: FontWeight.w600, color: AppColors.slate800),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'رد الدكتور / المندوب',
                      icon: Icons.mark_chat_read_rounded,
                      color: AppColors.success,
                      child: text(inquiry, 'answer').isEmpty
                          ? const EmptyState(message: 'لم يتم الرد على الاستفسار حتى الآن.')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (text(inquiry, 'answered_by_actor_label').isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      'بواسطة: ${text(inquiry, 'answered_by_actor_label')} - ${text(inquiry, 'answered_by_actor_name')}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.goldDeep),
                                    ),
                                  ),
                                Text(
                                  text(inquiry, 'answer'),
                                  style: const TextStyle(fontSize: 15, height: 1.8, fontWeight: FontWeight.w700, color: AppColors.midnight),
                                ),
                              ],
                            ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InquiryHeader extends StatelessWidget {
  const _InquiryHeader({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.royalBlue, AppColors.royalBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مركز الاستفسارات',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                Text(
                  'لديك ${text(stats, 'total', fallback: '0')} استفسار مسبق',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.contact_support_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.inquiry,
    required this.subject,
    required this.doctor,
    required this.color,
  });
  final Map<String, dynamic> inquiry;
  final Map<String, dynamic> subject;
  final Map<String, dynamic> doctor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  text(inquiry, 'status_label'),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
              const Spacer(),
              Text(
                timeAgo(text(inquiry, 'created_at')),
                style: const TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            text(inquiry, 'title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.midnight),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.school_rounded, size: 16, color: AppColors.royalBlue),
              const SizedBox(width: 8),
              Text(
                '${text(subject, 'name')} • د. ${text(doctor, 'name')}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.color,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          child,
        ],
      ),
    );
  }
}

class _InquiryFilters extends StatelessWidget {
  const _InquiryFilters({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'الكل'),
      ('pending', 'قيد الانتظار'),
      ('forwarded', 'محولة'),
      ('answered', 'تم الرد'),
      ('closed', 'مغلقة'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: filters.map((item) {
          final active = selected == item.$1;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: InkWell(
              onTap: () => onChanged(item.$1),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.royalBlue : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: active ? AppColors.royalBlue : AppColors.slate200),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.royalBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.slate600,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final subject = asMap(item['subject']);
    final doctor = asMap(subject['doctor']);
    final color = _hexColor(text(item, 'status_color'), AppColors.royalBlue);
    final isAnswered = text(item, 'status') == 'answered';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(
          StudentInquiriesScreen.detailsPath(number(item, 'id').toInt()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.contact_support_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text(item, 'title', fallback: 'استفسار'),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.midnight),
                        ),
                        Text(
                          timeAgo(text(item, 'created_at')),
                          style: const TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.slate300),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.school_rounded, size: 14, color: AppColors.royalBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${text(subject, 'name')} • د. ${text(doctor, 'name')}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MiniBadge(label: text(item, 'status_label'), color: color),
                  const SizedBox(width: 8),
                  if (text(item, 'answered_by_actor_label').isNotEmpty)
                    _MiniBadge(
                      label: text(item, 'answered_by_actor_label'),
                      color: AppColors.goldDeep,
                    ),
                  const Spacer(),
                  if (isAnswered)
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _hexColor(String value, Color fallback) {
  final clean = value.replaceAll('#', '');
  if (clean.length != 6) return fallback;
  return Color(int.tryParse('FF$clean', radix: 16) ?? fallback.toARGB32());
}
