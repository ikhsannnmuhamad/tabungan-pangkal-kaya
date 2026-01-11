import 'package:flutter/material.dart';
import '../services/tabungan_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/notif_service.dart';

class TabunganDetailPage extends StatefulWidget {
  final String tabunganId;
  const TabunganDetailPage({super.key, required this.tabunganId});

  @override
  State<TabunganDetailPage> createState() => _TabunganDetailPageState();
}

class _TabunganDetailPageState extends State<TabunganDetailPage> {
  final _jumlahController = TextEditingController();
  final _service = TabunganService();
  final NumberFormat format = NumberFormat("#,###", "id_ID");
  final DateFormat tanggalFormat = DateFormat("d MMMM yyyy", "id_ID");
  final DateFormat jamFormat = DateFormat("HH:mm", "id_ID");

  Map<String, dynamic>? _tabungan;
  List<Map<String, dynamic>> _history = [];

  bool _showInput = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await _service.getAllTabungan();
    if (all.containsKey(widget.tabunganId)) {
      setState(() {
        _tabungan = Map<String, dynamic>.from(all[widget.tabunganId]);
      });
    }
    final hist = await _service.getHistory(widget.tabunganId);
    setState(() {
      _history = hist;
    });
  }

  Future<void> _setor() async {
    final jumlah = int.tryParse(
      _jumlahController.text.replaceAll('.', '').replaceAll(',', ''),
    ) ?? 0;
    if (jumlah <= 0 || _tabungan?['status'] == 'tercapai') return;

    await _service.setorTabungan(tabunganId: widget.tabunganId, jumlah: jumlah);
    _jumlahController.clear();
    setState(() {
      _showInput = false;
    });
    await _loadData();

    // Tambahkan ke NotifService global
    final notifService = Provider.of<NotifService>(context, listen: false);
    notifService.addNotif(
      "Berhasil input setoran sebesar Rp ${format.format(jumlah)} pada ${tanggalFormat.format(DateTime.now())}",
      tipe: 'setor',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Setoran Rp ${format.format(jumlah)} berhasil ditambahkan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabungan == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int target = int.tryParse(_tabungan!['target'].toString()) ?? 0;
    final int saldo = int.tryParse(_tabungan!['saldo'].toString()) ?? 0;
    final String status = _tabungan!['status'] == 'tercapai' ? 'Tercapai' : 'Proses';
    final bool isTercapai = _tabungan!['status'] == 'tercapai';

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabungan!['tujuan']),
        actions: [
          Consumer<NotifService>(
            builder: (context, notifService, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
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
                                                        jamFormat.format(waktu),
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
                    },
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info tabungan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings, size: 40, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target: Rp ${format.format(target)}'),
                        Text('Jumlah Terkumpul: Rp ${format.format(saldo)}'),
                        Text('Status: $status',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tombol aksi
            Row(
              children: [
                if (!isTercapai)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _showInput = !_showInput),
                    icon: Icon(_showInput ? Icons.close : Icons.add),
                    label: Text(_showInput ? 'Batalkan' : 'Tambah Setoran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showInput ? Colors.red : null,
                    ),
                  ),
                if (!isTercapai) const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showHistory = !_showHistory),
                  icon: Icon(_showHistory ? Icons.close : Icons.history),
                  label: Text(_showHistory ? 'Tutup History' : 'Lihat History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showHistory ? Colors.red : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Input setoran
            if (_showInput && !isTercapai) ...[
              TextField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Setoran',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final raw = val.replaceAll('.', '').replaceAll(',', '');
                  final number = int.tryParse(raw);
                  if (number != null) {
                    final formatted = format.format(number);
                    _jumlahController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
                            ElevatedButton(
                onPressed: _setor,
                child: const Text('Simpan Setoran'),
              ),
              const SizedBox(height: 16),
            ],

            // History setoran
            if (_showHistory) ...[
              const Text('History Setoran:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final h = _history[index];
                    final jumlah = int.tryParse(h['jumlah'].toString()) ?? 0;
                    final waktu = DateTime.tryParse(h['waktu'].toString());
                    final formatted = waktu != null
                        ? "diinput pada ${tanggalFormat.format(waktu)} • ${jamFormat.format(waktu)}"
                        : h['waktu'].toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.attach_money, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rp ${format.format(jumlah)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatted,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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