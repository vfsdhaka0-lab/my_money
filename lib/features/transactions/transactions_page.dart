
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../shared/database_instance.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  Future<void> addTransaction(BuildContext context) async {
    final accounts = await database.watchAccounts().first;

    if (!context.mounted) return;

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an account first.'),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    int selectedAccountId = accounts.first.id;
    String selectedType = 'expense';

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Add Transaction'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Transaction type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'income',
                            child: Text('Income'),
                          ),
                          DropdownMenuItem(
                            value: 'expense',
                            child: Text('Expense'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                        ),
                      ),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount (taka)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Select account',
                        ),
                        items: accounts.map((account) {
                          return DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedAccountId = value;
                            });
                          }
                        },
                      ),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final amount = int.tryParse(
                        amountController.text.trim(),
                      );

                      if (title.isEmpty ||
                          amount == null ||
                          amount <= 0) {
                        return;
                      }

                      await database.addTransaction(
                        accountId: selectedAccountId,
                        title: title,
                        amountPaisa: amount * 100,
                        type: selectedType,
                        date: DateTime.now(),
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      amountController.dispose();
      noteController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: database.watchTransactions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final transactions = snapshot.data!;

          if (transactions.isEmpty) {
            return const Center(
              child: Text('No transactions yet'),
            );
          }

          return StreamBuilder<List<Account>>(
            stream: database.watchAccounts(),
            builder: (context, accountSnapshot) {
              if (!accountSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final accounts = accountSnapshot.data!;

              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];

                  final matchingAccounts = accounts.where(
                    (a) => a.id == transaction.accountId,
                  );

                  if (matchingAccounts.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final account = matchingAccounts.first;
                  final isIncome =
                      transaction.type == 'income';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome
                          ? Colors.green.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      child: Icon(
                        isIncome
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: isIncome
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    title: Text(transaction.title),
                    subtitle: Text(
                      '${account.name} • '
                      '${transaction.date.day}/'
                      '${transaction.date.month}/'
                      '${transaction.date.year}',
                    ),
                    trailing: Text(
                      '${isIncome ? '+' : '-'}'
                      '${formatMoney(transaction.amountPaisa)}',
                      style: TextStyle(
                        color: isIncome
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
