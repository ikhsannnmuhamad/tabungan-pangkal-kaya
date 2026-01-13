import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/calculation_page.dart';
import '../pages/menabung_page.dart';

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  const AppSidebar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'E-HTabungan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            selected: currentIndex == 0,
            selectedTileColor: Colors.blue.withOpacity(0.1),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('Kalkulator Keuangan'),
            selected: currentIndex == 1,
            selectedTileColor: Colors.blue.withOpacity(0.1),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CalculationPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.savings),
            title: const Text('Menabung'),
            selected: currentIndex == 2,
            selectedTileColor: Colors.blue.withOpacity(0.1),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MenabungPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}