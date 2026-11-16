
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';
import '../../shared/database_instance.dart';

class DuesPage extends StatelessWidget {
  const DuesPage({super.key});

  Future<List<_DueItem>> _loadDueItems(
    List<Due> dues,
  ) async {
    final items = await Future.wait(
      dues.map((due) async {
        final outstanding =
            await database.getOutstandingDue(due.id);

        return _DueItem(
          due: due,
          outstanding: outstanding,
        );
      }),
    );

    return items.where((item) => item.outstanding > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Due>>(
        stream: database.watchDues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load dues.'),
            );
          }

          final dues = snapshot.data ?? [];

          if (dues.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 55,
                    color: Colors.green,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No outstanding dues',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your unpaid purchases will appear here.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<_DueItem>>(
            future: _loadDueItems(dues),
            builder: (context, dueSnapshot) {
              if (dueSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (dueSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Could not calculate outstanding dues.',
                  ),
                );
              }

              final items = dueSnapshot.data ?? [];

              if (items.isEmpty) {
                return const Center(
                  child: Text('All dues have been paid.'),
                );
              }

              // GROUP OUTSTANDING DUES BY STORE.
              final Map<String, List<_DueItem>> groupedDues = {};

              for (final item in items) {
                final storeName = item.due.storeName;

                groupedDues.putIfAbsent(
                  storeName,
                  () => [],
                );

                groupedDues[storeName]!.add(item);
              }

              final totalDue = items.fold<int>(
                0,
                (total, item) => total + item.outstanding,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // TOTAL OUTSTANDING
                  Card(
                    color: Theme.of(context).colorScheme.primary,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Outstanding Due',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatMoney(totalDue),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${groupedDues.length} stores • '
                            '${items.length} purchases',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Store-wise Outstanding',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // STORE-WISE DUE LIST
                  ...groupedDues.entries.map((entry) {
                    final storeItems = entry.value;

                    final storeTotal = storeItems.fold<int>(
                      0,
                      (total, item) =>
                          total + item.outstanding,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.store),
                        ),
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${storeItems.length} purchase(s)',
                        ),
                        trailing: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatMoney(storeTotal),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                            ),
                          ],
                        ),
                        children: storeItems.map((item) {
                          return ListTile(
                            title: Text(
                              'Purchase #${item.due.transactionId}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Date: '
                              '${item.due.createdAt.day}/'
                              '${item.due.createdAt.month}/'
                              '${item.due.createdAt.year}',
                            ),
                            trailing: Text(
                              formatMoney(item.outstanding),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
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
}

class _DueItem {
  final Due due;
  final int outstanding;

  const _DueItem({
    required this.due,
    required this.outstanding,
  });
}
