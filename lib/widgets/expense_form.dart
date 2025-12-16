import 'package:flutter/material.dart';

class ExpenseForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController amountController;
  final VoidCallback onFinish;
  final VoidCallback onCancel;
  final String Function(String) formatNumber;

  const ExpenseForm({
    super.key,
    required this.nameController,
    required this.amountController,
    required this.onFinish,
    required this.onCancel,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Pengeluaran',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Biaya Pengeluaran',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            final formatted = formatNumber(val);
            amountController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(onPressed: onFinish, child: const Text('Selesai')),
            ElevatedButton(
              onPressed: onCancel,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Batalkan'),
            ),
          ],
        ),
      ],
    );
  }
}