import 'package:firebase_database/firebase_database.dart';

class TabunganService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('menabung');

  /// Membuat tabungan baru dengan wishlist
  Future<void> createTabungan({
    required String tujuan,
    required int target,
    String kategori = 'sekunder', // primer / sekunder / tersier
    DateTime? deadline,
    List<String> wishlist = const [],
  }) async {
    final newRef = _db.push();
    await newRef.set({
      'tujuan': tujuan,
      'target': target,
      'saldo': 0,
      'status': 'proses',
      'kategori': kategori,
      'deadline': deadline?.toIso8601String(),
      'wishlist': wishlist,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Mengambil semua tabungan
  Future<Map<String, dynamic>> getAllTabungan() async {
    final snapshot = await _db.get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {};
  }

  /// Menyetor tabungan
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

  /// Mengambil history setoran
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

  /// Menghapus tabungan
  Future<void> deleteTabungan(String id) async {
    await _db.child(id).remove();
  }

  /// Update tabungan
  Future<void> updateTabungan(
    String id, {
    String? tujuan,
    int? target,
    String? kategori,
    DateTime? deadline,
    List<String>? wishlist,
  }) async {
    final updateData = <String, dynamic>{};
    if (tujuan != null) updateData['tujuan'] = tujuan;
    if (target != null) updateData['target'] = target;
    if (kategori != null) updateData['kategori'] = kategori;
    if (deadline != null) updateData['deadline'] = deadline.toIso8601String();
    if (wishlist != null) updateData['wishlist'] = wishlist;

    if (updateData.isNotEmpty) {
      await _db.child(id).update(updateData);
    }
  }
}