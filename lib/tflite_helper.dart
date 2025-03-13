import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'detection_result.dart';

class TFLiteHelper extends GetxController {
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  Timer? frameDebounceTimer;
  Interpreter? interpreter;

  // Observables for state management
  final RxList<DetectionResult> detections = <DetectionResult>[].obs;
  var isCameraInitialized = false.obs;
  var isInterpreterBusy = false.obs;

  // Model Input/Output Shape
  static const int inputSize = 480;
  static const int numClasses = 2; // Update based on your model
  static const int outputSize = 4725; // Update based on your model

  @override
  void onInit() {
    super.onInit();
    initializeInterpreter().then((_) {
      initCamera();
    }).catchError((error) {
      print('Initialization error: $error');
    });
  }

  Future<void> initializeInterpreter() async {
    try {
      interpreter = await Interpreter.fromAsset(
        'assets/model/best_float32.tflite',
        options: InterpreterOptions()..threads = 4, // Optimize for performance
      );
      print('Interpreter initialized successfully.');
    } catch (e) {
      print('Failed to initialize the interpreter: $e');
    }
  }

  Future<void> initCamera() async {
    if (interpreter == null) {
      print('Waiting for interpreter to initialize');
      return;
    }

    // Request camera permission
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      // Get the front camera or fallback to the first one
      final CameraDescription? frontCamera = cameras?.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras!.first,
      );

      if (frontCamera == null) {
        print('No front camera found.');
        return;
      }

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.yuv420,
        enableAudio: false,
      );

      try {
        await cameraController!.initialize();
        cameraController!.startImageStream((image) {
          // Directly process each frame without using a timer
          if (!isInterpreterBusy.value) {
            objectDetector(image);
          }
        });

        isCameraInitialized.value = true; // Trigger reactive updates
      } catch (e) {
        print('Failed to initialize camera: $e');
      }
    } else {
      print("Camera permission denied.");
    }
  }

  void processResults(List<Map<String, dynamic>> results) {
    detections.clear(); // Clear previous detections
    if (results.isEmpty) {
      print('No detections found.');
    } else {
      for (var result in results) {
        detections.add(
          DetectionResult(
            label: result['class'],
            confidence: result['confidence'],
            x: result['box']['x'],
            y: result['box']['y'],
            width: result['box']['width'],
            height: result['box']['height'],
          ),
        );
      }
    }
  }

  Future<void> objectDetector(CameraImage image) async {
    if (interpreter == null) {
      print('Interpreter not initialized yet!');
      return;
    }

    if (isInterpreterBusy.value) {
      print('Interpreter is busy, skipping detection.');
      return;
    }

    isInterpreterBusy.value = true; // Set busy state

    try {
      final Uint8List input = preprocessImage(image);

      // Prepare output buffer: [1, 11, 8400]
      final List<List<List<double>>> output = List.generate(
        1,
            (_) => List.generate(6, (_) => List.filled(outputSize, 0.0)),
      );

      interpreter!.run(input, output);

      print('Raw Output: ${output[0][0].take(10)}'); // Debug raw output

      final List<Map<String, dynamic>> results = decodeOutput(output, 0.1); // Adjust confidence threshold
      processResults(results);
    } catch (e, stacktrace) {
      print("Error during object detection: $e");
      print("Stacktrace: $stacktrace");
    } finally {
      isInterpreterBusy.value = false; // Reset busy state
    }
  }

  // Decode model output
  List<Map<String, dynamic>> decodeOutput(
      List<List<List<double>>> output, double threshold) {
    final List<Map<String, dynamic>> detections = [];
    final List<List<double>> results = output[0]; // Access the first batch

    for (int i = 0; i < outputSize; i++) {
      final double xCenter = results[0][i];
      final double yCenter = results[1][i];
      final double width = results[2][i];
      final double height = results[3][i];
      final double confidence = results[4][i];
      final List<double> classProbs = results[5]; // Adjusted for 6 dimensions
      final int classIndex = classProbs.indexOf(classProbs.reduce((a, b) => a > b ? a : b));


      if (confidence > threshold && classIndex < classLabels.length) {
        detections.add({
          'class': classLabels[classIndex],
          'confidence': confidence,
          'box': {
            'x': xCenter - (width / 2),
            'y': yCenter - (height / 2),
            'width': width,
            'height': height,
          },
        });
      }
    }

    return detections;
  }

  Uint8List preprocessImage(CameraImage image) {
    final List<int> rgbImage = convertYUV420ToRGB(image);
    final Uint8List resizedImage =
    resizeImage(rgbImage, image.width, image.height, inputSize, inputSize);

    final Float32List floatBuffer = Float32List(inputSize * inputSize * 3);
    for (int i = 0; i < resizedImage.length; i++) {
      floatBuffer[i] = resizedImage[i] / 255.0; // Normalize
    }

    return floatBuffer.buffer.asUint8List();
  }

  List<int> convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    final List<int> rgbBuffer = List<int>.filled(width * height * 3, 0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yValue = image.planes[0].bytes[y * width + x];

        final int uvOffset = (y >> 1) * uvRowStride + (x >> 1) * uvPixelStride;
        final int uValue = image.planes[1].bytes[uvOffset];
        final int vValue = image.planes[2].bytes[uvOffset];

        final int r =
        (yValue + 1.370705 * (vValue - 128)).clamp(0, 255).toInt();
        final int g =
        (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        final int b =
        (yValue + 1.732446 * (uValue - 128)).clamp(0, 255).toInt();

        final int pixelIndex = (y * width + x) * 3;
        rgbBuffer[pixelIndex] = r;
        rgbBuffer[pixelIndex + 1] = g;
        rgbBuffer[pixelIndex + 2] = b;
      }
    }
    return rgbBuffer;
  }

  Uint8List resizeImage(List<int> image, int originalWidth, int originalHeight,
      int targetWidth, int targetHeight) {
    final Uint8List resizedImage = Uint8List(targetWidth * targetHeight * 3);

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final int srcX = (x * originalWidth / targetWidth).floor();
        final int srcY = (y * originalHeight / targetHeight).floor();

        final int srcIndex = (srcY * originalWidth + srcX) * 3;
        final int destIndex = (y * targetWidth + x) * 3;

        resizedImage[destIndex] = image[srcIndex];
        resizedImage[destIndex + 1] = image[srcIndex + 1];
        resizedImage[destIndex + 2] = image[srcIndex + 2];
      }
    }
    return resizedImage;
  }

  final List<String> classLabels = ['awake', 'drowsy'];

  @override
  void dispose() {
    frameDebounceTimer?.cancel();
    cameraController?.dispose();
    interpreter?.close();
    super.dispose();
  }
}
