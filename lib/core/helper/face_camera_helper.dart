import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';

/// Helper để mở camera trước, phát hiện khuôn mặt bằng ML Kit,
/// và trả về ảnh selfie dưới dạng base64
class FaceCameraHelper {
  static Future<String?> captureVerifiedSelfie(BuildContext context) async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    String? resultBase64;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FaceCameraScreen(
          camera: frontCamera,
          onCapture: (String base64) {
            resultBase64 = base64;
          },
        ),
      ),
    );

    return resultBase64;
  }
}

class _FaceCameraScreen extends StatefulWidget {
  const _FaceCameraScreen({required this.camera, required this.onCapture});
  final CameraDescription camera;
  final void Function(String base64) onCapture;

  @override
  State<_FaceCameraScreen> createState() => _FaceCameraScreenState();
}

class _FaceCameraScreenState extends State<_FaceCameraScreen> {
  late CameraController _controller;
  late FaceDetector _faceDetector;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusText = 'Hãy nhìn thẳng vào camera...';
  bool _faceDetected = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        minFaceSize: 0.3,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
      _controller.startImageStream(_detectFaces);
    }
  }

  Future<void> _detectFaces(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Merge all planes into one byte array
      int totalBytes = 0;
      for (final plane in image.planes) {
        totalBytes += plane.bytes.length;
      }
      final mergedBytes = Uint8List(totalBytes);
      int offset = 0;
      for (final plane in image.planes) {
        mergedBytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
        offset += plane.bytes.length;
      }

      final inputImage = InputImage.fromBytes(
        bytes: mergedBytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      if (mounted) {
        if (faces.isEmpty) {
          setState(() {
            _faceDetected = false;
            _statusText = 'Không phát hiện khuôn mặt...';
          });
        } else if (faces.length > 1) {
          setState(() {
            _faceDetected = false;
            _statusText = 'Chỉ được có 1 khuôn mặt trong khung!';
          });
        } else {
          setState(() {
            _faceDetected = true;
            _statusText = 'Đã phát hiện khuôn mặt ✓ Nhấn chụp';
          });
        }
      }
    } catch (_) {
      // ignore stream errors
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _capturePhoto() async {
    if (!_faceDetected) return;
    await _controller.stopImageStream();
    final XFile file = await _controller.takePicture();
    final bytes = await File(file.path).readAsBytes();
    final base64Str = base64Encode(bytes);
    widget.onCapture(base64Str);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Xác minh khuôn mặt',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: _isInitialized
          ? Column(
              children: [
                // Camera Preview
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CameraPreview(_controller),

                      // Face guide overlay
                      Container(
                        width: 240,
                        height: 290,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _faceDetected
                                ? Colors.greenAccent
                                : Colors.white54,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(130),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status & Capture button
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      // Status text
                      Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _faceDetected
                              ? Colors.greenAccent
                              : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Capture button
                      GestureDetector(
                        onTap: _faceDetected ? _capturePhoto : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _faceDetected
                                ? Colors.greenAccent
                                : Colors.white24,
                            border: Border.all(
                                color: Colors.white54, width: 3),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: _faceDetected
                                ? Colors.black
                                : Colors.white38,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hãy đặt khuôn mặt vào vòng tròn hướng dẫn',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
