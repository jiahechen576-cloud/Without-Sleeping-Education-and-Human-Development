import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reading_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/trace_screen.dart';
import 'screens/speak_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const ReadRabbitApp());
}

class ReadRabbitApp extends StatelessWidget {
  const ReadRabbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReadRabbit',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),

      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN NAVIGATION
// ─────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Read',
          ),

          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),

          NavigationDestination(
            icon: Icon(Icons.gesture_outlined),
            selectedIcon: Icon(Icons.gesture),
            label: 'Trace',
          ),

          NavigationDestination(
            icon: Icon(Icons.mic_none),
            selectedIcon: Icon(Icons.mic),
            label: 'Speak',
          ),

          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}