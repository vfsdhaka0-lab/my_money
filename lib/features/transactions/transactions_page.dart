
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../shared/database_instance.dart';
import '../../core/utils/money_formatter.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  // VALIDATION WARNING DIALOG

  Future<void> _showValidationDialog(
    BuildContext context,
    String message,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Required information'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ADD TRANSACTION

  Future<void> _addTransaction(BuildContext context) async {
    final accounts = await database.watchAccounts().first;
    final expenseCategories =
        await database.watchCategories(type: 'Expense').first;
    final incomeCategories =
        await database.watchCategories(type: 'Income').first;
    final stores = await database.watchStores().first;

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
    final noteController = TextEditingController();

    String selectedType = 'expense';
    String paymentStatus = 'paid';

    int selectedAccountId = accounts.first.id;
    int? selectedCategoryId;
    int? selectedStoreId;

    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    try {
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

              final availableCategories =
                  selectedType == 'expense'
                      ? expenseCategories
                      : incomeCategories;

              final selectedCategoryExists =
                  availableCategories.any(
                (category) => category.id == selectedCategoryId,
              );

              final selectedStoreExists = stores.any(
                (store) => store.id == selectedStoreId,
              );

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
                                  selectedCategoryId = null;
                                  selectedStoreId = null;
                                  paidController.clear();
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      // CATEGORY

                      DropdownButtonFormField<int?>(
                        value: selectedCategoryExists
                            ? selectedCategoryId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Category (optional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('No category'),
                          ),
                          ...availableCategories.map((category) {
                            return DropdownMenuItem<int?>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }),
                        ],
                        onChanged: isSaving
                            ? null
                            : (value) {
                                setModalState(() {
                                  selectedCategoryId = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      // TITLE

                      TextField(
                        controller: titleController,
                        enabled: !isSaving,
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
                        enabled: !isSaving,
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
                                    selectedStoreId = null;
                                  });
                                },
                        ),

                        // STORE SELECTION

                        if (isDuePurchase) ...[
                          const SizedBox(height: 16),

                          if (stores.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'No stores available. Please add a store '
                                'from Categories & Stores first.',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            DropdownButtonFormField<int>(
                              value: selectedStoreExists
                                  ? selectedStoreId
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Select store',
                                border: OutlineInputBorder(),
                              ),
                              items: stores.map((store) {
                                return DropdownMenuItem<int>(
                                  value: store.id,
                                  child: Text(store.name),
                                );
                              }).toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      setModalState(() {
                                        selectedStoreId = value;
                                      });
                                    },
                            ),
                        ],

                        // PARTIAL PAYMENT AMOUNT

                        if (paymentStatus == 'partial') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: paidController,
                            enabled: !isSaving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Paid immediately (taka)',
                              hintText: 'e.g. 400',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],

                        // FULL DUE INFORMATION

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
                        enabled: !isSaving,
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

                                  // VALIDATE TITLE AND AMOUNT

                                  if (title.isEmpty ||
                                      amount == null ||
                                      amount <= 0) {
                                    await _showValidationDialog(
                                      sheetContext,
                                      'Please enter a valid transaction title '
                                      'and an amount greater than zero.',
                                    );
                                    return;
                                  }

                                  final totalPaisa = amount * 100;

                                  int paidPaisa = totalPaisa;

                                  // VALIDATE PARTIAL PAYMENT

                                  if (paymentStatus == 'partial') {
                                    final paid = int.tryParse(
                                      paidController.text.trim(),
                                    );

                                    if (paid == null ||
                                        paid <= 0 ||
                                        paid >= amount) {
                                      await _showValidationDialog(
                                        sheetContext,
                                        'Please enter a paid amount greater '
                                        'than zero and less than the total amount.',
                                      );
                                      return;
                                    }

                                    paidPaisa = paid * 100;
                                  } else if (paymentStatus == 'full_due') {
                                    paidPaisa = 0;
                                  }

                                  // VALIDATE STORE

                                  if (isDuePurchase &&
                                      (selectedStoreId == null ||
                                          stores.isEmpty)) {
                                    await _showValidationDialog(
                                      sheetContext,
                                      'Please add a store in Categories & Stores '
                                      'and select a store for this due purchase.',
                                    );
                                    return;
                                  }

                                  setModalState(() {
                                    isSaving = true;
                                  });

                                  try {
                                    if (isDuePurchase) {
                                      final selectedStore =
                                          stores.firstWhere(
                                        (store) =>
                                            store.id == selectedStoreId,
                                      );

                                      await database.addPurchaseWithDue(
                                        accountId: selectedAccountId,
                                        title: title,
                                        totalAmountPaisa: totalPaisa,
                                        paidAmountPaisa: paidPaisa,
                                        storeName: selectedStore.name,
                                        categoryId: selectedCategoryId,
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
                                        categoryId: selectedCategoryId,
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
                                    if (context.mounted) {
                                      setModalState(() {
                                        isSaving = false;
                                      });

                                      await _showValidationDialog(
                                        sheetContext,
                                        'Could not save transaction:\n$e',
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
    } finally {
      titleController.dispose();
      amountController.dispose();
      paidController.dispose();
      noteController.dispose();
    }
  }

  // CONFIRM DELETE

  Future<bool> _confirmDelete(
    BuildContext context,
    Transaction item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: Text(
            'Are you sure you want to delete "${item.title}"?\n\n'
            'Any related due records and due payments will also be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return false;
    }

    try {
      await database.deleteTransaction(item.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully.'),
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete transaction: $e'),
          ),
        );
      }

      return false;
    }
  }

  // BUILD TRANSACTION LIST

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Account>>(
        stream: database.watchAccounts(),
        builder: (context, accountSnapshot) {
          if (accountSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final accounts = accountSnapshot.data ?? [];

          final accountNames = {
            for (final account in accounts)
              account.id: account.name,
          };

          return StreamBuilder<List<Transaction>>(
            stream: database.watchTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('Could not load transactions.'),
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
                      item.paidAmountPaisa > 0 &&
                      item.paidAmountPaisa < item.amountPaisa;

                  final isFullDue =
                      item.type == 'expense' &&
                      item.paidAmountPaisa == 0;

                  final accountName =
                      accountNames[item.accountId] ??
                          'Unknown account';

                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) =>
                        _confirmDelete(context, item),
                    onDismissed: (_) {},
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.only(right: 24),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: Card(
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
                            color:
                                isIncome ? Colors.green : Colors.red,
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
                            const SizedBox(height: 4),

                            // PAYMENT ACCOUNT INFORMATION

                            Text(
                              isFullDue
                                  ? 'Fully due — no payment made yet'
                                  : 'Paid by: $accountName',
                              style: TextStyle(
                                fontSize: 12,
                                color: isFullDue
                                    ? Colors.orange
                                    : Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                              ),
                            ),

                            // PARTIAL PAYMENT INFORMATION

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
                            color: isIncome
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
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
        shape: const CircleBorder(),
        onPressed: () => _addTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
