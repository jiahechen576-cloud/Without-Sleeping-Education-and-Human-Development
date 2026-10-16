import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _snapController;
  late AnimationController _dotsController;
  late AnimationController _curtainController;

  bool _showHome = false;

  @override
  void initState() {
    super.initState();

    // Main loading animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Logo snap animation after 100%
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Three-dot animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();

    // Curtain reveal
    _curtainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _startLoading();
  }

  Future<void> _startLoading() async {
    // Stage 1
    await _progressController.forward();

    if (!mounted) return;

    // Stage 2
    await _snapController.forward();

    if (!mounted) return;

    // Small pause after snap
    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    // Stage 3
    setState(() {
      _showHome = true;
    });

    await _curtainController.forward();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, animation, _) {
          return const MainNavigation();
        },
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.95,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _snapController.dispose();
    _dotsController.dispose();
    _curtainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Home screen behind the curtain
          if (_showHome) const MainNavigation(),

          // Loading screen
          AnimatedBuilder(
            animation: Listenable.merge([
              _progressController,
              _snapController,
              _dotsController,
            ]),
            builder: (context, child) {
              final progress = _progressController.value;

              final percentage = (progress * 100).round();

              // Elastic logo scale
              double logoScale = 1.0;

              if (_snapController.value > 0) {
                final snap = Curves.elasticOut.transform(
                  _snapController.value,
                );

                logoScale = 1.0 + (0.15 * snap);

                // Initial snap down
                if (_snapController.value < 0.25) {
                  logoScale =
                      1.0 -
                      (0.1 *
                          (_snapController.value / 0.25));
                }
              }

              return IgnorePointer(
                ignoring: _showHome,
                child: Opacity(
                  opacity: _showHome
                      ? 0.0
                      : 1.0,
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          // LOGO
                          Transform.scale(
                            scale: logoScale,
                            child: _ProgressiveLogo(
                              progress: progress,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // PERCENTAGE
                          AnimatedOpacity(
                            duration: const Duration(
                              milliseconds: 120,
                            ),
                            opacity:
                                _snapController.value > 0
                                    ? 0.0
                                    : 1.0,
                            child: Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color:
                                    Color(0xFF2D5A3D),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // THREE DOTS
                          _LoadingDots(
                            controller:
                                _dotsController,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Curtain
          if (_showHome)
            AnimatedBuilder(
              animation: _curtainController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _CurtainPainter(
                    progress:
                        _curtainController.value,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────
// PROGRESSIVE LOGO
// ─────────────────────────────────────────────

class _ProgressiveLogo extends StatelessWidget {
  final double progress;

  const _ProgressiveLogo({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grey/soft logo underneath
          Opacity(
            opacity: 0.12,
            child: Image.asset(
              'assets/image/readrabbit_logo.png',
              width: 270,
              fit: BoxFit.contain,
            ),
          ),

          // Green progressive fill
          ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor:
                  progress.clamp(0.0, 1.0),
              child: Image.asset(
                'assets/image/readrabbit_logo.png',
                width: 270,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────
// THREE DOT LOADING ANIMATION
// ─────────────────────────────────────────────

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;

  const _LoadingDots({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) {
              final phase =
                  (controller.value +
                          index * 0.22) %
                      1.0;

              final opacity =
                  0.35 +
                  (0.65 *
                      math.max(
                        0,
                        math.sin(
                          phase * math.pi,
                        ),
                      ));

              return Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration:
                        const BoxDecoration(
                      color: Color(0xFF4A8060),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────
// CURTAIN TRANSITION
// ─────────────────────────────────────────────

class _CurtainPainter extends CustomPainter {
  final double progress;

  _CurtainPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final p = progress.clamp(0.0, 1.0);

    final width = size.width;
    final height = size.height;

    final centerX = width / 2;

    final leftX =
        centerX * Curves.easeOut.transform(p);

    final rightX =
        width -
        centerX *
            Curves.easeOut.transform(p);

    final path = Path();

    // Left curtain
    path.moveTo(0, 0);
    path.lineTo(leftX, 0);

    path.quadraticBezierTo(
      leftX - 30,
      height * 0.25,
      leftX,
      height * 0.5,
    );

    path.quadraticBezierTo(
      leftX + 30,
      height * 0.75,
      leftX,
      height,
    );

    path.lineTo(0, height);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white,
    );

    // Right curtain
    final rightPath = Path();

    rightPath.moveTo(rightX, 0);
    rightPath.lineTo(width, 0);
    rightPath.lineTo(width, height);
    rightPath.lineTo(rightX, height);

    rightPath.quadraticBezierTo(
      rightX - 30,
      height * 0.75,
      rightX,
      height * 0.5,
    );

    rightPath.quadraticBezierTo(
      rightX + 30,
      height * 0.25,
      rightX,
      0,
    );

    rightPath.close();

    canvas.drawPath(
      rightPath,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(
    _CurtainPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}