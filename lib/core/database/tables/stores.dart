
import 'package:drift/drift.dart';

class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  // Local path of the store image.
  TextColumn get imagePath => text().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
