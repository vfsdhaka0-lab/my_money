
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

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Dues,
    DuePayments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

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

            // Existing transactions were already fully paid.
            await customStatement(
              'UPDATE transactions '
              'SET paid_amount_paisa = amount_paisa',
            );
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
    String? note,
  }) {
    return into(transactions).insert(
      TransactionsCompanion.insert(
        accountId: accountId,
        title: title,
        amountPaisa: amountPaisa,
        paidAmountPaisa: Value(amountPaisa),
        type: type,
        date: date,
        note: Value(note),
      ),
    );
  }

  // DUES
  Stream<List<Due>> watchDues() {
    return (select(dues)
          ..orderBy([
            (d) => OrderingTerm.desc(d.createdAt),
          ]))
        .watch();
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
