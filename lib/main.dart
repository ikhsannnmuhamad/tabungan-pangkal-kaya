import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const TabunganPangkalKayaApp());
}

class TabunganPangkalKayaApp extends StatelessWidget {
  const TabunganPangkalKayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tabungan Pangkal Kaya',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}