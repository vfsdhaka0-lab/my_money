
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
      body: StreamBuilder<List<DuePayment>>(
        stream: database.watchAllDuePayments(),
        builder: (context, paymentSnapshot) {
          if (paymentSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (paymentSnapshot.hasError) {
            return const Center(
              child: Text('Could not load payment records.'),
            );
          }

          return StreamBuilder<List<Due>>(
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
                          child: Text(
                            'All dues have been paid.',
                          ),
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
                              if (savedStore.name
                                      .trim()
                                      .toLowerCase() ==
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
          );
        },
      ),
    );
  }
}

// STORE OUTSTANDING PAGE

class StoreOutstandingPage extends StatefulWidget {
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
  State<StoreOutstandingPage> createState() =>
      _StoreOutstandingPageState();
}

class _StoreOutstandingPageState
    extends State<StoreOutstandingPage> {
  late Map<int, int> _outstandingAmounts;

  @override
  void initState() {
    super.initState();

    _outstandingAmounts = {
      for (final item in widget.items)
        item.due.id: item.outstanding,
    };
  }

  int get _totalDue {
    return _outstandingAmounts.values.fold<int>(
      0,
      (total, amount) => total + amount,
    );
  }

  List<DueItem> get _visibleItems {
    return widget.items.where((item) {
      return (_outstandingAmounts[item.due.id] ?? 0) > 0;
    }).toList();
  }

  int? _parsePaisa(String value) {
    final amount = double.tryParse(value.trim());

    if (amount == null ||
        !amount.isFinite ||
        amount < 0) {
      return null;
    }

    return (amount * 100).round();
  }

  // PAY INDIVIDUAL PURCHASE

  Future<void> _payPurchase(DueItem item) async {
    final accounts =
        await database.select(database.accounts).get();

    if (!mounted) return;

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an account first.'),
        ),
      );
      return;
    }

    final outstanding =
        _outstandingAmounts[item.due.id] ?? item.outstanding;

    final amountController = TextEditingController();
    final noteController = TextEditingController();

    int? selectedAccountId = accounts.first.id;
    DateTime paymentDate = DateTime.now();

    bool saving = false;

    final paymentAmount = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pay Individual Purchase'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.purchase.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Outstanding: ${formatMoney(outstanding)}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (Taka)',
                        hintText: 'Enter amount',
                        prefixText: '৳ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      value: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Payment Account',
                        border: OutlineInputBorder(),
                      ),
                      items: accounts.map((account) {
                        return DropdownMenuItem<int>(
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedAccountId = value;
                              });
                            },
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              final pickedDate =
                                  await showDatePicker(
                                context: context,
                                initialDate: paymentDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );

                              if (pickedDate != null) {
                                setDialogState(() {
                                  paymentDate = pickedDate;
                                });
                              }
                            },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        'Date: ${paymentDate.day}/'
                        '${paymentDate.month}/'
                        '${paymentDate.year}',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final amount = double.tryParse(
                            amountController.text.trim(),
                          );

                          if (amount == null ||
                              !amount.isFinite ||
                              amount <= 0) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a valid payment amount.',
                                ),
                              ),
                            );
                            return;
                          }

                          final amountPaisa =
                              (amount * 100).round();

                          if (amountPaisa > outstanding) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Payment cannot exceed the outstanding amount.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (selectedAccountId == null) {
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await database.addDuePayment(
                              dueId: item.due.id,
                              accountId: selectedAccountId!,
                              amountPaisa: amountPaisa,
                              date: paymentDate,
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(
                                dialogContext,
                                amountPaisa,
                              );
                            }
                          } catch (error) {
                            setDialogState(() {
                              saving = false;
                            });

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not save payment: $error',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Payment'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    noteController.dispose();

    if (paymentAmount == null || !mounted) return;

    setState(() {
      final remaining =
          (_outstandingAmounts[item.due.id] ?? outstanding) -
              paymentAmount;

      if (remaining <= 0) {
        _outstandingAmounts.remove(item.due.id);
      } else {
        _outstandingAmounts[item.due.id] = remaining;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment saved successfully.'),
      ),
    );
  }

  // PAY STORE

  Future<void> _payStore() async {
    final accounts =
        await database.select(database.accounts).get();

    if (!mounted) return;

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an account first.'),
        ),
      );
      return;
    }

    if (_totalDue <= 0) return;

    final amountController = TextEditingController();
    final noteController = TextEditingController();

    int? selectedAccountId = accounts.first.id;
    DateTime paymentDate = DateTime.now();
    bool saving = false;

    final result = await showDialog<Map<int, int>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final amount = double.tryParse(
              amountController.text.trim(),
            );

            final amountPaisa =
                amount != null &&
                        amount.isFinite &&
                        amount > 0
                    ? (amount * 100).round()
                    : 0;

            final validAmount =
                amountPaisa > 0 && amountPaisa <= _totalDue;

            return AlertDialog(
              title: const Text('Pay Store'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.storeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total outstanding: ${formatMoney(_totalDue)}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Total Payment (Taka)',
                        prefixText: '৳ ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Payment Account',
                        border: OutlineInputBorder(),
                      ),
                      items: accounts.map((account) {
                        return DropdownMenuItem<int>(
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedAccountId = value;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              final pickedDate =
                                  await showDatePicker(
                                context: context,
                                initialDate: paymentDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );

                              if (pickedDate != null) {
                                setDialogState(() {
                                  paymentDate = pickedDate;
                                });
                              }
                            },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        'Date: ${paymentDate.day}/'
                        '${paymentDate.month}/'
                        '${paymentDate.year}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving ||
                          !validAmount ||
                          selectedAccountId == null
                      ? null
                      : () async {
                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final paymentResult =
                                await database.addStoreDuePayment(
                              storeName: widget.storeName,
                              accountId: selectedAccountId!,
                              amountPaisa: amountPaisa,
                              date: paymentDate,
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(
                                dialogContext,
                                paymentResult,
                              );
                            }
                          } catch (error) {
                            setDialogState(() {
                              saving = false;
                            });

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not save payment: $error',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Payment'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    noteController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      for (final entry in result.entries) {
        final remaining =
            (_outstandingAmounts[entry.key] ?? 0) -
                entry.value;

        if (remaining <= 0) {
          _outstandingAmounts.remove(entry.key);
        } else {
          _outstandingAmounts[entry.key] = remaining;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Store payment saved successfully.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;

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
          widget.storeName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _totalDue <= 0
          ? const Center(
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
                    'All dues have been paid!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _StoreImage(
                              imagePath: widget.imagePath,
                              size: 65,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.storeName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${visibleItems.length} unpaid purchase(s)',
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Outstanding: ${formatMoney(_totalDue)}',
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
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _payStore,
                            icon: const Icon(
                              Icons.storefront_outlined,
                            ),
                            label: const Text('Pay Store'),
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
                ...visibleItems.map((item) {
                  final purchase = item.purchase;
                  final outstanding =
                      _outstandingAmounts[item.due.id] ?? 0;

                  final paidAmount =
                      purchase.amountPaisa - outstanding;

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
                            amount: outstanding,
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
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _payPurchase(item),
                              icon: const Icon(
                                Icons.payments_outlined,
                              ),
                              label: const Text(
                                'Pay Individual Purchase',
                              ),
                            ),
                          ),
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

// STORE IMAGE

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
                errorBuilder: (_, _, _) => _placeholder(),
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

// AMOUNT ROW

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

// EMPTY DUES

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

// PUBLIC DUE ITEM MODEL

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
