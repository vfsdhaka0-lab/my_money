
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../shared/database_instance.dart';
import 'borrow_lend_details_page.dart';
import 'new_borrow_lend_page.dart';

class BorrowLendPage extends StatelessWidget {
  final VoidCallback onMenuPressed;

  const BorrowLendPage({
    super.key,
    required this.onMenuPressed,
  });

  String _formatMoney(int paisa) {
    return '৳${(paisa / 100).toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  int _getOutstanding(int originalAmount, int paidAmount) {
    final outstanding = originalAmount - paidAmount;
    return outstanding < 0 ? 0 : outstanding;
  }

  Future<void> _openNewPage(
    BuildContext context,
    String type,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewBorrowLendPage(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: onMenuPressed,
          icon: const Icon(Icons.menu),
          tooltip: 'Open menu',
        ),
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
        builder: (context, recordSnapshot) {
          if (recordSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load Borrow & Lend records.'),
            );
          }

          if (!recordSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final records = recordSnapshot.data!;

          return StreamBuilder(
            stream: database
                .select(database.borrowLendPayments)
                .watch(),
            builder: (context, paymentSnapshot) {
              if (paymentSnapshot.hasError) {
                return const Center(
                  child: Text('Unable to load repayment records.'),
                );
              }

              if (!paymentSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final payments = paymentSnapshot.data!;

              int totalBorrowed = 0;
              int totalLent = 0;

              final outstandingAmounts = records.map((record) {
                final paidAmount = payments
                    .where(
                      (payment) =>
                          payment.borrowLendId == record.id,
                    )
                    .fold<int>(
                      0,
                      (total, payment) =>
                          total + payment.amountPaisa,
                    );

                final outstanding = _getOutstanding(
                  record.amountPaisa,
                  paidAmount,
                );

                if (record.type.toLowerCase() == 'borrow') {
                  totalBorrowed += outstanding;
                } else if (record.type.toLowerCase() == 'lend') {
                  totalLent += outstanding;
                }

                return outstanding;
              }).toList();

              return ListView(
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _openNewPage(context, 'borrow'),
                            icon: const Icon(
                              Icons.call_received_rounded,
                            ),
                            label: const Text('Borrow'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _openNewPage(context, 'lend'),
                            icon: const Icon(
                              Icons.call_made_rounded,
                            ),
                            label: const Text('Lend'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
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
                  if (records.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No Borrow or Lend Records',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tap Borrow or Lend to add your first record.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(records.length, (index) {
                      final record = records[index];
                      final outstanding = outstandingAmounts[index];
                      final isBorrow =
                          record.type.toLowerCase() == 'borrow';

                      final color =
                          isBorrow ? Colors.red : Colors.green;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BorrowLendDetailsPage(
                                  record: record,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      color.withOpacity(0.10),
                                  child: Icon(
                                    isBorrow
                                        ? Icons.call_received_rounded
                                        : Icons.call_made_rounded,
                                    color: color,
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
                                          color: color,
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
                                    const SizedBox(height: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
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
