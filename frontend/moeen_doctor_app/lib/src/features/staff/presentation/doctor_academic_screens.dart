part of 'staff_screens.dart';

typedef _Json = Map<String, dynamic>;

_Json _docMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<_Json> _docList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

String _docText(Object? value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _shortDocText(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength)}...';
}

num _docNum(Object? value, [num fallback = 0]) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

int _docInt(Object? value, [int fallback = 0]) =>
    _docNum(value, fallback).toInt();

bool _docBool(Object? value) =>
    value == true ||
    value == 1 ||
    value?.toString() == '1' ||
    value?.toString() == 'true';

Object? _docData(Map<String, dynamic> response) => response['data'] ?? response;

String _docDate(Object? raw) {
  final text = _docText(raw);
  if (text.length >= 10) return text.substring(0, 10);
  return text.isEmpty ? '-' : text;
}

String _docDateTimeForInput(Object? raw) {
  final text = _docText(raw);
  if (text.isEmpty) return '';
  return text.replaceFirst('T', ' ').split('.').first;
}

String _docDateTimeForApi(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}:00';
}

Color _docStatusColor(String status) {
  switch (status) {
    case 'published':
    case 'accepted':
    case 'approved':
    case 'completed':
      return AppColors.success;
    case 'closed':
    case 'overdue':
    case 'rejected':
      return AppColors.danger;
    case 'scheduled':
    case 'pending':
    case 'draft':
      return AppColors.warning;
    default:
      return AppColors.royalBlue;
  }
}

String _docStatusLabel(String status) {
  switch (status) {
    case 'published':
      return 'منشور';
    case 'scheduled':
      return 'مجدول';
    case 'draft':
      return 'مسودة';
    case 'closed':
      return 'مغلق';
    case 'accepted':
      return 'مقبول';
    case 'rejected':
      return 'مرفوض';
    case 'pending':
      return 'بانتظار المراجعة';
    case 'approved':
      return 'معتمد';
    case 'overdue':
      return 'متأخر';
    default:
      return status.isEmpty ? '-' : status;
  }
}

IconData _docFileIcon(String type) {
  final value = type.toLowerCase();
  if (value.contains('pdf')) return Icons.picture_as_pdf_rounded;
  if (value.contains('doc')) return Icons.description_rounded;
  if (value.contains('xls')) return Icons.table_chart_rounded;
  if (value.contains('ppt')) return Icons.slideshow_rounded;
  if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(value)) {
    return Icons.image_rounded;
  }
  if (value.contains('zip') || value.contains('rar')) {
    return Icons.folder_zip_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

String _docFileName(_Json item, {String fallback = 'moeen-file'}) {
  final title = _docText(
    item['title'] ?? item['attachment_name'] ?? item['file_name'],
    fallback,
  ).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final type = _docText(item['file_type']).replaceAll('.', '');
  if (type.isEmpty || title.toLowerCase().endsWith('.$type')) return title;
  return '$title.$type';
}

void _docSnack(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
}

Future<void> _docErrorDialog(BuildContext context, Object error) async {
  if (staffIsSubscriptionRequired(error)) {
    await showStaffSubscriptionRequiredDialog(context, error);
    if (!context.mounted) return;
  }
  final message = error is ApiException ? error.message : error.toString();
  await showMoeenInfoDialog(
    context: context,
    title: 'حدث خطأ',
    message: message,
    icon: Icons.error_outline_rounded,
    color: AppColors.danger,
  );
}

class _DocHero extends StatelessWidget {
  const _DocHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
          ...?bottom == null ? null : [bottom!],
        ],
      ),
    );
  }
}

class _DocMetric extends StatelessWidget {
  const _DocMetric({
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
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.055),
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
              left: -18,
              top: -18,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 22,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.midnight,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
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

class _DocEmpty extends StatelessWidget {
  const _DocEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: AppColors.slate400, size: 38),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocPill extends StatelessWidget {
  const _DocPill(this.label, this.color, {this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocHeroPill extends StatelessWidget {
  const _DocHeroPill(this.label, {required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocFilterChoice {
  const _DocFilterChoice({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

class _DocFilterPanel extends StatelessWidget {
  const _DocFilterPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.royalBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DocSubjectPicker extends StatelessWidget {
  const _DocSubjectPicker({
    required this.subjects,
    required this.subjectId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> subjects;
  final int? subjectId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: subjectId,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.slate500,
          ),
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.midnight,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.royalBlue,
                    size: 18,
                  ),
                  SizedBox(width: 9),
                  Text('كل المواد'),
                ],
              ),
            ),
            ...subjects.map(
              (subject) => DropdownMenuItem<int?>(
                value: _docInt(subject['id']),
                child: Row(
                  children: [
                    const Icon(
                      Icons.book_rounded,
                      color: AppColors.royalBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _docText(subject['name']),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DocSegmentFilter extends StatelessWidget {
  const _DocSegmentFilter({
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final String value;
  final List<_DocFilterChoice> choices;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: choices.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final choice = choices[index];
          final selected = value == choice.value;
          return InkWell(
            onTap: () => onChanged(choice.value),
            borderRadius: BorderRadius.circular(99),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? choice.color.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: selected ? choice.color : AppColors.slate200,
                  width: selected ? 1.4 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: choice.color.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? Icons.check_rounded : choice.icon,
                    color: selected ? choice.color : AppColors.slate500,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    choice.label,
                    style: TextStyle(
                      color: selected ? choice.color : AppColors.slate600,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DocPanelTabBar extends StatelessWidget {
  const _DocPanelTabBar({required this.controller, required this.tabs});

  final TabController controller;
  final List<Tab> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.slate100.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.slate600,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.royalBlue, AppColors.teal],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalBlue.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        tabs: tabs,
      ),
    );
  }
}

