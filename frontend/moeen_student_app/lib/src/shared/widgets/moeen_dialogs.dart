import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

Future<bool> showMoeenConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
  IconData icon = Icons.help_outline_rounded,
  Color color = AppColors.royalBlue,
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => MoeenDialog(
      title: title,
      message: message,
      icon: icon,
      color: danger ? AppColors.danger : color,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: danger ? AppColors.danger : color,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

Future<void> showMoeenInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonLabel = 'موافق',
  IconData icon = Icons.check_circle_rounded,
  Color color = AppColors.success,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => MoeenDialog(
      title: title,
      message: message,
      icon: icon,
      color: color,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: color),
          child: Text(buttonLabel),
        ),
      ],
    ),
  );
}

Future<T?> showMoeenBottomSheet<T>({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Color color,
  required Widget child,
  bool fullScreen = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * (fullScreen ? 0.96 : 0.88),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Premium Drag Handle
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: color,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              'يرجى إكمال البيانات أدناه',
                              style: TextStyle(
                                color: AppColors.slate400,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Integrated Close Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 20, color: AppColors.slate600),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class MoeenDialog extends StatelessWidget {
  const MoeenDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.actions,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, AppColors.cream],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
class MoeenDialogs {
  static void showLoading(BuildContext context, {String message = 'يرجى الانتظار...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.royalBlue),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, {required String message, String title = 'تم بنجاح'}) {
    showMoeenInfoDialog(context: context, title: title, message: message, icon: Icons.check_circle_rounded, color: AppColors.success);
  }

  static void showError(BuildContext context, {required String message, String title = 'خطأ'}) {
    showMoeenInfoDialog(context: context, title: title, message: message, icon: Icons.error_outline_rounded, color: AppColors.danger);
  }

  static void showImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black.withValues(alpha: 0.85)),
              ),
            ),
          ),
          Center(
            child: InteractiveViewer(
              maxScale: 5.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 64),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: Material(
              color: Colors.black26,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
