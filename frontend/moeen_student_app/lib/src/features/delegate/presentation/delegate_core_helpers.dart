part of 'delegate_screens.dart';

class _StatItem {
  const _StatItem(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

const _titleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w900,
  color: AppColors.midnight,
);

Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map)
    return value.map((key, value) => MapEntry(key.toString(), value));
  return const {};
}

List<dynamic> asList(Object? value) {
  if (value is List) return value;
  if (value is Map) {
    final data = value['data'];
    if (data is List) return data;
  }
  return const [];
}

String text(Object? source, String key, {String fallback = ''}) {
  final map = asMap(source);
  final value = map[key];
  if (value == null) return fallback;
  return value.toString();
}

num number(Object? source, String key, {num fallback = 0}) {
  final map = asMap(source);
  final value = map[key];
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

bool boolValue(Object? source, String key, {bool fallback = false}) {
  final map = asMap(source);
  final value = map[key];
  if (value is bool) return value;
  if (value == 1 || value == '1' || value == 'true') return true;
  if (value == 0 || value == '0' || value == 'false') return false;
  return fallback;
}

String value(Object? source, String key, {String fallback = '0'}) {
  final map = asMap(source);
  final raw = map[key];
  if (raw == null || raw.toString().isEmpty) return fallback;
  return raw.toString();
}

String timeText(Object? source) {
  return text(
    source,
    'created_at',
    fallback: text(source, 'updated_at', fallback: '-'),
  );
}

String dateOnly(String value) {
  if (value.contains('T')) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date != null) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    }
  }
  if (value.length >= 10) return value.substring(0, 10);
  return value.isEmpty ? '-' : value;
}

String timeOnly(String value) {
  if (value.isEmpty) return '-';
  final date = DateTime.tryParse(value)?.toLocal();
  if (date != null) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
  }
  if (value.contains(':') && value.length <= 8) {
    final parts = value.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        final period = hour >= 12 ? 'م' : 'ص';
        final hour12 = hour % 12 == 0 ? 12 : hour % 12;
        return '$hour12:${minute.toString().padLeft(2, '0')} $period';
      }
    }
  }
  if (value.length >= 16) return value.substring(11, 16);
  if (value.length >= 5) return value.substring(0, 5);
  return value;
}

String timeOnly24h(String value) {
  if (value.isEmpty) return '09:00';
  final date = DateTime.tryParse(value)?.toLocal();
  if (date != null) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  if (value.contains(':')) {
    final parts = value.split(':');
    if (parts.length >= 2) {
      final hour = parts[0].padLeft(2, '0');
      final minute = parts[1].padLeft(2, '0');
      return '$hour:$minute';
    }
  }
  return value;
}

String _formatReminderTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Future<void> pickDate(
  BuildContext context,
  TextEditingController controller,
) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (picked != null) {
    controller.text = picked.toIso8601String().split('T').first;
  }
}

Future<void> pickTime(
  BuildContext context,
  TextEditingController controller,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  if (picked != null) {
    controller.text = _formatReminderTime(picked);
  }
}

Future<void> _pickDateTime(
  BuildContext context,
  TextEditingController controller,
) async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (pickedDate == null || !context.mounted) {
    return;
  }

  final pickedTime = await showTimePicker(
    context: context,
    initialTime: _parseReminderTime(controller.text),
  );

  if (pickedTime == null) {
    return;
  }

  final date =
      '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
  final time = _formatReminderTime(pickedTime);
  controller.text = '$date $time:00';
}

TimeOfDay _parseReminderTime(String value) {
  final parts = value.split(':');
  if (parts.length >= 2) {
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    }
  }
  return const TimeOfDay(hour: 8, minute: 0);
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.danger),
  );
}

void _showNoPermissionSnackBar(BuildContext context) {
  showMoeenInfoDialog(
    context: context,
    title: 'ليس لديك صلاحيات',
    message:
        'ليس لديك صلاحيات لهذه العملية. راجع المسؤول الخاص بكليتك لمنحك الصلاحيات.',
    buttonLabel: 'موافق',
    icon: Icons.lock_outline_rounded,
    color: AppColors.warning,
  );
}


String _monthName(int month) {
  const names = [
    '',
    'يناير',
    'فبراير',
    'مارس',
    'إبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return month > 0 && month <= 12 ? names[month] : '';
}

String _dayLabel(String key) {
  return switch (key.toLowerCase()) {
    '7' || 'sunday' => 'الأحد',
    '1' || 'monday' => 'الاثنين',
    '2' || 'tuesday' => 'الثلاثاء',
    '3' || 'wednesday' => 'الأربعاء',
    '4' || 'thursday' => 'الخميس',
    '5' || 'friday' => 'الجمعة',
    '6' || 'saturday' => 'السبت',
    _ => key,
  };
}

String timeAgo(String value) {
  if (value.isEmpty) return '';
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
  return dateOnly(value);
}

String prettyDate(String value) {
  if (value.isEmpty) return '-';
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return value;
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

Color _hexColor(String value, Color fallback) {
  final clean = value.replaceAll('#', '');
  if (clean.length != 6) return fallback;
  return Color(int.tryParse('FF$clean', radix: 16) ?? fallback.toARGB32());
}
