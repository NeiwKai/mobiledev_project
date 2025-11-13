import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'display_picture_screen.dart';
import 'package:flutter/services.dart' show rootBundle;


class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});
  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  late Interpreter _interpreter;
  bool _isModelReady = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
    checkTFLiteAsset();
    _loadModel();
  }

  Future<void> checkTFLiteAsset() async {
    try {
      final bytes = await rootBundle.load('assets/pokemon_tcg_model.tflite');
      if (bytes.lengthInBytes == 0) {
        print('❌ The TFLite file is empty!');
      } else {
        print('✅ The TFLite file has ${bytes.lengthInBytes} bytes.');
      }
    } catch (e) {
      print('❌ Failed to load asset: $e');
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/pokemon_tcg_model.tflite');
      setState(() => _isModelReady = true);
      print('✅ TFLite model loaded');
    } catch (e) {
      print('❌ Failed to load model: $e');
    }
  }

  // Convert an image to model input tensor
  Future<List> imageToInputTensor(File file, int inputSize) async {
    final bytes = await file.readAsBytes();
    final oriImage = img.decodeImage(bytes);
    final resized = img.copyResize(oriImage!, width: inputSize, height: inputSize);

    return List.generate(1, (_) {
      return List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;
          return [r, g, b];
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!_isModelReady) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Model is still loading, please wait...')),
            );
            return;
          }

          try {
            await _initializeControllerFuture;

            final image = await _controller.takePicture();
            final input = await imageToInputTensor(File(image.path), 96);
            final output = List.generate(1, (_) => List.filled(1, 0.0));

            _interpreter.run(input, output);

            final probability = output[0][0];
            final isPositive = probability > 0.5;
            final label = isPositive ? 'Real' : 'Fake';

            if (!context.mounted) return;

            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => DisplayPictureScreen(
                  imagePath: image.path,
                  label: label,
                ),
              ),
            );
          } catch (e) {
            print('❌ Error: $e');
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

