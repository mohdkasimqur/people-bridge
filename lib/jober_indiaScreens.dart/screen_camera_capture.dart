import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ScreenCameraCapture extends StatefulWidget {
  const ScreenCameraCapture({
    super.key,
  });

  @override
  State<ScreenCameraCapture> createState() =>
      _ScreenCameraCaptureState();
}

class _ScreenCameraCaptureState
    extends State<ScreenCameraCapture> {
  CameraController? _controller;

  List<CameraDescription> _cameras = [];

  int _selectedCameraIndex = 0;

  bool _isInitializing = true;
  bool _isTakingPicture = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _isInitializing = true;
      _errorMessage = null;

      if (mounted) {
        setState(() {});
      }

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No camera found on this device.');
      }

      // Prefer the back camera initially.
      int backCameraIndex = _cameras.indexWhere(
        (camera) =>
            camera.lensDirection == CameraLensDirection.back,
      );

      if (backCameraIndex != -1) {
        _selectedCameraIndex = backCameraIndex;
      } else {
        _selectedCameraIndex = 0;
      }

      await _startCamera();

    } catch (e) {
      debugPrint('Camera initialization error: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to open camera.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _startCamera() async {
    await _controller?.dispose();

    final CameraDescription camera =
        _cameras[_selectedCameraIndex];

    final CameraController controller =
        CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    await controller.initialize();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _isInitializing = false;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  Future<void> _takePicture() async {
    final CameraController? controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final XFile image = await controller.takePicture();

      final File capturedFile = File(image.path);

      if (!mounted) return;

      // Return the captured photo to the Taxi profile page.
      Navigator.of(context).pop(capturedFile);

    } catch (e) {
      debugPrint('Take picture error: $e');

      if (!mounted) return;

      setState(() {
        _isTakingPicture = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to capture photo: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isInitializing = true;
      });

      if (_selectedCameraIndex >= _cameras.length - 1) {
        _selectedCameraIndex = 0;
      } else {
        _selectedCameraIndex++;
      }

      await _startCamera();

    } catch (e) {
      debugPrint('Switch camera error: $e');

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = 'Unable to switch camera.';
      });
    }
  }

  void _closeCamera() {
    Navigator.of(context).pop();
  }
  @override
  Widget build(BuildContext context) {
    final CameraController? controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ====================================================
            // CAMERA PREVIEW
            // ====================================================

            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _initializeCamera,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (
                _isInitializing ||
                controller == null ||
                !controller.value.isInitialized
            )
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            else
              Center(
                child: CameraPreview(controller),
              ),

            // ====================================================
            // TOP BAR
            // ====================================================

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // CLOSE
                    IconButton(
                      onPressed: _closeCamera,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const Spacer(),

                    // SWITCH CAMERA
                    if (_cameras.length > 1)
                      IconButton(
                        onPressed:
                            _isInitializing ||
                                    _isTakingPicture
                                ? null
                                : _switchCamera,
                        icon: const Icon(
                          Icons.flip_camera_ios_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ====================================================
            // BOTTOM CAMERA CONTROLS
            // ====================================================

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.only(
                  top: 20,
                  bottom: 30,
                ),
                child: Column(
                  children: [
                    // CAPTURE BUTTON
                    GestureDetector(
                      onTap: _isInitializing ||
                              _isTakingPicture ||
                              _errorMessage != null
                          ? null
                          : _takePicture,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 5,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isTakingPicture
                                  ? Colors.grey
                                  : Colors.white,
                            ),
                            child: _isTakingPicture
                                ? const Padding(
                                    padding: EdgeInsets.all(18),
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.black,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Tap to capture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}