import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/settings_service.dart';

class DyslexiaReadingScreen extends StatefulWidget {
  final String text;

  const DyslexiaReadingScreen({
    super.key,
    required this.text,
  });

  @override
  State<DyslexiaReadingScreen> createState() =>
      _DyslexiaReadingScreenState();
}

class _DyslexiaReadingScreenState
    extends State<DyslexiaReadingScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  final GlobalKey _readingStackKey = GlobalKey();
  final GlobalKey _readingViewportKey = GlobalKey();

  late String _readingText;
  late List<String> _words;
  late List<int> _wordStartOffsets;
  late List<GlobalKey> _wordKeys;

  int _currentWord = -1;

  bool _isSpeaking = false;
  bool _rulerEnabled = true;
  bool _readAloudEnabled = true;
  bool _highContrast = false;
  bool _dyslexiaLayout = true;

  double _fontSize = 22;
  double _letterSpacing = 1.2;
  double _lineSpacing = 1.5;
  double _speechRate = 0.45;
  double _rulerTop = 0;

  Color get _backgroundColor =>
      _highContrast ? Colors.black : const Color(0xFFFFFBF2);

  Color get _cardColor =>
      _highContrast ? const Color(0xFF181818) : const Color(0xFFFFF4D6);

  Color get _textColor =>
      _highContrast ? Colors.white : const Color(0xFF333333);

  Color get _primaryColor =>
      _highContrast ? Colors.yellow : const Color(0xFF5B9FE3);

  @override
  void initState() {
    super.initState();

    _readingText = widget.text.trim();

    final matches = RegExp(r'\S+').allMatches(_readingText);

    _words = matches.map((match) => match.group(0)!).toList();

    _wordStartOffsets = matches.map((match) => match.start).toList();

    _wordKeys = List.generate(
      _words.length,
      (_) => GlobalKey(),
    );

    _loadSettings();

    _flutterTts.setStartHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
        _currentWord = -1;
      });
    });

    _flutterTts.setCancelHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
        _currentWord = -1;
      });
    });

    _flutterTts.setProgressHandler(
      (String text, int startOffset, int endOffset, String word) {
        if (!mounted || _wordStartOffsets.isEmpty) return;

        final safeOffset =
            startOffset.clamp(0, _readingText.length).toInt();

        int nextWord = 0;

        for (int i = 0; i < _wordStartOffsets.length; i++) {
          if (_wordStartOffsets[i] <= safeOffset) {
            nextWord = i;
          } else {
            break;
          }
        }

        if (nextWord == _currentWord) return;

        setState(() {
          _currentWord = nextWord;
        });

        _followCurrentWord();
      },
    );
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      SettingsService.getFontSize(),
      SettingsService.getLetterSpacing(),
      SettingsService.getLineSpacing(),
      SettingsService.getReadingRuler(),
      SettingsService.getReadAloud(),
      SettingsService.getHighContrast(),
      SettingsService.getDyslexiaLayout(),
      SettingsService.getSpeechRate(),
    ]);

    if (!mounted) return;

    setState(() {
      _fontSize = (results[0] as double).clamp(16.0, 32.0);
      _letterSpacing = (results[1] as double).clamp(0.0, 3.0);
      _lineSpacing = (results[2] as double).clamp(1.0, 2.5);
      _rulerEnabled = results[3] as bool;
      _readAloudEnabled = results[4] as bool;
      _highContrast = results[5] as bool;
      _dyslexiaLayout = results[6] as bool;
      _speechRate = (results[7] as double).clamp(0.2, 0.8);
    });

    _scheduleRulerUpdate();
  }

  void _scheduleRulerUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateRulerPosition();
    });
  }

  void _updateRulerPosition() {
    if (!_rulerEnabled ||
        _currentWord < 0 ||
        _currentWord >= _wordKeys.length) {
      return;
    }

    final stackContext = _readingStackKey.currentContext;
    final wordContext = _wordKeys[_currentWord].currentContext;

    if (stackContext == null || wordContext == null) return;

    final stackObject = stackContext.findRenderObject();
    final wordObject = wordContext.findRenderObject();

    if (stackObject is! RenderBox ||
        wordObject is! RenderBox ||
        !stackObject.hasSize ||
        !wordObject.hasSize) {
      return;
    }

    final wordPosition = wordObject.localToGlobal(
      Offset.zero,
      ancestor: stackObject,
    );

    final wordCenter =
        wordPosition.dy + wordObject.size.height / 2;

    final newTop = (wordCenter - 21)
        .clamp(
          0.0,
          (stackObject.size.height - 42)
              .clamp(0.0, double.infinity),
        )
        .toDouble();

    if ((_rulerTop - newTop).abs() < 1) return;

    setState(() {
      _rulerTop = newTop;
    });
  }

  Future<void> _followCurrentWord() async {
    if (_currentWord < 0 ||
        _currentWord >= _wordKeys.length) {
      return;
    }

    final wordContext = _wordKeys[_currentWord].currentContext;

    if (wordContext == null) {
      _scheduleRulerUpdate();
      return;
    }

    final viewportContext = _readingViewportKey.currentContext;
    final wordObject = wordContext.findRenderObject();
    final viewportObject = viewportContext?.findRenderObject();

    if (wordObject is RenderBox &&
        viewportObject is RenderBox &&
        wordObject.hasSize &&
        viewportObject.hasSize) {
      final wordTop = wordObject.localToGlobal(Offset.zero).dy;
      final wordBottom = wordTop + wordObject.size.height;

      final viewportTop =
          viewportObject.localToGlobal(Offset.zero).dy;
      final viewportBottom =
          viewportTop + viewportObject.size.height;

      if (wordTop < viewportTop || wordBottom > viewportBottom) {
        await Scrollable.ensureVisible(
          wordContext,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.35,
        );
      }
    }

    if (!mounted) return;

    _scheduleRulerUpdate();
  }

  Future<void> _toggleReadingRuler(bool value) async {
    setState(() {
      _rulerEnabled = value;
    });

    await SettingsService.saveReadingRuler(value);

    if (!mounted) return;

    if (value) {
      _scheduleRulerUpdate();
    }
  }

  Future<void> _changeFontSize(double value) async {
    setState(() {
      _fontSize = value;
    });

    await SettingsService.saveFontSize(value);

    if (!mounted) return;

    _scheduleRulerUpdate();
  }

  Future<void> _changeLetterSpacing(double value) async {
    setState(() {
      _letterSpacing = value;
    });

    await SettingsService.saveLetterSpacing(value);

    if (!mounted) return;

    _scheduleRulerUpdate();
  }

  Future<void> _changeLineSpacing(double value) async {
    setState(() {
      _lineSpacing = value;
    });

    await SettingsService.saveLineSpacing(value);

    if (!mounted) return;

    _scheduleRulerUpdate();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _readAloud() async {
    if (_isSpeaking) {
      await _flutterTts.stop();

      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
        _currentWord = -1;
      });

      return;
    }

    if (_readingText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There is no text to read.'),
        ),
      );
      return;
    }

    final enabled = await SettingsService.getReadAloud();

    if (!mounted) return;

    setState(() {
      _readAloudEnabled = enabled;
    });

    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Read Aloud is disabled. Enable it in Settings.',
          ),
        ),
      );
      return;
    }

    final savedRate = await SettingsService.getSpeechRate();

    if (!mounted) return;

    setState(() {
      _speechRate = savedRate.clamp(0.2, 0.8);
      _currentWord = _words.isEmpty ? -1 : 0;
      _rulerTop = 0;
    });

    _scheduleRulerUpdate();

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(_readingText);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
        _currentWord = -1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to read this text aloud. Please try again.',
          ),
        ),
      );
    }
  }

  Widget _buildReadingText() {
    return Stack(
      key: _readingStackKey,
      children: [
        Wrap(
          spacing: _dyslexiaLayout ? 7 : 4,
          runSpacing: _dyslexiaLayout ? 14 : 6,
          children: List.generate(
            _words.length,
            (index) {
              final isCurrentWord = index == _currentWord;

              return AnimatedContainer(
                key: _wordKeys[index],
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: _dyslexiaLayout ? 5 : 2,
                  vertical: _dyslexiaLayout ? 3 : 1,
                ),
                decoration: BoxDecoration(
                  color: isCurrentWord
                      ? (_highContrast
                          ? Colors.yellow
                          : const Color(0xFFB9DCFF))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _words[index],
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: _lineSpacing,
                    letterSpacing: _letterSpacing,
                    color: isCurrentWord && _highContrast
                        ? Colors.black
                        : _textColor,
                    fontWeight: isCurrentWord
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        if (_rulerEnabled && _currentWord >= 0)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            top: _rulerTop,
            child: IgnorePointer(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: _primaryColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        title: const Text(
          'Easy Reading',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Reading Ruler',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _rulerEnabled,
                  activeThumbColor: _primaryColor,
                  onChanged: _toggleReadingRuler,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  'Text Size',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _fontSize.clamp(16.0, 32.0),
                    min: 16,
                    max: 32,
                    divisions: 16,
                    activeColor: _primaryColor,
                    label: _fontSize.round().toString(),
                    onChanged: _changeFontSize,
                  ),
                ),
                Text(
                  _fontSize.round().toString(),
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Line Spacing',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _lineSpacing.clamp(1.0, 2.5),
                    min: 1.0,
                    max: 2.5,
                    divisions: 6,
                    activeColor: _primaryColor,
                    label: _lineSpacing.toStringAsFixed(1),
                    onChanged: _changeLineSpacing,
                  ),
                ),
                Text(
                  _lineSpacing.toStringAsFixed(1),
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Letter Spacing',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _letterSpacing.clamp(0.0, 3.0),
                    min: 0,
                    max: 3,
                    divisions: 6,
                    activeColor: _primaryColor,
                    label: _letterSpacing.toStringAsFixed(1),
                    onChanged: _changeLetterSpacing,
                  ),
                ),
                Text(
                  _letterSpacing.toStringAsFixed(1),
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: _highContrast
                      ? Border.all(color: Colors.white, width: 1)
                      : null,
                ),
                child: SingleChildScrollView(
                  key: _readingViewportKey,
                  child: _buildReadingText(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _readAloud,
                icon: Icon(
                  _isSpeaking ? Icons.stop : Icons.volume_up,
                ),
                label: Text(
                  _isSpeaking ? 'Stop Reading' : 'Read Aloud',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor:
                      _highContrast ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _readAloudEnabled
                  ? 'Follow the highlighted words while listening.'
                  : 'Read Aloud is disabled in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textColor.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}