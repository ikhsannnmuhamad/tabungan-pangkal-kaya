import 'package:firebase_database/firebase_database.dart';

class FirebaseTestService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// TEST WRITE
  Future<void> writeTest() async {
    await _db.child('test_connection').set({
      'status': 'connected',
      'time': DateTime.now().toIso8601String(),
    });
  }

  /// TEST READ
  Future<Map?> readTest() async {
    final snapshot = await _db.child('test_connection').get();
    if (snapshot.exists) {
      return snapshot.value as Map;
    }
    return null;
  }
}
