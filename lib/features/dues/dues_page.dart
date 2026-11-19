
// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/money_formatter.dart';
import '../../shared/database_instance.dart';

class DuesPage extends StatelessWidget {
  const DuesPage({super.key});

  Future<List<DueItem>> _loadDueItems(
    List<Due> dues,
  ) async {
    final items = await Future.wait(
      dues.map((due) async {
        final outstanding =
            await database.getOutstandingDue(due.id);

        final purchase = await (database.select(
          database.transactions,
        )..where((t) => t.id.equals(due.transactionId)))
            .getSingleOrNull();

        if (purchase == null || outstanding <= 0) {
          return null;
        }

        return DueItem(
          due: due,
          purchase: purchase,
          outstanding: outstanding,
        );
      }),
    );

    return items.whereType<DueItem>().toList();
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
            return const _EmptyDues();
          }

          return StreamBuilder<List<Store>>(
            stream: database.watchStores(),
            builder: (context, storeSnapshot) {
              if (storeSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (storeSnapshot.hasError) {
                return const Center(
                  child: Text('Could not load stores.'),
                );
              }

              final stores = storeSnapshot.data ?? [];

              return FutureBuilder<List<DueItem>>(
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

                  final Map<String, List<DueItem>>
                      groupedDues = {};

                  for (final item in items) {
                    groupedDues
                        .putIfAbsent(
                          item.due.storeName,
                          () => [],
                        )
                        .add(item);
                  }

                  final totalDue = items.fold<int>(
                    0,
                    (total, item) =>
                        total + item.outstanding,
                  );

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
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

                      ...groupedDues.entries.map((entry) {
                        final storeItems = entry.value;

                        final storeTotal =
                            storeItems.fold<int>(
                          0,
                          (total, item) =>
                              total + item.outstanding,
                        );

                        Store? store;

                        for (final savedStore in stores) {
                          if (savedStore.name.trim().toLowerCase() ==
                              entry.key.trim().toLowerCase()) {
                            store = savedStore;
                            break;
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            leading: _StoreImage(
                              imagePath: store?.imagePath,
                            ),
                            title: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${storeItems.length} unpaid purchase(s)',
                            ),
                            trailing: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatMoney(storeTotal),
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 15,
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StoreOutstandingPage(
                                    storeName: entry.key,
                                    items: storeItems,
                                    imagePath: store?.imagePath,
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }
}

class StoreOutstandingPage extends StatelessWidget {
  final String storeName;
  final List<DueItem> items;
  final String? imagePath;

  const StoreOutstandingPage({
    super.key,
    required this.storeName,
    required this.items,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final totalDue = items.fold<int>(
      0,
      (total, item) => total + item.outstanding,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        toolbarHeight: 56,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        title: Text(
          storeName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _StoreImage(
                    imagePath: imagePath,
                    size: 65,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${items.length} unpaid purchase(s)',
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Outstanding: ${formatMoney(totalDue)}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Purchase History',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ...items.map((item) {
            final purchase = item.purchase;

            final paidAmount =
                purchase.amountPaisa - item.outstanding;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Purchase #${purchase.id} • '
                      '${purchase.date.day}/'
                      '${purchase.date.month}/'
                      '${purchase.date.year}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const Divider(height: 22),
                    _AmountRow(
                      label: 'Purchase amount',
                      amount: purchase.amountPaisa,
                    ),
                    const SizedBox(height: 8),
                    _AmountRow(
                      label: 'Total paid',
                      amount: paidAmount,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _AmountRow(
                      label: 'Outstanding',
                      amount: item.outstanding,
                      color: Colors.orange,
                      bold: true,
                    ),
                    if (purchase.note != null &&
                        purchase.note!.trim().isNotEmpty) ...[
                      const Divider(height: 20),
                      Text(
                        'Note: ${purchase.note}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StoreImage extends StatelessWidget {
  final String? imagePath;
  final double size;

  const _StoreImage({
    this.imagePath,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null &&
        imagePath!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: hasImage
            ? Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: const Icon(
        Icons.store,
        color: Colors.grey,
        size: 27,
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final int amount;
  final Color? color;
  final bool bold;

  const _AmountRow({
    required this.label,
    required this.amount,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          formatMoney(amount),
          style: TextStyle(
            color: color,
            fontWeight:
                bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmptyDues extends StatelessWidget {
  const _EmptyDues();

  @override
  Widget build(BuildContext context) {
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
}

class DueItem {
  final Due due;
  final Transaction purchase;
  final int outstanding;

  const DueItem({
    required this.due,
    required this.purchase,
    required this.outstanding,
  });
}
