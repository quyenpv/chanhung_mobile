import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Helper mở camera trước, phát hiện khuôn mặt bằng ML Kit,
/// xác minh lại trên ảnh chụp rồi trả về base64.
class FaceCameraHelper {
  static Future<String?> captureVerifiedSelfie(BuildContext context) async {
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (error, stack) {
      debugPrintStack(
        label: 'Unable to enumerate cameras: $error',
        stackTrace: stack,
      );
      return null;
    }
    if (!context.mounted) return null;
    if (cameras.isEmpty) {
      return null;
    }

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
  bool _isCapturing = false;
  String _statusText = 'Hãy nhìn thẳng vào camera...';
  bool _faceDetected = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
      await _controller.startImageStream(_detectFaces);
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Không mở được camera. Vui lòng thử lại.';
        });
      }
    }
  }

  InputImageRotation _rotationFromCamera() {
    final sensorOrientation = widget.camera.sensorOrientation;
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _detectFaces(CameraImage image) async {
    if (_isProcessing || _isCapturing) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted || _isCapturing) return;

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
            _statusText = 'Đã thấy khuôn mặt ✓ Nhấn chụp để so khớp hồ sơ';
          });
      }
    } catch (_) {
      // Bỏ qua lỗi stream — vẫn cho chụp và xác minh trên file
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    try {
      final format = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      Uint8List bytes;
      if (Platform.isAndroid) {
        // NV21: thường chỉ cần plane[0] khi imageFormatGroup = nv21
        if (image.planes.length == 1) {
          bytes = image.planes.first.bytes;
        } else {
          final WriteBuffer allBytes = WriteBuffer();
          for (final plane in image.planes) {
            allBytes.putUint8List(plane.bytes);
          }
          bytes = allBytes.done().buffer.asUint8List();
        }
      } else {
        bytes = image.planes.first.bytes;
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _rotationFromCamera(),
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _verifyFaceOnFile(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final faces = await _faceDetector.processImage(inputImage);
    return faces.length == 1;
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || !_isInitialized) return;

      setState(() {
        _isCapturing = true;
        _statusText = 'Đang kiểm tra khuôn mặt trên ảnh...';
      });

    try {
      if (_controller.value.isStreamingImages) {
        await _controller.stopImageStream();
      }

      final XFile file = await _controller.takePicture();
      final ok = await _verifyFaceOnFile(file.path);

      if (!ok) {
        if (mounted) {
          setState(() {
            _faceDetected = false;
            _statusText =
                'Không xác minh được khuôn mặt. Hãy nhìn thẳng và chụp lại.';
            _isCapturing = false;
          });
        }
        try {
          await _controller.startImageStream(_detectFaces);
        } catch (_) {}
        return;
      }

      final bytes = await File(file.path).readAsBytes();
      final base64Str = base64Encode(bytes);
      widget.onCapture(base64Str);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Lỗi chụp ảnh. Vui lòng thử lại.';
          _isCapturing = false;
        });
      }
      try {
        if (_isInitialized && !_controller.value.isStreamingImages) {
          await _controller.startImageStream(_detectFaces);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    try {
      if (_controller.value.isInitialized) {
        _controller.dispose();
      }
    } catch (_) {}
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
        title: const Text('Xác thực khuôn mặt',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: _isInitialized
          ? Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CameraPreview(_controller),
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
                      if (_isCapturing)
                        Container(
                          color: Colors.black45,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
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
                      // Cho phép chụp khi đã phát hiện mặt HOẶC khi stream lỗi
                      // (xác minh thật sự nằm ở ảnh chụp)
                      GestureDetector(
                        onTap: _isCapturing
                            ? null
                            : (_faceDetected ? _capturePhoto : null),
                        onLongPress: _isCapturing ? null : _capturePhoto,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _faceDetected
                                ? Colors.greenAccent
                                : Colors.white24,
                            border:
                                Border.all(color: Colors.white54, width: 3),
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
                        'Sau khi chụp, hệ thống so khớp với ảnh đại diện trên ERP',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 12),
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
