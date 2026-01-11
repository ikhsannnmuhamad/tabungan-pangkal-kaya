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
              onChanged: (val) {
                final raw = val.replaceAll('.', '').replaceAll(',', '');
                final number = int.tryParse(raw);
                if (number != null) {
                  final formatted = format.format(number);
                  targetController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final tujuan = tujuanController.text.trim();
              final target = int.tryParse(targetController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
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

  Future<void> _hapusTabungan(String id) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Tabungan"),
        content: const Text("Yakin ingin menghapus tabungan ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await _service.deleteTabungan(id);
      _loadTabungan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tabungan berhasil dihapus")),
      );
    }
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

                  final int saldo = int.tryParse(data['saldo'].toString()) ?? 0;
                  final int target = int.tryParse(data['target'].toString()) ?? 1;
                  final int percent = ((saldo / target) * 100).clamp(0, 100).toInt();
                  final String status = data['status'] == 'tercapai' ? 'Tercapai' : 'Proses';

                  return Stack(
                    children: [
                      BadgeWidget(
                        title: '${data['tujuan']}\n$percent%\n$status',
                        icon: Icons.savings,
                        color: data['status'] == 'tercapai' ? Colors.green : Colors.orange,
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
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _hapusTabungan(id),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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