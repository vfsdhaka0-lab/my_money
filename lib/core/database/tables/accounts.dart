import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  IntColumn get openingBalancePaisa =>
      integer().withDefault(const Constant(0))();

  TextColumn get currency =>
      text().withDefault(const Constant('BDT'))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
}
