part of 'student_content_screens.dart';

class StudentQrScanScreen extends ConsumerStatefulWidget {
  const StudentQrScanScreen({super.key});

  static const route = '/student/qr-scan';

  @override
  ConsumerState<StudentQrScanScreen> createState() => _StudentQrScanScreenState();
}

class _StudentQrScanScreenState extends ConsumerState<StudentQrScanScreen> with SingleTickerProviderStateMixin {
  late final MobileScannerController _scanner;
  late final AnimationController _laserController;
  bool _processing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanner.dispose();
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StudentShell(
      currentIndex: 20,
      title: 'مسح QR الحضور',
      child: Stack(
        children: [
          // Background Scanner
          Positioned.fill(
            child: MobileScanner(
              controller: _scanner,
              onDetect: (capture) {
                if (_processing) return;
                final code = capture.barcodes
                    .map((item) => item.rawValue ?? '')
                    .firstWhere((value) => value.isNotEmpty, orElse: () => '');
                if (code.isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  _submit(code);
                }
              },
            ),
          ),

          // Custom Overlay
          const Positioned.fill(child: _ScannerOverlay()),

          // Animated Frame & Laser
          Positioned.fill(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Stack(
                  children: [
                    const _FrameCorners(),
                    _LaserLine(animation: _laserController),
                  ],
                ),
              ),
            ),
          ),

          // Top Controls (Flashlight)
          Positioned(
            top: 20,
            right: 20,
            child: _CircleActionButton(
              icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              onTap: () {
                _scanner.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              },
              color: _isTorchOn ? AppColors.gold : Colors.white,
            ),
          ),

          // Bottom Instructions
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: _InstructionCard(),
          ),

          // Processing Overlay
          if (_processing)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        const SizedBox(height: 20),
                        const Text(
                          'جاري تسجيل الحضور...',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submit(String rawToken) async {
    final token = rawToken.trim();
    if (token.isEmpty || token.length < 20) return;
    setState(() => _processing = true);
    try {
      final message = await ref.read(studentContentRepositoryProvider).scanQrAttendance(token);
      if (!mounted) return;
      await _scanner.stop();
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تسجيل الحضور',
        message: message,
        icon: Icons.verified_rounded,
        color: AppColors.success,
      );
      if (mounted) context.go(StudentDashboardScreen.route);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();
  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.srcOut),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrameCorners extends StatelessWidget {
  const _FrameCorners();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(),
      size: Size.infinite,
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerSize = 40.0;
    final path = Path();

    // Top Left
    path.moveTo(0, cornerSize);
    path.lineTo(0, 0);
    path.lineTo(cornerSize, 0);

    // Top Right
    path.moveTo(size.width - cornerSize, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerSize);

    // Bottom Right
    path.moveTo(size.width, size.height - cornerSize);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - cornerSize, size.height);

    // Bottom Left
    path.moveTo(cornerSize, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - cornerSize);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LaserLine extends StatelessWidget {
  const _LaserLine({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Positioned(
          top: animation.value * 260,
          left: 10,
          right: 10,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0),
                  AppColors.gold,
                  AppColors.gold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.icon, required this.onTap, required this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'ضع الكود داخل المربع للمسح التلقائي',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
