
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../shared/database_instance.dart';

class BorrowLendPage extends StatelessWidget {
  const BorrowLendPage({super.key});

  String _formatMoney(int paisa) {
    final amount = paisa / 100;
    return '৳${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow & Lend'),
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
      body: StreamBuilder(
        stream: database.watchBorrowLends(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong while loading records.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final records = snapshot.data!;

          if (records.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No Borrow or Lend Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your borrowed and lent money records '
                      'will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return FutureBuilder<List<int>>(
            future: Future.wait(
              records.map(
                (record) =>
                    database.getOutstandingBorrowLend(record.id),
              ),
            ),
            builder: (context, outstandingSnapshot) {
              if (outstandingSnapshot.hasError) {
                return const Center(
                  child: Text('Unable to calculate outstanding balances.'),
                );
              }

              if (!outstandingSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final outstandingAmounts = outstandingSnapshot.data!;

              int totalBorrowed = 0;
              int totalLent = 0;

              for (var i = 0; i < records.length; i++) {
                final type = records[i].type.toLowerCase();

                if (type == 'borrow') {
                  totalBorrowed += outstandingAmounts[i];
                } else if (type == 'lend') {
                  totalLent += outstandingAmounts[i];
                }
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait(
                    records.map(
                      (record) =>
                          database.getOutstandingBorrowLend(record.id),
                    ),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            title: 'Borrowed',
                            amount: totalBorrowed,
                            color: Colors.red,
                            icon: Icons.call_received_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryCard(
                            title: 'Lent',
                            amount: totalLent,
                            color: Colors.green,
                            icon: Icons.call_made_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'All Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(records.length, (index) {
                      final record = records[index];
                      final outstanding = outstandingAmounts[index];
                      final isBorrow =
                          record.type.toLowerCase() == 'borrow';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isBorrow
                                    ? Colors.red.withOpacity(0.10)
                                    : Colors.green.withOpacity(0.10),
                                child: Icon(
                                  isBorrow
                                      ? Icons.call_received_rounded
                                      : Icons.call_made_rounded,
                                  color: isBorrow
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.personName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isBorrow ? 'Borrowed' : 'Lent',
                                      style: TextStyle(
                                        color: isBorrow
                                            ? Colors.red
                                            : Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${_formatDate(record.date)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatMoney(outstanding),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    outstanding == 0
                                        ? 'Completed'
                                        : 'Outstanding',
                                    style: TextStyle(
                                      color: outstanding == 0
                                          ? Colors.green
                                          : Colors.orange,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required int amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatMoney(amount),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
