import 'package:flutter/material.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  bool isPlaying = false;
  bool rulerEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F0),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F0),
        elevation: 0,

        title: const Text(
          'Read a Story',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(
              rulerEnabled
                  ? Icons.border_horizontal
                  : Icons.border_horizontal_outlined,
            ),
            onPressed: () {
              setState(() {
                rulerEnabled = !rulerEnabled;
              });
            },
          ),

          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Story title
            const Text(
              'The Garden Adventure',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Chapter 1',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            // Reading area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),

                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ],
                ),

                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Sam opened the garden gate and stepped inside.',
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.8,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'The morning sun was shining brightly. '
                        'Birds were singing in the trees, and '
                        'colourful flowers filled the garden.',
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.8,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Sam smiled and wondered what adventures '
                        'were waiting ahead.',
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.8,
                        ),
                      ),

                      if (rulerEnabled) ...[
                        const SizedBox(height: 30),

                        Container(
                          height: 45,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB9DDF7)
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Reading controls
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () {},
                  ),

                  IconButton(
                    iconSize: 42,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                    ),
                    onPressed: () {
                      setState(() {
                        isPlaying = !isPlaying;
                      });
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () {},
                  ),

                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () {},
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