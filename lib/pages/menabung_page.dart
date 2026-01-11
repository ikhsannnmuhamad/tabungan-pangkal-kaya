import 'package:flutter/material.dart';
import '../services/tabungan_service.dart';
import '../widgets/badge.dart';
import 'tabungan_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/notif_service.dart';

class MenabungPage extends StatefulWidget {
  const MenabungPage({super.key});

  @override
  State<MenabungPage> createState() => _MenabungPageState();
}

class _MenabungPageState extends State<MenabungPage> {
  final _service = TabunganService();
  Map<String, dynamic> _tabunganList = {};
  String _searchQuery = "";
  String _filterStatus = "Semua";
  bool _searchVisible = false;
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
      final nama = _tabunganList[id]?['tujuan'] ?? 'Tabungan';
      await _service.deleteTabungan(id);
      await _loadTabungan();

      final notifService = Provider.of<NotifService>(context, listen: false);
      notifService.addNotif(
        "Tabungan '$nama' berhasil dihapus pada ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now())}",
        tipe: 'hapus',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tabungan berhasil dihapus")),
      );
    }
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
              final target = int.tryParse(
                    targetController.text.replaceAll('.', '').replaceAll(',', ''),
                  ) ??
                  0;
              if (tujuan.isEmpty || target <= 0) return;
              await _service.createTabungan(tujuan: tujuan, target: target);
              Navigator.pop(context);
              await _loadTabungan();

              final notifService = Provider.of<NotifService>(context, listen: false);
              notifService.addNotif(
                "Tabungan '$tujuan' berhasil ditambahkan dengan target Rp ${format.format(target)} pada ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now())}",
                tipe: 'tambah',
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showFilterMenu() async {
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
      items: const [
        PopupMenuItem(value: 'Semua', child: Text('Semua')),
        PopupMenuItem(value: 'Proses', child: Text('Proses')),
        PopupMenuItem(value: 'Tercapai', child: Text('Tercapai')),
      ],
    );
    if (selected != null) {
      setState(() => _filterStatus = selected);
    }
  }

  void _showNotifDialog() {
    final notifService = Provider.of<NotifService>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Notifikasi"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: groupByJamDescending(notifService.notifikasi).entries.map((entry) {
                final jam = entry.key;
                final list = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jam, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...list.map((notif) {
                      final warna = switch (notif['tipe']) {
                        'hapus' => Colors.red,
                        'setor' => Colors.green,
                        'tambah' => Colors.blue,
                        _ => Colors.grey,
                      };
                      final icon = switch (notif['tipe']) {
                        'hapus' => Icons.delete,
                        'setor' => Icons.attach_money,
                        'tambah' => Icons.savings,
                        _ => Icons.info,
                      };
                      final waktu = notif['waktu'] as DateTime;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: warna.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, color: warna),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notif['pesan']),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Text(
                                      DateFormat("HH:mm", "id_ID").format(waktu),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              notifService.markAsRead();
              Navigator.pop(context);
            },
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _tabunganList.entries.where((entry) {
      final data = Map<String, dynamic>.from(entry.value);
      final cocokSearch = data['tujuan']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      final cocokFilter = switch (_filterStatus) {
        'Semua' => true,
        'Proses' => data['status'] != 'tercapai',
        'Tercapai' => data['status'] == 'tercapai',
        _ => true,
      };

      return cocokSearch && cocokFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menabung"),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.close : Icons.search),
            tooltip: _searchVisible ? "Tutup Pencarian" : "Cari . . .",
            color: _searchVisible ? Colors.red : null,
            onPressed: () => setState(() {
              _searchVisible = !_searchVisible;
              if (!_searchVisible) _searchQuery = "";
            }),
          ),
          Consumer<NotifService>(
            builder: (context, notifService, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    tooltip: "Notifikasi",
                    onPressed: _showNotifDialog,
                  ),
                  if (notifService.unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${notifService.unreadCount}',
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchVisible) ...[
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Cari . . .",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
            ],

            // Total Saldo
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

            // Tombol tambah tabungan + filter (notif tetap di navbar)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showTambahDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Tabungan"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showFilterMenu,
                  icon: const Icon(Icons.filter_list),
                  label: Text("Filter: $_filterStatus"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Grid badge tabungan
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

// Helper: group by jam untuk dialog notifikasi (terbaru di atas)
Map<String, List<Map<String, dynamic>>> groupByJamDescending(List<Map<String, dynamic>> list) {
  final sorted = [...list]..sort((a, b) => (b['waktu'] as DateTime).compareTo(a['waktu'] as DateTime));
  final Map<String, List<Map<String, dynamic>>> grouped = {};
  for (var item in sorted) {
    final waktu = item['waktu'] as DateTime;
    final jam = DateFormat("HH:mm").format(waktu);
    grouped.putIfAbsent(jam, () => []).add(item);
  }
  return grouped;
}