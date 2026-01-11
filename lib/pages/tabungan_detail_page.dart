import 'package:flutter/material.dart';
import '../services/tabungan_service.dart';

class TabunganDetailPage extends StatefulWidget {
  final String tabunganId;
  const TabunganDetailPage({super.key, required this.tabunganId});

  @override
  State<TabunganDetailPage> createState() => _TabunganDetailPageState();
}

class _TabunganDetailPageState extends State<TabunganDetailPage> {
  final _jumlahController = TextEditingController();
  final _service = TabunganService();

  Map<String, dynamic>? _tabungan;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // ambil langsung child id
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
    final jumlah = int.tryParse(_jumlahController.text) ?? 0;
    if (jumlah <= 0) return;
    await _service.setorTabungan(tabunganId: widget.tabunganId, jumlah: jumlah);
    _jumlahController.clear();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabungan == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_tabungan!['tujuan'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: Rp ${_tabungan!['target']}'),
            Text('Jumlah sementara: Rp ${_tabungan!['saldo']}'),
            Text('Status: ${_tabungan!['status']}'),
            const SizedBox(height: 16),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Setoran',
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: _setor,
              child: const Text('Tambah Setoran'),
            ),
            const SizedBox(height: 16),
            const Text('History Setoran:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final h = _history[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.attach_money, color: Colors.green),
                      title: Text('Rp ${h['jumlah']}'),
                      subtitle: Text(h['waktu']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}