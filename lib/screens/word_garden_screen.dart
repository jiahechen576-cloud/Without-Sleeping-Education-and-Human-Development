
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_language.dart';
import '../services/settings_service.dart';

class WordGardenScreen extends StatefulWidget {
  const WordGardenScreen({super.key});

  @override
  State<WordGardenScreen> createState() => _WordGardenScreenState();
}

class _WordGardenScreenState extends State<WordGardenScreen> {
  static const String _storageKey = 'readrabbit_word_garden_v1';

  static const Color _cream = Color(0xFFFFF9F0);
  static const Color _green = Color(0xFF39734A);
  static const Color _lightGreen = Color(0xFFEAF4E8);
  static const Color _darkText = Color(0xFF26352A);

  final FlutterTts _tts = FlutterTts();
  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, String>> _words = [];

  String _searchQuery = '';

  bool _loading = true;
  bool _highContrast = false;
  bool _dyslexiaLayout = true;

  double _fontSize = 22;
  double _letterSpacing = 1.2;
  double _lineSpacing = 1.5;

  bool get _isBM => appLanguage.value == 'Bahasa Melayu';

  Color get _backgroundColor =>
      _highContrast ? Colors.white : _cream;

  Color get _textColor =>
      _highContrast ? Colors.black : _darkText;

  Color get _cardColor => Colors.white;

  String _t(String english, String malay) {
    return _isBM ? malay : english;
  }

  List<int> get _filteredWordIndices {
    final query = _searchQuery.trim().toLowerCase();

    return List.generate(_words.length, (index) => index)
        .where((index) {
      final item = _words[index];

      return query.isEmpty ||
          (item['word'] ?? '').toLowerCase().contains(query) ||
          (item['meaning'] ?? '').toLowerCase().contains(query) ||
          (item['example'] ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    appLanguage.addListener(_onLanguageChanged);

    _loadWords();
    _loadAccessibilitySettings();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_storageKey);

      if (savedData != null) {
        final decodedData = jsonDecode(savedData);

        if (decodedData is List) {
          final loadedWords = decodedData
              .whereType<Map>()
              .map((item) {
            final map = Map<String, dynamic>.from(item);

            return <String, String>{
              'word': map['word']?.toString() ?? '',
              'meaning': map['meaning']?.toString() ?? '',
              'example': map['example']?.toString() ?? '',
              'language':
                  map['language']?.toString() ?? 'English',
            };
          }).toList();

          if (mounted) {
            setState(() {
              _words = loadedWords;
            });
          }
        }
      }
    } catch (error) {
      debugPrint('Could not load Word Garden: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _storageKey,
        jsonEncode(_words),
      );
    } catch (error) {
      debugPrint('Could not save Word Garden: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Could not save your words. Please try again.',
              'Perkataan tidak dapat disimpan. Sila cuba lagi.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _loadAccessibilitySettings() async {
    try {
      final fontSize = await SettingsService.getFontSize();
      final letterSpacing =
          await SettingsService.getLetterSpacing();
      final lineSpacing = await SettingsService.getLineSpacing();
      final highContrast =
          await SettingsService.getHighContrast();
      final dyslexiaLayout =
          await SettingsService.getDyslexiaLayout();

      if (!mounted) return;

      setState(() {
        _fontSize = fontSize;
        _letterSpacing = letterSpacing;
        _lineSpacing = lineSpacing;
        _highContrast = highContrast;
        _dyslexiaLayout = dyslexiaLayout;
      });
    } catch (error) {
      debugPrint(
        'Could not load accessibility settings: $error',
      );
    }
  }

  Future<void> _speak(
    String text, {
    String? savedLanguage,
  }) async {
    if (text.trim().isEmpty) return;

    try {
      await _tts.stop();
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);

      final language = savedLanguage ?? appLanguage.value;

      await _tts.setLanguage(
        language == 'Bahasa Melayu' ? 'ms-MY' : 'en-US',
      );

      await _tts.speak(text);
    } catch (error) {
      debugPrint('Text-to-speech error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Read aloud is unavailable right now.',
              'Fungsi bacaan suara tidak tersedia sekarang.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _addWord() async {
    await _showWordDialog();
  }

  Future<void> _editWord(int index) async {
    if (index < 0 || index >= _words.length) return;

    await _showWordDialog(
      existingWord: Map<String, String>.from(_words[index]),
      editingIndex: index,
    );
  }

  // The dialog owns its controllers and disposes them in its
  // own State.dispose(), instead of the parent disposing them.
  Future<void> _showWordDialog({
    Map<String, String>? existingWord,
    int? editingIndex,
  }) async {
    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _WordEntryDialog(
          existingWord: existingWord,
          isEditing: editingIndex != null,
          isBM: _isBM,
          backgroundColor: _backgroundColor,
          textColor: _textColor,
          green: _green,
          fontSize: _fontSize,
          letterSpacing: _letterSpacing,
          lineSpacing: _lineSpacing,
          dyslexiaLayout: _dyslexiaLayout,
        );
      },
    );

    if (result == null || !mounted) return;

    final savedWord = Map<String, String>.from(result);
    final normalizedWord = savedWord['word']!.toLowerCase();

    setState(() {
      if (editingIndex != null &&
          editingIndex >= 0 &&
          editingIndex < _words.length) {
        final originalIndex = editingIndex;

        // Remove the original entry before checking for duplicates.
        _words.removeAt(originalIndex);

        final duplicateIndex = _words.indexWhere(
          (item) =>
              item['word']!.toLowerCase() == normalizedWord,
        );

        if (duplicateIndex >= 0) {
          _words[duplicateIndex] = savedWord;
        } else {
          _words.insert(
            originalIndex.clamp(0, _words.length).toInt(),
            savedWord,
          );
        }
      } else {
        final duplicateIndex = _words.indexWhere(
          (item) =>
              item['word']!.toLowerCase() == normalizedWord,
        );

        if (duplicateIndex >= 0) {
          _words[duplicateIndex] = savedWord;
        } else {
          _words.insert(0, savedWord);
        }
      }
    });

    await _saveWords();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            'Your word has been saved 🌱',
            'Perkataan anda telah disimpan 🌱',
          ),
        ),
      ),
    );
  }

  Future<void> _deleteWord(int index) async {
    if (index < 0 || index >= _words.length) return;

    final removedWord = Map<String, String>.from(_words[index]);
    final word = removedWord['word'] ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _backgroundColor,
          title: Text(
            _t(
              'Delete this word?',
              'Padam perkataan ini?',
            ),
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            _t(
              'Are you sure you want to remove "$word" from your Word Garden?',
              'Adakah anda pasti mahu membuang "$word" daripada Taman Perkataan anda?',
            ),
            style: _bodyStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(_t('Cancel', 'Batal')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(_t('Delete', 'Padam')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _words.removeAt(index);
    });

    await _saveWords();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            '"$word" removed.',
            '"$word" telah dibuang.',
          ),
        ),
        action: SnackBarAction(
          label: _t('Undo', 'Buat asal'),
          onPressed: () async {
            if (!mounted) return;

            setState(() {
              _words.insert(
                index.clamp(0, _words.length).toInt(),
                removedWord,
              );
            });

            await _saveWords();
          },
        ),
      ),
    );
  }

  TextStyle _bodyStyle({
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      color: _textColor,
      fontSize: fontSize ?? _fontSize,
      fontWeight: fontWeight,
      height: _dyslexiaLayout ? _lineSpacing : 1.3,
      letterSpacing: _dyslexiaLayout ? _letterSpacing : 0,
    );
  }

  @override
  void dispose() {
    appLanguage.removeListener(_onLanguageChanged);
    _searchController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredIndices = _filteredWordIndices;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        title: Text(
          _t(
            'My Word Garden 🌱',
            'Taman Perkataan Saya 🌱',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _t(
              'Refresh settings',
              'Muat semula tetapan',
            ),
            onPressed: _loadAccessibilitySettings,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _green),
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _buildIntroduction(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addWord,
                      icon: const Icon(
                        Icons.add_circle_outline,
                      ),
                      label: Text(
                        _t(
                          'Save a new word',
                          'Simpan perkataan baharu',
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _t(
                            'My saved words',
                            'Perkataan yang disimpan',
                          ),
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _highContrast
                              ? Colors.white
                              : _lightGreen,
                          borderRadius: BorderRadius.circular(20),
                          border: _highContrast
                              ? Border.all(color: Colors.black)
                              : null,
                        ),
                        child: Text(
                          '${_words.length}',
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: _bodyStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: _t(
                        'Search words or meanings...',
                        'Cari perkataan atau maksud...',
                      ),
                      hintStyle: TextStyle(
                        color: _textColor.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _green,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: _t(
                                'Clear search',
                                'Kosongkan carian',
                              ),
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: _cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _highContrast
                              ? Colors.black
                              : const Color(0xFFDCE8D9),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _highContrast
                              ? Colors.black
                              : const Color(0xFFDCE8D9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_words.isEmpty)
                    _buildEmptyState()
                  else if (filteredIndices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 42,
                            color: _green,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _t(
                              'No matching words found. Try another search.',
                              'Tiada perkataan sepadan. Cuba carian lain.',
                            ),
                            textAlign: TextAlign.center,
                            style: _bodyStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredIndices.map(
                      (index) => _buildWordCard(index),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildIntroduction() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _highContrast ? Colors.white : _lightGreen,
        borderRadius: BorderRadius.circular(20),
        border: _highContrast
            ? Border.all(color: Colors.black, width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.spa_outlined,
            color: _green,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
                    'Every word grows at your pace.',
                    'Setiap perkataan berkembang mengikut rentak anda.',
                  ),
                  style: _bodyStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    'Save words you find difficult, add a simple meaning, '
                    'and listen whenever you need. There is no timer and '
                    'no pressure. Learn at your own pace.',
                    'Simpan perkataan yang sukar, tambah maksud yang mudah, '
                    'dan dengar apabila diperlukan. Tiada pemasa dan tiada '
                    'tekanan. Belajar mengikut rentak anda sendiri.',
                  ),
                  style: _bodyStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _highContrast
              ? Colors.black
              : const Color(0xFFDCE8D9),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_florist_outlined,
            size: 54,
            color: _green,
          ),
          const SizedBox(height: 14),
          Text(
            _t(
              'Your garden is ready to grow!',
              'Taman anda sedia untuk berkembang!',
            ),
            textAlign: TextAlign.center,
            style: _bodyStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              'When you find a tricky word, save it here. '
              'You can come back to it whenever you like.',
              'Apabila anda menemui perkataan yang sukar, '
              'simpan di sini. Anda boleh melihatnya semula '
              'pada bila-bila masa.',
            ),
            textAlign: TextAlign.center,
            style: _bodyStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(int index) {
    final item = _words[index];

    final word = item['word'] ?? '';
    final meaning = item['meaning'] ?? '';
    final example = item['example'] ?? '';
    final savedLanguage = item['language'] ?? 'English';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _highContrast
              ? Colors.black
              : const Color(0xFFDCE8D9),
          width: _highContrast ? 1.5 : 1,
        ),
        boxShadow: _highContrast
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  word,
                  style: _bodyStyle(
                    fontSize: _fontSize + 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: _t(
                  'Listen to word',
                  'Dengar perkataan',
                ),
                onPressed: () => _speak(
                  word,
                  savedLanguage: savedLanguage,
                ),
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: _green,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: _t(
                  'Word options',
                  'Pilihan perkataan',
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editWord(index);
                  } else if (value == 'delete') {
                    _deleteWord(index);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined),
                        const SizedBox(width: 10),
                        Text(_t('Edit', 'Edit')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline),
                        const SizedBox(width: 10),
                        Text(_t('Delete', 'Padam')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t('Simple meaning', 'Maksud mudah'),
            style: _bodyStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ).copyWith(color: _green),
          ),
          const SizedBox(height: 4),
          Text(
            meaning,
            textAlign: TextAlign.start,
            style: _bodyStyle(),
          ),
          const SizedBox(height: 12),
          if (example.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _highContrast
                    ? Colors.white
                    : const Color(0xFFF6F8F2),
                borderRadius: BorderRadius.circular(12),
                border: _highContrast
                    ? Border.all(color: Colors.black)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(
                      'Example sentence',
                      'Ayat contoh',
                    ),
                    style: _bodyStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ).copyWith(color: _green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    example,
                    style: _bodyStyle(
                      fontSize: _fontSize - 1,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: _t(
                        'Listen to example',
                        'Dengar ayat contoh',
                      ),
                      onPressed: () => _speak(
                        example,
                        savedLanguage: savedLanguage,
                      ),
                      icon: const Icon(
                        Icons.play_circle_outline,
                        color: _green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _speak(
                '$word. $meaning. '
                '${example.isEmpty ? '' : example}',
                savedLanguage: savedLanguage,
              ),
              icon: const Icon(
                Icons.record_voice_over_outlined,
              ),
              label: Text(
                _t(
                  'Read everything',
                  'Baca semuanya',
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Separate dialog widget.
//
// Its controllers and FormState are owned by this State object.
// Flutter disposes this State when the dialog route is removed.
class _WordEntryDialog extends StatefulWidget {
  const _WordEntryDialog({
    required this.existingWord,
    required this.isEditing,
    required this.isBM,
    required this.backgroundColor,
    required this.textColor,
    required this.green,
    required this.fontSize,
    required this.letterSpacing,
    required this.lineSpacing,
    required this.dyslexiaLayout,
  });

  final Map<String, String>? existingWord;
  final bool isEditing;
  final bool isBM;

  final Color backgroundColor;
  final Color textColor;
  final Color green;

  final double fontSize;
  final double letterSpacing;
  final double lineSpacing;
  final bool dyslexiaLayout;

  @override
  State<_WordEntryDialog> createState() =>
      _WordEntryDialogState();
}

class _WordEntryDialogState extends State<_WordEntryDialog> {
  late final TextEditingController _wordController;
  late final TextEditingController _meaningController;
  late final TextEditingController _exampleController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _t(String english, String malay) {
    return widget.isBM ? malay : english;
  }

  @override
  void initState() {
    super.initState();

    _wordController = TextEditingController(
      text: widget.existingWord?['word'] ?? '',
    );

    _meaningController = TextEditingController(
      text: widget.existingWord?['meaning'] ?? '',
    );

    _exampleController = TextEditingController(
      text: widget.existingWord?['example'] ?? '',
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();

    super.dispose();
  }

  TextStyle _inputStyle({
    bool multiline = false,
  }) {
    return TextStyle(
      color: widget.textColor,
      fontSize: widget.fontSize,
      height: multiline ? widget.lineSpacing : null,
      letterSpacing: widget.dyslexiaLayout
          ? widget.letterSpacing
          : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.backgroundColor,
      title: Text(
        widget.isEditing
            ? _t('Edit your word', 'Edit perkataan anda')
            : _t(
                'Save a new word 🌱',
                'Simpan perkataan baharu 🌱',
              ),
        style: TextStyle(
          color: widget.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _wordController,
                autofocus: true,
                textCapitalization:
                    TextCapitalization.sentences,
                style: _inputStyle(),
                decoration: InputDecoration(
                  labelText: _t(
                    'Word or phrase',
                    'Perkataan atau frasa',
                  ),
                  hintText: _t(
                    'e.g. beautiful',
                    'contoh: cantik',
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _t(
                      'Please enter a word.',
                      'Sila masukkan perkataan.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _meaningController,
                minLines: 2,
                maxLines: 4,
                style: _inputStyle(multiline: true),
                decoration: InputDecoration(
                  labelText: _t(
                    'Simple meaning',
                    'Maksud mudah',
                  ),
                  hintText: _t(
                    'Explain it in your own words',
                    'Terangkan dengan ayat sendiri',
                  ),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _t(
                      'Please add a simple meaning.',
                      'Sila masukkan maksud mudah.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _exampleController,
                minLines: 2,
                maxLines: 4,
                style: _inputStyle(multiline: true),
                decoration: InputDecoration(
                  labelText: _t(
                    'Example sentence (optional)',
                    'Ayat contoh (pilihan)',
                  ),
                  hintText: _t(
                    'Use the word in a sentence',
                    'Gunakan perkataan dalam ayat',
                  ),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            _t('Cancel', 'Batal'),
            style: TextStyle(color: widget.green),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: widget.green,
            foregroundColor: Colors.white,
          ),
          onPressed: _save,
          child: Text(
            widget.isEditing
                ? _t('Save changes', 'Simpan perubahan')
                : _t('Save word', 'Simpan perkataan'),
          ),
        ),
      ],
    );
  }

  void _save() {
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    final result = <String, String>{
      'word': _wordController.text.trim(),
      'meaning': _meaningController.text.trim(),
      'example': _exampleController.text.trim(),
      'language': widget.existingWord?['language'] ??
          appLanguage.value,
    };

    Navigator.of(context).pop(result);
  }
}
