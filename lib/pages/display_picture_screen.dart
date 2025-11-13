import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final String label;

  const DisplayPictureScreen({super.key, required this.imagePath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      //body: Image.file(File(imagePath)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The captured image
          Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 5),

          // The caption/label below the image
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
