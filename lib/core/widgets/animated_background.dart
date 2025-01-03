import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
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
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
