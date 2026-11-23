
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../shared/database_instance.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';

class FinancialCalendarPage extends StatefulWidget {
  final VoidCallback onMenuPressed;

  const FinancialCalendarPage({
    super.key,
    required this.onMenuPressed,
  });

  @override
  State<FinancialCalendarPage> createState() =>
      _FinancialCalendarPageState();
}

class _FinancialCalendarPageState
    extends State<FinancialCalendarPage> {
  static const Color primary = Color(0xFF4FA38D);

  late DateTime selectedMonth;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    selectedMonth = DateTime(now.year, now.month);
    selectedDate = DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day} ${_monthName(date.month).substring(0, 3)}';
  }

  void _changeMonth(int amount) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + amount,
      );

      selectedDate = DateTime(
        selectedMonth.year,
        selectedMonth.month,
        1,
      );
    });
  }

  void _goToToday() {
    final today = DateTime.now();

    setState(() {
      selectedMonth = DateTime(today.year, today.month);
      selectedDate = _dateOnly(today);
    });
  }

  Color _kindColor(String kind) {
    switch (kind) {
      case 'income':
        return Colors.green;

      case 'expense':
        return Colors.red;

      case 'transfer':
        return Colors.blue;

      case 'borrow':
        return Colors.orange;

      case 'lend':
        return Colors.deepPurple;

      default:
        return Colors.grey;
    }
  }

  IconData _kindIcon(String kind) {
    switch (kind) {
      case 'income':
        return Icons.arrow_downward_rounded;

      case 'expense':
        return Icons.arrow_upward_rounded;

      case 'transfer':
        return Icons.swap_horiz_rounded;

      case 'borrow':
        return Icons.call_received_rounded;

      case 'lend':
        return Icons.call_made_rounded;

      default:
        return Icons.receipt_long;
    }
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'income':
        return 'Income';

      case 'expense':
        return 'Expense';

      case 'transfer':
        return 'Transfer';

      case 'borrow':
        return 'Borrow';

      case 'lend':
        return 'Lend';

      default:
        return 'Activity';
    }
  }

  Widget _buildDot(String kind) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: _kindColor(kind),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLegendItem(String title, String kind) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(kind),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(
    List<_CalendarActivity> activities,
  ) {
    final firstDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    final startingWeekday = firstDay.weekday % 7;

    final firstCalendarDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1 - startingWeekday,
    );

    final activitiesByDate =
        <DateTime, List<_CalendarActivity>>{};

    for (final activity in activities) {
      final date = _dateOnly(activity.date);

      activitiesByDate.putIfAbsent(
        date,
        () => [],
      );

      activitiesByDate[date]!.add(activity);
    }

    final today = _dateOnly(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: Center(
                  child: Text(
                    'Sun',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Mon',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Tue',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Wed',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Thu',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Fri',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Sat',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 3,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final date = firstCalendarDay.add(
                Duration(days: index),
              );

              final dateKey = _dateOnly(date);

              final isCurrentMonth =
                  date.month == selectedMonth.month;

              final isSelected =
                  dateKey == _dateOnly(selectedDate);

              final isToday = dateKey == today;

              final dayActivities =
                  activitiesByDate[dateKey] ?? [];

              final kinds = dayActivities
                  .map((activity) => activity.kind)
                  .toSet()
                  .toList();

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() {
                    selectedDate = dateKey;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : isToday
                            ? primary.withOpacity(0.10)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: primary)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: !isCurrentMonth
                              ? Colors.grey.shade400
                              : isSelected
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          for (final kind in kinds.take(4))
                            Container(
                              width: 5,
                              height: 5,
                              margin:
                                  const EdgeInsets.symmetric(
                                horizontal: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : _kindColor(kind),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 19,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(amount),
                style: TextStyle(
                  fontSize: 14,
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

  Widget _buildDailySummary(
    List<_CalendarActivity> activities,
  ) {
    var income = 0;
    var expense = 0;
    var transfers = 0;
    var borrowLendNet = 0;

    for (final activity in activities) {
      switch (activity.kind) {
        case 'income':
          income += activity.amount;
          break;

        case 'expense':
          expense += activity.amount;
          break;

        case 'transfer':
          transfers += activity.amount;
          break;

        case 'borrow':
          borrowLendNet += activity.amount;
          break;

        case 'lend':
          borrowLendNet -= activity.amount;
          break;
      }
    }

    final net = income - expense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Summary',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            _buildSummaryCard(
              title: 'Income',
              amount: income,
              color: Colors.green,
              icon: Icons.trending_up,
            ),
            const SizedBox(width: 9),
            _buildSummaryCard(
              title: 'Expense',
              amount: expense,
              color: Colors.red,
              icon: Icons.trending_down,
            ),
          ],
        ),

        const SizedBox(height: 9),

        Row(
          children: [
            _buildSummaryCard(
              title: 'Transfers',
              amount: transfers,
              color: Colors.blue,
              icon: Icons.swap_horiz,
            ),
            const SizedBox(width: 9),
            _buildSummaryCard(
              title: 'Borrow/Lend Net',
              amount: borrowLendNet.abs(),
              color: borrowLendNet >= 0
                  ? Colors.orange
                  : Colors.deepPurple,
              icon: Icons.account_balance,
            ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Income - Expense',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${net < 0 ? '-' : '+'}${formatMoney(net.abs())}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: net >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityList(
    List<_CalendarActivity> activities,
  ) {
    final dailyActivities = activities
        .where(
          (activity) =>
              _dateOnly(activity.date) ==
              _dateOnly(selectedDate),
        )
        .toList()
      ..sort(
        (a, b) => b.date.compareTo(a.date),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Activities',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${dailyActivities.length} records',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (dailyActivities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 40,
                  color: Colors.grey,
                ),
                SizedBox(height: 10),
                Text(
                  'No activities on this date',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        else
          ...dailyActivities.map(
            (activity) {
              final color = _kindColor(activity.kind);

              return Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _kindIcon(activity.kind),
                        color: color,
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            activity.subtitle,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),

                          if (activity.note != null &&
                              activity.note!.trim().isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 4),
                              child: Text(
                                activity.note!,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatMoney(activity.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _kindLabel(activity.kind),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  List<_CalendarActivity> _createActivities({
    required List<Transaction> transactions,
    required List<Due> dues,
    required List<DuePayment> duePayments,
    required List<Transfer> transfers,
    required List<BorrowLend> borrowLends,
    required List<BorrowLendPayment> borrowLendPayments,
    required List<Account> accounts,
  }) {
    final activities = <_CalendarActivity>[];

    final accountNames = {
      for (final account in accounts)
        account.id: account.name,
    };

    final duesById = {
      for (final due in dues)
        due.id: due,
    };

    final borrowLendsById = {
      for (final item in borrowLends)
        item.id: item,
    };

    // Regular income and expense transactions.
    for (final item in transactions) {
      if (item.type != 'income' && item.type != 'expense') {
        continue;
      }

      if (item.paidAmountPaisa <= 0) {
        continue;
      }

      activities.add(
        _CalendarActivity(
          title: item.title,
          subtitle:
              accountNames[item.accountId] ?? 'Unknown account',
          amount: item.paidAmountPaisa,
          date: item.date,
          kind: item.type,
          note: item.note,
        ),
      );
    }

    // Later payments towards store dues.
    for (final payment in duePayments) {
      final due = duesById[payment.dueId];

      activities.add(
        _CalendarActivity(
          title: 'Store Due Payment',
          subtitle:
              '${due?.storeName ?? 'Unknown Store'} • '
              '${accountNames[payment.accountId] ?? 'Unknown account'}',
          amount: payment.amountPaisa,
          date: payment.date,
          kind: 'expense',
          note: payment.note,
        ),
      );
    }

    // Transfers.
    for (final transfer in transfers) {
      final from =
          accountNames[transfer.fromAccountId] ?? 'Unknown';

      final to =
          accountNames[transfer.toAccountId] ?? 'Unknown';

      activities.add(
        _CalendarActivity(
          title: 'Account Transfer',
          subtitle: '$from → $to',
          amount: transfer.amountPaisa,
          date: transfer.date,
          kind: 'transfer',
          note: transfer.note,
        ),
      );
    }

    // Original borrow and lend records.
    for (final item in borrowLends) {
      activities.add(
        _CalendarActivity(
          title: item.type == 'borrow'
              ? 'Borrowed from ${item.personName}'
              : 'Lent to ${item.personName}',
          subtitle:
              accountNames[item.accountId] ?? 'Unknown account',
          amount: item.amountPaisa,
          date: item.date,
          kind: item.type == 'borrow' ? 'borrow' : 'lend',
          note: item.note,
        ),
      );
    }

    // Borrow and lend repayments.
    for (final payment in borrowLendPayments) {
      final record =
          borrowLendsById[payment.borrowLendId];

      if (record == null) continue;

      final isBorrow = record.type == 'borrow';

      activities.add(
        _CalendarActivity(
          title: isBorrow
              ? 'Borrow Repayment'
              : 'Lend Repayment Received',
          subtitle:
              '${record.personName} • '
              '${accountNames[payment.accountId] ?? 'Unknown account'}',
          amount: payment.amountPaisa,
          date: payment.date,
          kind: isBorrow ? 'borrow' : 'lend',
          note: payment.note,
        ),
      );
    }

    return activities;
  }

  Widget _buildCalendarContent({
    required List<Transaction> transactions,
    required List<Due> dues,
    required List<DuePayment> duePayments,
    required List<Transfer> transfers,
    required List<BorrowLend> borrowLends,
    required List<BorrowLendPayment> borrowLendPayments,
    required List<Account> accounts,
  }) {
    final activities = _createActivities(
      transactions: transactions,
      dues: dues,
      duePayments: duePayments,
      transfers: transfers,
      borrowLends: borrowLends,
      borrowLendPayments: borrowLendPayments,
      accounts: accounts,
    );

    final selectedActivities = activities
        .where(
          (activity) =>
              _dateOnly(activity.date) ==
              _dateOnly(selectedDate),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),

      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuPressed,
        ),
        title: const Text(
          'Financial Calendar',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),

                Expanded(
                  child: Center(
                    child: Text(
                      '${_monthName(selectedMonth.month)} '
                      '${selectedMonth.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),

                TextButton(
                  onPressed: _goToToday,
                  child: const Text(
                    'Today',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            _buildCalendar(activities),

            const SizedBox(height: 12),

            Wrap(
              spacing: 13,
              runSpacing: 8,
              children: [
                _buildLegendItem('Income', 'income'),
                _buildLegendItem('Expense', 'expense'),
                _buildLegendItem('Transfer', 'transfer'),
                _buildLegendItem('Borrow', 'borrow'),
                _buildLegendItem('Lend', 'lend'),
              ],
            ),

            const SizedBox(height: 22),

            Text(
              _formatDate(selectedDate),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildDailySummary(selectedActivities),

            const SizedBox(height: 22),

            _buildActivityList(activities),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _loading() {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F7F6),
      body: Center(
        child: CircularProgressIndicator(
          color: primary,
        ),
      ),
    );
  }

  Widget _error(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Unable to load calendar data.\n$message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Account>>(
      stream: database.watchAccounts(),
      builder: (context, accountSnapshot) {
        if (accountSnapshot.hasError) {
          return _error(accountSnapshot.error.toString());
        }

        if (!accountSnapshot.hasData) {
          return _loading();
        }

        return StreamBuilder<List<Transaction>>(
          stream: database.watchTransactions(),
          builder: (context, transactionSnapshot) {
            if (transactionSnapshot.hasError) {
              return _error(
                transactionSnapshot.error.toString(),
              );
            }

            if (!transactionSnapshot.hasData) {
              return _loading();
            }

            return StreamBuilder<List<Due>>(
              stream: database.watchDues(),
              builder: (context, dueSnapshot) {
                if (dueSnapshot.hasError) {
                  return _error(dueSnapshot.error.toString());
                }

                if (!dueSnapshot.hasData) {
                  return _loading();
                }

                return StreamBuilder<List<DuePayment>>(
                  stream: database.watchAllDuePayments(),
                  builder: (context, duePaymentSnapshot) {
                    if (duePaymentSnapshot.hasError) {
                      return _error(
                        duePaymentSnapshot.error.toString(),
                      );
                    }

                    if (!duePaymentSnapshot.hasData) {
                      return _loading();
                    }

                    return StreamBuilder<List<Transfer>>(
                      stream: database.watchTransfers(),
                      builder: (context, transferSnapshot) {
                        if (transferSnapshot.hasError) {
                          return _error(
                            transferSnapshot.error.toString(),
                          );
                        }

                        if (!transferSnapshot.hasData) {
                          return _loading();
                        }

                        return StreamBuilder<List<BorrowLend>>(
                          stream: database.watchBorrowLends(),
                          builder: (context, borrowSnapshot) {
                            if (borrowSnapshot.hasError) {
                              return _error(
                                borrowSnapshot.error.toString(),
                              );
                            }

                            if (!borrowSnapshot.hasData) {
                              return _loading();
                            }

                            return StreamBuilder<
                                List<BorrowLendPayment>>(
                              stream: database
                                  .watchAllBorrowLendPayments(),
                              builder: (
                                context,
                                borrowPaymentSnapshot,
                              ) {
                                if (borrowPaymentSnapshot.hasError) {
                                  return _error(
                                    borrowPaymentSnapshot.error
                                        .toString(),
                                  );
                                }

                                if (!borrowPaymentSnapshot.hasData) {
                                  return _loading();
                                }

                                return _buildCalendarContent(
                                  accounts: accountSnapshot.data!,
                                  transactions:
                                      transactionSnapshot.data!,
                                  dues: dueSnapshot.data!,
                                  duePayments:
                                      duePaymentSnapshot.data!,
                                  transfers: transferSnapshot.data!,
                                  borrowLends: borrowSnapshot.data!,
                                  borrowLendPayments:
                                      borrowPaymentSnapshot.data!,
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
  }
}

class _CalendarActivity {
  final String title;
  final String subtitle;
  final int amount;
  final DateTime date;
  final String kind;
  final String? note;

  const _CalendarActivity({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.kind,
    this.note,
  });
}
