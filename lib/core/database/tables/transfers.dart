
import 'package:drift/drift.dart';

class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Account money is transferred from.
  IntColumn get fromAccountId => integer()();

  // Account money is transferred to.
  IntColumn get toAccountId => integer()();

  // Transfer amount in paisa.
  IntColumn get amountPaisa => integer()();

  DateTimeColumn get date => dateTime()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
