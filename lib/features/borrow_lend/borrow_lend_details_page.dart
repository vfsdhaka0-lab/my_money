
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../shared/database_instance.dart';
import 'borrow_lend_payment_page.dart';

class BorrowLendDetailsPage extends StatefulWidget {
  final BorrowLend record;

  const BorrowLendDetailsPage({
    super.key,
    required this.record,
  });

  @override
  State<BorrowLendDetailsPage> createState() =>
      _BorrowLendDetailsPageState();
}

class _BorrowLendDetailsPageState
    extends State<BorrowLendDetailsPage> {
  String _formatMoney(int paisa) {
    return '৳${(paisa / 100).toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  bool get _isBorrow =>
      widget.record.type.toLowerCase() == 'borrow';

  @override
  Widget build(BuildContext context) {
    final color = _isBorrow ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow & Lend Details'),
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
        stream: database.watchBorrowLendPayments(widget.record.id),
        builder: (context, paymentSnapshot) {
          if (paymentSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load repayment history.'),
            );
          }

          if (!paymentSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final payments = paymentSnapshot.data!;

          final paidAmount = payments.fold<int>(
            0,
            (total, payment) => total + payment.amountPaisa,
          );

          final outstanding =
              widget.record.amountPaisa - paidAmount;

          final safeOutstanding =
              outstanding < 0 ? 0 : outstanding;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.record.personName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isBorrow ? 'Borrowed Money' : 'Lent Money',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _amountRow(
                      'Original Amount',
                      widget.record.amountPaisa,
                    ),
                    const SizedBox(height: 12),
                    _amountRow(
                      'Total Repaid',
                      paidAmount,
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Outstanding Balance',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatMoney(safeOutstanding),
                      style: TextStyle(
                        color: safeOutstanding == 0
                            ? Colors.green
                            : color,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (safeOutstanding == 0) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Fully settled',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _informationCard(
                icon: Icons.calendar_today,
                title: 'Date',
                value: _formatDate(widget.record.date),
              ),

              if (widget.record.note != null &&
                  widget.record.note!.trim().isNotEmpty)
                _informationCard(
                  icon: Icons.notes,
                  title: 'Note',
                  value: widget.record.note!,
                ),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Repayment History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${payments.length} payment(s)',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (payments.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No repayments recorded yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ...payments.map((payment) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 9),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(
                          Icons.payments_outlined,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        _formatMoney(payment.amountPaisa),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(_formatDate(payment.date)),
                          if (payment.note != null &&
                              payment.note!.trim().isNotEmpty)
                            Text(payment.note!),
                        ],
                      ),
                    ),
                  );
                }),

              if (safeOutstanding > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BorrowLendPaymentPage(
                            borrowLendId: widget.record.id,
                            personName: widget.record.personName,
                            type: widget.record.type,
                            outstandingPaisa: safeOutstanding,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Record Repayment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _amountRow(String title, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          _formatMoney(amount),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _informationCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
