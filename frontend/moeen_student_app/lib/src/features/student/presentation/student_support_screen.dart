import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import 'widgets/student_shell.dart';

class StudentSupportScreen extends ConsumerWidget {
  const StudentSupportScreen({super.key});

  static const route = '/student/support';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StudentShell(
      currentIndex: 0,
      title: 'مركز المساعدة',
      child: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
        color: AppColors.royalBlue,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 48),
          children: [
            const _SupportHero(),
            const SizedBox(height: 28),
            const _SectionTitle(title: 'قنوات التواصل المباشر'),
            const SizedBox(height: 12),
            const _ContactCard(
              icon: Icons.phone_in_talk_rounded,
              color: AppColors.royalBlue,
              title: 'الهاتف المباشر',
              value: '+967 777 000 111',
              subtitle: 'السبت - الخميس | 8:00 ص - 2:00 م',
            ),
            const _ContactCard(
              icon: Icons.chat_rounded,
              color: AppColors.success,
              title: 'واتساب الدعم',
              value: '+967 777 000 222',
              subtitle: 'للاستفسارات العاجلة والتقنية',
            ),
            const _ContactCard(
              icon: Icons.alternate_email_rounded,
              color: AppColors.orange,
              title: 'البريد الإلكتروني',
              value: 'support@moeen.tech',
              subtitle: 'للمراسلات والطلبات الرسمية',
            ),
            const SizedBox(height: 28),
            const _SectionTitle(title: 'منصات التواصل الاجتماعي'),
            const SizedBox(height: 12),
            const _ContactCard(
              icon: Icons.public_rounded,
              color: AppColors.info,
              title: 'الموقع الإلكتروني',
              value: 'moeen.tech',
              subtitle: 'البوابة الإخبارية والتحديثات',
            ),
            const _ContactCard(
              icon: Icons.camera_alt_rounded,
              color: AppColors.rose,
              title: 'إنستغرام',
              value: '@moeen.app',
              subtitle: 'دليل الاستخدام والشروحات',
            ),
            const SizedBox(height: 32),
            const _SupportNotice(),
          ],
        ),
      ),
    );
  }
}

class _SupportHero extends StatelessWidget {
  const _SupportHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.royalBlueDark,
                    AppColors.royalBlue,
                    const Color(0xFF1E40AF),
                  ],
                ),
              ),
            ),
            // Decorative Circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: 20,
              child: Icon(
                Icons.support_agent_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.gold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'مركز الدعم والمساعدة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'نحن هنا لخدمتك، تواصل معنا عبر القنوات المتاحة.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.royalBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.midnight,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Text('تم نسخ $title بنجاح'),
          ],
        ),
        backgroundColor: AppColors.midnight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(18),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _copyToClipboard(context),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Copy Action
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate100),
                  ),
                  child: const Icon(
                    Icons.copy_all_rounded,
                    color: AppColors.royalBlue,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportNotice extends StatelessWidget {
  const _SupportNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.goldDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ملاحظات هامة للطلاب',
                style: TextStyle(
                  color: AppColors.goldDeep,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'عند وجود مشكلة في الحضور أو رفع الملفات، يرجى إرسال اسمك، رقم القيد، وصف دقيق للمشكلة، مع لقطة شاشة توضيحية لضمان سرعة المعالجة.',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
