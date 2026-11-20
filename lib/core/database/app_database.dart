
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/transactions.dart';
import 'tables/dues.dart';
import 'tables/due_payments.dart';
import 'tables/stores.dart';
import 'tables/transfers.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Dues,
    DuePayments,
    Stores,
    Transfers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  // DATABASE MIGRATION
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(categories, categories.color);
          }

          if (from < 3) {
            await m.addColumn(
              transactions,
              transactions.paidAmountPaisa,
            );

            await m.createTable(dues);
            await m.createTable(duePayments);

            await customStatement(
              'UPDATE transactions '
              'SET paid_amount_paisa = amount_paisa',
            );
          }

          if (from < 4) {
            await m.createTable(stores);
          }
        },
      );

  // ACCOUNT BALANCE VALIDATION
  //
  // Only accounts whose name contains "bank" can go negative.
  // All other accounts must have enough balance before an
  // outgoing payment can be saved.
  //
  // Existing negative balances are not changed. They simply
  // cannot be used for additional outgoing payments.
  Future<void> _checkAccountBalance({
    required int accountId,
    required int outgoingAmountPaisa,
  }) async {
    if (outgoingAmountPaisa <= 0) {
      throw ArgumentError('Payment must be greater than zero.');
    }

    final account = await (select(accounts)
          ..where((a) => a.id.equals(accountId)))
        .getSingleOrNull();

    if (account == null) {
      throw StateError('Account not found.');
    }

    // Bank accounts are allowed to have negative balances.
    if (account.name.trim().toLowerCase().contains('bank')) {
      return;
    }

    final accountTransactions = await (select(transactions)
          ..where((t) => t.accountId.equals(accountId)))
        .get();

    var currentBalance = account.openingBalancePaisa;

    for (final item in accountTransactions) {
      if (item.type == 'income') {
        currentBalance += item.paidAmountPaisa;
      } else if (item.type == 'expense') {
        currentBalance -= item.paidAmountPaisa;
      }
    }

    final accountPayments = await (select(duePayments)
          ..where((payment) => payment.accountId.equals(accountId)))
        .get();

    for (final payment in accountPayments) {
      currentBalance -= payment.amountPaisa;
    }

    if (currentBalance < outgoingAmountPaisa) {
      throw StateError(
        'Insufficient balance. '
        'Available balance: ${currentBalance / 100} Tk.',
      );
    }
  }

  // ACCOUNTS
  Stream<List<Account>> watchAccounts() {
    return select(accounts).watch();
  }

  Future<int> addAccount({
    required String name,
    required int openingBalancePaisa,
  }) {
    return into(accounts).insert(
      AccountsCompanion.insert(
        name: name,
        openingBalancePaisa: Value(openingBalancePaisa),
      ),
    );
  }

  // DELETE ACCOUNT ONLY WHEN UNUSED
  Future<bool> deleteAccountIfUnused(int accountId) async {
    return transaction(() async {
      final linkedTransactions = await (select(transactions)
            ..where((t) => t.accountId.equals(accountId)))
          .get();

      if (linkedTransactions.isNotEmpty) {
        return false;
      }

      final linkedPayments = await (select(duePayments)
            ..where((payment) => payment.accountId.equals(accountId)))
          .get();

      if (linkedPayments.isNotEmpty) {
        return false;
      }

      await (delete(accounts)
            ..where((a) => a.id.equals(accountId)))
          .go();

      return true;
    });
  }

  // CATEGORIES
  Stream<List<Category>> watchCategories({
    required String type,
  }) {
    return (select(categories)
          ..where((c) => c.type.equals(type))
          ..where((c) => c.isActive.equals(true))
          ..orderBy([
            (c) => OrderingTerm.asc(c.name),
          ]))
        .watch();
  }

  // ADD CATEGORY
  Future<int> addCategory({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    return into(categories).insert(
      CategoriesCompanion.insert(
        name: name.trim(),
        type: type,
        icon: Value(icon),
        color: Value(color),
      ),
    );
  }

  // STORES
  Stream<List<Store>> watchStores() {
    return (select(stores)
          ..orderBy([
            (s) => OrderingTerm.asc(s.name),
          ]))
        .watch();
  }

  Future<int> addStore({
    required String name,
    String? imagePath,
    String? note,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Store name cannot be empty.');
    }

    return into(stores).insert(
      StoresCompanion.insert(
        name: name.trim(),
        imagePath: Value(imagePath),
        note: Value(note),
      ),
    );
  }

  // TRANSACTIONS
  Stream<List<Transaction>> watchTransactions() {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
          ]))
        .watch();
  }

  Future<int> addTransaction({
    required int accountId,
    required String title,
    required int amountPaisa,
    required String type,
    required DateTime date,
    int? categoryId,
    String? note,
  }) async {
    return transaction(() async {
      if (type == 'expense') {
        await _checkAccountBalance(
          accountId: accountId,
          outgoingAmountPaisa: amountPaisa,
        );
      }

      return into(transactions).insert(
        TransactionsCompanion.insert(
          accountId: accountId,
          categoryId: Value(categoryId),
          title: title,
          amountPaisa: amountPaisa,
          paidAmountPaisa: Value(amountPaisa),
          type: type,
          date: date,
          note: Value(note),
        ),
      );
    });
  }

  // ADD PURCHASE WITH PARTIAL OR FULL DUE
  Future<int> addPurchaseWithDue({
    required int accountId,
    required String title,
    required int totalAmountPaisa,
    required int paidAmountPaisa,
    required String storeName,
    required DateTime date,
    int? categoryId,
    String? note,
  }) async {
    if (totalAmountPaisa <= 0 ||
        paidAmountPaisa < 0 ||
        paidAmountPaisa > totalAmountPaisa ||
        storeName.trim().isEmpty) {
      throw ArgumentError('Invalid purchase information.');
    }

    return transaction(() async {
      if (paidAmountPaisa > 0) {
        await _checkAccountBalance(
          accountId: accountId,
          outgoingAmountPaisa: paidAmountPaisa,
        );
      }

      final transactionId = await into(transactions).insert(
        TransactionsCompanion.insert(
          accountId: accountId,
          categoryId: Value(categoryId),
          title: title,
          amountPaisa: totalAmountPaisa,
          paidAmountPaisa: Value(paidAmountPaisa),
          type: 'expense',
          date: date,
          note: Value(note),
        ),
      );

      if (paidAmountPaisa < totalAmountPaisa) {
        await into(dues).insert(
          DuesCompanion.insert(
            storeName: storeName.trim(),
            transactionId: transactionId,
            initialPaidPaisa: paidAmountPaisa,
            note: Value(note),
          ),
        );
      }

      return transactionId;
    });
  }

  // DELETE TRANSACTION AND RELATED DUE RECORDS
  Future<void> deleteTransaction(int transactionId) async {
    await transaction(() async {
      final relatedDues = await (select(dues)
            ..where((d) => d.transactionId.equals(transactionId)))
          .get();

      for (final due in relatedDues) {
        await (delete(duePayments)
              ..where((payment) => payment.dueId.equals(due.id)))
            .go();
      }

      await (delete(dues)
            ..where((d) => d.transactionId.equals(transactionId)))
          .go();

      await (delete(transactions)
            ..where((t) => t.id.equals(transactionId)))
          .go();
    });
  }

  // DUES
  Stream<List<Due>> watchDues() {
    return (select(dues)
          ..orderBy([
            (d) => OrderingTerm.desc(d.createdAt),
          ]))
        .watch();
  }

  // CALCULATE OUTSTANDING AMOUNT FOR A DUE
  Future<int> getOutstandingDue(int dueId) async {
    final due = await (select(dues)
          ..where((d) => d.id.equals(dueId)))
        .getSingleOrNull();

    if (due == null) {
      throw StateError('Due record not found.');
    }

    final purchase = await (select(transactions)
          ..where((t) => t.id.equals(due.transactionId)))
        .getSingleOrNull();

    if (purchase == null) {
      throw StateError('Purchase transaction not found.');
    }

    final payments = await (select(duePayments)
          ..where((payment) => payment.dueId.equals(dueId)))
        .get();

    final totalPayments = payments.fold<int>(
      0,
      (total, payment) => total + payment.amountPaisa,
    );

    return purchase.amountPaisa -
        due.initialPaidPaisa -
        totalPayments;
  }

  // DUE PAYMENTS
  Stream<List<DuePayment>> watchDuePayments(int dueId) {
    return (select(duePayments)
          ..where((payment) => payment.dueId.equals(dueId))
          ..orderBy([
            (payment) => OrderingTerm.desc(payment.date),
          ]))
        .watch();
  }

  Stream<List<DuePayment>> watchAllDuePayments() {
    return (select(duePayments)
          ..orderBy([
            (payment) => OrderingTerm.desc(payment.date),
          ]))
        .watch();
  }

  // ADD PAYMENT TOWARDS AN INDIVIDUAL PURCHASE
  Future<void> addDuePayment({
    required int dueId,
    required int accountId,
    required int amountPaisa,
    required DateTime date,
    String? note,
  }) async {
    if (amountPaisa <= 0) {
      throw ArgumentError('Payment must be greater than zero.');
    }

    await transaction(() async {
      final due = await (select(dues)
            ..where((d) => d.id.equals(dueId)))
          .getSingleOrNull();

      if (due == null) {
        throw StateError('Due record not found.');
      }

      final purchase = await (select(transactions)
            ..where((t) => t.id.equals(due.transactionId)))
          .getSingleOrNull();

      if (purchase == null) {
        throw StateError('Purchase transaction not found.');
      }

      final previousPayments = await (select(duePayments)
            ..where((payment) => payment.dueId.equals(dueId)))
          .get();

      final alreadyPaid = previousPayments.fold<int>(
        0,
        (total, payment) => total + payment.amountPaisa,
      );

      final outstanding = purchase.amountPaisa -
          due.initialPaidPaisa -
          alreadyPaid;

      if (outstanding <= 0 || amountPaisa > outstanding) {
        throw StateError(
          'Payment exceeds the outstanding due.',
        );
      }

      await _checkAccountBalance(
        accountId: accountId,
        outgoingAmountPaisa: amountPaisa,
      );

      await into(duePayments).insert(
        DuePaymentsCompanion.insert(
          dueId: dueId,
          accountId: accountId,
          amountPaisa: amountPaisa,
          date: date,
          note: Value(note),
        ),
      );
    });
  }

  // PAY AN ENTIRE STORE
  //
  // If allocations is null:
  // Automatically pays the oldest unpaid purchases first.
  //
  // If allocations is supplied:
  // Uses the manually selected amount for each due ID.
  //
  // Returns the actual allocation:
  // {dueId: amountPaidPaisa}
  Future<Map<int, int>> addStoreDuePayment({
    required String storeName,
    required int accountId,
    required int amountPaisa,
    required DateTime date,
    String? note,
    Map<int, int>? allocations,
  }) async {
    if (storeName.trim().isEmpty || amountPaisa <= 0) {
      throw ArgumentError('Invalid store payment information.');
    }

    return transaction(() async {
      await _checkAccountBalance(
        accountId: accountId,
        outgoingAmountPaisa: amountPaisa,
      );

      final storeDues = await (select(dues)
            ..where((d) => d.storeName.equals(storeName.trim())))
          .get();

      final balances = <_StoreDueBalance>[];

      for (final due in storeDues) {
        final purchase = await (select(transactions)
              ..where((t) => t.id.equals(due.transactionId)))
            .getSingleOrNull();

        if (purchase == null) {
          continue;
        }

        final previousPayments = await (select(duePayments)
              ..where((payment) => payment.dueId.equals(due.id)))
            .get();

        final alreadyPaid = previousPayments.fold<int>(
          0,
          (total, payment) => total + payment.amountPaisa,
        );

        final outstanding = purchase.amountPaisa -
            due.initialPaidPaisa -
            alreadyPaid;

        if (outstanding > 0) {
          balances.add(
            _StoreDueBalance(
              dueId: due.id,
              purchaseDate: purchase.date,
              outstanding: outstanding,
            ),
          );
        }
      }

      // Oldest purchase first.
      balances.sort((a, b) {
        final dateComparison =
            a.purchaseDate.compareTo(b.purchaseDate);

        if (dateComparison != 0) {
          return dateComparison;
        }

        return a.dueId.compareTo(b.dueId);
      });

      final totalOutstanding = balances.fold<int>(
        0,
        (total, item) => total + item.outstanding,
      );

      if (amountPaisa > totalOutstanding) {
        throw StateError(
          'Payment exceeds the store outstanding amount.',
        );
      }

      final result = <int, int>{};

      if (allocations == null) {
        // AUTOMATIC OLDEST-FIRST ALLOCATION
        var remaining = amountPaisa;

        for (final item in balances) {
          if (remaining <= 0) break;

          final payment = remaining > item.outstanding
              ? item.outstanding
              : remaining;

          result[item.dueId] = payment;
          remaining -= payment;
        }
      } else {
        // MANUAL ALLOCATION
        final validDueIds =
            balances.map((item) => item.dueId).toSet();

        for (final entry in allocations.entries) {
          if (!validDueIds.contains(entry.key)) {
            throw StateError(
              'Invalid purchase selected for allocation.',
            );
          }

          if (entry.value < 0) {
            throw StateError(
              'Allocation cannot be negative.',
            );
          }

          final balance = balances.firstWhere(
            (item) => item.dueId == entry.key,
          );

          if (entry.value > balance.outstanding) {
            throw StateError(
              'Allocation exceeds a purchase outstanding amount.',
            );
          }

          if (entry.value > 0) {
            result[entry.key] = entry.value;
          }
        }

        final allocatedTotal = result.values.fold<int>(
          0,
          (total, value) => total + value,
        );

        if (allocatedTotal != amountPaisa) {
          throw StateError(
            'The allocations must equal the total payment.',
          );
        }
      }

      // SAVE EACH PURCHASE PAYMENT SEPARATELY.
      for (final entry in result.entries) {
        await into(duePayments).insert(
          DuePaymentsCompanion.insert(
            dueId: entry.key,
            accountId: accountId,
            amountPaisa: entry.value,
            date: date,
            note: Value(note),
          ),
        );
      }

      return result;
    });
  }
}

// STORE DUE BALANCE HELPER
class _StoreDueBalance {
  final int dueId;
  final DateTime purchaseDate;
  final int outstanding;

  const _StoreDueBalance({
    required this.dueId,
    required this.purchaseDate,
    required this.outstanding,
  });
}

// DATABASE CONNECTION
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory =
        await getApplicationDocumentsDirectory();

    final file = File(
      p.join(directory.path, 'my_money.sqlite'),
    );

    return NativeDatabase.createInBackground(file);
  });
}
