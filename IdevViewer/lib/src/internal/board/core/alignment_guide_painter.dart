import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/board/core/alignment_guide.dart';

/// 정렬 가이드라인을 그리는 CustomPainter
class AlignmentGuidePainter extends CustomPainter {
  final AlignmentGuide guide;
  final Color color;
  final double strokeWidth;

  const AlignmentGuidePainter({
    required this.guide,
    this.color = Colors.blue,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    switch (guide.type) {
      case AlignmentType.verticalCenter:
        canvas.drawLine(
          Offset(guide.position, 0),
          Offset(guide.position, size.height),
          paint,
        );
        break;
      case AlignmentType.horizontalCenter:
        canvas.drawLine(
          Offset(0, guide.position),
          Offset(size.width, guide.position),
          paint,
        );
        break;
      case AlignmentType.leftEdge:
      case AlignmentType.rightEdge:
        canvas.drawLine(
          Offset(guide.position, 0),
          Offset(guide.position, size.height),
          paint,
        );
        break;
      case AlignmentType.topEdge:
      case AlignmentType.bottomEdge:
        canvas.drawLine(
          Offset(0, guide.position),
          Offset(size.width, guide.position),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is AlignmentGuidePainter) {
      return oldDelegate.guide != guide ||
          oldDelegate.color != color ||
          oldDelegate.strokeWidth != strokeWidth;
    }
    return true;
  }
}
