
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';
import '../../shared/database_instance.dart';

class TransferHistoryPage extends StatelessWidget {
  const TransferHistoryPage({super.key});

  static const Color primary = Color(0xFF4FA38D);
  static const Color background = Color(0xFFF8F9F2);
  static const Color darkText = Color(0xFF414331);

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
        title: const Text('Transfer History'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Account>>(
        stream: database.watchAccounts(),
        builder: (context, accountSnapshot) {
          if (accountSnapshot.hasError) {
            return Center(
              child: Text('Error: ${accountSnapshot.error}'),
            );
          }

          if (!accountSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final accounts = accountSnapshot.data!;

          final accountNames = {
            for (final account in accounts) account.id: account.name,
          };

          return StreamBuilder<List<Transfer>>(
            stream: database.watchTransfers(),
            builder: (context, transferSnapshot) {
              if (transferSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${transferSnapshot.error}'),
                );
              }

              if (!transferSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final transfers = transferSnapshot.data!;

              if (transfers.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 64,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No transfers yet.',
                          style: TextStyle(
                            fontSize: 17,
                            color: darkText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Your account transfers will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                itemCount: transfers.length,
                itemBuilder: (context, index) {
                  final transfer = transfers[index];

                  final fromName =
                      accountNames[transfer.fromAccountId] ??
                          'Unknown account';

                  final toName =
                      accountNames[transfer.toAccountId] ??
                          'Unknown account';

                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 43,
                                height: 43,
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.13),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.swap_horiz,
                                  color: primary,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Account Transfer',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      formatDate(transfer.date),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatMoney(transfer.amountPaisa),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 13),
                            child: Divider(height: 1),
                          ),

                          Row(
                            children: [
                              const Icon(
                                Icons.arrow_upward,
                                color: Colors.redAccent,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'From:',
                                style: TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  fromName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: darkText,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 9),

                          Row(
                            children: [
                              const Icon(
                                Icons.arrow_downward,
                                color: primary,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'To:',
                                style: TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  toName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: darkText,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (transfer.note != null &&
                              transfer.note!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Note: ${transfer.note}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
