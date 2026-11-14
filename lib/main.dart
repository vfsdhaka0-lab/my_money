// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'core/database/app_database.dart';

final database = AppDatabase();

void main() {
  runApp(const MyMoneyApp());
}

class MyMoneyApp extends StatelessWidget {
  const MyMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyMoney',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const AccountsPage(),
    );
  }
}

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  String formatMoney(int paisa) {
    final taka = paisa ~/ 100;
    final remainder =
        (paisa % 100).toString().padLeft(2, '0');

    return '৳$taka.$remainder';
  }

  Future<void> showAddAccountDialog(
    BuildContext context,
  ) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) {
          String? error;

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
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
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final name =
                          nameController.text.trim();

                      final taka = int.tryParse(
                        balanceController.text.trim(),
                      );

                      if (name.isEmpty) {
                        setState(() {
                          error =
                              'Please enter an account name.';
                        });
                        return;
                      }

                      if (taka == null || taka < 0) {
                        setState(() {
                          error =
                              'Enter a valid whole-taka balance.';
                        });
                        return;
                      }

                      try {
                        await database.addAccount(
                          name: name,
                          openingBalancePaisa: taka * 100,
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (e) {
                        setState(() {
                          error = 'Could not save account.';
                        });
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
            return Center(
              child: Text(
                'Database error: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final accounts = snapshot.data!;

          if (accounts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text('No accounts yet'),
                  Text('Tap + to add your first account.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.account_balance_wallet,
                    ),
                  ),
                  title: Text(account.name),
                  subtitle: const Text('Opening balance'),
                  trailing: Text(
                    formatMoney(
                      account.openingBalancePaisa,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddAccountDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
