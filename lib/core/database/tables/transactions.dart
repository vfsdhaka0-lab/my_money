
import 'package:drift/drift.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get accountId => integer()();

  IntColumn get categoryId => integer().nullable()();

  TextColumn get title => text()();

  // Total income or expense amount.
  IntColumn get amountPaisa => integer()();

  // Amount actually paid at the time of the transaction.
  IntColumn get paidAmountPaisa =>
      integer().withDefault(const Constant(0))();

  TextColumn get type => text()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get date => dateTime()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
