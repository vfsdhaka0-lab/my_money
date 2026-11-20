
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../shared/database_instance.dart';

class NewTransferPage extends StatefulWidget {
  const NewTransferPage({super.key});

  @override
  State<NewTransferPage> createState() => _NewTransferPageState();
}

class _NewTransferPageState extends State<NewTransferPage> {
  static const Color primary = Color(0xFF4FA38D);
  static const Color background = Color(0xFFF8F9F2);
  static const Color darkText = Color(0xFF414331);

  final amountController = TextEditingController();
  final noteController = TextEditingController();

  int? fromAccountId;
  int? toAccountId;

  DateTime selectedDate = DateTime.now();

  bool isSaving = false;

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> saveTransfer() async {
    if (fromAccountId == null || toAccountId == null) {
      showMessage('Please select both accounts.');
      return;
    }

    if (fromAccountId == toAccountId) {
      showMessage('Please select two different accounts.');
      return;
    }

    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || !amount.isFinite || amount <= 0) {
      showMessage('Enter a valid transfer amount.');
      return;
    }

    if (amount > 90000000000000) {
      showMessage('Transfer amount is too large.');
      return;
    }

    final amountPaisa = (amount * 100).round();

    if (amountPaisa <= 0) {
      showMessage('Transfer amount must be greater than zero.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await database.addTransfer(
        fromAccountId: fromAccountId!,
        toAccountId: toAccountId!,
        amountPaisa: amountPaisa,
        date: selectedDate,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer completed successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      showMessage(
        e.toString().replaceFirst('Bad state: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('New Transfer'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 56,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: StreamBuilder<List<Account>>(
        stream: database.watchAccounts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final accounts = snapshot.data!;

          if (accounts.length < 2) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'You need at least two accounts to make a transfer.\n\n'
                  'Please add another account first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: darkText,
                  ),
                ),
              ),
            );
          }

          fromAccountId ??= accounts.first.id;

          toAccountId ??= accounts
              .firstWhere(
                (account) => account.id != fromAccountId,
              )
              .id;

          // Handle accounts being deleted while this screen is open.
          if (!accounts.any((a) => a.id == fromAccountId)) {
            fromAccountId = accounts.first.id;
          }

          if (!accounts.any((a) => a.id == toAccountId) ||
              toAccountId == fromAccountId) {
            toAccountId = accounts
                .firstWhere(
                  (account) => account.id != fromAccountId,
                )
                .id;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Transfer money between your accounts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: darkText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                DropdownButtonFormField<int>(
                  value: fromAccountId,
                  decoration: const InputDecoration(
                    labelText: 'From account',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    border: OutlineInputBorder(),
                  ),
                  items: accounts.map((account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            fromAccountId = value;
                            if (toAccountId == value) {
                              toAccountId = accounts
                                  .firstWhere(
                                    (a) => a.id != value,
                                  )
                                  .id;
                            }
                          });
                        },
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: toAccountId,
                  decoration: const InputDecoration(
                    labelText: 'To account',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(),
                  ),
                  items: accounts
                      .where((account) => account.id != fromAccountId)
                      .map((account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            toAccountId = value;
                          });
                        },
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: amountController,
                  enabled: !isSaving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (taka)',
                    hintText: 'e.g. 1000 or 1250.50',
                    prefixText: '৳ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : selectDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    'Date: ${formatDate(selectedDate)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: noteController,
                  enabled: !isSaving,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g. Cash to bKash',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: isSaving ? null : saveTransfer,
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.swap_horiz),
                    label: Text(
                      isSaving ? 'Saving...' : 'Transfer Money',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
