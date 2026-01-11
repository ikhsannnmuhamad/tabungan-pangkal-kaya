import 'package:flutter/material.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/finance_news_card.dart';
import '../services/firebase_test_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController();
  final FirebaseTestService _firebaseTest = FirebaseTestService();

  int _currentIndex = 0;

  final List<Widget> _cards = const [
    FinanceNewsCard(
      title: 'IHSG Menguat',
      subtitle: 'IHSG naik 1,25% ditopang sektor perbankan',
      icon: Icons.trending_up,
      color: Colors.green,
    ),
    FinanceNewsCard(
      title: 'Saham BBCA',
      subtitle: 'BBCA ditutup naik 2,1% hari ini',
      icon: Icons.show_chart,
      color: Colors.blue,
    ),
    FinanceNewsCard(
      title: 'Pasar Global',
      subtitle: 'Wall Street menguat jelang data inflasi AS',
      icon: Icons.public,
      color: Colors.orange,
    ),
  ];

  void _next() {
    if (_currentIndex < _cards.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _testFirebase() async {
    await _firebaseTest.writeTest();
    final data = await _firebaseTest.readTest();
    debugPrint('HASIL FIREBASE: $data');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tes Firebase berhasil (cek console & database)'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tabungan Pangkal Kaya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      drawer: const AppSidebar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ringkasan Pasar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cards.length,
                onPageChanged: (i) {
                  setState(() => _currentIndex = i);
                },
                itemBuilder: (_, i) => _cards[i],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0 ? _back : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                Text('${_currentIndex + 1} / ${_cards.length}'),
                IconButton(
                  onPressed:
                      _currentIndex < _cards.length - 1 ? _next : null,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ===============================
            // TOMBOL TEST FIREBASE (STEP 3)
            // ===============================
            ElevatedButton.icon(
              onPressed: _testFirebase,
              icon: const Icon(Icons.cloud_done),
              label: const Text('TEST FIREBASE'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
