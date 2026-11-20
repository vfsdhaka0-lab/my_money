import 'package:drift/drift.dart';

class BorrowLendPayments extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Borrow or lend record this payment belongs to.
  IntColumn get borrowLendId => integer()();

  // Account used for this repayment.
  IntColumn get accountId => integer()();

  // Repayment amount in paisa.
  IntColumn get amountPaisa => integer()();

  DateTimeColumn get date => dateTime()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}