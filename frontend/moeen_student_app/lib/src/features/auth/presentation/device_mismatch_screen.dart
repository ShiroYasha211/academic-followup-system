import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_shell.dart';
import '../../../shared/widgets/moeen_logo.dart';
import '../logic/auth_controller.dart';

class DeviceMismatchScreen extends ConsumerWidget {
  const DeviceMismatchScreen({super.key, this.whatsappNumber});

  static const route = '/device-mismatch';

  final String? whatsappNumber;

  Future<void> _openWhatsApp(BuildContext context, String? resolvedNumber) async {
    final number = resolvedNumber;
    if (number == null || number.isEmpty) {
      _showNoNumberSnackbar(context);
      return;
    }
    // Normalise: remove leading +, spaces, dashes
    final clean = number.replaceAll(RegExp(r'[+\s\-]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) _showNoNumberSnackbar(context);
    }
  }

  Future<void> _copyNumber(BuildContext context, String? resolvedNumber) async {
    final number = resolvedNumber;
    if (number == null || number.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: number));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('تم نسخ رقم الإدارة'),
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

  void _showNoNumberSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('لم يتم تحديد رقم التواصل بعد. راجع الإدارة مباشرة.'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(18),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(publicSupportSettingsProvider);

    final dynamicNumber = settingsAsync.when(
      data: (data) => data['support_whatsapp']?.toString(),
      loading: () => null,
      error: (_, __) => null,
    );

    final finalNumber = (dynamicNumber != null && dynamicNumber.isNotEmpty)
        ? dynamicNumber
        : whatsappNumber;

    final hasNumber = finalNumber != null && finalNumber.isNotEmpty;

    return AuthShell(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header card ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Center(child: MoeenLogo(compact: true, centered: true)),
                  const SizedBox(height: 28),

                  // Icon with pulsing ring
                  _DeviceBlockedIcon(),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'جهاز غير معتمد',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Body text
                  const Text(
                    'هذا الحساب مرتبط بجهاز آخر.\nيرجى التواصل مع الإدارة لتسجيل جهازك الجديد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.slate500,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Explanation box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_rounded, color: AppColors.info, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'لحماية حسابك، يُسمح بتسجيل الدخول من جهاز واحد معتمد فقط. '
                            'إذا غيّرت جهازك أو أعدت تثبيت التطبيق، تواصل مع الإدارة لتحديث معلومات جهازك.',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // WhatsApp button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openWhatsApp(context, finalNumber),
                      icon: const Icon(Icons.chat_rounded, size: 20),
                      label: const Text(
                        'تواصل مع الإدارة عبر واتساب',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  if (hasNumber) ...[
                    const SizedBox(height: 10),
                    // Copy number row
                    OutlinedButton.icon(
                      onPressed: () => _copyNumber(context, finalNumber),
                      icon: const Icon(Icons.copy_all_rounded, size: 18),
                      label: Text(
                        'نسخ الرقم: $finalNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate600,
                        side: const BorderSide(color: AppColors.slate200, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Back to login
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'العودة لتسجيل الدخول',
                      style: TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
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

class _DeviceBlockedIcon extends StatefulWidget {
  @override
  State<_DeviceBlockedIcon> createState() => _DeviceBlockedIconState();
}

class _DeviceBlockedIconState extends State<_DeviceBlockedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger.withValues(alpha: 0.08 * _pulse.value),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.15 * _pulse.value),
              width: 2,
            ),
          ),
          child: child,
        );
      },
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger.withValues(alpha: 0.12),
          ),
          child: const Icon(
            Icons.phone_locked_rounded,
            color: AppColors.danger,
            size: 32,
          ),
        ),
      ),
    );
  }
}
