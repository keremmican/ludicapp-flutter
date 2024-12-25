import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  final List<String> _images = [
    'lib/assets/images/background1.jpg',
    'lib/assets/images/background2.jpg',
    'lib/assets/images/background3.jpg',
  ];

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startSlidingTimer();
  }

  void _startSlidingTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _images.length;
        });
        _startSlidingTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background images with fade transition
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Image.asset(
            _images[_currentImageIndex],
            key: ValueKey<String>(_images[_currentImageIndex]),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Top gradient overlay for logo area (darker and extends further down)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withOpacity(0.8), // Darker at the top
                  Colors.black.withOpacity(0.6), // Extend darkness downward
                  Colors.transparent,
                ],
                stops: [0.0, 0.5, 1.0], // Adjust gradient spread
              ),
            ),
          ),
        ),

        // Bottom gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(1), // Fully black
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
