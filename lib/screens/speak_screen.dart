import 'package:flutter/material.dart';

class SpeakScreen extends StatelessWidget {
  const SpeakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Speak & Write',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}