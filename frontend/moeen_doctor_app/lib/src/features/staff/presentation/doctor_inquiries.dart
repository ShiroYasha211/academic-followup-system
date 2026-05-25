part of 'staff_screens.dart';

class DoctorInquiriesScreen extends ConsumerStatefulWidget {
  const DoctorInquiriesScreen({super.key});

  static const route = '/doctor/inquiries';

  @override
  ConsumerState<DoctorInquiriesScreen> createState() =>
      _DoctorInquiriesScreenState();
}

class _DoctorInquiriesScreenState extends ConsumerState<DoctorInquiriesScreen> {
  String _status = 'all';
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/inquiries',
          query: {if (_status != 'all') 'status': _status},
        );
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'استفسارات الطلاب',
      currentRoute: DoctorInquiriesScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final data = _docMap(_docData(snapshot.data ?? const {}));
          final stats = _docMap(data['stats']);
          final settings = _docMap(data['settings']);
          final subjects = _docList(settings['subjects']);
          final inquiries = _docList(data['inquiries']);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'استفسارات الطلاب',
                  subtitle:
                      'إدارة الاستفسارات المحولة وإعدادات فتح الأسئلة لكل مادة.',
                  icon: Icons.forum_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: () => _showSettings(subjects),
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // Bento Metrics Grid
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InquiryBentoCard(
                      label: 'الكل',
                      value: _docText(stats['total'], '0'),
                      color: AppColors.royalBlue,
                      icon: Icons.forum_rounded,
                    ),
                    _InquiryBentoCard(
                      label: 'محولة',
                      value: _docText(stats['forwarded'], '0'),
                      color: AppColors.warning,
                      icon: Icons.forward_rounded,
                    ),
                    _InquiryBentoCard(
                      label: 'مجاب عنها',
                      value: _docText(stats['answered'], '0'),
                      color: AppColors.success,
                      icon: Icons.check_circle_rounded,
                    ),
                    _InquiryBentoCard(
                      label: 'مغلقة',
                      value: _docText(stats['closed'], '0'),
                      color: AppColors.danger,
                      icon: Icons.lock_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Filter Panel with horizontal chips
                const Text(
                  'تصفية الاستفسارات',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFilterChips(),
                const SizedBox(height: 16),

                if (inquiries.isEmpty)
                  const _DocEmpty('لا توجد استفسارات في هذا التصنيف.')
                else
                  ...inquiries.map(
                    (inquiry) => _InquiryCard(
                      inquiry: inquiry,
                      onTap: () async {
                        await context.push(
                          DoctorInquiryDetailsScreen.path(
                            _docInt(inquiry['id']),
                          ),
                        );
                        _reload();
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final choices = [
      {
        'value': 'all',
        'label': 'الكل',
        'icon': Icons.apps_rounded,
        'color': AppColors.royalBlue,
      },
      {
        'value': 'forwarded',
        'label': 'محولة',
        'icon': Icons.forward_rounded,
        'color': AppColors.warning,
      },
      {
        'value': 'answered',
        'label': 'مجاب عنها',
        'icon': Icons.check_circle_rounded,
        'color': AppColors.success,
      },
      {
        'value': 'closed',
        'label': 'مغلقة',
        'icon': Icons.lock_rounded,
        'color': AppColors.danger,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: choices.map((choice) {
          final val = choice['value'] as String;
          final label = choice['label'] as String;
          final icon = choice['icon'] as IconData;
          final color = choice['color'] as Color;
          final isSelected = _status == val;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              avatar: Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : color,
              ),
              selectedColor: color,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? Colors.transparent : AppColors.slate100,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              label: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.slate700,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _status = val;
                    _future = _fetch();
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showSettings(List<_Json> subjects) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'إعدادات الاستفسارات',
      icon: Icons.settings_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _InquirySettingsPanel(subjects: subjects, onChanged: _reload),
    );
  }
}

// Bento stat card widget
class _InquiryBentoCard extends StatelessWidget {
  const _InquiryBentoCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      height: 98,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.14), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              left: -14,
              top: -14,
              child: Icon(icon, size: 64, color: color.withValues(alpha: 0.06)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorInquiryDetailsScreen extends StatelessWidget {
  const DoctorInquiryDetailsScreen({super.key, required this.inquiryId});

  static const route = '/doctor/inquiries/:inquiryId';

  final int inquiryId;

  static String path(int inquiryId) => '/doctor/inquiries/$inquiryId';

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'تفاصيل الاستفسار',
      currentRoute: DoctorInquiriesScreen.route,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          const _DocHero(
            title: 'تفاصيل الاستفسار',
            subtitle: 'مراجعة سؤال الطالب والرد عليه من مساحة واضحة ومنظمة.',
            icon: Icons.question_answer_rounded,
          ),
          const SizedBox(height: 14),
          _InquiryDetailsPanel(inquiryId: inquiryId, onAnswered: () {}),
        ],
      ),
    );
  }
}

IconData _inquiryStatusIcon(String status) {
  switch (status) {
    case 'answered':
      return Icons.mark_chat_read_rounded;
    case 'closed':
      return Icons.lock_rounded;
    case 'forwarded':
      return Icons.forward_to_inbox_rounded;
    default:
      return Icons.contact_support_rounded;
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.inquiry, required this.onTap});

  final _Json inquiry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final student = _docMap(inquiry['student']);
    final subject = _docMap(inquiry['subject']);
    final status = _docText(inquiry['status']);
    final color = _docStatusColor(status);
    final title = _docText(inquiry['title'] ?? inquiry['question'], 'استفسار');
    final body = _docText(inquiry['question'] ?? inquiry['body'], '-');
    final studentName = _docText(student['name'], 'طالب');

    // Add subtle glow border for forwarded/pending replies
    final isForwarded = status == 'forwarded';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isForwarded
                ? color.withValues(alpha: 0.4)
                : AppColors.slate100,
            width: isForwarded ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isForwarded ? 0.08 : 0.045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Letter-based Avatar with gradient
                _buildStudentAvatar(studentName, color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _DocPill(
                  _docStatusLabel(status),
                  color,
                  icon: _inquiryStatusIcon(status),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w700,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: AppColors.royalBlue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _docText(subject['name'], '-'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.slate300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAvatar(String name, Color statusColor) {
    final initial = name.isNotEmpty ? name.substring(0, 1) : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.8),
            statusColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InquiryDetailsPanel extends ConsumerStatefulWidget {
  const _InquiryDetailsPanel({
    required this.inquiryId,
    required this.onAnswered,
  });

  final int inquiryId;
  final VoidCallback onAnswered;

  @override
  ConsumerState<_InquiryDetailsPanel> createState() =>
      _InquiryDetailsPanelState();
}

class _InquiryDetailsPanelState extends ConsumerState<_InquiryDetailsPanel> {
  late Future<Map<String, dynamic>> _future = _fetch();
  final _answer = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/inquiries/${widget.inquiryId}');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final inquiry = _docMap(_docData(snapshot.data ?? const {}));
        final student = _docMap(inquiry['student']);
        final subject = _docMap(inquiry['subject']);
        final status = _docText(inquiry['status']);
        final color = _docStatusColor(status);
        final canAnswer = status == 'forwarded';
        final studentName = _docText(student['name'], 'طالب');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student Card Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Circular letter-based avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      studentName.isNotEmpty
                          ? studentName.substring(0, 1)
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_docText(subject['name'], '-')} • ${_docText(student['student_number'], '-')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Inquiry Title Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _docText(
                        inquiry['title'] ?? inquiry['question'],
                        'استفسار',
                      ),
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _DocPill(
                    _docStatusLabel(status),
                    color,
                    icon: _inquiryStatusIcon(status),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Student Question bubble
            _buildChatBubble(
              title: 'سؤال الطالب',
              icon: Icons.help_rounded,
              color: AppColors.royalBlue,
              text: _docText(inquiry['question'] ?? inquiry['body'], '-'),
              isStudent: true,
            ),

            // Doctor Answer bubble
            if (_docText(inquiry['answer']).isNotEmpty)
              _buildChatBubble(
                title: 'رد الدكتور',
                icon: Icons.mark_chat_read_rounded,
                color: AppColors.success,
                text: _docText(inquiry['answer']),
                isStudent: false,
              ),

            if (canAnswer) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.045),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'كتابة الرد',
                      style: TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Predefined Quick templates
                    _buildQuickTemplatesRow(),

                    TextField(
                      controller: _answer,
                      maxLines: 5,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'اكتب رداً واضحاً ومباشراً للطالب...',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: AppColors.slate50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.royalBlue,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _sending ? null : _sendAnswer,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('إرسال الرد'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQuickTemplatesRow() {
    final templates = [
      'يرجى مراجعة المندوب لمتابعة الطلب.',
      'سأقوم بشرح هذا الاستفسار بالتفصيل في المحاضرة القادمة.',
      'تم مراجعة استفسارك وتعديل الدرجات/الحضور بنجاح.',
      'يرجى الحضور لمكتب أستاذ المادة للمناقشة والتوضيح.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: templates.map((tmpl) {
              String label = tmpl;
              if (tmpl.startsWith('يرجى مراجعة')) {
                label = 'مراجعة المندوب';
              } else if (tmpl.startsWith('سأقوم بشرح')) {
                label = 'شرح بالمحاضرة';
              } else if (tmpl.startsWith('تم مراجعة')) {
                label = 'تم التعديل';
              } else if (tmpl.startsWith('يرجى الحضور')) {
                label = 'حضور للمكتب';
              }

              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ActionChip(
                  backgroundColor: AppColors.slate50,
                  side: const BorderSide(color: AppColors.slate100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  label: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.royalBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _answer.text = tmpl;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildChatBubble({
    required String title,
    required IconData icon,
    required Color color,
    required String text,
    required bool isStudent,
  }) {
    return Align(
      alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        width: MediaQuery.sizeOf(context).width * 0.85,
        decoration: BoxDecoration(
          color: isStudent ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: isStudent
                ? const Radius.circular(24)
                : const Radius.circular(4),
            bottomRight: isStudent
                ? const Radius.circular(4)
                : const Radius.circular(24),
          ),
          border: Border.all(
            color: isStudent ? AppColors.slate100 : const Color(0xFFDCFCE7),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.slate700,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendAnswer() async {
    if (_answer.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/inquiries/${widget.inquiryId}/answer',
        {'answer': _answer.text.trim()},
      );
      if (!mounted) return;
      widget.onAnswered();
      setState(() {
        _future = _fetch();
      });
      _docSnack(context, 'تم إرسال الرد.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _InquiryMessageBlock extends StatelessWidget {
  const _InquiryMessageBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.text,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.slate700,
              fontWeight: FontWeight.w700,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _InquirySettingsPanel extends ConsumerStatefulWidget {
  const _InquirySettingsPanel({
    required this.subjects,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> subjects;
  final VoidCallback onChanged;

  @override
  ConsumerState<_InquirySettingsPanel> createState() =>
      _InquirySettingsPanelState();
}

class _InquirySettingsPanelState extends ConsumerState<_InquirySettingsPanel> {
  late final List<_Json> _subjects = widget.subjects
      .map(Map<String, dynamic>.from)
      .toList();

  @override
  Widget build(BuildContext context) {
    if (_subjects.isEmpty) {
      return const _DocEmpty('لا توجد مواد لإعداد الاستفسارات.');
    }
    return Column(
      children: _subjects.asMap().entries.map((entry) {
        final index = entry.key;
        final subject = entry.value;
        final enabled = _docBool(subject['inquiries_enabled']);
        final color = enabled ? AppColors.success : AppColors.danger;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.045),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      enabled ? Icons.forum_rounded : Icons.forum_outlined,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docText(subject['subject_name'], 'مادة'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.midnight,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          enabled
                              ? 'متاحة لاستقبال الاستفسارات'
                              : 'الاستفسارات مغلقة',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    activeThumbColor: AppColors.success,
                    onChanged: (value) => _update(index, value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Text(
                  _docText(
                    subject['status_message'],
                    enabled
                        ? 'الاستفسارات مفتوحة لهذه المادة.'
                        : 'الاستفسارات مغلقة لهذه المادة.',
                  ),
                  style: const TextStyle(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
              if (!enabled && _docText(subject['closed_reason']).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _docText(subject['closed_reason']),
                            style: const TextStyle(
                              color: AppColors.slate700,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _update(int index, bool enabled) async {
    final subject = _subjects[index];
    var reason = _docText(subject['closed_reason']);
    if (!enabled) {
      final controller = TextEditingController(text: reason);
      final ok = await showMoeenBottomSheet<bool>(
        context: context,
        title: 'سبب إغلاق الاستفسارات',
        icon: Icons.lock_rounded,
        color: AppColors.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'السبب اختياري'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      reason = controller.text.trim();
    }
    try {
      final response = await ref.read(staffRepositoryProvider).patch(
        '/doctor/inquiries/subjects/${subject['subject_id']}/settings',
        {'inquiries_enabled': enabled, 'inquiries_closed_reason': reason},
      );
      final updated = _docMap(_docMap(_docData(response))['subject']);
      setState(
        () => _subjects[index] = {
          ...subject,
          ...updated,
          'status_message': enabled
              ? 'الاستفسارات مفتوحة لهذه المادة.'
              : (reason.isNotEmpty ? reason : 'الاستفسارات مغلقة لهذه المادة.'),
        },
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}
