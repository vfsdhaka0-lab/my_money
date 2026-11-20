import 'package:drift/drift.dart';

class BorrowLends extends Table {
  IntColumn get id => integer().autoIncrement()();

  // borrow or lend.
  TextColumn get type => text()();

  // Person's name.
  TextColumn get personName => text()();

  // Account receiving or paying the original amount.
  IntColumn get accountId => integer()();

  // Original amount in paisa.
  IntColumn get amountPaisa => integer()();

  DateTimeColumn get date => dateTime()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}