import 'package:flutter/material.dart';
import 'detection_result.dart';

class DetectionOverlay extends StatelessWidget {
  final List<DetectionResult> detections;

  const DetectionOverlay({Key? key, required this.detections}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: detections.map((detection) {
        return Positioned(
          left: detection.x * MediaQuery.of(context).size.width,
          top: detection.y * MediaQuery.of(context).size.height,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detection.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Confidence: ${(detection.confidence * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
