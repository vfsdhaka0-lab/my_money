
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../shared/database_instance.dart';
import '../../core/utils/money_formatter.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  Future<void> _addTransaction(BuildContext context) async {
    final accounts = await database.watchAccounts().first;

    if (!context.mounted) return;

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add an account first.'),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final paidController = TextEditingController();
    final storeController = TextEditingController();
    final noteController = TextEditingController();

    String selectedType = 'expense';
    String paymentStatus = 'paid';
    int selectedAccountId = accounts.first.id;
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDuePurchase =
                selectedType == 'expense' &&
                paymentStatus != 'paid';

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 24,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add Transaction',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // TRANSACTION TYPE

                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Transaction type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Expense'),
                        ),
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Income'),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) return;

                              setModalState(() {
                                selectedType = value;
                                paymentStatus = 'paid';
                                paidController.clear();
                                storeController.clear();
                              });
                            },
                    ),

                    const SizedBox(height: 16),

                    // TITLE

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Grocery shopping',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // AMOUNT

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (taka)',
                        hintText: 'e.g. 1000',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ACCOUNT

                    DropdownButtonFormField<int>(
                      value: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Account',
                        border: OutlineInputBorder(),
                      ),
                      items: accounts.map((account) {
                        return DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) return;

                              setModalState(() {
                                selectedAccountId = value;
                              });
                            },
                    ),

                    // PAYMENT STATUS FOR EXPENSES

                    if (selectedType == 'expense') ...[
                      const SizedBox(height: 20),

                      const Text(
                        'Payment status',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        value: paymentStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'paid',
                            child: Text('Fully Paid'),
                          ),
                          DropdownMenuItem(
                            value: 'partial',
                            child: Text('Partially Paid'),
                          ),
                          DropdownMenuItem(
                            value: 'full_due',
                            child: Text('Full Due'),
                          ),
                        ],
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value == null) return;

                                setModalState(() {
                                  paymentStatus = value;
                                  paidController.clear();
                                });
                              },
                      ),

                      // STORE NAME FOR DUE PURCHASES

                      if (isDuePurchase) ...[
                        const SizedBox(height: 16),

                        TextField(
                          controller: storeController,
                          decoration: const InputDecoration(
                            labelText: 'Store name',
                            hintText: 'e.g. Rahim Store',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],

                      // PAID AMOUNT ONLY FOR PARTIAL PAYMENT

                      if (paymentStatus == 'partial') ...[
                        const SizedBox(height: 16),

                        TextField(
                          controller: paidController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Paid immediately (taka)',
                            hintText: 'e.g. 400',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],

                      if (paymentStatus == 'full_due') ...[
                        const SizedBox(height: 10),

                        const Text(
                          'No payment will be deducted from your account now. '
                          'The full amount will be recorded as due.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 16),

                    // DATE

                    OutlinedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setModalState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        'Date: ${selectedDate.day}/'
                        '${selectedDate.month}/'
                        '${selectedDate.year}',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // NOTE

                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SAVE BUTTON

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final title =
                                    titleController.text.trim();

                                final amount = int.tryParse(
                                  amountController.text.trim(),
                                );

                                if (title.isEmpty ||
                                    amount == null ||
                                    amount <= 0) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Enter a valid title and amount.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final totalPaisa = amount * 100;

                                int paidPaisa = totalPaisa;

                                if (paymentStatus == 'partial') {
                                  final paid = int.tryParse(
                                    paidController.text.trim(),
                                  );

                                  if (paid == null ||
                                      paid <= 0 ||
                                      paid >= amount) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Enter a paid amount greater than zero '
                                          'and less than the total amount.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  paidPaisa = paid * 100;
                                } else if (paymentStatus == 'full_due') {
                                  paidPaisa = 0;
                                }

                                if (isDuePurchase &&
                                    storeController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Enter the store name.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  isSaving = true;
                                });

                                try {
                                  if (isDuePurchase) {
                                    await database.addPurchaseWithDue(
                                      accountId: selectedAccountId,
                                      title: title,
                                      totalAmountPaisa: totalPaisa,
                                      paidAmountPaisa: paidPaisa,
                                      storeName:
                                          storeController.text.trim(),
                                      date: selectedDate,
                                      note: noteController.text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : noteController.text.trim(),
                                    );
                                  } else {
                                    await database.addTransaction(
                                      accountId: selectedAccountId,
                                      title: title,
                                      amountPaisa: totalPaisa,
                                      type: selectedType,
                                      date: selectedDate,
                                      note: noteController.text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : noteController.text.trim(),
                                    );
                                  }

                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
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
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Transaction'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    amountController.dispose();
    paidController.dispose();
    storeController.dispose();
    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Transaction>>(
        stream: database.watchTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const Center(
              child: Text('No transactions yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final item = transactions[index];

              final isIncome = item.type == 'income';
              final isPartiallyPaid =
                  item.paidAmountPaisa < item.amountPaisa;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIncome
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.red.withValues(alpha: 0.12),
                    child: Icon(
                      isIncome
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.date.day}/'
                        '${item.date.month}/'
                        '${item.date.year}',
                      ),
                      if (isPartiallyPaid) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Paid: ${formatMoney(item.paidAmountPaisa)}'
                          '  •  Due: ${formatMoney(item.amountPaisa - item.paidAmountPaisa)}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : '-'}'
                    '${formatMoney(item.amountPaisa)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // ADD TRANSACTION BUTTON

      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () => _addTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
