// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:get/get.dart';

class AugmentedReality extends StatefulWidget {
  final String model;
  final String modelName;
  final String modelDescription;

  const AugmentedReality({
    super.key,
    required this.model,
    required this.modelName,
    required this.modelDescription,
  });

  @override
  AugmentedRealityState createState() => AugmentedRealityState();
}

class AugmentedRealityState extends State<AugmentedReality> {
  bool _showInfo = true; // Visibility state for model name & description

  @override
  void initState() {
    super.initState();

    // Set a timer to hide model info after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showInfo = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 3D Model Viewer
          ModelViewer(
            src: widget.model,
            ar: true,
            autoRotate: true,
            disableZoom: true,
          ),

          // Back Button
          Positioned(
            top: 20.0,
            left: 10.0,
            child: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
              ),
            ),
          ),

          // Model Name & Description (Hides after 10 seconds)
          if (_showInfo)
            Positioned(
              bottom: 20.0,
              left: 20.0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                width: MediaQuery.of(context).size.width * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.modelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.modelDescription,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
