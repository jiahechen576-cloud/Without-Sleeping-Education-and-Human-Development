import 'package:shared_preferences/shared_preferences.dart';


class SettingsService {
  static const String _readingRulerKey = 'reading_ruler';
  static const String _readAloudKey = 'read_aloud';
  static const String _dyslexiaLayoutKey = 'dyslexia_layout';
  static const String _highContrastKey = 'high_contrast';
  static const String _aiReadAloudKey = 'ai_read_aloud';

  static const String _fontSizeKey = 'font_size';
  static const String _letterSpacingKey = 'letter_spacing';
  static const String _lineSpacingKey = 'line_spacing';
  static const String _speechRateKey = 'speech_rate';
  static const String _languageKey = 'app_language';

  // Reading Ruler
  static Future<void> saveReadingRuler(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_readingRulerKey, value);
  }

  static Future<bool> getReadingRuler() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_readingRulerKey) ?? true;
  }

  // Read Aloud
  static Future<void> saveReadAloud(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_readAloudKey, value);
  }

  static Future<bool> getReadAloud() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_readAloudKey) ?? true;
  }

  // Dyslexia-Friendly Layout
  static Future<void> saveDyslexiaLayout(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dyslexiaLayoutKey, value);
  }

  static Future<bool> getDyslexiaLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dyslexiaLayoutKey) ?? true;
  }

  // High Contrast
  static Future<void> saveHighContrast(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
  }

  static Future<bool> getHighContrast() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_highContrastKey) ?? false;
  }

  // ReadRabbit Buddy: Read AI Responses Aloud
  static Future<void> saveAiReadAloud(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiReadAloudKey, value);
  }

  static Future<bool> getAiReadAloud() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_aiReadAloudKey) ?? false;
  }

  // Font Size
  static Future<void> saveFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, value);
  }

  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 22;
  }

  // Letter Spacing
  static Future<void> saveLetterSpacing(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_letterSpacingKey, value);
  }

  static Future<double> getLetterSpacing() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_letterSpacingKey) ?? 1.2;
  }

  // Line Spacing
  static Future<void> saveLineSpacing(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lineSpacingKey, value);
  }

  static Future<double> getLineSpacing() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lineSpacingKey) ?? 1.5;
  }

  // Speech Speed
  static Future<void> saveSpeechRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, value);
  }

  static Future<double> getSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_speechRateKey) ?? 0.45;
  }

  // App Language
  static Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'English';
  }
}