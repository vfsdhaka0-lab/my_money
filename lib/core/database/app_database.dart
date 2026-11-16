
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

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Dues,
    DuePayments,
    Stores,
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

  Future<int> addCategory({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) {
    return into(categories).insert(
      CategoriesCompanion.insert(
        name: name,
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
  }) {
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
          ..where((p) => p.dueId.equals(dueId)))
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
          ..where((p) => p.dueId.equals(dueId))
          ..orderBy([
            (p) => OrderingTerm.desc(p.date),
          ]))
        .watch();
  }

  Stream<List<DuePayment>> watchAllDuePayments() {
    return (select(duePayments)
          ..orderBy([
            (p) => OrderingTerm.desc(p.date),
          ]))
        .watch();
  }

  // ADD PAYMENT TOWARDS AN EXISTING DUE
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
            ..where((p) => p.dueId.equals(dueId)))
          .get();

      final alreadyPaid = previousPayments.fold<int>(
        0,
        (total, payment) => total + payment.amountPaisa,
      );

      final outstanding = purchase.amountPaisa -
          due.initialPaidPaisa -
          alreadyPaid;

      if (amountPaisa > outstanding) {
        throw StateError(
          'Payment exceeds the outstanding due.',
        );
      }

      final account = await (select(accounts)
            ..where((a) => a.id.equals(accountId)))
          .getSingleOrNull();

      if (account == null) {
        throw StateError('Account not found.');
      }

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
