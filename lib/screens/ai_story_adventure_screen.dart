
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'story_reading_screen.dart';
import '../services/story_history_service.dart';

class AiStoryAdventureScreen extends StatefulWidget {
  const AiStoryAdventureScreen({super.key});

  @override
  State<AiStoryAdventureScreen> createState() =>
      _AiStoryAdventureScreenState();
}

class _AiStoryAdventureScreenState
    extends State<AiStoryAdventureScreen> {
  final TextEditingController _topicController =
      TextEditingController();

  String _language = 'English';
  String _difficulty = 'Easy';
  int _questionCount = 5;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _storyData;
  String? _savedStoryId;

  final Map<int, int> _selectedAnswers = {};

  static const String _backendUrl =
      'http://10.0.2.2:3000/story';

  Future<void> _generateStory() async {
    final topic = _topicController.text.trim();

    if (topic.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a story topic.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _storyData = null;
       _savedStoryId = null;
      _selectedAnswers.clear();
    });

    try {
      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
  'topic': topic,
  'language': _language,
  'difficulty': _difficulty,
  'questionCount': _questionCount,
}),
          )
          .timeout(const Duration(seconds: 90));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is! Map<String, dynamic>) {
          throw const FormatException(
            'The server returned an invalid response.',
          );
        }

        if (data['title'] == null ||
            data['story'] == null ||
            data['questions'] is! List) {
          throw const FormatException(
            'The story response is incomplete.',
          );
        }

 String? savedStoryId;

try {
  savedStoryId = await StoryHistoryService.saveStory(
    title: data['title'].toString(),
    story: data['story'].toString(),
    language: _language,
    topic: topic,
    difficulty: _difficulty,
    questionCount: _questionCount,
  );
} catch (storageError) {
  debugPrint('Could not save story history: $storageError');
}

if (!mounted) return;

setState(() {
  _storyData = data;
  _savedStoryId = savedStoryId;
  _isLoading = false;
});
      } else {
        String message =
            'The server returned an error '
            '(${response.statusCode}).';

        try {
          final errorData = jsonDecode(response.body);

          if (errorData is Map &&
              errorData['error'] is String) {
            message = errorData['error'] as String;
          }
        } catch (_) {
          // Keep the default error message.
        }

        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to generate the story. '
            'Please check your connection and try again.';
        _isLoading = false;
      });

      debugPrint('Story generation error: $error');
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

Future<void> _saveQuizResult() async {
  final id = _savedStoryId;
  final questions = _storyData?['questions'];

  if (id == null || questions is! List || questions.isEmpty) {
    return;
  }

  if (_selectedAnswers.length != questions.length) {
    return;
  }

  var score = 0;

  for (var i = 0; i < questions.length; i++) {
    final question = questions[i];

    if (question is Map &&
        _selectedAnswers[i] == question['correctAnswer']) {
      score++;
    }
  }

  try {
    await StoryHistoryService.saveQuizResult(
      id: id,
      score: score,
      total: questions.length,
    );
  } catch (error) {
    debugPrint('Could not save quiz result: $error');
  }
}

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF9F0);
    const green = Color(0xFF4F8A52);
    const darkGreen = Color(0xFF285C38);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: darkGreen,
        elevation: 0,
        title: const Text(
          'AI Story Adventure',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F1FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 56,
                      color: darkGreen,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Your Next Adventure!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your own story and test '
                      'your understanding with fun questions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              
              const Text(
                'Number of questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<int>(
                initialValue: _questionCount,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.quiz_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 3,
                    child: Text('3 questions - Quick practice'),
                  ),
                  DropdownMenuItem(
                    value: 5,
                    child: Text('5 questions - Standard practice'),
                  ),
                  DropdownMenuItem(
                    value: 10,
                    child: Text('10 questions - Extra practice'),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _questionCount = value;
                          });
                        }
                      },
              ),


              const Text(
                'What would you like to read about?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _topicController,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'e.g. A rabbit in a magical garden',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.edit_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Story language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'English',
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: 'Bahasa Melayu',
                    child: Text('Bahasa Melayu'),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _language = value;
                          });
                        }
                      },
              ),

              const SizedBox(height: 22),

              const Text(
                'Reading difficulty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _difficulty,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Easy',
                    child: Text('Easy'),
                  ),
                  DropdownMenuItem(
                    value: 'Medium',
                    child: Text('Medium'),
                  ),
                  DropdownMenuItem(
                    value: 'Advanced',
                    child: Text('Advanced'),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _difficulty = value;
                          });
                        }
                      },
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : _generateStory,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  _isLoading
                      ? 'Creating your story...'
                      : 'Generate Story',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  minimumSize:
                      const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
              ),

              if (_isLoading) ...[
                const SizedBox(height: 24),
                const Center(
                  child: CircularProgressIndicator(
                    color: green,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your adventure is being created...',
                  textAlign: TextAlign.center,
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],

              if (_storyData != null) ...[
                const SizedBox(height: 28),
                _buildStoryResult(darkGreen),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryResult(Color darkGreen) {
    final title = _storyData!['title'].toString();
    final story = _storyData!['story'].toString();

    final questions =
        _storyData!['questions'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF4F8A52),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'YOUR STORY',
                    style: TextStyle(
                      color: Color(0xFF4F8A52),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                       builder: (_) => StoryReadingScreen(
  title: title,
  story: story,
  language: _language,
),
                      ),
                    );
                  },
                  icon: const Icon(Icons.headphones_rounded),
                  label: const Text('Read Story with Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8A52),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),


              Text(
                title,
                style: TextStyle(
                  fontSize: 25,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                story,
                
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.8,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Check Your Understanding',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Choose an answer for each question.',
          style: TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 16),

        ...List.generate(questions.length, (index) {
          final questionData = questions[index];

          if (questionData is! Map) {
            return const SizedBox.shrink();
          }

          final question =
              questionData['question']?.toString() ??
              'Question ${index + 1}';

          final options =
              questionData['options'] is List
                  ? List<dynamic>.from(
                      questionData['options'] as List,
                    )
                  : <dynamic>[];

          final correctAnswer =
              questionData['correctAnswer'];

          final hasAnswered =
              _selectedAnswers.containsKey(index);

          final isCorrect =
              hasAnswered &&
              _selectedAnswers[index] == correctAnswer;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF4F8A52),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                RadioGroup<int>(
                  groupValue: _selectedAnswers[index],
                  onChanged: (value) {
  if (value == null || hasAnswered) return;

setState(() {
  _selectedAnswers[index] = value;
});

if (_selectedAnswers.length == questions.length) {
  _saveQuizResult();
}
},
                  child: Column(
                    children: List.generate(
                      options.length,
                      (optionIndex) {
                        return RadioListTile<int>(
                          value: optionIndex,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            options[optionIndex].toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                if (hasAnswered) ...[
                  const SizedBox(height: 8),

                  Text(
                    isCorrect
                        ? 'Correct! Well done!'
                        : 'Not quite. Review the explanation below.',
                    style: TextStyle(
                      color: isCorrect
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    questionData['explanation']?.toString() ??
                        'Review the story to find the answer.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        if (questions.isNotEmpty &&
            _selectedAnswers.length == questions.length) ...[
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE4F1FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 44,
                  color: Color(0xFF4F8A52),
                ),

                const SizedBox(height: 8),

                Text(
                  'Adventure Complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Score: ${questions.asMap().entries.where((entry) {
                    final data = entry.value;

                    return data is Map &&
                        _selectedAnswers[entry.key] ==
                            data['correctAnswer'];
                  }).length} / ${questions.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
