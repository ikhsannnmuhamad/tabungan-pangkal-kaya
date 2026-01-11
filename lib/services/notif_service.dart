import 'package:flutter/material.dart';

class NotifService extends ChangeNotifier {
  final List<Map<String, dynamic>> _notifikasi = [];
  final List<Map<String, dynamic>> _unread = [];

  List<Map<String, dynamic>> get notifikasi => _notifikasi;
  int get unreadCount => _unread.length;

  void addNotif(String pesan, {String tipe = 'info'}) {
    final now = DateTime.now();
    final item = {
      'pesan': pesan,
      'waktu': now,
      'tipe': tipe,
    };
    _notifikasi.add(item);
    _unread.add(item);
    notifyListeners();
  }

  void markAsRead() {
    _unread.clear();
    notifyListeners();
  }

  void clearNotif() {
    _notifikasi.clear();
    _unread.clear();
    notifyListeners();
  }
}