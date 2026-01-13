import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../widgets/expense_form.dart';
import '../widgets/expense_table.dart';
import '../services/theme_service.dart'; // untuk toggle theme

class CalculationPage extends StatefulWidget {
  const CalculationPage({super.key});

  @override
  State<CalculationPage> createState() => _CalculationPageState();
}

class _CalculationPageState extends State<CalculationPage> {
  final TextEditingController _moneyController = TextEditingController();
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();

  final List<Map<String, dynamic>> _expenses = [];
  bool _moneyLocked = false;
  bool _isAddingExpense = false;

  final NumberFormat currencyFormat = NumberFormat("#,###", "id_ID");

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatNumber(String value) {
    final raw = value.replaceAll('.', '').replaceAll(',', '');
    if (raw.isEmpty) return '';
    final number = int.tryParse(raw);
    if (number == null) return value;
    return currencyFormat.format(number);
  }

  bool _isNumeric(String value) {
    final raw = value.replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(raw) != null;
  }

  int _parseInt(String value) {
    final raw = value.replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(raw) ?? 0;
  }

  void _lockMoney() {
    final text = _moneyController.text.trim();
    if (text.isEmpty) {
      _showSnack('Jumlah uang tidak boleh kosong');
      return;
    }
    if (!_isNumeric(text)) {
      _showSnack('Jumlah uang harus berupa angka');
      return;
    }
    setState(() {
      _moneyLocked = true;
    });
  }

  void _resetAll() {
    setState(() {
      _moneyController.clear();
      _expenses.clear();
      _moneyLocked = false;
      _isAddingExpense = false;
      _expenseNameController.clear();
      _expenseAmountController.clear();
    });
  }

  void _startAddExpense() {
    setState(() {
      _isAddingExpense = true;
      _expenseNameController.clear();
      _expenseAmountController.clear();
    });
  }

  void _finishAddExpense() {
    final String name = _expenseNameController.text.trim();
    final String amountText = _expenseAmountController.text.trim();

    if (name.isEmpty && amountText.isEmpty) {
      _showSnack('Masukan nama pengeluaran dan besaran yang akan dikeluarkan');
      return;
    }
    if (name.isEmpty) {
      _showSnack('Nama pengeluaran tidak boleh kosong');
      return;
    }
    if (amountText.isEmpty) {
      _showSnack('Besaran pengeluaran tidak boleh kosong');
      return;
    }
    if (!_isNumeric(amountText)) {
      _showSnack('Besaran pengeluaran harus berupa angka');
      return;
    }

    final amount = _parseInt(amountText);
    if (amount <= 0) {
      _showSnack('Besaran pengeluaran harus lebih dari 0');
      return;
    }

    setState(() {
      _expenses.add({'name': name, 'amount': amount});
      _isAddingExpense = false;
    });
    _showSnack('Berhasil menambahkan pengeluaran');
  }

  void _cancelAddExpense() {
    setState(() {
      _isAddingExpense = false;
    });
  }

  void _deleteExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
    });
    _showSnack('Berhasil menghapus pengeluaran');
  }

  void _showExpenseTable() {
    showDialog(
      context: context,
      builder: (context) => ExpenseTable(
        expenses: _expenses,
        onDelete: _deleteExpense,
      ),
    );
  }

  void _calculate() {
    final moneyText = _moneyController.text.trim();
    if (moneyText.isEmpty || !_isNumeric(moneyText)) {
      _showSnack('Jumlah uang harus diisi dan berupa angka');
      return;
    }
    if (_expenses.isEmpty) {
      _showSnack('Tambahkan minimal satu pengeluaran terlebih dahulu');
      return;
    }

    final int money = _parseInt(moneyText);
    final int totalExpenses =
        _expenses.fold(0, (sum, e) => sum + (e['amount'] as int));
    final int remaining = money - totalExpenses;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hasil Kalkulasi'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Jumlah Uang: Rp ${currencyFormat.format(money)}'),
              const SizedBox(height: 8),
              ..._expenses.map(
                (e) => Text(
                  '${e['name']}: Rp ${currencyFormat.format(e['amount'])}',
                ),
              ),
              const SizedBox(height: 12),
              remaining >= 0
                  ? Text(
                      'Sisa: Rp ${currencyFormat.format(remaining)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    )
                  : Text(
                      'Kurang: Rp ${currencyFormat.format(remaining)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Keuangan'),
        actions: [
          Consumer<ThemeService>(
            builder: (context, themeService, _) => IconButton(
              icon: Icon(
                themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: themeService.toggleTheme,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _moneyController,
              keyboardType: TextInputType.number,
              enabled: !_moneyLocked,
              decoration: const InputDecoration(
                labelText: 'Jumlah Uang',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                final formatted = _formatNumber(val);
                _moneyController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              },
            ),
            const SizedBox(height: 16),
            if (!_moneyLocked)
              ElevatedButton(
                onPressed: _lockMoney,
                child: const Text('Lanjutkan'),
              ),
            if (_moneyLocked) ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _startAddExpense,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                  if (_expenses.isNotEmpty && !_isAddingExpense)
                    ElevatedButton(
                      onPressed: _showExpenseTable,
                      child: const Text('Lihat Tabel'),
                    ),
                  if (_expenses.isNotEmpty && !_isAddingExpense)
                    ElevatedButton(
                      onPressed: _calculate,
                      child: const Text('Hitung'),
                    ),
                  ElevatedButton.icon(
                    onPressed: _resetAll,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isAddingExpense)
                ExpenseForm(
                  nameController: _expenseNameController,
                  amountController: _expenseAmountController,
                  onFinish: _finishAddExpense,
                  onCancel: _cancelAddExpense,
                  formatNumber: _formatNumber,
                ),
            ],
          ],
        ),
      ),
    );
  }
}