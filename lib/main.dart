import 'package:flutter/material.dart';

import 'services/settings_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reading_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/trace_screen.dart';
import 'screens/speak_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_language.dart';

void main() {
  runApp(const ReadRabbitApp());
}

class ReadRabbitApp extends StatefulWidget {
  const ReadRabbitApp({super.key});

  @override
  State<ReadRabbitApp> createState() => _ReadRabbitAppState();
}

class _ReadRabbitAppState extends State<ReadRabbitApp> {
  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await SettingsService.getLanguage();
    appLanguage.value = language;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ReadRabbit',
          theme: ThemeData(
            useMaterial3: true,

            // ReadRabbit brand colours.
            scaffoldBackgroundColor: const Color(0xFFFFF9F0),
            fontFamily: 'Arial',

            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D4A),
              brightness: Brightness.light,
              primary: const Color(0xFF2E7D4A),
              secondary: const Color(0xFF81B784),
              surface: const Color(0xFFFFFDF8),
              onSurface: const Color(0xFF26372B),
            ),

            // Consistent AppBar styling.
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFFF9F0),
              foregroundColor: Color(0xFF26372B),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontFamily: 'Arial',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF26372B),
              ),
            ),

            // Consistent cards.
            cardTheme: CardThemeData(
              color: const Color(0xFFFFFDF8),
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(
                  color: Color(0xFFE8E8DC),
                  width: 1,
                ),
              ),
            ),

            // Consistent buttons.
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D4A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Arial',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Consistent text buttons.
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D4A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Consistent input fields.
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFFFFDF8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFD8E2D5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFD8E2D5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF2E7D4A),
                  width: 2,
                ),
              ),
            ),

            // Consistent bottom navigation styling.
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFFFFFDF8),
              indicatorColor: const Color(0xFFE5F2E5),
              elevation: 0,
              height: 72,
              labelBehavior:
                  NavigationDestinationLabelBehavior.alwaysShow,
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(
                      color: Color(0xFF2E7D4A),
                      size: 25,
                    );
                  }

                  return const IconThemeData(
                    color: Color(0xFF778278),
                    size: 23,
                  );
                },
              ),
              labelTextStyle:
                  WidgetStateProperty.resolveWith<TextStyle>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D4A),
                    );
                  }

                  return const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 12,
                    color: Color(0xFF657066),
                  );
                },
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

// MAIN NAVIGATION
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    ReadingScreen(),
    ScanScreen(),
    TraceScreen(),
    SpeakScreen(),
    SettingsScreen(),
  ];

  String translate(String english, String malay) {
    return appLanguage.value == 'Bahasa Melayu' ? malay : english;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: translate('Home', 'Utama'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book),
                label: translate('Read', 'Baca'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.document_scanner_outlined),
                selectedIcon: const Icon(Icons.document_scanner),
                label: translate('Scan', 'Imbas'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.gesture_outlined),
                selectedIcon: const Icon(Icons.gesture),
                label: translate('Trace', 'Jejak'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.mic_none),
                selectedIcon: const Icon(Icons.mic),
                label: translate('Speak', 'Bertutur'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: translate('Settings', 'Tetapan'),
              ),
            ],
          ),
        );
      },
    );
  }
}