
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TraceScreen extends StatefulWidget {
  const TraceScreen({super.key});

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  final FlutterTts _tts = FlutterTts();
  final GlobalKey _drawingAreaKey = GlobalKey();

  final List<String> _letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
    'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  static const double _passingScore = 0.60;

  int _currentLetter = 0;

  final List<Offset?> _points = [];

  bool _letterCompleted = false;
  bool _isChecking = false;

  String get _letter => _letters[_currentLetter];

  void _startDrawing(DragStartDetails details) {
    if (_letterCompleted || _isChecking) return;

    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _continueDrawing(DragUpdateDetails details) {
    if (_letterCompleted || _isChecking) return;

    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _endDrawing(DragEndDetails details) {
    if (_letterCompleted || _isChecking) return;

    setState(() {
      _points.add(null);
    });
  }

  double _distanceToSegment(
    Offset point,
    Offset start,
    Offset end,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      final x = point.dx - start.dx;
      final y = point.dy - start.dy;
      return math.sqrt(x * x + y * y);
    }

    final projection = (
      ((point.dx - start.dx) * dx +
              (point.dy - start.dy) * dy) /
          lengthSquared
    ).clamp(0.0, 1.0);

    final closestX = start.dx + projection * dx;
    final closestY = start.dy + projection * dy;

    final distanceX = point.dx - closestX;
    final distanceY = point.dy - closestY;

    return math.sqrt(
      distanceX * distanceX + distanceY * distanceY,
    );
  }

  Future<double> _calculateTraceScore() async {
    final context = _drawingAreaKey.currentContext;
    final renderObject = context?.findRenderObject();

    if (renderObject is! RenderBox || !renderObject.hasSize) {
      throw Exception('Drawing area is unavailable.');
    }

    final size = renderObject.size;
    final width = size.width.ceil();
    final height = size.height.ceil();

    if (width <= 0 || height <= 0) {
      throw Exception('Drawing area has no size.');
    }

    // Render the target letter into a transparent image.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final textPainter = TextPainter(
      text: TextSpan(
        text: _letter,
        style: const TextStyle(
          fontSize: 230,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    if (byteData == null) {
      image.dispose();
      throw Exception('Could not analyse the target letter.');
    }

    final pixels = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    // Collect all connected drawing segments.
    final drawnSegments = <List<Offset>>[];

    for (int i = 0; i < _points.length - 1; i++) {
      final start = _points[i];
      final end = _points[i + 1];

      if (start != null && end != null) {
        drawnSegments.add([start, end]);
      }
    }

    if (drawnSegments.isEmpty) {
      image.dispose();
      return 0;
    }

    int totalGuideSamples = 0;
    int coveredGuideSamples = 0;

    // Sample the guide every three pixels.
    for (int y = 0; y < height; y += 3) {
      for (int x = 0; x < width; x += 3) {
        final pixelIndex = (y * width + x) * 4;
        final alpha = pixels[pixelIndex + 3];

        // Ignore pixels outside the target letter.
        if (alpha < 32) continue;

        totalGuideSamples++;

        final samplePoint = Offset(
          x.toDouble(),
          y.toDouble(),
        );

        bool covered = false;

        for (final segment in drawnSegments) {
          final distance = _distanceToSegment(
            samplePoint,
            segment[0],
            segment[1],
          );

          // Allow a small tolerance for finger movement.
          if (distance <= 18) {
            covered = true;
            break;
          }
        }

        if (covered) {
          coveredGuideSamples++;
        }
      }
    }

    image.dispose();

    if (totalGuideSamples == 0) return 0;

    return coveredGuideSamples / totalGuideSamples;
  }

  Future<void> _checkTraceProgress() async {
    if (_isChecking || _letterCompleted) return;

    final drawnPoints =
        _points.where((point) => point != null).length;

    if (drawnPoints < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Draw the letter first, then tap Check Letter.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      final score = await _calculateTraceScore();

      if (!mounted) return;

      // Pass only when coverage reaches at least 60%.
      final isCorrect = score >= _passingScore;

      setState(() {
        _isChecking = false;
        _letterCompleted = isCorrect;
      });

      if (isCorrect) {
        _showSuccessDialog(score);
      } else {
        _showRetryDialog(score);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isChecking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not check the tracing. Please try again.',
          ),
        ),
      );
    }
  }

  void _showSuccessDialog(double score) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '🎉 Great Job!',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'You passed letter $_letter!\n\n'
            'Text coverage: ${(score * 100).round()}%\n'
            'Passing score: 60%',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Keep Practicing'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _nextLetter();
              },
              child: const Text('Next Letter'),
            ),
          ],
        );
      },
    );
  }

  void _showRetryDialog(double score) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '💪 Try Again!',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'You have not reached the required coverage yet.\n\n'
            'Your coverage: ${(score * 100).round()}%\n'
            'Passing score: 60%\n\n'
            'Follow the faint letter guide more closely and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Keep Drawing'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _clearDrawing();
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  void _clearDrawing() {
    setState(() {
      _points.clear();
      _letterCompleted = false;
    });
  }

  void _nextLetter() {
    setState(() {
      _points.clear();
      _letterCompleted = false;
      _currentLetter = (_currentLetter + 1) % _letters.length;
    });
  }

  Future<void> _speakLetter() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);
    await _tts.speak(_letter);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF2),
        elevation: 0,
        title: const Text(
          'Trace Letters',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 5),
            const Text(
              'Practice writing letters with your finger.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Letter ${_currentLetter + 1} of ${_letters.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B9FE3),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _letter,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B9FE3),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE8DDBF),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: GestureDetector(
                    key: _drawingAreaKey,
                    onPanStart: _startDrawing,
                    onPanUpdate: _continueDrawing,
                    onPanEnd: _endDrawing,
                    child: CustomPaint(
                      painter: _TracePainter(
                        points: List<Offset?>.from(_points),
                        letter: _letter,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _speakLetter,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Hear Letter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5B9FE3),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isChecking ? null : _clearDrawing,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isChecking || _letterCompleted
                    ? null
                    : _checkTraceProgress,
                icon: _isChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.fact_check),
                label: Text(
                  _isChecking ? 'Checking...' : 'Check Letter',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF69A879),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _nextLetter,
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  'Next Letter',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B9FE3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final List<Offset?> points;
  final String letter;

  _TracePainter({
    required this.points,
    required this.letter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guideTextPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(
          fontSize: 230,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE8DFC7),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    guideTextPainter.layout();

    guideTextPainter.paint(
      canvas,
      Offset(
        (size.width - guideTextPainter.width) / 2,
        (size.height - guideTextPainter.height) / 2,
      ),
    );

    final drawingPainter = Paint()
      ..color = const Color(0xFF5B9FE3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      final currentPoint = points[i];
      final nextPoint = points[i + 1];

      if (currentPoint != null && nextPoint != null) {
        canvas.drawLine(
          currentPoint,
          nextPoint,
          drawingPainter,
        );
      }
    }

    if (points.isNotEmpty && points.last != null) {
      final dotPainter = Paint()
        ..color = const Color(0xFF5B9FE3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(points.last!, 3.5, dotPainter);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) {
    return true;
  }
}
