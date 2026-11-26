
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';
import '../../shared/database_instance.dart';

class AccountReconciliationPage extends StatefulWidget {
  final Account account;
  final int currentBalancePaisa;

  const AccountReconciliationPage({
    super.key,
    required this.account,
    required this.currentBalancePaisa,
  });

  @override
  State<AccountReconciliationPage> createState() =>
      _AccountReconciliationPageState();
}

class _AccountReconciliationPageState
    extends State<AccountReconciliationPage> {
  final TextEditingController actualBalanceController =
      TextEditingController();

  final TextEditingController reasonController =
      TextEditingController();

  DateTime adjustmentDate = DateTime.now();

  bool isSaving = false;

  int? parseMoney(String value) {
    final input = value.trim();

    if (!RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(input)) {
      return null;
    }

    final isNegative = input.startsWith('-');
    final cleanValue = isNegative ? input.substring(1) : input;

    final parts = cleanValue.split('.');

    final taka = int.tryParse(parts[0]);

    if (taka == null) return null;

    final paisa = parts.length > 1
        ? int.parse(parts[1].padRight(2, '0'))
        : 0;

    final total = taka * 100 + paisa;

    return isNegative ? -total : total;
  }

  String displayMoney(int paisa) {
    if (paisa >= 0) {
      return formatMoney(paisa);
    }

    return '-${formatMoney(paisa.abs())}';
  }

  Future<void> selectAdjustmentDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: adjustmentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() {
        adjustmentDate = selected;
      });
    }
  }

  Future<void> saveAdjustment() async {
    final actualBalance =
        parseMoney(actualBalanceController.text);

    final reason = reasonController.text.trim();

    if (actualBalance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid actual balance.'),
        ),
      );
      return;
    }

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason.'),
        ),
      );
      return;
    }

    if (actualBalance < 0 &&
        !widget.account.name.toLowerCase().contains('bank')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cash and mobile wallet balances cannot be negative.',
          ),
        ),
      );
      return;
    }

    final difference =
        actualBalance - widget.currentBalancePaisa;

    if (difference == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your actual balance already matches MyMoney.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await database.addAccountAdjustment(
        accountId: widget.account.id,
        amountPaisa: difference,
        reason: reason,
        date: adjustmentDate,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balance adjustment saved.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save adjustment: $e'),
        ),
      );

      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    actualBalanceController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actualBalance =
        parseMoney(actualBalanceController.text);

    final difference = actualBalance == null
        ? null
        : actualBalance - widget.currentBalancePaisa;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        title: const Text('Reconcile Balance'),
        backgroundColor: const Color(0xFF4FA38D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.account.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current MyMoney Balance',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayMoney(widget.currentBalancePaisa),
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Actual Balance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: actualBalanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixText: '৳ ',
                hintText: 'Enter actual balance',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adjustment Difference',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      difference == null
                          ? 'Enter actual balance'
                          : '${difference > 0 ? '+' : ''}'
                              '${displayMoney(difference)}',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: difference == null
                            ? Colors.black54
                            : difference > 0
                                ? Colors.green
                                : difference < 0
                                    ? Colors.red
                                    : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Positive means increase. '
                      'Negative means decrease.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Reason',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Why does the balance not match?',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Adjustment Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: selectAdjustmentDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                '${adjustmentDate.day}/'
                '${adjustmentDate.month}/'
                '${adjustmentDate.year}',
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA38D),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving ? null : saveAdjustment,
                child: isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Adjustment',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
