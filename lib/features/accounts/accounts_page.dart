
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../shared/database_instance.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';
import 'new_transfer_page.dart';
import 'transfer_history_page.dart';

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

  // CONFIRM AND DELETE ACCOUNT

  Future<bool> confirmDelete(
    BuildContext context,
    Account account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'Are you sure you want to delete "${account.name}"?\n\n'
          'An account used by transactions, due payments, '
          'transfers, Borrow & Lend records, or balance adjustments '
          'cannot be deleted.',
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
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return false;
    }

    try {
      final deleted =
          await database.deleteAccountIfUnused(account.id);

      if (!context.mounted) {
        return deleted;
      }

      if (!deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot delete this account because it is used '
              'by transactions, due payments, transfers, '
              'Borrow & Lend records, or balance adjustments.',
            ),
          ),
        );

        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted.'),
        ),
      );

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete account: $e'),
          ),
        );
      }

      return false;
    }
  }

  // ACCOUNT BALANCE

  int accountBalance(
    Account account,
    List<Transaction> transactions,
    List<DuePayment> duePayments,
    List<Transfer> transfers,
    List<BorrowLend> borrowLends,
    List<BorrowLendPayment> borrowLendPayments,
    List<AccountAdjustment> accountAdjustments,
  ) {
    final transactionBalance = transactions
        .where((t) => t.accountId == account.id)
        .fold<int>(
      account.openingBalancePaisa,
      (total, item) {
        if (item.type == 'income') {
          return total + item.paidAmountPaisa;
        }

        if (item.type == 'expense') {
          return total - item.paidAmountPaisa;
        }

        return total;
      },
    );

    final totalDuePayments = duePayments
        .where((payment) => payment.accountId == account.id)
        .fold<int>(
      0,
      (total, payment) => total + payment.amountPaisa,
    );

    final outgoingTransfers = transfers
        .where((transfer) => transfer.fromAccountId == account.id)
        .fold<int>(
      0,
      (total, transfer) => total + transfer.amountPaisa,
    );

    final incomingTransfers = transfers
        .where((transfer) => transfer.toAccountId == account.id)
        .fold<int>(
      0,
      (total, transfer) => total + transfer.amountPaisa,
    );

    // Original borrowing and lending amounts.

    final borrowedAmount = borrowLends
        .where(
          (item) =>
              item.accountId == account.id &&
              item.type == 'borrow',
        )
        .fold<int>(
      0,
      (total, item) => total + item.amountPaisa,
    );

    final lentAmount = borrowLends
        .where(
          (item) =>
              item.accountId == account.id &&
              item.type == 'lend',
        )
        .fold<int>(
      0,
      (total, item) => total + item.amountPaisa,
    );

    // Repayments made for borrowed money.

    final borrowedRepayments = borrowLendPayments
        .where((payment) => payment.accountId == account.id)
        .where((payment) {
          return borrowLends.any(
            (item) =>
                item.id == payment.borrowLendId &&
                item.type == 'borrow',
          );
        })
        .fold<int>(
      0,
      (total, payment) => total + payment.amountPaisa,
    );

    // Repayments received for lent money.

    final lentRepayments = borrowLendPayments
        .where((payment) => payment.accountId == account.id)
        .where((payment) {
          return borrowLends.any(
            (item) =>
                item.id == payment.borrowLendId &&
                item.type == 'lend',
          );
        })
        .fold<int>(
      0,
      (total, payment) => total + payment.amountPaisa,
    );

    // Include account balance adjustments.

    final totalAdjustments = accountAdjustments
        .where((item) => item.accountId == account.id)
        .fold<int>(
      0,
      (total, item) => total + item.amountPaisa,
    );

    return transactionBalance -
        totalDuePayments -
        outgoingTransfers +
        incomingTransfers +
        borrowedAmount -
        lentAmount -
        borrowedRepayments +
        lentRepayments +
        totalAdjustments;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

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

              // DUE PAYMENT STREAM

              return StreamBuilder<List<DuePayment>>(
                stream: database.watchAllDuePayments(),
                builder: (context, paymentSnapshot) {
                  if (paymentSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${paymentSnapshot.error}',
                      ),
                    );
                  }

                  if (!paymentSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final duePayments = paymentSnapshot.data!;

                  // TRANSFER STREAM

                  return StreamBuilder<List<Transfer>>(
                    stream: database.watchTransfers(),
                    builder: (context, transferSnapshot) {
                      if (transferSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${transferSnapshot.error}',
                          ),
                        );
                      }

                      if (!transferSnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final transfers = transferSnapshot.data!;

                      // BORROW & LEND STREAM

                      return StreamBuilder<List<BorrowLend>>(
                        stream: database.watchBorrowLends(),
                        builder: (context, borrowLendSnapshot) {
                          if (borrowLendSnapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${borrowLendSnapshot.error}',
                              ),
                            );
                          }

                          if (!borrowLendSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final borrowLends =
                              borrowLendSnapshot.data!;

                          // BORROW & LEND REPAYMENT STREAM

                          return StreamBuilder<List<BorrowLendPayment>>(
                            stream: database
                                .select(database.borrowLendPayments)
                                .watch(),
                            builder: (context, borrowPaymentSnapshot) {
                              if (borrowPaymentSnapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error: ${borrowPaymentSnapshot.error}',
                                  ),
                                );
                              }

                              if (!borrowPaymentSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final borrowLendPayments =
                                  borrowPaymentSnapshot.data!;

                              // ACCOUNT ADJUSTMENT STREAM

                              return StreamBuilder<
                                  List<AccountAdjustment>>(
                                stream: database
                                    .watchAllAccountAdjustments(),
                                builder: (
                                  context,
                                  adjustmentSnapshot,
                                ) {
                                  if (adjustmentSnapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'Error: ${adjustmentSnapshot.error}',
                                      ),
                                    );
                                  }

                                  if (!adjustmentSnapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final accountAdjustments =
                                      adjustmentSnapshot.data!;

                                  // TOTAL BALANCE

                                  final totalBalance = accounts.fold<int>(
                                    0,
                                    (total, account) =>
                                        total +
                                        accountBalance(
                                          account,
                                          transactions,
                                          duePayments,
                                          transfers,
                                          borrowLends,
                                          borrowLendPayments,
                                          accountAdjustments,
                                        ),
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
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const TransferHistoryPage(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: _Shortcut(
                                              icon: Icons.swap_horiz,
                                              title: 'New transfer',
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const NewTransferPage(),
                                                  ),
                                                );
                                              },
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
                                          duePayments,
                                          transfers,
                                          borrowLends,
                                          borrowLendPayments,
                                          accountAdjustments,
                                        );

                                        final color =
                                            accountColor(account.name);

                                        return Dismissible(
                                          key: ValueKey(account.id),
                                          direction:
                                              DismissDirection.endToStart,

                                          background: Container(
                                            margin:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(17),
                                            ),
                                            alignment:
                                                Alignment.centerRight,
                                            padding:
                                                const EdgeInsets.only(
                                              right: 24,
                                            ),
                                            child: const Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          confirmDismiss: (_) async {
                                            return confirmDelete(
                                              context,
                                              account,
                                            );
                                          },

                                          onDismissed: (_) {},

                                          child: Card(
                                            color: Colors.white,
                                            elevation: 2,
                                            margin:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(17),
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
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                              ),
                                              trailing: Text(
                                                formatMoney(balance),
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  color: darkText,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
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
                          );
                        },
                      );
                    },
                  );
                },
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
