
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';
import '../../shared/database_instance.dart';

class AccountAdjustmentHistoryPage extends StatelessWidget {
  final Account account;

  const AccountAdjustmentHistoryPage({
    super.key,
    required this.account,
  });

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String displayMoney(int paisa) {
    if (paisa >= 0) {
      return formatMoney(paisa);
    }

    return '-${formatMoney(paisa.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        title: const Text('Adjustment History'),
        backgroundColor: const Color(0xFF4FA38D),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AccountAdjustment>>(
        stream: database.watchAccountAdjustments(account.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final adjustments = snapshot.data!;

          if (adjustments.isEmpty) {
            return const Center(
              child: Text(
                'No balance adjustments yet.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            );
          }

          final totalAdjustments = adjustments.fold<int>(
            0,
            (total, item) => total + item.amountPaisa,
          );

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Adjustment',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${totalAdjustments > 0 ? '+' : ''}'
                        '${displayMoney(totalAdjustments)}',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: totalAdjustments > 0
                              ? Colors.green
                              : totalAdjustments < 0
                                  ? Colors.red
                                  : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        account.name,
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 20,
                  ),
                  itemCount: adjustments.length,
                  itemBuilder: (context, index) {
                    final adjustment = adjustments[index];
                    final isIncrease =
                        adjustment.amountPaisa > 0;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isIncrease
                              ? Colors.green.withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          child: Icon(
                            isIncrease
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: isIncrease
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(
                          adjustment.reason,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            formatDate(adjustment.date),
                          ),
                        ),
                        trailing: Text(
                          '${isIncrease ? '+' : ''}'
                          '${displayMoney(adjustment.amountPaisa)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isIncrease
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
