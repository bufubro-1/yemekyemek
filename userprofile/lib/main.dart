import 'package:flutter/material.dart';

import 'screens/splash_decision_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const YemekYemekApp());
}

class YemekYemekApp extends StatelessWidget {
  const YemekYemekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YemekYemek?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashDecisionScreen(),
    );
  }
}
