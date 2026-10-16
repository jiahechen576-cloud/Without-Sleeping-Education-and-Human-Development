
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoryHistoryService {
  static const String _storageKey = 'readrabbit_story_history';

  // Get all saved stories.
  static Future<List<Map<String, dynamic>>> getStories() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStories = prefs.getStringList(_storageKey) ?? [];

    final stories = <Map<String, dynamic>>[];

    for (final savedStory in savedStories) {
      try {
        final decoded = jsonDecode(savedStory);

        if (decoded is Map) {
          stories.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Skip an invalid saved entry without losing other stories.
      }
    }

    stories.sort((a, b) {
      final aTime = a['createdAt'] as int? ?? 0;
      final bTime = b['createdAt'] as int? ?? 0;
      return bTime.compareTo(aTime);
    });

    return stories;
  }

  // Save a new story or update an existing one.
  static Future<String> saveStory({
    required String title,
    required String story,
    required String language,
    String topic = '',
    String difficulty = 'Easy',
    int questionCount = 3,
  }) async {
    final stories = await getStories();

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = now.toString();

    stories.insert(0, {
      'id': id,
      'title': title,
      'story': story,
      'language': language,
      'topic': topic,
      'difficulty': difficulty,
      'questionCount': questionCount,
      'createdAt': now,
      'status': 'not_started',
      'progress': 0,
      'quizScore': null,
      'quizTotal': null,
    });

    await _writeStories(stories);

    return id;
  }

  // Update reading progress for a saved story.
  static Future<void> updateProgress({
    required String id,
    required int progress,
    required String status,
  }) async {
    final stories = await getStories();

    final index = stories.indexWhere(
      (item) => item['id'] == id,
    );

    if (index == -1) return;

    stories[index]['progress'] = progress.clamp(0, 100);
    stories[index]['status'] = status;

    await _writeStories(stories);
  }

  // Save the quiz score for a story.
  static Future<void> saveQuizResult({
    required String id,
    required int score,
    required int total,
  }) async {
    final stories = await getStories();

    final index = stories.indexWhere(
      (item) => item['id'] == id,
    );

    if (index == -1) return;

    stories[index]['quizScore'] = score;
    stories[index]['quizTotal'] = total;

    await _writeStories(stories);
  }

  // Remove a story from history.
  static Future<void> deleteStory(String id) async {
    final stories = await getStories();

    stories.removeWhere((item) => item['id'] == id);

    await _writeStories(stories);
  }

  static Future<void> _writeStories(
    List<Map<String, dynamic>> stories,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedStories = stories
        .map((item) => jsonEncode(item))
        .toList();

    await prefs.setStringList(_storageKey, encodedStories);
  }
}
