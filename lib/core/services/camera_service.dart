import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();

  Future<void> initialize(CameraDescription camera) async {
    _controller = CameraController(camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller!.initialize();
    await _initializeControllerFuture;
  }

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<String?> takePictureBase64() async {
    if (!isInitialized) return null;

    try {
      final XFile image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("Error taking picture: $e");
      return null;
    }
  }

  void dispose() {
    _controller?.dispose();
  }

  CameraController? get controller => _controller;
  Future<void>? get initializeControllerFuture => _initializeControllerFuture;
}
