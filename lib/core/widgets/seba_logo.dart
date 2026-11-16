import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Seba mark: an orange rounded square with a circle held in a cupped bowl.
class SebaLogo extends StatelessWidget {
  const SebaLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Seba logo',
      child: CustomPaint(size: Size.square(size), painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final background = Paint()..color = AppColors.brand;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.25)),
      background,
    );

    final white = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(s * 0.5, s * 0.39), s * 0.125, white);

    final bowl = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.078
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(s * 0.234, s * 0.5625)
      ..quadraticBezierTo(s * 0.5, s * 0.906, s * 0.766, s * 0.5625);
    canvas.drawPath(path, bowl);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
