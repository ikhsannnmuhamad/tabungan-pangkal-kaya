import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/tabungan_service.dart';
import '../services/notif_service.dart';
import '../services/theme_service.dart';
import '../widgets/app_sidebar.dart';

class PengeluaranPage extends StatefulWidget {
  const PengeluaranPage({super.key});

  @override
  State<PengeluaranPage> createState() => _PengeluaranPageState();
}

class _PengeluaranPageState extends State<PengeluaranPage> {
  final _service = TabunganService();
  final _namaController = TextEditingController();
  final _jumlahController = TextEditingController();
  String? _selectedTabunganId;
  Map<String, dynamic> _tabunganList = {};
  Map<String, List<Map<String, dynamic>>> _allPengeluaran = {};
  int _totalPengeluaran = 0;

  final NumberFormat format = NumberFormat("#,###", "id_ID");
  final DateFormat tanggalFormat = DateFormat("d MMMM yyyy", "id_ID");
  final DateFormat jamFormat = DateFormat("HH:mm", "id_ID");

  DateTime? _filterStart;
  DateTime? _filterEnd;
  bool _showHistory = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getAllTabungan();
    final pengeluaranData = await _service.getPengeluaranTabungan();

    int total = 0;
    final now = DateTime.now();
    for (var list in pengeluaranData.values) {
      for (var p in list) {
        final waktu = DateTime.tryParse(p['waktu'].toString());
        if (waktu != null && waktu.year == now.year && waktu.month == now.month) {
          total += int.tryParse(p['jumlah'].toString()) ?? 0;
        }
      }
    }

    setState(() {
      _tabunganList = data;
      _allPengeluaran = pengeluaranData;
      _totalPengeluaran = total;
    });
  }

  Future<void> _simpanPengeluaran() async {
    final nama = _namaController.text.trim();
    final jumlah = int.tryParse(
      _jumlahController.text.replaceAll('.', '').replaceAll(',', ''),
    ) ?? 0;
    if (nama.isEmpty || jumlah <= 0 || _selectedTabunganId == null) return;

    await _service.pengeluaranTabungan(
      tabunganId: _selectedTabunganId!,
      nama: nama,
      jumlah: jumlah,
    );
    await _loadData();

    final notifService = Provider.of<NotifService>(context, listen: false);
    notifService.addNotif(
      "Pengeluaran '$nama' sebesar Rp ${format.format(jumlah)} dicatat pada ${tanggalFormat.format(DateTime.now())}",
      tipe: 'pengeluaran',
    );

    _namaController.clear();
    _jumlahController.clear();
    _selectedTabunganId = null;
  }

  void _showTambahDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Pengeluaran"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedTabunganId,
              hint: const Text("Pilih Tabungan"),
              items: _tabunganList.entries
                  .where((entry) {
                    final saldo = int.tryParse(entry.value['saldo'].toString()) ?? 0;
                    return saldo > 0;
                  })
                  .map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text("${entry.value['tujuan']} (Rp ${format.format(entry.value['saldo'])})"),
                    );
                  }).toList(),
              onChanged: (val) => _selectedTabunganId = val,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: "Nama Pengeluaran"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Nominal"),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _simpanPengeluaran();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() async {
    final pickedStart = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedStart == null) return;

    final pickedEnd = await showDatePicker(
      context: context,
      initialDate: pickedStart,
      firstDate: pickedStart,
      lastDate: DateTime.now(),
    );
    if (pickedEnd == null) return;

    setState(() {
      _filterStart = pickedStart;
      _filterEnd = pickedEnd;
      _showHistory = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allHistory = _allPengeluaran.entries.expand((entry) {
      return entry.value.map((p) => {
            'tabungan': _tabunganList[entry.key]?['tujuan'] ?? entry.key,
            'nama': p['nama'],
            'jumlah': p['jumlah'],
            'waktu': p['waktu'],
          });
    }).where((p) {
      final waktu = DateTime.tryParse(p['waktu'].toString());
      if (_filterStart != null && _filterEnd != null && waktu != null) {
        return waktu.isAfter(_filterStart!.subtract(const Duration(days: 1))) &&
               waktu.isBefore(_filterEnd!.add(const Duration(days: 1)));
      }
      return true;
    }).where((p) {
      return p['nama'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengeluaran"),
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
      drawer: const AppSidebar(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.money_off, size: 36, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Pengeluaran Bulan Ini",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'Rp ${format.format(_totalPengeluaran)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.red),
                    onPressed: _showTambahDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (_showHistory) {
                      setState(() => _showHistory = false);
                    } else {
                      _showFilterDialog();
                    }
                  },
                  icon: Icon(_showHistory ? Icons.close : Icons.history),
                  label: Text(_showHistory ? "Tutup History" : "Lihat History"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text("Filter Tanggal"),
                ),
              ],
            ),
            if (_showHistory) ...[
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Cari nama pengeluaran...",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
                            if (allHistory.isNotEmpty) ...[
                Text(
                  _filterStart != null && _filterEnd != null
                      ? "History Pengeluaran tanggal ${tanggalFormat.format(_filterStart!)} s/d ${tanggalFormat.format(_filterEnd!)}"
                      : "History Pengeluaran",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...allHistory.map((p) {
                  final jumlah = int.tryParse(p['jumlah'].toString()) ?? 0;
                  final waktu = DateTime.tryParse(p['waktu'].toString());
                  final formattedTanggal = waktu != null
                      ? tanggalFormat.format(waktu)
                      : p['waktu'].toString();
                  final formattedJam = waktu != null ? jamFormat.format(waktu) : "";
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.edit_note, color: Colors.orange),
                      title: Text("${p['nama']} - Rp ${format.format(jumlah)}"),
                      subtitle: Text("${p['tabungan']} • $formattedTanggal • $formattedJam"),
                    ),
                  );
                }),
              ] else ...[
                const Text("Tidak ada data pengeluaran untuk periode ini."),
              ],
            ],
          ],
        ),
      ),
    );
  }
}