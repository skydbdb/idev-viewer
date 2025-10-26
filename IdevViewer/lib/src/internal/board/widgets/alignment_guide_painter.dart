import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/board/core/alignment_guide.dart';

class AlignmentGuidePainter extends CustomPainter {
  final AlignmentGuide guide;
  final Color color;
  final double strokeWidth;
  const AlignmentGuidePainter(
      {required this.guide, this.color = Colors.blue, this.strokeWidth = 2.0});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    switch (guide.type) {
      case AlignmentType.verticalCenter:
      case AlignmentType.leftEdge:
      case AlignmentType.rightEdge:
        canvas.drawLine(Offset(guide.position, 0),
            Offset(guide.position, size.height), paint);
        break;
      case AlignmentType.horizontalCenter:
      case AlignmentType.topEdge:
      case AlignmentType.bottomEdge:
        canvas.drawLine(Offset(0, guide.position),
            Offset(size.width, guide.position), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
