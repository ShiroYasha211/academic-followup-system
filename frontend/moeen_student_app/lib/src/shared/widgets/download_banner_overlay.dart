import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/downloads/download_service.dart';
import '../../core/theme/app_colors.dart';

/// A global overlay that listens to [DownloadService.events] and displays
/// an animated in-app banner when the user has the app open.
class DownloadBannerOverlay extends StatefulWidget {
  const DownloadBannerOverlay({super.key, required this.child});
  final Widget child;

  @override
  State<DownloadBannerOverlay> createState() => _DownloadBannerOverlayState();
}

class _DownloadBannerOverlayState extends State<DownloadBannerOverlay>
    with TickerProviderStateMixin {
  StreamSubscription<DownloadEvent>? _sub;

  // Active banners stack
  final List<_BannerEntry> _banners = [];

  @override
  void initState() {
    super.initState();
    _sub = DownloadService.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(DownloadEvent event) {
    if (!mounted) return;
    // Only show "started" and "completed/failed" banners
    if (event.type == DownloadEventType.progress) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final entry = _BannerEntry(event: event, controller: controller);

    setState(() => _banners.add(entry));
    controller.forward();

    // Auto-dismiss after a delay
    final delay = event.type == DownloadEventType.started
        ? const Duration(seconds: 4)
        : const Duration(seconds: 5);

    Future.delayed(delay, () {
      if (!mounted) return;
      controller.reverse().then((_) {
        if (!mounted) return;
        setState(() => _banners.remove(entry));
        controller.dispose();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Banner overlay
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 16,
          right: 16,
          child: Column(
            children: _banners
                .map((entry) => _AnimatedBannerTile(entry: entry))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _BannerEntry {
  _BannerEntry({required this.event, required this.controller});
  final DownloadEvent event;
  final AnimationController controller;
}

class _AnimatedBannerTile extends StatelessWidget {
  const _AnimatedBannerTile({required this.entry});
  final _BannerEntry entry;

  @override
  Widget build(BuildContext context) {
    final event = entry.event;

    final (icon, label, color) = switch (event.type) {
      DownloadEventType.started => (
        Icons.cloud_download_rounded,
        'جاري تحضير التحميل',
        AppColors.royalBlue,
      ),
      DownloadEventType.completed => (
        Icons.check_circle_rounded,
        'تم التحميل بنجاح',
        AppColors.success,
      ),
      DownloadEventType.failed => (
        Icons.error_rounded,
        'حدث خطأ في التحميل',
        AppColors.danger,
      ),
      _ => (Icons.info_rounded, '', AppColors.slate600),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: entry.controller,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: entry.controller,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInQuart,
        );
        return FadeTransition(
          opacity: t,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1.2),
              end: Offset.zero,
            ).animate(t),
            child: child,
          ),
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Status Color Accent
                      Container(
                        width: 6,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Icon Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: event.type == DownloadEventType.started
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              )
                            : Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: AppColors.midnight,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
