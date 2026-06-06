import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/device_not_authorized_exception.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/router/landing_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_shell.dart';
import '../../../shared/widgets/moeen_card.dart';
import '../../../shared/widgets/moeen_logo.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/status_message.dart';
import '../logic/auth_controller.dart';
import 'device_mismatch_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const route = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(
          login: _loginController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);

    // Navigate to device mismatch screen on device-binding error
    if (authState.hasError && authState.error is DeviceNotAuthorizedException) {
      final ex = authState.error as DeviceNotAuthorizedException;
      context.push(
        DeviceMismatchScreen.route,
        extra: {'whatsapp_number': ex.whatsappNumber ?? ''},
      );
      return;
    }

    final session = authState.valueOrNull;
    if (session != null) {
      final pendingPath = PushNotificationService.takePendingNavigationPath();
      context.go(pendingPath ?? landingRouteFor(session));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final error = authState.hasError ? authState.error.toString() : null;

    return AuthShell(
      child: MoeenCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: MoeenLogo(compact: true, centered: true)),
              const SizedBox(height: 28),
              Text(
                'تسجيل الدخول',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'ادخل بحساب الطالب أو المندوب للوصول إلى خدمات معين.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (error != null) ...[
                StatusMessage.error(error),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _loginController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'البريد أو رقم القيد',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'أدخل البريد أو رقم القيد.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'أدخل كلمة المرور.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              PrimaryActionButton(
                label: 'دخول إلى التطبيق',
                icon: Icons.login_rounded,
                loading: authState.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'لا تملك حسابًا؟ ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.push(RegisterScreen.route),
                    child: const Text(
                      'إنشاء حساب',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => _showSupportDialog(context, ref),
                  icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.slate400),
                  label: const Text(
                    'تواجه مشكلة في تسجيل الدخول؟ تواصل مع الدعم',
                    style: TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSupportDialog(BuildContext context, WidgetRef ref) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final settingsAsync = ref.watch(publicSupportSettingsProvider);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: SafeArea(
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.05),
                                AppColors.primary.withValues(alpha: 0.01),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                          child: Column(
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.slate200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 30),
                                      ),
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.success.withValues(alpha: 0.4),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.circle, color: AppColors.success, size: 6),
                                              SizedBox(width: 6),
                                              Text(
                                                'الدعم متاح ومتصل الآن',
                                                style: TextStyle(
                                                  color: AppColors.success,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'مركز الدعم والمساعدة',
                                          style: TextStyle(
                                            color: AppColors.midnight,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'تواجه مشكلة؟ اختر قناة الاتصال المناسبة وسنساعدك فوراً',
                                          style: TextStyle(
                                            color: AppColors.slate500,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.slate100),

                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: settingsAsync.when(
                            data: (data) {
                              final phone = data['support_phone']?.toString() ?? '+967 777 000 111';
                              final whatsapp = data['support_whatsapp']?.toString() ?? '+967 777 000 222';
                              final email = data['support_email']?.toString() ?? 'support@moeen.tech';
                              final workHours = data['support_work_hours']?.toString() ?? 'السبت - الخميس | 8:00 ص - 2:00 م';
                              final notice = data['support_notice']?.toString();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSupportCard(
                                    context: context,
                                    iconWidget: const WhatsAppIcon(size: 26),
                                    color: const Color(0xFF25D366),
                                    title: 'واتساب الدعم',
                                    value: whatsapp,
                                    subtitle: 'للاستفسارات العاجلة والمشاكل التقنية',
                                    actionLabel: 'مراسلة',
                                    onTap: () => _launchWhatsApp(context, whatsapp),
                                    onCopy: () => _copyText(context, whatsapp, 'رقم الواتساب'),
                                  ),
                                  _buildSupportCard(
                                    context: context,
                                    iconWidget: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 22),
                                    color: AppColors.primary,
                                    title: 'الهاتف المباشر',
                                    value: phone,
                                    subtitle: 'للاتصال والتواصل الهاتفي المباشر',
                                    actionLabel: 'اتصال',
                                    onTap: () => _launchURL(context, 'tel:${phone.replaceAll(RegExp(r'[\s]'), '')}'),
                                    onCopy: () => _copyText(context, phone, 'رقم الهاتف'),
                                  ),
                                  _buildSupportCard(
                                    context: context,
                                    iconWidget: const GmailIcon(size: 26),
                                    color: const Color(0xFFEA4335),
                                    title: 'البريد الإلكتروني',
                                    value: email,
                                    subtitle: 'للمراسلات الرسمية وتفعيل الحسابات',
                                    actionLabel: 'راسلنا',
                                    onTap: () => _launchEmail(context, email),
                                    onCopy: () => _copyText(context, email, 'البريد الإلكتروني'),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.ghostWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.slate100),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.slate100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.slate600),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'ساعات العمل والدعم الفني',
                                                style: TextStyle(
                                                  color: AppColors.slate500,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                workHours,
                                                style: const TextStyle(
                                                  color: AppColors.midnight,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (notice != null && notice.trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.cream,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'توجيهات الدعم الفني:',
                                                  style: TextStyle(
                                                    color: AppColors.midnight,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  notice,
                                                  style: const TextStyle(
                                                    color: AppColors.slate700,
                                                    fontSize: 11,
                                                    height: 1.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                            error: (error, stack) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'خطأ في تحميل قنوات الاتصال بالدعم الفني',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.midnight),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => ref.invalidate(publicSupportSettingsProvider),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.slate100,
                              foregroundColor: AppColors.slate700,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSupportCard({
    required BuildContext context,
    required Widget iconWidget,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
    required VoidCallback onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100, width: 1.5),
      ),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: iconWidget,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: const TextStyle(
                            color: AppColors.midnight,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.slate400,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_all_rounded, color: AppColors.slate400, size: 18),
                        onPressed: onCopy,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.slate50,
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.slate100),
                          ),
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

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تعذر فتح التطبيق الخاص بهذا الرابط.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(18),
          ),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String number) async {
    final clean = number.replaceAll(RegExp(r'[+\s\-]'), '');
    final appUri = Uri.parse('whatsapp://send?phone=$clean');
    final webUri = Uri.parse('https://wa.me/$clean');
    
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تعذر فتح تطبيق واتساب. يرجى التأكد من تثبيته.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(18),
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تعذر فتح تطبيق البريد الإلكتروني.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(18),
          ),
        );
      }
    }
  }

  Future<void> _copyText(BuildContext context, String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Text('تم نسخ $label بنجاح'),
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
}

class WhatsAppIcon extends StatelessWidget {
  final double size;
  const WhatsAppIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WhatsAppPainter(),
      ),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGreen = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paintGreen);

    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final bubblePath = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;
    bubblePath.addOval(Rect.fromCircle(center: center, radius: radius));

    final tailRoot1 = Offset(
      center.dx + radius * -0.5,
      center.dy + radius * 0.866,
    );
    final tailRoot2 = Offset(
      center.dx + radius * -0.866,
      center.dy + radius * 0.5,
    );
    final tailTip = Offset(
      center.dx - radius * 1.1,
      center.dy + radius * 1.1,
    );

    final tailPath = Path()
      ..moveTo(tailRoot1.dx, tailRoot1.dy)
      ..lineTo(tailTip.dx, tailTip.dy)
      ..lineTo(tailRoot2.dx, tailRoot2.dy)
      ..close();

    canvas.drawPath(bubblePath, paintWhite);
    canvas.drawPath(tailPath, paintWhite);

    const iconData = Icons.call;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size.width * 0.42,
        fontFamily: iconData.fontFamily,
        color: const Color(0xFF25D366),
      ),
    );
    textPainter.layout();
    
    final textOffset = Offset(
      (size.width - textPainter.width) / 2 - (size.width * 0.02),
      (size.height - textPainter.height) / 2 - (size.width * 0.02),
    );
    
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.15);
    canvas.translate(-size.width / 2, -size.height / 2);
    textPainter.paint(canvas, textOffset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GmailIcon extends StatelessWidget {
  final double size;
  const GmailIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GmailPainter(),
      ),
    );
  }
}

class _GmailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const red = Color(0xFFEA4335);

    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.25, w * 0.8, h * 0.5),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(rect, paintWhite);

    final paintRed = Paint()
      ..color = red
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(w * 0.12, h * 0.7)
      ..lineTo(w * 0.12, h * 0.28)
      ..lineTo(w * 0.5, h * 0.52)
      ..lineTo(w * 0.88, h * 0.28)
      ..lineTo(w * 0.88, h * 0.7);

    canvas.drawPath(path, paintRed);
    
    final paintShade = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;
    
    final foldTriangle = Path()
      ..moveTo(w * 0.15, h * 0.3)
      ..lineTo(w * 0.5, h * 0.52)
      ..lineTo(w * 0.85, h * 0.3)
      ..close();
    
    canvas.drawPath(foldTriangle, paintShade);

    final topFold = Path()
      ..moveTo(w * 0.12, h * 0.28)
      ..lineTo(w * 0.5, h * 0.52)
      ..lineTo(w * 0.88, h * 0.28);
      
    canvas.drawPath(topFold, paintRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
