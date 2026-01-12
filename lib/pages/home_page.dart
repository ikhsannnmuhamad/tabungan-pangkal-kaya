import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/app_sidebar.dart';
import '../widgets/finance_news_card.dart';
import '../services/tabungan_service.dart';

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

  /// ================= IMAGE BADGE =================
  final List<Widget> _cards = const [
    FinanceNewsCard(
      title: 'Tahura',
      subtitle: 'Wisata alam dan ruang terbuka hijau',
      icon: Icons.park,
      color: Colors.green,
      backgroundImage: 'assets/images/tahura.jpeg',
    ),
    FinanceNewsCard(
      title: 'Taichan',
      subtitle: 'Kuliner ayam taichan favorit',
      icon: Icons.restaurant,
      color: Colors.orange,
      backgroundImage: 'assets/images/taichan.jpeg',
    ),
    FinanceNewsCard(
      title: 'Geprek',
      subtitle: 'Ayam geprek pedas khas nusantara',
      icon: Icons.local_fire_department,
      color: Colors.red,
      backgroundImage: 'assets/images/geprek.jpeg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTotalSaldo();
  }

  /// ================= LOAD TOTAL SALDO =================
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

  /// ================= QUICK MENU ITEM =================
  Widget _quickMenu({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
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
          'Tabungan Pangkal Kaya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      drawer: const AppSidebar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// ================= TOTAL SALDO =================
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total Saldo',
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
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 36,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo Terkumpul',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _hideSaldo
                                ? 'Rp ••••••'
                                : 'Rp ${format.format(_totalSaldo)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

            /// ================= IMAGE BADGE =================
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

            /// ================= QUICK MENU =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
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
                  _quickMenu(
                    icon: Icons.trending_up,
                    label: 'Prediksi',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur belum tersedia'),
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
