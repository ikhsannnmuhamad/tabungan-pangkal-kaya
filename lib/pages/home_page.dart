import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../widgets/app_sidebar.dart';
import '../widgets/finance_news_card.dart';
import '../services/tabungan_service.dart';
import '../services/theme_service.dart';

import '../pages/calculation_page.dart';
import '../pages/menabung_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController();
  final TabunganService _tabunganService = TabunganService();

  int _currentIndex = 0;
  int _totalSaldo = 0;
  bool _hideSaldo = true;

  final NumberFormat format = NumberFormat("#,###", "id_ID");

  final List<Widget> _cards = const [
    FinanceNewsCard(
      title: 'Menabung Pangkal Kaya',
      subtitle: 'Mulai dari langkah kecil untuk masa depan besar',
      icon: Icons.savings,
      color: Colors.green,
      backgroundImage: 'assets/images/langkah.jpg',
    ),
    FinanceNewsCard(
      title: 'Uang Bijak, Hidup Tenang',
      subtitle: 'Kelola keuangan dengan cerdas demi kesejahteraan',
      icon: Icons.account_balance,
      color: Colors.blue,
      backgroundImage: 'assets/images/kelola.jpg',
    ),
    FinanceNewsCard(
      title: 'Simpan Hari Ini, Nikmati Esok',
      subtitle: 'Investasi kecil, hasil besar di masa depan',
      icon: Icons.trending_up,
      color: Colors.orange,
      backgroundImage: 'assets/images/investasi.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTotalSaldo();
  }

  Future<void> _loadTotalSaldo() async {
    final data = await _tabunganService.getAllTabungan();
    int total = 0;
    for (var entry in data.entries) {
      final tabungan = Map<String, dynamic>.from(entry.value);
      total += int.tryParse(tabungan['saldo'].toString()) ?? 0;
    }
    setState(() => _totalSaldo = total);
  }

  void _toggleSaldo() {
    setState(() => _hideSaldo = !_hideSaldo);
  }

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

  Widget _quickMenu({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: Colors.blue),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'E-HTabungan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Consumer<ThemeService>(
            builder: (context, themeService, _) => IconButton(
              icon: Icon(
                themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: themeService.toggleTheme,
            ),
          ),
        ],
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
                  'Saldo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 36, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Tabungan',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            _hideSaldo
                                ? 'Rp ••••••'
                                : 'Rp ${format.format(_totalSaldo)}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _hideSaldo
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.green,
                      ),
                      onPressed: _toggleSaldo,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 190,
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cards.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, i) => _cards[i],
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Menu Lainnya',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _quickMenu(
                    icon: Icons.calculate,
                    label: 'Kalkulasi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CalculationPage(),
                        ),
                      );
                    },
                  ),
                  _quickMenu(
                    icon: Icons.savings,
                    label: 'Menabung',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MenabungPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}