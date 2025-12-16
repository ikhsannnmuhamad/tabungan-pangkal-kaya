import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseTable extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;
  final Function(int) onDelete;

  const ExpenseTable({
    super.key,
    required this.expenses,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat("#,###", "id_ID");

    return AlertDialog(
      title: const Text('Tabel Pengeluaran'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nama')),
                DataColumn(label: Text('Jumlah')),
                DataColumn(label: Text('Aksi')),
              ],
              rows: expenses.asMap().entries.map((entry) {
                int index = entry.key;
                var e = entry.value;
                return DataRow(cells: [
                  DataCell(Text(e['name'])),
                  DataCell(Text('Rp ${currencyFormat.format(e['amount'])}')),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        onDelete(index);
                        setState(() {});
                      },
                    ),
                  ),
                ]);
              }).toList(),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}