import 'package:firebase_database/firebase_database.dart';

class TabunganService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref("menabung");

  Future<Map<String, dynamic>> getAllTabungan() async {
    final snapshot = await _db.get();
    if (!snapshot.exists || snapshot.value == null) return {};
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  Future<void> createTabungan({required String tujuan, required int target}) async {
    final newRef = _db.push();
    await newRef.set({
      'tujuan': tujuan,
      'target': target,
      'saldo': 0,
      'status': 'proses',
    });
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    final normalized = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(normalized) ?? 0;
  }

  Future<void> setorTabungan({required String tabunganId, required int jumlah}) async {
    final ref = _db.child(tabunganId);
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final saldo = _parseInt(data['saldo']);
    final target = _parseInt(data['target']);
    final newSaldo = saldo + jumlah;

    await ref.update({
      'saldo': newSaldo,
      'status': newSaldo >= target ? 'tercapai' : 'proses',
    });

    await ref.child('history').push().set({
      'jumlah': jumlah,
      'waktu': DateTime.now().toIso8601String(),
    });
  }

  Future<void> pengeluaranTabungan({
    required String tabunganId,
    required String nama,
    required int jumlah,
  }) async {
    final ref = _db.child(tabunganId);
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final saldo = _parseInt(data['saldo']);
    final target = _parseInt(data['target']);
    final newSaldo = saldo - jumlah;

    // Jika tabungan sudah pernah tercapai, maka setiap pengeluaran wajib
    // mengembalikan status menjadi 'proses' (agar badge ikut berubah).
    final wasTercapai = data['status'] == 'tercapai';
    final updatedStatus = wasTercapai ? 'proses' : (newSaldo >= target ? 'tercapai' : 'proses');

    await ref.update({
      'saldo': newSaldo < 0 ? 0 : newSaldo,
      'status': updatedStatus,
    });

    await ref.child('pengeluaran').push().set({
      'nama': nama,
      'jumlah': jumlah,
      'waktu': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHistory(String tabunganId) async {
    final snapshot = await _db.child(tabunganId).child('history').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.entries.map<Map<String, dynamic>>((e) {
      final value = Map<String, dynamic>.from(e.value as Map);
      return {
        'id': e.key,
        'jumlah': value['jumlah'],
        'waktu': value['waktu'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPengeluaran(String tabunganId) async {
    final snapshot = await _db.child(tabunganId).child('pengeluaran').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.entries.map<Map<String, dynamic>>((e) {
      final value = Map<String, dynamic>.from(e.value as Map);
      return {
        'id': e.key,
        'nama': value['nama'],
        'jumlah': value['jumlah'],
        'waktu': value['waktu'],
      };
    }).toList();
  }

  Future<Map<String, List<Map<String, dynamic>>>> getPengeluaranTabungan() async {
    final snapshot = await _db.get();
    if (!snapshot.exists || snapshot.value == null) return {};

    final allData = Map<String, dynamic>.from(snapshot.value as Map);
    final result = <String, List<Map<String, dynamic>>>{};

    for (var entry in allData.entries) {
      final tabunganId = entry.key;
      final tabunganData = Map<String, dynamic>.from(entry.value as Map);

      if (tabunganData['pengeluaran'] != null) {
        final pengeluaranData = Map<String, dynamic>.from(tabunganData['pengeluaran'] as Map);
        result[tabunganId] = pengeluaranData.entries.map<Map<String, dynamic>>((e) {
          final value = Map<String, dynamic>.from(e.value as Map);
          return {
            'id': e.key,
            'nama': value['nama'],
            'jumlah': value['jumlah'],
            'waktu': value['waktu'],
          };
        }).toList();
      }
    }

    return result;
  }

  Future<void> deleteTabungan(String id) async {
    await _db.child(id).remove();
  }
}