
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../shared/database_instance.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';
import '../transactions/transactions_page.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  static const Color primary = Color(0xFF4FA38D);
  static const Color background = Color(0xFFF8F9F2);
  static const Color accent = Color(0xFFFFB900);
  static const Color darkText = Color(0xFF414331);

  // ADD ACCOUNT

  Future<void> addAccount(BuildContext context) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Account name',
                  hintText: 'e.g. Cash, bKash, Bank',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Opening balance (taka)',
                  hintText: 'e.g. 5000',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final balance = int.tryParse(
                  balanceController.text.trim(),
                );

                if (name.isEmpty ||
                    balance == null ||
                    balance < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid name and balance.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await database.addAccount(
                    name: name,
                    openingBalancePaisa: balance * 100,
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Could not save account.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      nameController.dispose();
      balanceController.dispose();
    }
  }

  // ACCOUNT BALANCE

  int accountBalance(
    Account account,
    List<Transaction> transactions,
  ) {
    return transactions
        .where((t) => t.accountId == account.id)
        .fold<int>(
      account.openingBalancePaisa,
      (total, transaction) {
        if (transaction.type == 'income') {
          return total + transaction.amountPaisa;
        }

        if (transaction.type == 'expense') {
          return total - transaction.amountPaisa;
        }

        return total;
      },
    );
  }

  // ACCOUNT ICON

  IconData accountIcon(String name) {
    final value = name.toLowerCase();

    if (value.contains('cash')) {
      return Icons.payments_outlined;
    }

    if (value.contains('bkash') || value.contains('nagad')) {
      return Icons.account_balance_wallet_outlined;
    }

    if (value.contains('bank')) {
      return Icons.account_balance_outlined;
    }

    return Icons.wallet_outlined;
  }

  // ACCOUNT COLOR

  Color accountColor(String name) {
    final value = name.toLowerCase();

    if (value.contains('cash')) {
      return const Color(0xFF91B58F);
    }

    if (value.contains('bkash')) {
      return const Color(0xFFE83E8C);
    }

    if (value.contains('nagad')) {
      return const Color(0xFFE87532);
    }

    if (value.contains('bank')) {
      return const Color(0xFF4F83C2);
    }

    return primary;
  }

  void showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature will be available in a future update.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // DRAWER

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: primary,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'MyMoney',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
              ),
              title: const Text('Accounts'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Transactions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // APP BAR

      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
        title: const Text(
          'Accounts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ACCOUNT LIST

      body: StreamBuilder<List<Account>>(
        stream: database.watchAccounts(),
        builder: (context, accountSnapshot) {
          if (accountSnapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${accountSnapshot.error}',
              ),
            );
          }

          if (!accountSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final accounts = accountSnapshot.data!;

          return StreamBuilder<List<Transaction>>(
            stream: database.watchTransactions(),
            builder: (context, transactionSnapshot) {
              if (transactionSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${transactionSnapshot.error}',
                  ),
                );
              }

              if (!transactionSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final transactions = transactionSnapshot.data!;

              final totalBalance = accounts.fold<int>(
                0,
                (total, account) =>
                    total +
                    accountBalance(account, transactions),
              );

              return ListView(
                padding: const EdgeInsets.only(
                  top: 38,
                  bottom: 100,
                ),
                children: [
                  // TOTAL LABEL

                  const Center(
                    child: Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // TOTAL BALANCE

                  Center(
                    child: Text(
                      formatMoney(totalBalance),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // TRANSFER SHORTCUTS

                  Row(
                    children: [
                      Expanded(
                        child: _Shortcut(
                          icon: Icons.history,
                          title: 'Transfer history',
                          onTap: () => showComingSoon(
                            context,
                            'Transfer history',
                          ),
                        ),
                      ),
                      Expanded(
                        child: _Shortcut(
                          icon: Icons.swap_horiz,
                          title: 'New transfer',
                          onTap: () => showComingSoon(
                            context,
                            'Account transfers',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ACCOUNTS

                  if (accounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          'No accounts yet. Add your first account.',
                        ),
                      ),
                    ),

                  ...accounts.map((account) {
                    final balance = accountBalance(
                      account,
                      transactions,
                    );

                    final color = accountColor(account.name);

                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 23,
                          backgroundColor: color,
                          child: Icon(
                            accountIcon(account.name),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          formatMoney(balance),
                          style: const TextStyle(
                            fontSize: 17,
                            color: darkText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),

      // ADD ACCOUNT BUTTON

      floatingActionButton: FloatingActionButton(
        mini: false,
        shape: const CircleBorder(),
        backgroundColor: accent,
        foregroundColor: darkText,
        elevation: 5,
        onPressed: () => addAccount(context),
        child: const Icon(
          Icons.add,
          size: 32,
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}

// TRANSFER SHORTCUT WIDGET

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _Shortcut({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AccountsPage.primary,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AccountsPage.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
