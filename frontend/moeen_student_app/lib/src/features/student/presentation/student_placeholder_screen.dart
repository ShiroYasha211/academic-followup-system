import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'widgets/student_shell.dart';

class StudentPlaceholderScreen extends StatelessWidget {
  const StudentPlaceholderScreen({super.key, required this.feature});

  static const route = '/student/placeholder/:feature';

  final String feature;

  static String path(String feature) => '/student/placeholder/$feature';

  @override
  Widget build(BuildContext context) {
    final label = _labels[feature] ?? 'مسار قادم';
    final isWorkingOn = feature == 'flashcards' || feature == 'tree-farm';

    return StudentShell(
      currentIndex: 3,
      title: label,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 58,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isWorkingOn
                      ? 'جاري العمل على هذه الخدمة في الوقت الحالي وسيتم إطلاقها قريباً.'
                      : 'تم تجهيز المسار داخل التطبيق. سيتم بناء الصفحة الكاملة في المرحلة القادمة.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _labels = {
    'subjects': 'المواد الدراسية',
    'attendance': 'الحضور',
    'grades': 'الدرجات',
    'notifications': 'الإشعارات',
    'study-center': 'مركز الدراسة',
    'qr': 'مسح QR',
    'more': 'باقي خدمات الطالب',
    'flashcards': 'One Line Shot',
    'tree-farm': 'مزرعة الأشجار',
  };
}
