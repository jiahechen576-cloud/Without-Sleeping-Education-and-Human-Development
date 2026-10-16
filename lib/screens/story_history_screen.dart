
import 'package:flutter/material.dart';

import '../services/story_history_service.dart';
import 'ai_story_adventure_screen.dart';
import 'story_reading_screen.dart';

class StoryHistoryScreen extends StatefulWidget {
  const StoryHistoryScreen({super.key});

  @override
  State<StoryHistoryScreen> createState() =>
      _StoryHistoryScreenState();
}

class _StoryHistoryScreenState extends State<StoryHistoryScreen> {
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;

  static const Color _cream = Color(0xFFFFF9F0);
  static const Color _green = Color(0xFF4F8A52);
  static const Color _darkGreen = Color(0xFF285C38);

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final stories = await StoryHistoryService.getStories();

      if (!mounted) return;

      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Could not load story history: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is! int) return 'Date unavailable';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _statusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In progress';
      default:
        return 'Not started';
    }
  }

  Future<void> _deleteStory(Map<String, dynamic> story) async {
    final id = story['id']?.toString();

    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete story?'),
        content: Text(
          'Remove "${story['title']}" from your story history?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await StoryHistoryService.deleteStory(id);

      if (!mounted) return;

      setState(() {
        _stories.removeWhere((item) => item['id'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story deleted.')),
      );
    } catch (error) {
      debugPrint('Could not delete story: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete this story.'),
        ),
      );
    }
  }

  void _openStory(Map<String, dynamic> story) {
    final title = story['title']?.toString() ?? 'My Story';
    final content = story['story']?.toString() ?? '';
    

    Navigator.push(
      context,
      MaterialPageRoute(
builder: (_) => StoryReadingScreen(
  title: title,
  story: content,
  language: 'en-US',
),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _darkGreen,
        elevation: 0,
        title: const Text(
          'Story History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: _loadStories,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AiStoryAdventureScreen(),
              
            ),
            
          );

          if (mounted) {
            _loadStories();
          }
        },
        icon: const Icon(Icons.auto_stories_rounded),
        label: const Text('Create Story'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _green),
      );
    }

    if (_stories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 76,
                color: _green,
              ),
              const SizedBox(height: 16),
              const Text(
                'No stories yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your first AI adventure. '
                'Your saved stories will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStories,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];

          final title =
              story['title']?.toString() ?? 'Untitled Story';
          final language =
              story['language']?.toString() ?? 'English';
          final difficulty =
              story['difficulty']?.toString() ?? 'Easy';
          final status =
              story['status']?.toString() ?? 'not_started';
          final progress =
              (story['progress'] as num?)?.toInt() ?? 0;
          final quizScore = story['quizScore'];
          final quizTotal = story['quizTotal'];

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4F1FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: _darkGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _darkGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDate(story['createdAt'])} · '
                              '$language · $difficulty',
                              style: const TextStyle(
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete story',
                        onPressed: () => _deleteStory(story),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.flag_outlined,
                        size: 18,
                        color: _green,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_statusText(status)),
                      ),
                      Text('$progress%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0, 100) / 100,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: const Color(0xFFE8E8E8),
                    color: _green,
                  ),
                  const SizedBox(height: 12),
                  if (quizScore is num && quizTotal is num)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Quiz score: ${quizScore.toInt()} / '
                        '${quizTotal.toInt()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openStory(story),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Read Story Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
