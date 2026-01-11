import 'package:flutter/material.dart';
import '../services/tabungan_service.dart';
import '../widgets/badge.dart';
import 'tabungan_detail_page.dart';
import 'package:intl/intl.dart';

class MenabungPage extends StatefulWidget {
  const MenabungPage({super.key});

  @override
  State<MenabungPage> createState() => _MenabungPageState();
}

class _MenabungPageState extends State<MenabungPage> {
  final _service = TabunganService();
  Map<String, dynamic> _tabunganList = {};
  String _searchQuery = "";
  int _totalSaldo = 0;

  final NumberFormat format = NumberFormat("#,###", "id_ID");

  @override
  void initState() {
    super.initState();
    _loadTabungan();
  }

  Future<void> _loadTabungan() async {
    final data = await _service.getAllTabungan();
    int total = 0;
    for (var entry in data.entries) {
      final tabungan = Map<String, dynamic>.from(entry.value);
      total += int.tryParse(tabungan['saldo'].toString()) ?? 0;
    }
    setState(() {
      _tabunganList = data;
      _totalSaldo = total;
    });
  }

  void _showTambahDialog() {
    final tujuanController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Tabungan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tujuanController,
              decoration: const InputDecoration(
                labelText: "Tujuan Tabungan",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Target Nominal",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final tujuan = tujuanController.text.trim();
              final target = int.tryParse(targetController.text.trim()) ?? 0;
              if (tujuan.isEmpty || target <= 0) return;
              await _service.createTabungan(tujuan: tujuan, target: target);
              Navigator.pop(context);
              _loadTabungan();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _tabunganList.entries.where((entry) {
      final data = Map<String, dynamic>.from(entry.value);
      return data['tujuan']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Menabung")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Cari tabungan...",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),

            // Total Saldo horizontal layout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 40, color: Colors.blue),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Saldo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${format.format(_totalSaldo)}',
                        style: const TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tombol tambah tabungan
            Center(
              child: ElevatedButton.icon(
                onPressed: _showTambahDialog,
                icon: const Icon(Icons.add),
                label: const Text("Tambah Tabungan"),
              ),
            ),
            const SizedBox(height: 16),

            // Grid badge tabungan (centered wrap)
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: filtered.map((entry) {
                  final id = entry.key;
                  final data = Map<String, dynamic>.from(entry.value);
                  return BadgeWidget(
                    title:
                        '${data['tujuan']}\nRp ${format.format(data['saldo'])} / Rp ${format.format(data['target'])}',
                    icon: Icons.savings,
                    color: data['status'] == 'tercapai'
                        ? Colors.green
                        : Colors.orange,
                    width: 120,
                    height: 120,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TabunganDetailPage(tabunganId: id),
                        ),
                      ).then((_) => _loadTabungan());
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}