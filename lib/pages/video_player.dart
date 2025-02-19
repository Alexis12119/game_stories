import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerComponent extends StatefulWidget {
  final String video;

  const VideoPlayerComponent({
    super.key,
    required this.video,
  });

  @override
  State<VideoPlayerComponent> createState() => _VideoPlayerComponentState();
}

class _VideoPlayerComponentState extends State<VideoPlayerComponent> {
  late VideoPlayerController _controller;
  bool _showButtons = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      widget.video,
    );
    _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
    });

    _controller.addListener(() {
      // Check if video has finished (allow a small buffer of 1 second)
      if (_controller.value.position >= _controller.value.duration - const Duration(seconds: 1)) {
        Get.back(); // Go back once the video ends
      }
    });

    _startHideTimer(); // Start the hide timer
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Function to hide the buttons after a timeout
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showButtons = false;
      });
    });
  }

  // Function to handle screen tap to show the buttons
  void _onScreenTapped() {
    setState(() {
      _showButtons = true;
    });
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScreenTapped,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video Player
            Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(),
            ),
            // Play/Pause and Seek buttons
            if (_showButtons)
              Positioned(
                bottom: 80.0,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rewind button (seek back 10 seconds)
                    FloatingActionButton(
                      onPressed: () {
                        _controller.seekTo(_controller.value.position - const Duration(seconds: 10));
                        _startHideTimer();
                      },
                      child: const Icon(Icons.replay_10),
                    ),
                    const SizedBox(width: 16),
                    // Play/Pause button
                    FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                        _startHideTimer();
                      },
                      child: Icon(
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Fast-forward button (seek forward 10 seconds)
                    FloatingActionButton(
                      onPressed: () {
                        _controller.seekTo(_controller.value.position + const Duration(seconds: 10));
                        _startHideTimer();
                      },
                      child: const Icon(Icons.forward_10),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
