
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../shared/database_instance.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

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
                ),
              ),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Opening balance (taka)',
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
                  return;
                }

                await database.addAccount(
                  name: name,
                  openingBalancePaisa: balance * 100,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyMoney'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Account>>(
        stream: database.watchAccounts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final accounts = snapshot.data!;

          if (accounts.isEmpty) {
            return const Center(
              child: Text('No accounts yet'),
            );
          }

          return StreamBuilder<List<Transaction>>(
            stream: database.watchTransactions(),
            builder: (context, transactionSnapshot) {
              if (!transactionSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final transactions = transactionSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];

                  final balance = transactions
                      .where((t) => t.accountId == account.id)
                      .fold<int>(
                    account.openingBalancePaisa,
                    (total, transaction) {
                      if (transaction.type == 'income') {
                        return total + transaction.amountPaisa;
                      }

                      return total - transaction.amountPaisa;
                    },
                  );

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(
                          Icons.account_balance_wallet,
                        ),
                      ),
                      title: Text(account.name),
                      subtitle: const Text('Current balance'),
                      trailing: Text(
                        formatMoney(balance),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
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
        onPressed: () => addAccount(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
