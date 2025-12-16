import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onShowTable;
  final VoidCallback onCalculate;
  final VoidCallback onReset;
  final bool hasExpenses;
  final bool isAdding;

  const ActionButtons({
    super.key,
    required this.onAdd,
    required this.onShowTable,
    required this.onCalculate,
    required this.onReset,
    required this.hasExpenses,
    required this.isAdding,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Pengeluaran'),
        ),
        const SizedBox(width: 8),
        if (hasExpenses && !isAdding)
          ElevatedButton(
            onPressed: onShowTable,
            child: const Text('Lihat Tabel'),
          ),
        const SizedBox(width: 8),
        if (hasExpenses && !isAdding)
          ElevatedButton(
            onPressed: onCalculate,
            child: const Text('Hitung'),
          ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
        ),
      ],
    );
  }
}