
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../shared/database_instance.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  // ADD TRANSACTION

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
    final paidController = TextEditingController(text: '0');
    final storeController = TextEditingController();
    final noteController = TextEditingController();

    int selectedAccountId = accounts.first.id;
    String selectedType = 'expense';
    bool isDuePurchase = false;
    bool isSaving = false;

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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TRANSACTION TYPE

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

                              if (value == 'income') {
                                isDuePurchase = false;
                              }
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // TITLE

                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g. Groceries, Salary',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // TOTAL AMOUNT

                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: selectedType == 'income'
                              ? 'Amount (taka)'
                              : 'Expense amount (taka)',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // DUE PURCHASE OPTION

                      if (selectedType == 'expense') ...[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Purchase with Due',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'I have not paid the full amount.',
                          ),
                          value: isDuePurchase,
                          onChanged: (value) {
                            setState(() {
                              isDuePurchase = value;
                            });
                          },
                        ),
                      ],

                      // DUE PURCHASE FIELDS

                      if (isDuePurchase) ...[
                        const SizedBox(height: 8),

                        TextField(
                          controller: storeController,
                          decoration: const InputDecoration(
                            labelText: 'Store name',
                            hintText: 'e.g. Rahim Store',
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: paidController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Paid immediately (taka)',
                            hintText: 'Enter 0 for full due',
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'The remaining amount will be '
                          'recorded as outstanding due.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // ACCOUNT

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

                      const SizedBox(height: 12),

                      // NOTE

                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                        ),
                      ),
                    ],
                  ),
                ),

                // ACTIONS

                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),

                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title =
                                titleController.text.trim();

                            final amount = int.tryParse(
                              amountController.text.trim(),
                            );

                            final storeName =
                                storeController.text.trim();

                            final paidAmount = int.tryParse(
                              paidController.text.trim(),
                            );

                            // BASIC VALIDATION

                            if (title.isEmpty ||
                                amount == null ||
                                amount <= 0) {
                              ScaffoldMessenger.of(
                                dialogContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Enter a valid title and amount.',
                                  ),
                                ),
                              );
                              return;
                            }

                            // DUE VALIDATION

                            if (isDuePurchase) {
                              if (storeName.isEmpty) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter the store name.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (paidAmount == null ||
                                  paidAmount < 0 ||
                                  paidAmount >= amount) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Paid amount must be zero or '
                                      'less than the total amount.',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            setState(() {
                              isSaving = true;
                            });

                            try {
                              final note =
                                  noteController.text.trim().isEmpty
                                      ? null
                                      : noteController.text.trim();

                              if (isDuePurchase) {
                                // PURCHASE WITH PARTIAL OR FULL DUE

                                await database.addPurchaseWithDue(
                                  accountId: selectedAccountId,
                                  title: title,
                                  totalAmountPaisa: amount * 100,
                                  paidAmountPaisa: paidAmount! * 100,
                                  storeName: storeName,
                                  date: DateTime.now(),
                                  note: note,
                                );
                              } else {
                                // NORMAL INCOME OR EXPENSE

                                await database.addTransaction(
                                  accountId: selectedAccountId,
                                  title: title,
                                  amountPaisa: amount * 100,
                                  type: selectedType,
                                  date: DateTime.now(),
                                  note: note,
                                );
                              }

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                setState(() {
                                  isSaving = false;
                                });

                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Could not save transaction: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save'),
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
      paidController.dispose();
      storeController.dispose();
      noteController.dispose();
    }
  }

  // TRANSACTION PAGE

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
            return Center(
              child: Text('${snapshot.error}'),
            );
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

                  final isPartiallyPaid =
                      !isIncome &&
                      transaction.paidAmountPaisa <
                          transaction.amountPaisa;

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

                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${account.name} • '
                          '${transaction.date.day}/'
                          '${transaction.date.month}/'
                          '${transaction.date.year}',
                        ),

                        if (isPartiallyPaid)
                          Text(
                            'Paid: ${formatMoney(transaction.paidAmountPaisa)} '
                            '• Due: ${formatMoney(transaction.amountPaisa - transaction.paidAmountPaisa)}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                      ],
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
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
