
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/app_language.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _readingRuler = true;
  bool _readAloud = true;
  bool _dyslexiaLayout = true;
  bool _highContrast = false;
  bool _aiReadAloud = false;

  double _fontSize = 22;
  double _letterSpacing = 1.2;
  double _lineSpacing = 1.5;
  double _speechRate = 0.45;

  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final readingRuler = await SettingsService.getReadingRuler();
    final readAloud = await SettingsService.getReadAloud();
    final dyslexiaLayout = await SettingsService.getDyslexiaLayout();
    final highContrast = await SettingsService.getHighContrast();
    final aiReadAloud = await SettingsService.getAiReadAloud();

    final fontSize = await SettingsService.getFontSize();
    final letterSpacing = await SettingsService.getLetterSpacing();
    final lineSpacing = await SettingsService.getLineSpacing();
    final speechRate = await SettingsService.getSpeechRate();
    final language = await SettingsService.getLanguage();

    if (!mounted) return;

    setState(() {
      _readingRuler = readingRuler;
      _readAloud = readAloud;
      _dyslexiaLayout = dyslexiaLayout;
      _highContrast = highContrast;
      _aiReadAloud = aiReadAloud;

      _fontSize = fontSize;
      _letterSpacing = letterSpacing;
      _lineSpacing = lineSpacing;
      _speechRate = speechRate;
      _language = language;
    });
  }

  Future<void> _selectLanguage() async {
    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Choose App Language'),
          children: [
            ListTile(
              leading: Icon(
                Icons.check_circle,
                color: _language == 'English'
                    ? const Color(0xFF2D5A3D)
                    : Colors.grey,
              ),
              title: const Text('English'),
              subtitle: const Text('Use English'),
              onTap: () {
                Navigator.pop(dialogContext, 'English');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check_circle,
                color: _language == 'Bahasa Melayu'
                    ? const Color(0xFF2D5A3D)
                    : Colors.grey,
              ),
              title: const Text('Bahasa Melayu'),
              subtitle: const Text('Gunakan Bahasa Melayu'),
              onTap: () {
                Navigator.pop(dialogContext, 'Bahasa Melayu');
              },
            ),
          ],
        );
      },
    );

    if (selectedLanguage == null || !mounted) return;

   if (!mounted) return;

setState(() {
  _language = selectedLanguage;
});

// Update the shared language immediately.
appLanguage.value = selectedLanguage;

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      selectedLanguage == 'English'
          ? 'App language saved: English'
          : 'Bahasa aplikasi disimpan: Bahasa Melayu',
    ),
    duration: const Duration(seconds: 2),
  ),
);

    // Update the shared language immediately.
    appLanguage.value = selectedLanguage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selectedLanguage == 'English'
              ? 'App language saved: English'
              : 'Bahasa aplikasi disimpan: Bahasa Melayu',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8F2),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF1F3D2A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          // PROFILE
          _sectionTitle('Profile'),
          _settingsCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EA),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF2D5A3D),
                  size: 28,
                ),
              ),
              title: const Text(
                'Reader Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F3D2A),
                ),
              ),
              subtitle: const Text(
                'Personalise your reading experience',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
              ),
              onTap: () {},
            ),
          ),

          const SizedBox(height: 24),

          // READING PREFERENCES
          _sectionTitle('Reading Preferences'),
          _settingsCard(
            child: Column(
              children: [
                _switchTile(
                  icon: Icons.straighten_rounded,
                  title: 'Reading Ruler',
                  subtitle: 'Highlight the line you are reading',
                  value: _readingRuler,
                  onChanged: (value) {
                    setState(() => _readingRuler = value);
                    SettingsService.saveReadingRuler(value);
                  },
                ),
                const Divider(),
                _switchTile(
                  icon: Icons.record_voice_over_rounded,
                  title: 'Read Aloud',
                  subtitle: 'Automatically enable text-to-speech',
                  value: _readAloud,
                  onChanged: (value) {
                    setState(() => _readAloud = value);
                    SettingsService.saveReadAloud(value);
                  },
                ),
                const Divider(),
                _switchTile(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Dyslexia-Friendly Layout',
                  subtitle: 'Use easier-to-read spacing and layout',
                  value: _dyslexiaLayout,
                  onChanged: (value) {
                    setState(() => _dyslexiaLayout = value);
                    SettingsService.saveDyslexiaLayout(value);
                  },
                ),
                const Divider(),
                _switchTile(
                  icon: Icons.contrast_rounded,
                  title: 'High Contrast',
                  subtitle: 'Increase visual contrast',
                  value: _highContrast,
                  onChanged: (value) {
                    setState(() => _highContrast = value);
                    SettingsService.saveHighContrast(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // FONT SIZE
          _settingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.format_size_rounded,
                      color: Color(0xFF2D5A3D),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Font Size',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F3D2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_fontSize.toStringAsFixed(0)} px',
                  style: const TextStyle(color: Colors.grey),
                ),
                Slider(
                  value: _fontSize.clamp(16.0, 32.0),
                  min: 16,
                  max: 32,
                  divisions: 16,
                  activeColor: const Color(0xFF2D5A3D),
                  onChanged: (value) {
                    setState(() => _fontSize = value);
                    SettingsService.saveFontSize(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // LETTER SPACING
          _settingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.space_bar_rounded,
                      color: Color(0xFF2D5A3D),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Letter Spacing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F3D2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _letterSpacing.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.grey),
                ),
                Slider(
                  value: _letterSpacing.clamp(0.0, 3.0),
                  min: 0,
                  max: 3,
                  divisions: 6,
                  activeColor: const Color(0xFF2D5A3D),
                  onChanged: (value) {
                    setState(() => _letterSpacing = value);
                    SettingsService.saveLetterSpacing(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // LINE SPACING
          _settingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.format_line_spacing_rounded,
                      color: Color(0xFF2D5A3D),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Line Spacing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F3D2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _lineSpacing.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.grey),
                ),
                Slider(
                  value: _lineSpacing.clamp(1.0, 2.5),
                  min: 1,
                  max: 2.5,
                  divisions: 6,
                  activeColor: const Color(0xFF2D5A3D),
                  onChanged: (value) {
                    setState(() => _lineSpacing = value);
                    SettingsService.saveLineSpacing(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // VOICE
          _sectionTitle('Voice'),
          _settingsCard(
            child: Column(
              children: [
                _switchTile(
                  icon: Icons.volume_up_rounded,
                  title: 'Read AI Responses Aloud',
                  subtitle: 'Hear responses from ReadRabbit Buddy',
                  value: _aiReadAloud,
                  onChanged: (value) async {
                    setState(() => _aiReadAloud = value);

                    await SettingsService.saveAiReadAloud(value);

                    // Check the context after the async operation.
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'AI responses aloud enabled.'
                              : 'AI responses aloud disabled.',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          color: Color(0xFF2D5A3D),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Speech Speed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F3D2A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _speechRate.toStringAsFixed(2),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Slider(
                      value: _speechRate.clamp(0.2, 0.8),
                      min: 0.2,
                      max: 0.8,
                      divisions: 6,
                      activeColor: const Color(0xFF2D5A3D),
                      onChanged: (value) {
                        setState(() => _speechRate = value);
                        SettingsService.saveSpeechRate(value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // LANGUAGE
          _sectionTitle('Language'),
          _settingsCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EA),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: Color(0xFF2D5A3D),
                ),
              ),
              title: const Text(
                'App Language',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F3D2A),
                ),
              ),
              subtitle: Text(_language),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
              ),
              onTap: _selectLanguage,
            ),
          ),

          const SizedBox(height: 24),

          // ABOUT
          _sectionTitle('About'),
          _settingsCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2D5A3D),
                  ),
                  title: const Text(
                    'About ReadRabbit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3D2A),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                  ),
                  onTap: () {},
                ),
                const Divider(),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.code_rounded,
                    color: Color(0xFF2D5A3D),
                  ),
                  title: Text(
                    'Version',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3D2A),
                    ),
                  ),
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F3D2A),
        ),
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: const Color(0xFF2D5A3D),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F3D2A),
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        activeThumbColor: Colors.green,
        onChanged: onChanged,
      ),
    );
  }
}
