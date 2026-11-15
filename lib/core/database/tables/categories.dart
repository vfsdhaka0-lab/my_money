
import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get type => text()();

  TextColumn get icon =>
      text().withDefault(const Constant('category'))();

  TextColumn get color =>
      text().withDefault(const Constant('#4FA38D'))();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
}
