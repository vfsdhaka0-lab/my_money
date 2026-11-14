import 'package:drift/drift.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get accountId => integer()();

  IntColumn get categoryId => integer().nullable()();

  TextColumn get title => text()();

  IntColumn get amountPaisa => integer()();

  TextColumn get type => text()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get date => dateTime()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
