import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AuthStatusMessage extends StatelessWidget {
  const AuthStatusMessage.error(this.message, {super.key})
    : color = AppColors.danger,
      icon = Icons.error_outline_rounded;

  const AuthStatusMessage.success(this.message, {super.key})
    : color = AppColors.success,
      icon = Icons.check_circle_outline_rounded;

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
