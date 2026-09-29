import 'package:flutter/material.dart';

class TraceScreen extends StatelessWidget {
  const TraceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Trace Letters',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}