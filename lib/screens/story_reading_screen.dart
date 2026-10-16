
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/settings_service.dart';

class StoryReadingScreen extends StatefulWidget {
  final String title;
  final String story;
  final String language;

  const StoryReadingScreen({
    super.key,
    required this.title,
    required this.story,
    required this.language,
  });

  @override
  State<StoryReadingScreen> createState() =>
      _StoryReadingScreenState();
}

class _StoryReadingScreenState extends State<StoryReadingScreen> {
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scrollController = ScrollController();

  final List<GlobalKey> _paragraphKeys = [];

  List<String> _paragraphs = [];
  List<int> _paragraphOffsets = [];

  int _currentWordStart = -1;
  int _currentWordEnd = -1;
  int _currentParagraph = -1;

  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _isReady = false;

  double _fontSize = 22;
  double _letterSpacing = 1.2;
  double _lineSpacing = 1.5;
  double _speechRate = 0.45;

  bool _rulerEnabled = true;

  @override
  void initState() {
    super.initState();

    _prepareParagraphs();
    _initializeReader();
  }

  Future<void> _initializeReader() async {
    await _loadSettings();

    if (!mounted) return;

    await _setupTts();
  }

  Future<void> _loadSettings() async {
    final savedFontSize = await SettingsService.getFontSize();
    final savedLetterSpacing =
        await SettingsService.getLetterSpacing();
    final savedLineSpacing =
        await SettingsService.getLineSpacing();
    final savedReadingRuler =
        await SettingsService.getReadingRuler();
    final savedSpeechRate =
        await SettingsService.getSpeechRate();

    if (!mounted) return;

    setState(() {
      _fontSize = savedFontSize.clamp(16.0, 32.0);
      _letterSpacing = savedLetterSpacing;
      _lineSpacing = savedLineSpacing;
      _rulerEnabled = savedReadingRuler;
      _speechRate = savedSpeechRate.clamp(0.2, 0.8);
    });
  }

  void _prepareParagraphs() {
    _paragraphs = widget.story
        .split('\n')
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .toList();

    _paragraphOffsets = [];
    _paragraphKeys.clear();

    int offset = 0;

    for (final paragraph in _paragraphs) {
      final originalIndex = widget.story.indexOf(
        paragraph,
        offset,
      );

      final start = originalIndex >= 0
          ? originalIndex
          : offset;

      _paragraphOffsets.add(start);
      _paragraphKeys.add(GlobalKey());

      offset = start + paragraph.length;
    }
  }

  Future<void> _setupTts() async {
    final selectedLanguage = widget.language
        .trim()
        .toLowerCase()
        .replaceAll('_', '-');

    final isMalay = selectedLanguage == 'ms' ||
        selectedLanguage == 'ms-my' ||
        selectedLanguage.contains('melayu') ||
        selectedLanguage.contains('malay') ||
        selectedLanguage.contains('malaysia');

    final ttsLanguage = isMalay ? 'ms-MY' : 'en-US';

    await _tts.setLanguage(ttsLanguage);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(1.0);

    _tts.setProgressHandler(
      (String text, int start, int end, String word) {
        if (!mounted) return;

        int paragraphIndex = 0;

        for (int i = 0; i < _paragraphOffsets.length; i++) {
          if (start >= _paragraphOffsets[i]) {
            paragraphIndex = i;
          } else {
            break;
          }
        }

        setState(() {
          _currentWordStart = start;
          _currentWordEnd = end;
          _currentParagraph = paragraphIndex;
          _isSpeaking = true;
          _isPaused = false;
        });

        _scrollToParagraph(paragraphIndex);
      },
    );

    _tts.setStartHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = true;
        _isPaused = false;
      });
    });

    _tts.setCompletionHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
        _isPaused = false;
        _currentWordStart = -1;
        _currentWordEnd = -1;
        _currentParagraph = -1;
      });
    });

    _tts.setCancelHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    });

    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  void _scrollToParagraph(int index) {
    if (index < 0 || index >= _paragraphKeys.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final paragraphContext =
          _paragraphKeys[index].currentContext;

      if (paragraphContext != null) {
        Scrollable.ensureVisible(
          paragraphContext,
          duration: const Duration(milliseconds: 300),
          alignment: 0.35,
        );
      }
    });
  }

  Future<void> _playStory() async {
    if (!_isReady) return;

    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _currentWordStart = -1;
      _currentWordEnd = -1;
      _currentParagraph = -1;
      _isPaused = false;
      _isSpeaking = true;
    });

    await _tts.speak(widget.story);
  }

  Future<void> _pauseOrResume() async {
    if (_isPaused) {
      await _tts.speak(widget.story);
      return;
    }

    await _tts.pause();

    if (!mounted) return;

    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _stopStory() async {
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _isSpeaking = false;
      _isPaused = false;
      _currentWordStart = -1;
      _currentWordEnd = -1;
      _currentParagraph = -1;
    });
  }

  Widget _buildHighlightedParagraph(int index) {
    final paragraph = _paragraphs[index];
    final paragraphStart = _paragraphOffsets[index];

    final rulerActive =
        _rulerEnabled && _currentParagraph == index;

    final spans = <TextSpan>[];
    final wordPattern = RegExp(r'\S+');

    int previousEnd = 0;

    for (final match in wordPattern.allMatches(paragraph)) {
      if (match.start > previousEnd) {
        spans.add(
          TextSpan(
            text: paragraph.substring(previousEnd, match.start),
          ),
        );
      }

      final globalStart = paragraphStart + match.start;
      final globalEnd = paragraphStart + match.end;

      final isCurrentWord =
          _currentWordStart >= 0 &&
          _currentWordEnd > _currentWordStart &&
          globalStart < _currentWordEnd &&
          globalEnd > _currentWordStart;

      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            backgroundColor: isCurrentWord
                ? const Color(0xFFFFD66B)
                : Colors.transparent,
            color: const Color(0xFF253D2C),
            fontWeight: isCurrentWord
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      );

      previousEnd = match.end;
    }

    if (previousEnd < paragraph.length) {
      spans.add(
        TextSpan(
          text: paragraph.substring(previousEnd),
        ),
      );
    }

    return Container(
      key: _paragraphKeys[index],
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rulerActive
            ? const Color(0xFFDCEBFF)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rulerActive
              ? const Color(0xFF7DA7E8)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: _fontSize,
            height: _lineSpacing,
            letterSpacing: _letterSpacing,
          ),
          children: spans,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _tts.setProgressHandler((text, start, end, word) {});
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF9F0);
    const darkGreen = Color(0xFF285C38);
    const green = Color(0xFF4F8A52);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: darkGreen,
        elevation: 0,
        title: const Text(
          'Story Reader',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Follow the highlighted word as you listen.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isReady ? _playStory : null,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Read aloud'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSpeaking
                            ? _pauseOrResume
                            : null,
                        icon: Icon(
                          _isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                        label: Text(
                          _isPaused ? 'Resume' : 'Pause',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSpeaking || _isPaused
                            ? _stopStory
                            : null,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Stop'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final newValue = !_rulerEnabled;

                          setState(() {
                            _rulerEnabled = newValue;
                          });

                          await SettingsService.saveReadingRuler(
                            newValue,
                          );
                        },
                        icon: Icon(
                          _rulerEnabled
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                        label: Text(
                          _rulerEnabled ? 'Ruler On' : 'Ruler Off',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _paragraphs.length,
                itemBuilder: (context, index) {
                  return _buildHighlightedParagraph(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
