import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/expense_form.dart';
import '../widgets/expense_table.dart';
import '../widgets/action_buttons.dart';

class CalculationPage extends StatefulWidget {
  const CalculationPage({super.key});

  @override
  State<CalculationPage> createState() => _CalculationPageState();
}

class _CalculationPageState extends State<CalculationPage> {
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();

  final List<Map<String, dynamic>> _expenses = [];
  bool _salaryLocked = false;
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

  void _lockSalary() {
    final text = _salaryController.text.trim();
    if (text.isEmpty) {
      _showSnack('Jumlah gaji tidak boleh kosong');
      return;
    }
    if (!_isNumeric(text)) {
      _showSnack('Jumlah gaji harus berupa angka');
      return;
    }
    setState(() {
      _salaryLocked = true;
    });
  }

  void _resetAll() {
    setState(() {
      _salaryController.clear();
      _expenses.clear();
      _salaryLocked = false;
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
    final salaryText = _salaryController.text.trim();
    if (salaryText.isEmpty || !_isNumeric(salaryText)) {
      _showSnack('Jumlah gaji harus diisi dan berupa angka');
      return;
    }
    if (_expenses.isEmpty) {
      _showSnack('Tambahkan minimal satu pengeluaran terlebih dahulu');
      return;
    }

    final int salary = _parseInt(salaryText);
    final int totalExpenses =
        _expenses.fold(0, (sum, e) => sum + (e['amount'] as int));
    final int remaining = salary - totalExpenses;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hasil Kalkulasi'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gaji: Rp ${currencyFormat.format(salary)}'),
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
      appBar: AppBar(title: const Text('Pengkalkulasian Keuangan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              enabled: !_salaryLocked,
              decoration: const InputDecoration(
                labelText: 'Jumlah Gaji',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                final formatted = _formatNumber(val);
                _salaryController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              },
            ),
            const SizedBox(height: 16),
            if (!_salaryLocked)
              ElevatedButton(
                onPressed: _lockSalary,
                child: const Text('Lanjutkan'),
              ),
            if (_salaryLocked) ...[
              ActionButtons(
                onAdd: _startAddExpense,
                onShowTable:
                    _expenses.isNotEmpty && !_isAddingExpense ? _showExpenseTable : () {},
                onCalculate:
                    _expenses.isNotEmpty && !_isAddingExpense ? _calculate : () {},
                onReset: _resetAll,
                hasExpenses: _expenses.isNotEmpty,
                isAdding: _isAddingExpense,
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