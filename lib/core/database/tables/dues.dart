
import 'package:drift/drift.dart';

class Dues extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Store or shop name.
  TextColumn get storeName => text()();

  // The original purchase transaction.
  IntColumn get transactionId => integer()();

  // Amount already paid at the time of purchase.
  IntColumn get initialPaidPaisa => integer()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  TextColumn get note => text().nullable()();
}
