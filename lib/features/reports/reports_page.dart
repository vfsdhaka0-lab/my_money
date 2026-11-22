
// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../shared/database_instance.dart';
import '../../core/utils/money_formatter.dart';

class ReportsPage extends StatefulWidget {
  final VoidCallback onMenuPressed;

  const ReportsPage({
    super.key,
    required this.onMenuPressed,
  });

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const Color primary = Color(0xFF4FA38D);

  late DateTime startDate;
  late DateTime endDate;

  String paymentFilter = 'All Payments';

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month, now.day);
  }

  bool _isInSelectedRange(DateTime date) {
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    final value = DateTime(date.year, date.month, date.day);

    return !value.isBefore(start) && !value.isAfter(end);
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: endDate,
    );

    if (selected != null) {
      setState(() {
        startDate = selected;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        endDate = selected;
      });
    }
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _monthText(String key) {
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[month - 1]} $year';
  }

  String _pdfMoney(int paisa) {
    final absoluteAmount = paisa.abs();
    final taka = absoluteAmount ~/ 100;
    final remainder = (absoluteAmount % 100)
        .toString()
        .padLeft(2, '0');

    final sign = paisa < 0 ? '-' : '';

    return 'BDT $sign$taka.$remainder';
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 22,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // CALCULATE ACCOUNT BALANCE.
  // Uses the same balance rules as the Accounts page.
  int _accountBalance({
    required dynamic account,
    required List transactions,
    required List duePayments,
    required List transfers,
    required List borrowLends,
    required List borrowLendPayments,
  }) {
    var balance = account.openingBalancePaisa as int;

    // Income and expenses.
    for (final item in transactions) {
      if (item.accountId != account.id) {
        continue;
      }

      if (item.type == 'income') {
        balance += item.paidAmountPaisa as int;
      } else if (item.type == 'expense') {
        balance -= item.paidAmountPaisa as int;
      }
    }

    // Store due payments.
    for (final payment in duePayments) {
      if (payment.accountId == account.id) {
        balance -= payment.amountPaisa as int;
      }
    }

    // Account transfers.
    for (final transfer in transfers) {
      if (transfer.fromAccountId == account.id) {
        balance -= transfer.amountPaisa as int;
      }

      if (transfer.toAccountId == account.id) {
        balance += transfer.amountPaisa as int;
      }
    }

    // Original borrowing and lending amounts.
    for (final item in borrowLends) {
      if (item.accountId != account.id) {
        continue;
      }

      if (item.type == 'borrow') {
        balance += item.amountPaisa as int;
      } else if (item.type == 'lend') {
        balance -= item.amountPaisa as int;
      }
    }

    final borrowLendById = {
      for (final item in borrowLends) item.id: item,
    };

    // Borrow and lend repayments.
    for (final payment in borrowLendPayments) {
      if (payment.accountId != account.id) {
        continue;
      }

      final record = borrowLendById[payment.borrowLendId];

      if (record == null) {
        continue;
      }

      if (record.type == 'borrow') {
        balance -= payment.amountPaisa as int;
      } else if (record.type == 'lend') {
        balance += payment.amountPaisa as int;
      }
    }

    return balance;
  }

  // BUILD A COMBINED PAYMENT HISTORY.
  // Store due payments, borrow repayments and lend repayments.
  List<Map<String, dynamic>> _paymentHistoryRecords({
    required List accounts,
    required List duePayments,
    required List dues,
    required List borrowLends,
    required List borrowLendPayments,
  }) {
    final accountById = {
      for (final account in accounts) account.id: account,
    };

    final dueById = {
      for (final due in dues) due.id: due,
    };

    final borrowLendById = {
      for (final item in borrowLends) item.id: item,
    };

    final records = <Map<String, dynamic>>[];

    // Store due payments.
    for (final payment in duePayments) {
      if (!_isInSelectedRange(payment.date)) {
        continue;
      }

      final due = dueById[payment.dueId];

      if (due == null) {
        continue;
      }

      final account = accountById[payment.accountId];

      records.add({
        'type': 'Store Due',
        'name': due.storeName.toString(),
        'date': payment.date as DateTime,
        'account': account?.name.toString() ?? 'Unknown Account',
        'amount': payment.amountPaisa as int,
        'direction': 'out',
        'note': payment.note?.toString() ?? '',
      });
    }

    // Borrow and lend repayments.
    for (final payment in borrowLendPayments) {
      if (!_isInSelectedRange(payment.date)) {
        continue;
      }

      final record = borrowLendById[payment.borrowLendId];

      if (record == null) {
        continue;
      }

      final account = accountById[payment.accountId];

      final isBorrow = record.type == 'borrow';

      records.add({
        'type': isBorrow
            ? 'Borrow Repayment'
            : 'Lend Repayment',
        'name': record.personName.toString(),
        'date': payment.date as DateTime,
        'account': account?.name.toString() ?? 'Unknown Account',
        'amount': payment.amountPaisa as int,
        'direction': isBorrow ? 'out' : 'in',
        'note': payment.note?.toString() ?? '',
      });
    }

    records.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;

      return dateB.compareTo(dateA);
    });

    return records;
  }

  // PAYMENT HISTORY SECTION.
  Widget _buildPaymentHistory({
    required List accounts,
    required List duePayments,
    required List dues,
    required List borrowLends,
    required List borrowLendPayments,
  }) {
    final allRecords = _paymentHistoryRecords(
      accounts: accounts,
      duePayments: duePayments,
      dues: dues,
      borrowLends: borrowLends,
      borrowLendPayments: borrowLendPayments,
    );

    final filteredRecords = allRecords.where((record) {
      if (paymentFilter == 'All Payments') {
        return true;
      }

      if (paymentFilter == 'Store Due') {
        return record['type'] == 'Store Due';
      }

      if (paymentFilter == 'Borrow') {
        return record['type'] == 'Borrow Repayment';
      }

      if (paymentFilter == 'Lend') {
        return record['type'] == 'Lend Repayment';
      }

      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Payment History'),

        // Payment type filters.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'All Payments',
              'Store Due',
              'Borrow',
              'Lend',
            ].map((filter) {
              final selected = paymentFilter == filter;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  selectedColor: primary.withOpacity(0.18),
                  labelStyle: TextStyle(
                    color: selected
                        ? primary
                        : Colors.grey.shade700,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: selected
                        ? primary
                        : Colors.grey.withOpacity(0.25),
                  ),
                  onSelected: (_) {
                    setState(() {
                      paymentFilter = filter;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        if (filteredRecords.isEmpty)
          _emptyMessage('No completed payments in this period.')
        else
          ...filteredRecords.map((record) {
            final type = record['type'] as String;
            final name = record['name'] as String;
            final date = record['date'] as DateTime;
            final account = record['account'] as String;
            final amount = record['amount'] as int;
            final direction = record['direction'] as String;
            final note = record['note'] as String;

            final isMoneyIn = direction == 'in';

            final Color amountColor = isMoneyIn
                ? Colors.green
                : Colors.red;

            final IconData icon;

            if (type == 'Store Due') {
              icon = Icons.store_outlined;
            } else if (type == 'Borrow Repayment') {
              icon = Icons.call_received_rounded;
            } else {
              icon = Icons.call_made_rounded;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: amountColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 11,
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_dateText(date)} • $account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (note.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isMoneyIn ? '+' : '-'}${formatMoney(amount)}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // EXPORT FINANCIAL REPORT AS PDF.
  Future<void> _exportPdf({
    required int totalIncome,
    required int totalExpense,
    required List sortedCategories,
    required Map<int, String> categoryNames,
    required List visibleMonths,
    required Map<String, Map<String, int>> monthlyTotals,
    required List accounts,
    required List transactions,
    required List duePayments,
    required List dues,
    required List transfers,
    required List borrowLends,
    required List borrowLendPayments,
  }) async {
    final document = pw.Document();

    final netIncome = totalIncome - totalExpense;

    final accountRows = accounts.map((account) {
      final balance = _accountBalance(
        account: account,
        transactions: transactions,
        duePayments: duePayments,
        transfers: transfers,
        borrowLends: borrowLends,
        borrowLendPayments: borrowLendPayments,
      );

      return [
        account.name.toString(),
        _pdfMoney(balance),
      ];
    }).toList();

    final paymentRecords = _paymentHistoryRecords(
      accounts: accounts,
      duePayments: duePayments,
      dues: dues,
      borrowLends: borrowLends,
      borrowLendPayments: borrowLendPayments,
    );

    final paymentRows = paymentRecords.map((record) {
      final direction = record['direction'] as String;
      final amount = record['amount'] as int;

      return [
        record['type'].toString(),
        record['name'].toString(),
        _dateText(record['date'] as DateTime),
        record['account'].toString(),
        '${direction == 'in' ? '+' : '-'}${_pdfMoney(amount)}',
      ];
    }).toList();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'MyMoney',
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Financial Report',
            style: const pw.TextStyle(
              fontSize: 17,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Report Period: ${_dateText(startDate)} - '
            '${_dateText(endDate)}',
          ),
          pw.Divider(height: 28),

          pw.Text(
            'Income & Expenses',
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: ['Description', 'Amount'],
            data: [
              ['Total Income', _pdfMoney(totalIncome)],
              ['Total Expenses', _pdfMoney(totalExpense)],
              ['Net Income', _pdfMoney(netIncome)],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
          ),

          pw.SizedBox(height: 24),
          pw.Text(
            'Expense by Category',
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          if (sortedCategories.isEmpty)
            pw.Text('No expenses in this period.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Category', 'Amount', 'Percentage'],
              data: sortedCategories.map((entry) {
                final name = categoryNames[entry.key] ??
                    'Unknown Category';

                final percentage = totalExpense == 0
                    ? 0.0
                    : entry.value / totalExpense * 100;

                return [
                  name,
                  _pdfMoney(entry.value as int),
                  '${percentage.toStringAsFixed(1)}%',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),

          pw.SizedBox(height: 24),
          pw.Text(
            'Monthly Income & Expenses',
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          if (visibleMonths.isEmpty)
            pw.Text('No monthly data available.')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'Month',
                'Income',
                'Expenses',
              ],
              data: visibleMonths.map((month) {
                final values = monthlyTotals[month]!;

                return [
                  _monthText(month),
                  _pdfMoney(values['income'] ?? 0),
                  _pdfMoney(values['expense'] ?? 0),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),

          pw.SizedBox(height: 24),
          pw.Text(
            'Account Balance Summary',
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          if (accountRows.isEmpty)
            pw.Text('No accounts available.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Account', 'Balance'],
              data: accountRows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),

          pw.SizedBox(height: 24),
          pw.Text(
            'Payment History',
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          if (paymentRows.isEmpty)
            pw.Text('No completed payments in this period.')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'Type',
                'Person / Store',
                'Date',
                'Account',
                'Amount',
              ],
              data: paymentRows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 8,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),

          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Center(
            child: pw.Text(
              'Generated by MyMoney',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'mymoney_financial_report.pdf',
    );
  }

  Widget _buildReportContent({
    required List accounts,
    required List transactions,
    required List duePayments,
    required List dues,
    required List transfers,
    required List borrowLends,
    required List borrowLendPayments,
    required List expenseCategories,
  }) {
    int totalIncome = 0;
    int totalExpense = 0;

    final Map<int, int> categoryTotals = {};
    final Map<int, String> categoryNames = {};

    for (final category in expenseCategories) {
      categoryNames[category.id] = category.name;
    }

    final Map<int, dynamic> dueById = {
      for (final due in dues) due.id: due,
    };

    final Map<int, dynamic> transactionById = {
      for (final transaction in transactions)
        transaction.id: transaction,
    };

    final Map<String, Map<String, int>> monthlyTotals = {};

    void addMonthlyAmount(
      DateTime date,
      String type,
      int amount,
    ) {
      final key = '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}';

      monthlyTotals.putIfAbsent(
        key,
        () => {
          'income': 0,
          'expense': 0,
        },
      );

      monthlyTotals[key]![type] =
          (monthlyTotals[key]![type] ?? 0) + amount;
    }

    // Original transaction payments.
    for (final transaction in transactions) {
      if (!_isInSelectedRange(transaction.date)) {
        continue;
      }

      final amount = transaction.paidAmountPaisa as int;

      if (transaction.type == 'income') {
        totalIncome += amount;

        addMonthlyAmount(
          transaction.date,
          'income',
          amount,
        );
      } else if (transaction.type == 'expense') {
        totalExpense += amount;

        addMonthlyAmount(
          transaction.date,
          'expense',
          amount,
        );

        final categoryId = transaction.categoryId;

        if (categoryId != null) {
          categoryTotals[categoryId] =
              (categoryTotals[categoryId] ?? 0) + amount;
        }
      }
    }

    // Later payments for store dues.
    // Attributed to the original purchase category.
    for (final payment in duePayments) {
      if (!_isInSelectedRange(payment.date)) {
        continue;
      }

      final due = dueById[payment.dueId];

      if (due == null) {
        continue;
      }

      final transaction = transactionById[due.transactionId];

      if (transaction == null) {
        continue;
      }

      final amount = payment.amountPaisa as int;

      totalExpense += amount;

      addMonthlyAmount(
        payment.date,
        'expense',
        amount,
      );

      final categoryId = transaction.categoryId;

      if (categoryId != null) {
        categoryTotals[categoryId] =
            (categoryTotals[categoryId] ?? 0) + amount;
      }
    }

    final netBalance = totalIncome - totalExpense;

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedMonths = monthlyTotals.keys.toList()..sort();

    final visibleMonths = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6)
        : sortedMonths;

    int highestMonthlyAmount = 0;

    for (final month in visibleMonths) {
      final values = monthlyTotals[month]!;

      highestMonthlyAmount = math.max(
        highestMonthlyAmount,
        math.max(
          values['income'] ?? 0,
          values['expense'] ?? 0,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        // Date filter.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Period',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectStartDate,
                      child: Column(
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dateText(startDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectEndDate,
                      child: Column(
                        children: [
                          const Text(
                            'To',
                            style: TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dateText(endDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () {
                      final now = DateTime.now();

                      setState(() {
                        startDate = DateTime(
                          now.year,
                          now.month,
                          1,
                        );
                        endDate = DateTime(
                          now.year,
                          now.month,
                          now.day,
                        );
                      });
                    },
                    child: const Text('This Month'),
                  ),
                  TextButton(
                    onPressed: () {
                      final now = DateTime.now();

                      setState(() {
                        startDate = DateTime(
                          now.year,
                          1,
                          1,
                        );
                        endDate = DateTime(
                          now.year,
                          now.month,
                          now.day,
                        );
                      });
                    },
                    child: const Text('This Year'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        startDate = DateTime(2000, 1, 1);
                        endDate = DateTime.now();
                      });
                    },
                    child: const Text('All Time'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Export PDF button.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await _exportPdf(
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                  sortedCategories: sortedCategories,
                  categoryNames: categoryNames,
                  visibleMonths: visibleMonths,
                  monthlyTotals: monthlyTotals,
                  accounts: accounts,
                  transactions: transactions,
                  duePayments: duePayments,
                  dues: dues,
                  transfers: transfers,
                  borrowLends: borrowLends,
                  borrowLendPayments: borrowLendPayments,
                );
              } catch (error) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not export PDF: $error',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        _sectionTitle('Income & Expenses'),

        Row(
          children: [
            _summaryCard(
              title: 'Income',
              amount: formatMoney(totalIncome),
              color: Colors.green,
              icon: Icons.arrow_downward_rounded,
            ),
            const SizedBox(width: 10),
            _summaryCard(
              title: 'Expenses',
              amount: formatMoney(totalExpense),
              color: Colors.red,
              icon: Icons.arrow_upward_rounded,
            ),
          ],
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Income',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formatMoney(netBalance),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: netBalance >= 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
        ),

        // Expense categories.
        _sectionTitle('Expense by Category'),

        if (sortedCategories.isEmpty)
          _emptyMessage('No expenses in this period.')
        else
          ...sortedCategories.map((entry) {
            final name = categoryNames[entry.key] ??
                'Unknown Category';

            final percentage = totalExpense == 0
                ? 0.0
                : entry.value / totalExpense;

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        formatMoney(entry.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 9,
                      backgroundColor:
                          Colors.grey.withOpacity(0.15),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }),

        // Monthly trend.
        _sectionTitle('Monthly Income & Expenses'),

        if (visibleMonths.isEmpty)
          _emptyMessage('No monthly data available.')
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _legendDot(Colors.green, 'Income'),
                    const SizedBox(width: 18),
                    _legendDot(Colors.red, 'Expenses'),
                  ],
                ),
                const SizedBox(height: 18),
                ...visibleMonths.map((month) {
                  final values = monthlyTotals[month]!;

                  final income = values['income'] ?? 0;
                  final expense = values['expense'] ?? 0;

                  final maxValue = highestMonthlyAmount == 0
                      ? 1
                      : highestMonthlyAmount;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _monthText(month),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _monthlyBar(
                          label: 'Income',
                          amount: income,
                          maxValue: maxValue,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 6),
                        _monthlyBar(
                          label: 'Expense',
                          amount: expense,
                          maxValue: maxValue,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

        // Account balances.
        _sectionTitle('Account Balance Summary'),

        if (accounts.isEmpty)
          _emptyMessage('No accounts available.')
        else
          ...accounts.map((account) {
            final balance = _accountBalance(
              account: account,
              transactions: transactions,
              duePayments: duePayments,
              transfers: transfers,
              borrowLends: borrowLends,
              borrowLendPayments: borrowLendPayments,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      account.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(balance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: balance < 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }),

        // Completed payment history.
        _buildPaymentHistory(
          accounts: accounts,
          duePayments: duePayments,
          dues: dues,
          borrowLends: borrowLends,
          borrowLendPayments: borrowLendPayments,
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _monthlyBar({
    required String label,
    required int amount,
    required int maxValue,
    required Color color,
  }) {
    final ratio = amount / maxValue;

    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.grey.withOpacity(0.12),
              valueColor:
                  AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 95,
          child: Text(
            formatMoney(amount),
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuPressed,
        ),
        title: const Text(
          'Financial Reports',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: database.watchAccounts(),
        builder: (context, accountSnapshot) {
          if (!accountSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return StreamBuilder(
            stream: database.watchTransactions(),
            builder: (context, transactionSnapshot) {
              if (!transactionSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return StreamBuilder(
                stream: database.watchAllDuePayments(),
                builder: (context, paymentSnapshot) {
                  if (!paymentSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return StreamBuilder(
                    stream: database.watchDues(),
                    builder: (context, dueSnapshot) {
                      if (!dueSnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      return StreamBuilder(
                        stream: database.watchTransfers(),
                        builder: (context, transferSnapshot) {
                          if (!transferSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return StreamBuilder(
                            stream: database.watchBorrowLends(),
                            builder: (context, borrowSnapshot) {
                              if (!borrowSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              return StreamBuilder(
                                stream: database
                                    .watchAllBorrowLendPayments(),
                                builder: (
                                  context,
                                  borrowPaymentSnapshot,
                                ) {
                                  if (!borrowPaymentSnapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  return StreamBuilder(
                                    stream: database.watchCategories(
                                      type: 'Expense',
                                    ),
                                    builder: (
                                      context,
                                      categorySnapshot,
                                    ) {
                                      if (!categorySnapshot.hasData) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      return _buildReportContent(
                                        accounts: accountSnapshot.data!,
                                        transactions:
                                            transactionSnapshot.data!,
                                        duePayments:
                                            paymentSnapshot.data!,
                                        dues: dueSnapshot.data!,
                                        transfers:
                                            transferSnapshot.data!,
                                        borrowLends:
                                            borrowSnapshot.data!,
                                        borrowLendPayments:
                                            borrowPaymentSnapshot.data!,
                                        expenseCategories:
                                            categorySnapshot.data!,
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
          );
        },
      ),
    );
  }
}
