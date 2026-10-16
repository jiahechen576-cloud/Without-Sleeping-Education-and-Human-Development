import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class SpeakScreen extends StatefulWidget {
  const SpeakScreen({super.key});

  @override
  State<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _textController =
      TextEditingController();

  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isSpeaking = false;

  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      debugLogging: true,
      onStatus: (status) {
        if (!mounted) return;

        setState(() {
          _isListening = status == 'listening';
        });
      },
      onError: (error) {
        if (!mounted) return;

        debugPrint('SPEECH ERROR: $error');

        setState(() {
          _isListening = false;
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _speechAvailable = available;
    });
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) return;

    if (_isListening) {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _isListening = false;
      });

      return;
    }

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;

        final recognized = result.recognizedWords;

        debugPrint('RECOGNIZED: $recognized');

        setState(() {
          _spokenText = recognized;
          _textController.value = TextEditingValue(
            text: recognized,
            selection: TextSelection.collapsed(
              offset: recognized.length,
            ),
          );
        });
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: 'en-US',
        partialResults: true,
      ),
    );
  }

  Future<void> _readAloud() async {
    if (_spokenText.trim().isEmpty) return;

    if (_isSpeaking) {
      await _tts.stop();

      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });

      return;
    }

    setState(() {
      _isSpeaking = true;
    });

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    });

    _tts.setCancelHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    });

    await _tts.speak(_spokenText);
  }

  void _clearText() {
    setState(() {
      _spokenText = '';
      _textController.clear();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
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
          'Speak & Write',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              'Speak naturally and your words will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _textController,
                  onChanged: (value) {
                    _spokenText = value;
                  },
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.5,
                    letterSpacing: 1.2,
                    color: Color(0xFF333333),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Your speech will appear here...',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!_speechAvailable)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Speech recognition is not available.',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed:
                    _speechAvailable ? _toggleListening : null,
                icon: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  size: 28,
                ),
                label: Text(
                  _isListening
                      ? 'Stop Listening'
                      : 'Start Speaking',
                  style: const TextStyle(
                    fontSize: 18,
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _spokenText.trim().isEmpty
                        ? null
                        : _readAloud,
                    icon: Icon(
                      _isSpeaking
                          ? Icons.stop
                          : Icons.volume_up,
                    ),
                    label: Text(
                      _isSpeaking
                          ? 'Stop Reading'
                          : 'Read Aloud',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(0xFF5B9FE3),
                      minimumSize:
                          const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _spokenText.isEmpty
                        ? null
                        : _clearText,
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      minimumSize:
                          const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}