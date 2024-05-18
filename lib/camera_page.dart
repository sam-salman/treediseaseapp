import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io'; // For handling files

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _handleCameraPermission();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras[0], ResolutionPreset.max);
      _initializeControllerFuture = _cameraController.initialize();
      setState(() {});
    } else {
      // Handle the case where no cameras are found
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Cameras Found'),
          content: const Text('No cameras are available on this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleCameraPermission() async {
    if (await Permission.camera.request().isGranted) {
      await _initializeCamera();
    } else {
      // Handle the case where the user denies the camera permission
      // For example, show a dialog or a message.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Camera Permission'),
          content: const Text('Camera permission is required to take pictures.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      // Ensure the camera is initialized
      await _initializeControllerFuture;

      // Attempt to take a picture and get the file where it was saved
      final XFile image = await _cameraController.takePicture();

      // If the picture was taken, display it on a new screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_cameraController),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _takePicture,
                      child: const Icon(Icons.camera),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display Picture')),
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}
