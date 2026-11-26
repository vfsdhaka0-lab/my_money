import 'package:drift/drift.dart';

class AccountAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get accountId => integer()();

  // Positive = increase, negative = decrease.
  IntColumn get amountPaisa => integer()();

  TextColumn get reason => text()();

  DateTimeColumn get date => dateTime()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}