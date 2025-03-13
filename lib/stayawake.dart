import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'tflite_helper.dart';
import 'detection_overlay.dart';

class StayAwake extends StatelessWidget {
  final TFLiteHelper _tfliteHelper = Get.put(TFLiteHelper());

  StayAwake({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Drowsiness Detection'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera Preview with Mirroring
          Obx(() {
            if (_tfliteHelper.isCameraInitialized.value) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(-1.0, 1.0), // Flip horizontally
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: CameraPreview(_tfliteHelper.cameraController!),
                ),
              );
            } else if (_tfliteHelper.cameraController == null) {
              return const Center(child: Text('Failed to initialize the camera.'));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),

          // Detection Overlay
          Obx(() {
            if (_tfliteHelper.detections.isNotEmpty) {
              return DetectionOverlay(detections: _tfliteHelper.detections);
            } else {
              return Container(); // No detections
            }
          }),

          // Processing Overlay
          Obx(() {
            if (_tfliteHelper.isInterpreterBusy.value) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Text(
                    'Processing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            } else {
              return Container();
            }
          }),
        ],
      ),
    );
  }
}
