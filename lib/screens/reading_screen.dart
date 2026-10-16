import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/settings_service.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _readingStackKey = GlobalKey();

  double _rulerTop = 155;

  double fontSize = 22;
  double letterSpacing = 1.2;
  double lineSpacing = 1.5;

  bool rulerEnabled = true;
  bool readAloudEnabled = true;
  bool highContrast = false;
  bool dyslexiaLayout = true;
  bool isPlaying = false;

  int currentWord = 0;

  final List<String> words = [
    'Lina', 'loves', 'walking', 'in', 'the', 'garden.',
    'Every', 'morning,', 'she', 'visits', 'the', 'flowers',
    'and', 'watches', 'the', 'butterflies', 'fly', 'around.',
    'She', 'enjoys', 'listening', 'to', 'the', 'birds',
    'singing', 'in', 'the', 'trees.', 'One', 'sunny',
    'morning,', 'Lina', 'notices', 'a', 'small', 'rabbit',
    'hiding', 'behind', 'a', 'bush.', 'She', 'walks',
    'slowly', 'towards', 'it', 'so', 'she', 'does',
    'not', 'scare', 'the', 'little', 'animal.', 'The',
    'rabbit', 'looks', 'at', 'Lina', 'and', 'then',
    'hops', 'towards', 'a', 'group', 'of', 'colourful',
    'flowers.', 'Lina', 'smiles', 'and', 'follows', 'it',
    'carefully.', 'Along', 'the', 'way,', 'she', 'sees',
    'red', 'roses,', 'yellow', 'sunflowers,', 'and', 'tiny',
    'purple', 'flowers.', 'The', 'garden', 'feels', 'peaceful',
    'and', 'bright.', 'After', 'exploring', 'the', 'garden,',
    'Lina', 'sits', 'under', 'a', 'big', 'tree', 'and',
    'reads', 'her', 'favourite', 'book.', 'She', 'feels',
    'happy', 'because', 'every', 'day', 'in', 'the',
    'garden', 'brings', 'a', 'new', 'adventure.',
  ];

  String get _storyText => words.join(' ');

  late final List<GlobalKey> _wordKeys =
      List.generate(words.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedFontSize = await SettingsService.getFontSize();
    final savedLetterSpacing =
        await SettingsService.getLetterSpacing();
    final savedLineSpacing =
        await SettingsService.getLineSpacing();
    final savedReadingRuler =
        await SettingsService.getReadingRuler();
    final savedReadAloud =
        await SettingsService.getReadAloud();
    final savedHighContrast =
        await SettingsService.getHighContrast();
    final savedDyslexiaLayout =
        await SettingsService.getDyslexiaLayout();

    if (!mounted) return;

    setState(() {
      fontSize = savedFontSize.clamp(16.0, 32.0);
      letterSpacing = savedLetterSpacing;
      lineSpacing = savedLineSpacing;
      rulerEnabled = savedReadingRuler;
      readAloudEnabled = savedReadAloud;
      highContrast = savedHighContrast;
      dyslexiaLayout = savedDyslexiaLayout;
    });

    _scheduleRulerPositionUpdate();
  }

  Future<void> speakStory() async {
    final enabled = await SettingsService.getReadAloud();

    if (!mounted) return;

    if (!enabled) {
      setState(() {
        readAloudEnabled = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Read Aloud is turned off. Enable it in Settings to listen.',
          ),
        ),
      );
      return;
    }

    await flutterTts.setLanguage('en-US');

    final savedSpeechRate =
        await SettingsService.getSpeechRate();

    await flutterTts.setSpeechRate(savedSpeechRate);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);

    if (!mounted) return;

    flutterTts.setProgressHandler(
      (String text, int start, int end, String spokenWord) {
        if (!mounted || words.isEmpty) return;

        final safeStart = start.clamp(0, text.length);
        final textBeforeWord = text.substring(0, safeStart).trim();

        final index = textBeforeWord.isEmpty
            ? 0
            : textBeforeWord
                .split(RegExp(r'\s+'))
                .where((item) => item.isNotEmpty)
                .length;

        final nextIndex = index.clamp(0, words.length - 1);

        if (nextIndex != currentWord) {
          setState(() {
            currentWord = nextIndex;
          });

          _scrollToCurrentWord();
        }
      },
    );

    flutterTts.setCompletionHandler(() {
      if (!mounted) return;

      setState(() {
        isPlaying = false;
        currentWord = 0;
      });

      _scrollToCurrentWord();
    });

    flutterTts.setCancelHandler(() {
      if (!mounted) return;

      setState(() {
        isPlaying = false;
      });
    });

    setState(() {
      readAloudEnabled = true;
      isPlaying = true;
      currentWord = 0;
    });

    await _scrollToCurrentWord();
    await flutterTts.speak(_storyText);
  }

  Future<void> _stopStory() async {
    await flutterTts.stop();

    if (!mounted) return;

    setState(() {
      isPlaying = false;
    });
  }

  void _moveToWord(int nextIndex) {
    setState(() {
      currentWord = nextIndex.clamp(0, words.length - 1);
    });

    _scrollToCurrentWord();
  }

  void _scheduleRulerPositionUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateRulerPosition();
      }
    });
  }

  Future<void> _scrollToCurrentWord() async {
    if (!mounted ||
        currentWord < 0 ||
        currentWord >= _wordKeys.length) {
      return;
    }

    final wordContext = _wordKeys[currentWord].currentContext;

    if (wordContext == null) return;

    await Scrollable.ensureVisible(
      wordContext,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );

    if (!mounted) return;

    _updateRulerPosition();
  }

  void _updateRulerPosition() {
    if (!mounted || currentWord >= _wordKeys.length) return;

    final stackContext = _readingStackKey.currentContext;
    final wordContext = _wordKeys[currentWord].currentContext;

    if (stackContext == null || wordContext == null) return;

    final stackObject = stackContext.findRenderObject();
    final wordObject = wordContext.findRenderObject();

    if (stackObject is! RenderBox ||
        wordObject is! RenderBox) {
      return;
    }

    if (!stackObject.hasSize || !wordObject.hasSize) return;

    final stackTop = stackObject.localToGlobal(Offset.zero).dy;
    final wordTop = wordObject.localToGlobal(Offset.zero).dy;

    final wordCenter =
        wordTop - stackTop + wordObject.size.height / 2;

    final maxTop =
        (stackObject.size.height - 48)
            .clamp(0.0, double.infinity);

    final newTop =
        (wordCenter - 24).clamp(0.0, maxTop).toDouble();

    if ((_rulerTop - newTop).abs() > 1) {
      setState(() {
        _rulerTop = newTop;
      });
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        highContrast ? Colors.black : const Color(0xFFFFF9F0);

    final headingColor =
        highContrast ? Colors.white : const Color(0xFF1F3D2A);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Reading Assistant',
          style: TextStyle(
            color: headingColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: headingColor),
        actions: [
          IconButton(
            onPressed: () async {
              final newValue = !rulerEnabled;

              setState(() {
                rulerEnabled = newValue;
              });

              await SettingsService.saveReadingRuler(newValue);

              if (!mounted) return;

              if (newValue) {
                _scheduleRulerPositionUpdate();
              }
            },
            icon: Icon(
              rulerEnabled
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            tooltip: 'Reading ruler',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'The Garden Adventure',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: headingColor,
                        ),
                      ),
                      Text(
                        'Page 4 / 10',
                        style: TextStyle(
                          color: highContrast
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.4,
                      minHeight: 7,
                      backgroundColor: highContrast
                          ? Colors.grey.shade800
                          : const Color(0xFFE6E0D7),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6FAF7B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: highContrast ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: highContrast
                      ? Border.all(color: Colors.white, width: 1)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  key: _readingStackKey,
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            '🌱',
                            style: TextStyle(fontSize: 45),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'The Garden Adventure',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: headingColor,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: dyslexiaLayout ? 7 : 4,
                            runSpacing: dyslexiaLayout ? 12 : 6,
                            children: List.generate(
                              words.length,
                              (index) {
                                final highlighted = index == currentWord;

                                return AnimatedContainer(
                                  key: _wordKeys[index],
                                  duration:
                                      const Duration(milliseconds: 200),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: dyslexiaLayout ? 5 : 2,
                                    vertical: dyslexiaLayout ? 3 : 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: highlighted
                                        ? const Color(0xFFFFE58A)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    words[index],
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      height: dyslexiaLayout
                                          ? lineSpacing
                                          : 1.2,
                                      letterSpacing: dyslexiaLayout
                                          ? letterSpacing
                                          : 0.0,
                                      color: highlighted
                                          ? Colors.black
                                          : highContrast
                                              ? Colors.white
                                              : const Color(0xFF222222),
                                      fontWeight: highlighted
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 25),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                    if (rulerEnabled)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        left: 0,
                        right: 0,
                        top: _rulerTop,
                        child: IgnorePointer(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8EC5FF)
                                  .withValues(alpha: 0.18),
                              border: Border.symmetric(
                                horizontal: BorderSide(
                                  color: const Color(0xFF6FAF7B)
                                      .withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: 16,
                      color: headingColor,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: fontSize.clamp(16.0, 32.0),
                      min: 16,
                      max: 32,
                      divisions: 16,
                      activeColor: const Color(0xFF4A8060),
                      onChanged: (value) {
                        setState(() {
                          fontSize = value;
                        });

                        SettingsService.saveFontSize(value);
                        _scheduleRulerPositionUpdate();
                      },
                    ),
                  ),
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => _moveToWord(currentWord - 1),
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      size: 30,
                      color: headingColor,
                    ),
                  ),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D5A3D),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () async {
                        if (isPlaying) {
                          await _stopStory();
                        } else {
                          await speakStory();
                        }
                      },
                      icon: Icon(
                        isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _moveToWord(currentWord + 1),
                    icon: Icon(
                      Icons.skip_next_rounded,
                      size: 30,
                      color: headingColor,
                    ),
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