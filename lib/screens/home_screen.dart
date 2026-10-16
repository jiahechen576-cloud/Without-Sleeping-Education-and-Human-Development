
import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/settings_service.dart';
import '../services/app_language.dart';
import 'reading_screen.dart';
import 'scan_screen.dart';
import 'trace_screen.dart';
import 'speak_screen.dart';
import 'settings_screen.dart';
import 'word_garden_screen.dart';
import 'ai_story_adventure_screen.dart';
import 'story_history_screen.dart';

// ============================================================
// READRABBIT HOME SCREEN
// UI REDESIGN - EXISTING NAVIGATION PRESERVED
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color cream = Color(0xFFFFF9F0);
  static const Color green = Color(0xFF2D5A3D);
  static const Color lightGreen = Color(0xFFE8F3E8);
  static const Color darkText = Color(0xFF263629);
  static const Color mutedText = Color(0xFF738074);
  static const Color cardBorder = Color(0xFFEAE8DF);

  String _language = 'English';

  bool get _isBM => _language == 'Bahasa Melayu';

  String _t(String english, String malay) {
    return _isBM ? malay : english;
  }

  @override
  void initState() {
    super.initState();
    appLanguage.addListener(_handleLanguageChanged);
    _loadLanguage();
  }

  void _handleLanguageChanged() {
    if (!mounted) return;

    setState(() {
      _language = appLanguage.value;
    });
  }

  Future<void> _loadLanguage() async {
    try {
      final language = await SettingsService.getLanguage();

      if (!mounted) return;

      appLanguage.value = language;

      setState(() {
        _language = language;
      });
    } catch (error) {
      debugPrint('Unable to load app language: $error');
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );

    await _loadLanguage();
  }

  void _navigate(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: darkText,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: mutedText,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDay(String day, bool completed) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: completed ? green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed
                  ? green
                  : const Color(0xFFD7DFD5),
              width: 1.2,
            ),
          ),
          child: Icon(
            completed ? Icons.check_rounded : Icons.circle_outlined,
            size: 18,
            color: completed ? Colors.white : Colors.black26,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                completed ? FontWeight.w700 : FontWeight.w500,
            color: completed ? green : mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: green.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: green, size: 21),
            ),
            const SizedBox(height: 9),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: green,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 158),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: green.withValues(alpha: 0.055),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: green, size: 25),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: green.withValues(alpha: 0.65),
                    size: 19,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: mutedText,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideFeatureCard({
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color borderColor,
    required Widget trailing,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    appLanguage.removeListener(_handleLanguageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: const Center(
                      child: Text(
                        '🐰',
                        style: TextStyle(fontSize: 31),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ReadRabbit',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                            color: green,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _t(
                            'Your reading companion',
                            'Teman membaca anda',
                          ),
                          style: const TextStyle(
                            color: mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openSettings,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: green,
                          size: 23,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 29),

              // ------------------------------------------------
              // GREETING
              // ------------------------------------------------
              Text(
                _t(
                  'Good morning, Sam! 🌟',
                  'Selamat pagi, Sam! 🌟',
                ),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _t(
                  'Every little step makes you a stronger reader.',
                  'Setiap langkah kecil menjadikan anda pembaca '
                  'yang lebih baik.',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: mutedText,
                ),
              ),

              const SizedBox(height: 23),

              // ------------------------------------------------
              // READING STREAK
              // ------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD9E9D9),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 47,
                          height: 47,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFED9145),
                            size: 29,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(
                                  '7-Day Reading Streak!',
                                  'Rekod Membaca 7 Hari!',
                                ),
                                style: const TextStyle(
                                  color: green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _t(
                                  'You are building a great habit.',
                                  'Anda sedang membina tabiat yang baik.',
                                ),
                                style: const TextStyle(
                                  color: mutedText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 21),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDay(_t('Mon', 'Isn'), true),
                        _buildDay(_t('Tue', 'Sel'), true),
                        _buildDay(_t('Wed', 'Rab'), true),
                        _buildDay(_t('Thu', 'Kha'), true),
                        _buildDay(_t('Fri', 'Jum'), true),
                        _buildDay(_t('Sat', 'Sab'), true),
                        _buildDay(_t('Sun', 'Aha'), false),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 23),

              // ------------------------------------------------
              // STATISTICS
              // ------------------------------------------------
              _sectionTitle(
                _t('Your Progress', 'Kemajuan Anda'),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  _buildStatCard(
                    '1,248',
                    _t('Words Read', 'Perkataan'),
                    Icons.menu_book_rounded,
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    '23',
                    _t('Sessions', 'Sesi'),
                    Icons.timer_outlined,
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    '47',
                    _t('Stars', 'Bintang'),
                    Icons.star_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 29),

              // ------------------------------------------------
              // QUICK START
              // ------------------------------------------------
              _sectionTitle(
                _t('Quick Start 🚀', 'Mula Pantas 🚀'),
                subtitle: _t(
                  'Choose an activity to get started.',
                  'Pilih aktiviti untuk bermula.',
                ),
              ),
              const SizedBox(height: 15),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.menu_book_rounded,
                      title: _t('Read a Story', 'Baca Cerita'),
                      subtitle: _t(
                        'Karaoke + Ruler',
                        'Karaoke + Pembaris',
                      ),
                      color: const Color(0xFFE6EEFF),
                      onTap: () => _navigate(
                        const ReadingScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.document_scanner_outlined,
                      title: _t('Scan Text', 'Imbas Teks'),
                      subtitle: _t(
                        'Scan printed text',
                        'Imbas teks bercetak',
                      ),
                      color: const Color(0xFFFFE9D9),
                      onTap: () => _navigate(
                        const ScanScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.draw_outlined,
                      title: _t('Trace Letters', 'Jejak Huruf'),
                      subtitle: _t(
                        'Practise with your finger',
                        'Berlatih dengan jari',
                      ),
                      color: const Color(0xFFF4E5FF),
                      onTap: () => _navigate(
                        const TraceScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.mic_none_rounded,
                      title: _t('Speak & Write', 'Cakap & Tulis'),
                      subtitle: _t(
                        'Turn speech into text',
                        'Tukar suara kepada teks',
                      ),
                      color: const Color(0xFFFFE4EC),
                      onTap: () => _navigate(
                        const SpeakScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const SizedBox(height: 12),


          // ------------------------------------------------
          // AI STORY ADVENTURE
          // ------------------------------------------------
          _buildWideFeatureCard(
            leading: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: green,
                size: 31,
              ),
            ),
            title: _t(
              'AI Story Adventure ✨',
              'Pengembaraan Cerita AI ✨',
            ),
            subtitle: _t(
              'Create your own story, practise reading, '
              'and answer fun comprehension questions.',
              'Cipta cerita sendiri, berlatih membaca dan '
              'jawab soalan pemahaman yang menyeronokkan.',
            ),
            onTap: () => _navigate(
              const AiStoryAdventureScreen(),
            ),
            backgroundColor: const Color(0xFFE6EEFF),
            borderColor: const Color(0xFFCCD9F5),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: green,
              size: 17,
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------
          // MY STORY HISTORY
          // ------------------------------------------------
          _buildWideFeatureCard(
            leading: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: green,
                size: 31,
              ),
            ),
            title: _t(
              'My Story History 📚',
              'Sejarah Cerita Saya 📚',
            ),
            subtitle: _t(
              'Revisit saved stories, check reading progress, '
              'and review your quiz scores.',
              'Baca semula cerita tersimpan, semak kemajuan '
              'membaca dan lihat markah kuiz.',
            ),
            onTap: () => _navigate(
              const StoryHistoryScreen(),
            ),
            backgroundColor: const Color(0xFFE5F3E7),
            borderColor: const Color(0xFFC6E2CB),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: green,
              size: 17,
            ),
          ),

              // ------------------------------------------------
              // AI ASSISTANT
              // ------------------------------------------------
              _sectionTitle(
                _t('Your Reading Buddy 💚', 'Rakan Membaca Anda 💚'),
                subtitle: _t(
                  'Need help understanding something?',
                  'Perlukan bantuan memahami sesuatu?',
                ),
              ),
              const SizedBox(height: 14),

              _buildWideFeatureCard(
                leading: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Center(
                    child: Text(
                      '🐰',
                      style: TextStyle(fontSize: 34),
                    ),
                  ),
                ),
                title: _t(
                  'ReadRabbit Buddy 🇲🇾',
                  'ReadRabbit Buddy 🇲🇾',
                ),
                subtitle: _t(
                  'Ask about words, simplify sentences, '
                  'or explore a story in English or Bahasa Melayu.',
                  'Tanya tentang perkataan, mudahkan ayat '
                  'atau fahami cerita dalam Bahasa Melayu atau English.',
                ),
                onTap: () => _navigate(
                  const BahasaMelayuChatScreen(),
                ),
                backgroundColor: const Color(0xFFE5F3E7),
                borderColor: const Color(0xFFC6E2CB),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: green,
                  size: 17,
                ),
              ),

              const SizedBox(height: 29),

              // ------------------------------------------------
              // WORD GARDEN
              // ------------------------------------------------
              _sectionTitle(
                _t('My Word Garden 🌱', 'Taman Perkataan Saya 🌱'),
                subtitle: _t(
                  'Keep track of the words you learn.',
                  'Simpan dan ulang kaji perkataan yang dipelajari.',
                ),
              ),
              const SizedBox(height: 14),

              _buildWideFeatureCard(
                leading: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: green,
                    size: 31,
                  ),
                ),
                title: _t(
                  'Grow your vocabulary',
                  'Kembangkan kosa kata',
                ),
                subtitle: _t(
                  'Save difficult words, simple meanings, '
                  'and example sentences in one place.',
                  'Simpan perkataan sukar, maksud mudah dan '
                  'ayat contoh di satu tempat.',
                ),
                onTap: () => _navigate(
                  const WordGardenScreen(),
                ),
                backgroundColor: const Color(0xFFF0EBDD),
                borderColor: const Color(0xFFE3D8C2),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: green,
                  size: 17,
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // LAST READING SESSION
              // ------------------------------------------------
              _sectionTitle(
                _t('Pick Up Where You Left Off 📖',
                    'Sambung Bacaan Anda 📖'),
                subtitle: _t(
                  'Your last reading adventure.',
                  'Pengembaraan membaca anda yang terakhir.',
                ),
              ),
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: green.withValues(alpha: 0.035),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 55,
                          height: 65,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6EEFF),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: green,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(
                                  'The Garden Adventure',
                                  'Pengembaraan di Taman',
                                ),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: darkText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _t(
                                  'Yesterday · 12 min',
                                  'Semalam · 12 minit',
                                ),
                                style: const TextStyle(
                                  color: mutedText,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: lightGreen,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  _t(
                                    '40% completed',
                                    '40% selesai',
                                  ),
                                  style: const TextStyle(
                                    color: green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _t('Reading progress', 'Kemajuan membaca'),
                          style: const TextStyle(
                            color: mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _t('Page 4 of 10', 'Halaman 4 daripada 10'),
                          style: const TextStyle(
                            color: green,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const LinearProgressIndicator(
                        value: 0.4,
                        minHeight: 9,
                        backgroundColor: Color(0xFFECEFE9),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(green),
                      ),
                    ),
                    const SizedBox(height: 19),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigate(
                          const ReadingScreen(),
                        ),
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          size: 23,
                        ),
                        label: Text(
                          _t(
                            'Continue Reading',
                            'Sambung Membaca',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // FOOTER
              // ------------------------------------------------
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFF83A88A),
                      size: 19,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _t(
                        'Every reader grows at their own pace.',
                        'Setiap pembaca berkembang mengikut rentak sendiri.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: mutedText,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BAHASA MELAYU AI CHAT SCREEN
// EXISTING CHAT FUNCTIONALITY PRESERVED
// ============================================================

class BahasaMelayuChatScreen extends StatefulWidget {
  const BahasaMelayuChatScreen({super.key});

  @override
  State<BahasaMelayuChatScreen> createState() =>
      _BahasaMelayuChatScreenState();
}

class _BahasaMelayuChatScreenState
    extends State<BahasaMelayuChatScreen> {
  static const Color backgroundColor = Color(0xFFF4F8F2);
  static const Color green = Color(0xFF2D5A3D);
  static const Color assistantBubble = Color(0xFFE5F3E7);

  String _t(String english, String malay) {
    return appLanguage.value == 'Bahasa Melayu' ? malay : english;
  }

  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _chatTts = FlutterTts();
  final stt.SpeechToText _chatSpeech = stt.SpeechToText();

  final List<Map<String, String>> _messages = [];

  bool _isListening = false;
  bool _isLoading = false;
  bool _aiReadAloud = false;
  bool _highContrast = false;
  bool _dyslexiaLayout = true;

  double _fontSize = 22;
  double _letterSpacing = 1.2;
  double _lineSpacing = 1.5;

  @override
  void initState() {
    super.initState();
    _loadChatSettings();
  }

  Future<void> _loadChatSettings() async {
    try {
      final fontSize = await SettingsService.getFontSize();
      final letterSpacing =
          await SettingsService.getLetterSpacing();
      final lineSpacing = await SettingsService.getLineSpacing();
      final highContrast =
          await SettingsService.getHighContrast();
      final dyslexiaLayout =
          await SettingsService.getDyslexiaLayout();
      final aiReadAloud =
          await SettingsService.getAiReadAloud();

      if (!mounted) return;

      setState(() {
        _fontSize = fontSize.clamp(16.0, 32.0).toDouble();
        _letterSpacing =
            letterSpacing.clamp(0.0, 3.0).toDouble();
        _lineSpacing =
            lineSpacing.clamp(1.0, 2.5).toDouble();
        _highContrast = highContrast;
        _dyslexiaLayout = dyslexiaLayout;
        _aiReadAloud = aiReadAloud;
      });

      if (!_aiReadAloud) {
        await _chatTts.stop();
      }
    } catch (error) {
      debugPrint('Unable to load chat settings: $error');
    }
  }

  String _cleanTextForSpeech(String text) {
    return text
        .replaceAll(
          RegExp(r'!\[([^\]]*)\]\([^)]+\)'),
          '',
        )
        .replaceAll(
          RegExp(r'\[([^\]]+)\]\([^)]+\)'),
          r'$1',
        )
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'[*_\~\`]'), '')
        .replaceAll(
          RegExp(
            r'[\u{1F000}-\u{1FAFF}'
            r'\u{2600}-\u{27BF}'
            r'\u{2300}-\u{23FF}'
            r'\u{2B00}-\u{2BFF}'
            r'\u{FE00}-\u{FE0F}'
            r'\u{1F1E6}-\u{1F1FF}'
            r'\u{1F3FB}-\u{1F3FF}'
            r'\u{200D}'
            r'\u{20E3}]',
            unicode: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r' *\n *'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<void> _speakAssistantReply(
    String reply, {
    bool force = false,
  }) async {
    if ((!_aiReadAloud && !force) || reply.trim().isEmpty) {
      return;
    }

    try {
      await _chatTts.stop();
      await _chatTts.setSpeechRate(0.45);
      await _chatTts.setPitch(1.0);

      final cleanReply = _cleanTextForSpeech(reply);
      if (cleanReply.isEmpty) return;

      try {
        await _chatTts.setLanguage('ms-MY');
      } catch (_) {
        await _chatTts.setLanguage('en-US');
      }

      await _chatTts.speak(cleanReply);
    } catch (error) {
      debugPrint('Text-to-speech error: $error');
    }
  }

  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _explainWord(
    String word,
    String originalReply,
  ) async {
    if (_isLoading || word.trim().isEmpty) return;

    final prompt =
        'Explain the meaning of "$word" in the context of this text:\n'
        '"$originalReply"\n\n'
        'Explain it using simple, dyslexia-friendly language. '
        'Reply in the same language as the original text. '
        'Give a short explanation and one simple example. '
        'Do not use emojis.';

    await _sendMessage(
      messageOverride: prompt,
      wordToSave: word,
    );
  }

  Future<void> _toggleChatListening() async {
    if (_isLoading) return;

    if (_isListening) {
      await _chatSpeech.stop();

      if (mounted) {
        setState(() => _isListening = false);
      }

      return;
    }

    try {
      final available = await _chatSpeech.initialize(
        onStatus: (status) {
          debugPrint('Chat speech status: $status');

          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (error) {
          debugPrint('Chat speech error: $error');

          if (!mounted) return;

          setState(() => _isListening = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _t(
                  'Speech recognition error. Please check your '
                  'microphone permission and try again.',
                  'Ralat pengecaman suara. Sila semak kebenaran '
                  'mikrofon dan cuba lagi.',
                ),
              ),
            ),
          );
        },
      );

      if (!mounted) return;

      if (!available) {
        setState(() => _isListening = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Speech recognition is unavailable. Please check '
                'your microphone permission and device settings.',
                'Pengecaman suara tidak tersedia. Sila semak '
                'kebenaran mikrofon dan tetapan peranti anda.',
              ),
            ),
          ),
        );

        return;
      }

      final locales = await _chatSpeech.locales();

      if (!mounted) return;

      final preferredLanguage =
          appLanguage.value == 'Bahasa Melayu' ? 'ms' : 'en';

      String? selectedLocaleId;

      for (final locale in locales) {
        if (locale.localeId
            .toLowerCase()
            .startsWith(preferredLanguage)) {
          selectedLocaleId = locale.localeId;
          break;
        }
      }

      if (selectedLocaleId == null && locales.isNotEmpty) {
        selectedLocaleId = locales.first.localeId;

        debugPrint(
          'Preferred speech language $preferredLanguage unavailable. '
          'Using $selectedLocaleId instead.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Your preferred speech language is unavailable. '
                'Using another available language.',
                'Bahasa pilihan tidak tersedia. Menggunakan bahasa '
                'lain yang tersedia.',
              ),
            ),
          ),
        );
      }

      if (selectedLocaleId == null) {
        setState(() => _isListening = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'No speech-recognition language is available.',
                'Tiada bahasa pengecaman suara tersedia.',
              ),
            ),
          ),
        );

        return;
      }

      debugPrint(
        'Using speech-recognition locale: $selectedLocaleId',
      );

      setState(() => _isListening = true);

      await _chatSpeech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: selectedLocaleId,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
        ),
        onResult: (result) {
          final recognisedText = result.recognizedWords;

          debugPrint(
            'Recognised speech: "$recognisedText", '
            'final: ${result.finalResult}',
          );

          if (!mounted || recognisedText.isEmpty) return;

          setState(() {
            _messageController.value = TextEditingValue(
              text: recognisedText,
              selection: TextSelection.collapsed(
                offset: recognisedText.length,
              ),
            );
          });
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to start chat voice input: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => _isListening = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Unable to start voice input. Please try again.',
              'Tidak dapat memulakan input suara. Sila cuba lagi.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _simplifyAnswer(String answer) async {
    if (_isLoading || answer.trim().isEmpty) return;

    final prompt =
        'Simplify the following answer in the same language. '
        'Use familiar words and shorter sentences. '
        'Keep the original meaning:\n\n$answer';

    await _sendMessage(messageOverride: prompt);
  }

  Future<void> _saveReplyToWordGarden(
    String reply, {
    String? suggestedWord,
  }) async {
    final wordController =
        TextEditingController(text: suggestedWord ?? '');
    final meaningController = TextEditingController(text: reply);
    final exampleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _t(
              'Save to My Word Garden 🌱',
              'Simpan ke Taman Perkataan Saya 🌱',
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: wordController,
                    autofocus: suggestedWord == null,
                    decoration: InputDecoration(
                      labelText: _t(
                        'Word or phrase',
                        'Perkataan atau frasa',
                      ),
                      hintText: _t(
                        'Enter the difficult word',
                        'Masukkan perkataan yang sukar',
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: meaningController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: _t(
                        'Simple meaning',
                        'Maksud mudah',
                      ),
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _t(
                          'Please enter a meaning.',
                          'Sila masukkan maksud.',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: exampleController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: _t(
                        'Example sentence (optional)',
                        'Ayat contoh (pilihan)',
                      ),
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_t('Cancel', 'Batal')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(dialogContext, {
                  'word': wordController.text.trim(),
                  'meaning': meaningController.text.trim(),
                  'example': exampleController.text.trim(),
                  'language': appLanguage.value,
                });
              },
              child: Text(_t('Save word', 'Simpan perkataan')),
            ),
          ],
        );
      },
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    wordController.dispose();
    meaningController.dispose();
    exampleController.dispose();

    if (result == null || !mounted) return;

    try {
      const storageKey = 'readrabbit_word_garden_v1';
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(storageKey);

      final List<dynamic> decoded = savedData == null
          ? <dynamic>[]
          : jsonDecode(savedData) as List<dynamic>;

      final words = decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final newWord = <String, String>{
        'word': result['word']!,
        'meaning': result['meaning']!,
        'example': result['example']!,
        'language': result['language']!,
      };

      final existingIndex = words.indexWhere(
        (item) =>
            (item['word']?.toString() ?? '')
                .trim()
                .toLowerCase() ==
            result['word']!.trim().toLowerCase(),
      );

      if (existingIndex >= 0) {
        words[existingIndex] = newWord;
      } else {
        words.insert(0, newWord);
      }

      await prefs.setString(storageKey, jsonEncode(words));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingIndex >= 0
                ? _t(
                    'Word updated in your garden.',
                    'Perkataan dikemas kini dalam taman anda.',
                  )
                : _t(
                    'Word saved to My Word Garden! 🌱',
                    'Perkataan disimpan ke Taman Perkataan Saya! 🌱',
                  ),
          ),
        ),
      );
    } catch (error) {
      debugPrint('Unable to save word to Word Garden: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Could not save the word. Please try again.',
              'Perkataan tidak dapat disimpan. Sila cuba lagi.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _copyAnswer(String answer) async {
    if (answer.trim().isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: answer),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Answer copied successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _startNewChat() async {
    if (_isLoading) return;

    await _chatTts.stop();
    await _chatSpeech.stop();

    if (!mounted) return;

    setState(() {
      _messages.clear();
      _messageController.clear();
      _isListening = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perbualan baharu telah dimulakan.'),
      ),
    );
  }

  @override
  void dispose() {
    _chatSpeech.stop();
    _chatTts.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foregroundColor = _highContrast
        ? Colors.white
        : const Color(0xFF1F3D2A);

    return Scaffold(
      backgroundColor:
          _highContrast ? Colors.black : backgroundColor,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ReadRabbit Buddy 🇲🇾',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Pembantu membaca anda',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New Chat',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _isLoading ? null : _startNewChat,
          ),
          IconButton(
            tooltip: 'Refresh reading settings',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadChatSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome(foregroundColor)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading &&
                          index == _messages.length) {
                        return _buildLoadingIndicator();
                      }

                      return _buildMessageBubble(
                        _messages[index],
                        foregroundColor,
                      );
                    },
                  ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildWelcome(Color foregroundColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _highContrast
                    ? Colors.black
                    : assistantBubble,
                shape: BoxShape.circle,
                border: _highContrast
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: const Center(
                child: Text(
                  '🐰',
                  style: TextStyle(fontSize: 52),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hai! Saya ReadRabbit Buddy 💚',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
                color: foregroundColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Saya boleh membantu anda memahami perkataan, '
              'memudahkan ayat dan menerangkan cerita. '
              'Anda boleh bertanya dalam Bahasa Melayu atau English.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _fontSize,
                letterSpacing:
                    _dyslexiaLayout ? _letterSpacing : 0,
                height: _lineSpacing,
                color: foregroundColor,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestion('Apakah maksud perkataan ini?'),
                _buildSuggestion('Terangkan dengan lebih mudah'),
                _buildSuggestion('Explain this in simple English'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String suggestion) {
    return ActionChip(
      label: Text(
        suggestion,
        style: TextStyle(
          color: _highContrast ? Colors.white : green,
          fontSize: _fontSize.clamp(12.0, 18.0).toDouble(),
        ),
      ),
      onPressed: _isLoading
          ? null
          : () {
              _messageController.text = suggestion;
              _sendMessage();
            },
      backgroundColor:
          _highContrast ? Colors.black : Colors.white,
      side: BorderSide(
        color: _highContrast ? Colors.white : const Color(0xFFD4E5D5),
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, String> message,
    Color foregroundColor,
  ) {
    final isUser = message['role'] == 'user';
    final text = message['text'] ?? '';

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? green
              : (_highContrast ? Colors.black : assistantBubble),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(isUser ? 17 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 17),
          ),
          border: _highContrast
              ? Border.all(color: Colors.white, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUser)
              Text(
                text,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: _fontSize,
                  letterSpacing:
                      _dyslexiaLayout ? _letterSpacing : 0,
                  height: _lineSpacing,
                  color: Colors.white,
                ),
              )
            else
              _TappableAssistantText(
                key: ValueKey(text),
                text: text,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: _fontSize,
                  letterSpacing:
                      _dyslexiaLayout ? _letterSpacing : 0,
                  height: _lineSpacing,
                  color: foregroundColor,
                ),
                onWordTap: (word) => _explainWord(word, text),
              ),
            if (!isUser) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _simplifyAnswer(text),
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                    ),
                    label: const Text('Simplify This Answer'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _highContrast ? Colors.white : green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _saveReplyToWordGarden(
                              text,
                              suggestedWord: message['wordToSave'],
                            ),
                    icon: const Icon(
                      Icons.spa_outlined,
                      size: 18,
                    ),
                    label: Text(_t('Save word', 'Simpan perkataan')),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _highContrast ? Colors.white : green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _speakAssistantReply(text),
                    icon: const Icon(
                      Icons.volume_up_outlined,
                      size: 18,
                    ),
                    label: const Text('Read aloud'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _highContrast ? Colors.white : green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _copyAnswer(text),
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 18,
                    ),
                    label: const Text('Copy Answer'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _highContrast ? Colors.white : green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _highContrast ? Colors.black : assistantBubble,
          borderRadius: BorderRadius.circular(16),
          border: _highContrast
              ? Border.all(color: Colors.white, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _highContrast ? Colors.white : green,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Sedang berfikir...',
              style: TextStyle(
                color: _highContrast ? Colors.white : green,
                fontSize: _fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: _highContrast ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: _highContrast ? Colors.white : Colors.grey.shade200,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: _isListening ? 'Stop microphone' : 'Speak',
              onPressed: _isLoading ? null : _toggleChatListening,
              icon: Icon(
                _isListening
                    ? Icons.mic
                    : Icons.mic_none_rounded,
                color: _isListening
                    ? Colors.red
                    : (_highContrast ? Colors.white : green),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: _fontSize,
                  letterSpacing:
                      _dyslexiaLayout ? _letterSpacing : 0,
                  height: _lineSpacing,
                  color: _highContrast ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Taip soalan anda di sini...',
                  hintStyle: TextStyle(
                    color: _highContrast
                        ? Colors.white70
                        : Colors.black54,
                  ),
                  filled: true,
                  fillColor:
                      _highContrast ? Colors.black : backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: _highContrast
                          ? Colors.white
                          : Colors.transparent,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: _highContrast
                          ? Colors.white
                          : green,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) {
                  if (!_isLoading) _sendMessage();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send message',
              onPressed: _isLoading ? null : _sendMessage,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage({
    String? messageOverride,
    String? wordToSave,
  }) async {
    final message =
        (messageOverride ?? _messageController.text).trim();

    if (message.isEmpty || _isLoading) return;

    final history = _messages.map((item) {
      return <String, String>{
        'role': item['role']!,
        'content': item['text']!,
      };
    }).toList();

    setState(() {
      _messages.add({
        'role': 'user',
        'text': message,
      });

      if (messageOverride == null) {
        _messageController.clear();
      }

      _isLoading = true;
    });

    _scrollToLatestMessage();

    try {
      final response = await http
          .post(
            Uri.parse('http://10.0.2.2:3000/chat'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'message': message,
              'history': history,
              'preferences': {
                'fontSize': _fontSize,
                'letterSpacing': _letterSpacing,
                'lineSpacing': _lineSpacing,
                'highContrast': _highContrast,
                'dyslexiaLayout': _dyslexiaLayout,
              },
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['reply']?.toString() ?? 'Tiada jawapan diterima.';

        setState(() {
          final assistantMessage = <String, String>{
            'role': 'assistant',
            'text': reply,
          };

          if (wordToSave != null) {
            assistantMessage['wordToSave'] = wordToSave;
          }

          _messages.add(assistantMessage);
        });

        _scrollToLatestMessage();
        await _speakAssistantReply(reply);
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text':
                'Maaf, ReadRabbit Buddy menghadapi masalah '
                '(kod ${response.statusCode}). Sila cuba lagi.',
          });
        });

        _scrollToLatestMessage();
      }
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'text':
              'Permintaan mengambil masa terlalu lama. '
              'Sila cuba lagi.',
        });
      });

      _scrollToLatestMessage();
    } catch (error) {
      debugPrint('Chat request error: $error');

      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'text':
              'Tidak dapat menyambung ke ReadRabbit Buddy. '
              'Pastikan backend sedang berjalan dan cuba lagi.',
        });
      });

      _scrollToLatestMessage();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ============================================================
// TAPPABLE WORDS IN ASSISTANT REPLIES
// EXISTING WORD-TAP FUNCTIONALITY PRESERVED
// ============================================================

class _TappableAssistantText extends StatefulWidget {
  const _TappableAssistantText({
    super.key,
    required this.text,
    required this.style,
    required this.onWordTap,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final ValueChanged<String> onWordTap;

  @override
  State<_TappableAssistantText> createState() =>
      _TappableAssistantTextState();
}

class _TappableAssistantTextState
    extends State<_TappableAssistantText> {
  final List<TapGestureRecognizer> _recognizers = [];

  static final RegExp _wordCharacters = RegExp(
    r'[A-Za-z0-9À-ÖØ-öø-ÿĀ-ž]',
  );

  static final RegExp _trimWordPunctuation = RegExp(
    r'^[^A-Za-z0-9À-ÖØ-öø-ÿĀ-ž]+|'
    r'[^A-Za-z0-9À-ÖØ-öø-ÿĀ-ž]+$',
  );

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }

    _recognizers.clear();
  }

  List<TextSpan> _buildSpans() {
    final spans = <TextSpan>[];

    final tokens = RegExp(r'\s+|[^\s]+')
        .allMatches(widget.text)
        .map((match) => match.group(0)!)
        .toList();

    for (final token in tokens) {
      if (token.trim().isEmpty) {
        spans.add(TextSpan(text: token));
        continue;
      }

      final word = token.replaceAll(_trimWordPunctuation, '');

      if (word.isEmpty || !_wordCharacters.hasMatch(word)) {
        spans.add(TextSpan(text: token));
        continue;
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onWordTap(word);

      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: token,
          style: widget.style.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: widget.style.color,
          ),
          recognizer: recognizer,
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    return Text.rich(
      TextSpan(
        style: widget.style,
        children: _buildSpans(),
      ),
      textAlign: widget.textAlign,
    );
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }
}
