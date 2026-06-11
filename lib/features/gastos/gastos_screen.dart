import 'package:flutter/material.dart';

class GastosScreen extends StatelessWidget {
  const GastosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: const Center(child: Text('Modulo Gastos')),
    );
  }
}
