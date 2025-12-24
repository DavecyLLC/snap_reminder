import 'dart:io';
import 'package:flutter/material.dart';

class PhotoViewerScreen extends StatelessWidget {
  final File imageFile;
  const PhotoViewerScreen({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Photo'),
      ),
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 400) Navigator.pop(context);
          },
          child: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 6.0,
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Image not found', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
