import 'package:flutter/material.dart';

class NotifService extends ChangeNotifier {
  final List<Map<String, dynamic>> _notifikasi = [];
  bool _hasUnread = false;

  List<Map<String, dynamic>> get notifikasi => _notifikasi;
  bool get hasUnread => _hasUnread;

  /// Tambahkan notifikasi baru
  void addNotif(String pesan) {
    final now = DateTime.now();
    _notifikasi.add({
      'pesan': pesan,
      'waktu': now,
    });
    _hasUnread = true;
    notifyListeners();
  }

  /// Tandai semua notif sudah dibaca (badge hilang)
  void markAsRead() {
    _hasUnread = false;
    notifyListeners();
  }

  /// Hapus semua notifikasi (opsional)
  void clearNotif() {
    _notifikasi.clear();
    _hasUnread = false;
    notifyListeners();
  }
}