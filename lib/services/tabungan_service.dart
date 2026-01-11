import 'package:firebase_database/firebase_database.dart';

class TabunganService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('menabung');

  Future<void> createTabungan({
    required String tujuan,
    required int target,
  }) async {
    final newRef = _db.push();
    await newRef.set({
      'tujuan': tujuan,
      'target': target,
      'saldo': 0,
      'status': 'proses',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getAllTabungan() async {
    final snapshot = await _db.get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {};
  }

  Future<void> setorTabungan({
    required String tabunganId,
    required int jumlah,
  }) async {
    final tabunganRef = _db.child(tabunganId);
    final snapshot = await tabunganRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final int saldoLama = data['saldo'] ?? 0;
    final int target = data['target'] ?? 0;

    final int saldoBaru = saldoLama + jumlah;
    final String statusBaru = saldoBaru >= target ? 'tercapai' : 'proses';

    await tabunganRef.child('history').push().set({
      'jumlah': jumlah,
      'waktu': DateTime.now().toIso8601String(),
    });

    await tabunganRef.update({
      'saldo': saldoBaru,
      'status': statusBaru,
    });
  }

  Future<List<Map<String, dynamic>>> getHistory(String tabunganId) async {
    final snapshot = await _db.child(tabunganId).child('history').get();
    if (!snapshot.exists) return [];
    final Map data = snapshot.value as Map;
    return data.entries.map<Map<String, dynamic>>((e) {
      return {
        'id': e.key,
        'jumlah': e.value['jumlah'],
        'waktu': e.value['waktu'],
      };
    }).toList();
  }
}