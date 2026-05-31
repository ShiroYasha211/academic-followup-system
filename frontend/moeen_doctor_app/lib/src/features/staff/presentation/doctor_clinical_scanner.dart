part of 'staff_screens.dart';

class _StudentLogInfoCard extends StatelessWidget {
  const _StudentLogInfoCard({required this.log});

  final _Json log;

  @override
  Widget build(BuildContext context) {
    final student = _docMap(log['student']);
    final studentName = _docText(student['name'], _docText(log['student_name'], 'طالب'));
    final studentNumber = _docText(student['student_number'], _docText(log['student_number'], '-'));
    final center = _docText(log['training_center'], _docText(_docMap(log['training_center'])['name'], '-'));
    final dept = _docText(log['department'], _docText(_docMap(log['department'])['name'], '-'));
    final logDate = _docDate(log['log_date']);
    final initial = studentName.isNotEmpty ? studentName.substring(0, 1) : 'ط';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.04),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.royalBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_rounded,
                          color: AppColors.slate400,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'رقم القيد: $studentNumber',
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.slate100),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مركز التدريب',
                      style: TextStyle(
                        color: AppColors.slate400,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'القسم الطبي',
                      style: TextStyle(
                        color: AppColors.slate400,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dept,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التاريخ',
                      style: TextStyle(
                        color: AppColors.slate400,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      logDate,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogActivityGroupCard extends StatelessWidget {
  const _LogActivityGroupCard({
    required this.group,
    required this.status,
    required this.onStatusChanged,
  });

  final _Json group;
  final String status;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final key = _docText(group['key']);
    final label = _docText(group['label'], key);
    final items = _docList(group['items']);

    Color groupBorderColor;
    Color groupBgColor;
    if (status == 'approved') {
      groupBorderColor = AppColors.success.withValues(alpha: 0.4);
      groupBgColor = AppColors.success.withValues(alpha: 0.02);
    } else if (status == 'rejected') {
      groupBorderColor = AppColors.danger.withValues(alpha: 0.4);
      groupBgColor = AppColors.danger.withValues(alpha: 0.02);
    } else {
      groupBorderColor = AppColors.slate200;
      groupBgColor = AppColors.slate50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: groupBgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: groupBorderColor, width: status != 'pending' ? 1.6 : 1),
        boxShadow: [
          if (status != 'pending')
            BoxShadow(
              color: (status == 'approved' ? AppColors.success : AppColors.danger).withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.slate200.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length} بنود',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: AppColors.slate200),
          ...items.map((item) {
            final itemMap = _docMap(item);
            final itemStatus = _docText(itemMap['review_status']);
            final isItemApproved = _docBool(itemMap['is_confirmed']);

            IconData itemIcon;
            Color itemColor;
            if (itemStatus == 'rejected') {
              itemIcon = Icons.cancel_rounded;
              itemColor = AppColors.danger;
            } else if (isItemApproved || itemStatus == 'approved') {
              itemIcon = Icons.check_circle_rounded;
              itemColor = AppColors.success;
            } else {
              itemIcon = Icons.radio_button_unchecked_rounded;
              itemColor = AppColors.slate400;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(itemIcon, size: 16, color: itemColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _docText(itemMap['label'], '-'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),
          const Text(
            'قرار الدكتور لهذا الجزء:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              color: AppColors.slate500,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildDecisionSegment(
                  value: 'pending',
                  label: 'بانتظار',
                  activeColor: AppColors.slate500,
                  icon: Icons.hourglass_empty_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDecisionSegment(
                  value: 'approved',
                  label: 'اعتماد',
                  activeColor: AppColors.success,
                  icon: Icons.check_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDecisionSegment(
                  value: 'rejected',
                  label: 'رفض',
                  activeColor: AppColors.danger,
                  icon: Icons.close_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionSegment({
    required String value,
    required String label,
    required Color activeColor,
    required IconData icon,
  }) {
    final isSelected = status == value;

    return GestureDetector(
      onTap: () => onStatusChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.slate200,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeColor : AppColors.slate400,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? activeColor : AppColors.slate600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorNotesBento extends StatelessWidget {
  const _DoctorNotesBento({required this.notesController});

  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.rate_review_rounded,
                color: AppColors.royalBlue,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'ملاحظات الدكتور وتوجيهاته',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: AppColors.slate100),
          TextFormField(
            controller: notesController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'اكتب هنا أي ملاحظات أو توجيهات للطالب بخصوص السجل السريري...',
              hintStyle: TextStyle(fontSize: 12.5),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final width = size.width;
    final height = size.height;

    // Viewfinder size
    final rect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: 240,
      height: 240,
    );

    // Draw the dark background mask with a clear hole in the middle
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromLTWH(0, 0, width, height))
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24))),
      paint,
    );

    // Paint neon cyan corner brackets
    final borderPaint = Paint()
      ..color = AppColors.info
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final path = Path();
    final len = 24.0; // corner line length

    // Top-left corner
    path.moveTo(rrect.left, rrect.top + len);
    path.lineTo(rrect.left, rrect.top);
    path.lineTo(rrect.left + len, rrect.top);

    // Top-right corner
    path.moveTo(rrect.right - len, rrect.top);
    path.lineTo(rrect.right, rrect.top);
    path.lineTo(rrect.right, rrect.top + len);

    // Bottom-left corner
    path.moveTo(rrect.left, rrect.bottom - len);
    path.lineTo(rrect.left, rrect.bottom);
    path.lineTo(rrect.left + len, rrect.bottom);

    // Bottom-right corner
    path.moveTo(rrect.right - len, rrect.bottom);
    path.lineTo(rrect.right, rrect.bottom);
    path.lineTo(rrect.right, rrect.bottom - len);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerLaserLine extends StatefulWidget {
  const _ScannerLaserLine();

  @override
  State<_ScannerLaserLine> createState() => _ScannerLaserLineState();
}

class _ScannerLaserLineState extends State<_ScannerLaserLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Since height is 420, center is 210. Viewfinder center is 210.
        // Viewfinder size is 240, so top of viewfinder is 210 - 120 = 90.
        // Bottom is 210 + 120 = 330.
        final top = 90.0 + _controller.value * 236.0;
        return Positioned(
          top: top,
          left: (MediaQuery.sizeOf(context).width - 32 - 232) / 2, // 32 is padding, 232 is width
          width: 232,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withValues(alpha: 0.0),
                  AppColors.info,
                  AppColors.info.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
