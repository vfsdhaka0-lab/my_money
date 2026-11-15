
import 'package:drift/drift.dart';

class DuePayments extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Which due record this payment belongs to.
  IntColumn get dueId => integer()();

  // Account used to make the payment.
  IntColumn get accountId => integer()();

  // Amount paid.
  IntColumn get amountPaisa => integer()();

  DateTimeColumn get date => dateTime()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
