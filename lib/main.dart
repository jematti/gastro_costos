import 'package:flutter/material.dart';

import 'features/dashboard/home_screen.dart';

void main() {
  runApp(const GastroCostosApp());
}

class GastroCostosApp extends StatelessWidget {
  const GastroCostosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GastroCostos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
