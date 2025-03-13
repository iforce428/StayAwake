import 'package:flutter/material.dart';
import '../detection_result.dart';

class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;

  DetectionPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      backgroundColor: Colors.black,
    );

    for (var detection in detections) {
      // Scale bounding box coordinates to fit the canvas size
      final double left = detection.x * size.width;
      final double top = detection.y * size.height;
      final double right = (detection.x + detection.width) * size.width;
      final double bottom = (detection.y + detection.height) * size.height;

      final rect = Rect.fromLTRB(left, top, right, bottom);

      canvas.drawRect(rect, paint);

      // Draw the label
      final label = "${detection.label} ${(detection.confidence * 100).toStringAsFixed(1)}%";
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(left, top - 20));
    }
    print('Canvas size: ${size.width} x ${size.height}');

  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

