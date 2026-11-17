import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/database_instance.dart';
import 'google_drive_service.dart';

class BackupRestoreService {
  BackupRestoreService._();

  static final BackupRestoreService instance =
      BackupRestoreService._();

  Future<void> restoreFromGoogleDrive() async {
    final backupFile =
        await GoogleDriveService.instance.downloadBackup();

    if (backupFile == null) {
      throw Exception('No backup found in Google Drive.');
    }

    final temporaryDirectory =
        await getTemporaryDirectory();

    final restoreDirectory = Directory(
      p.join(temporaryDirectory.path, 'mymoney_restore'),
    );

    if (await restoreDirectory.exists()) {
      await restoreDirectory.delete(recursive: true);
    }

    await restoreDirectory.create(recursive: true);

    try {
      await extractFileToDisk(
        backupFile.path,
        restoreDirectory.path,
      );

      final snapshotFile = File(
        p.join(restoreDirectory.path, 'my_money.sqlite'),
      );

      if (!await snapshotFile.exists()) {
        throw Exception('Backup database was not found.');
      }

      final appDirectory =
          await getApplicationDocumentsDirectory();

      // Restore store images without deleting existing images.
      final sourceImages = Directory(
        p.join(restoreDirectory.path, 'store_images'),
      );

      final destinationImages = Directory(
        p.join(appDirectory.path, 'store_images'),
      );

      if (await sourceImages.exists()) {
        await destinationImages.create(recursive: true);

        await for (final entity
            in sourceImages.list(recursive: true)) {
          if (entity is! File) continue;

          final relativePath = p.relative(
            entity.path,
            from: sourceImages.path,
          );

          final destination = File(
            p.join(destinationImages.path, relativePath),
          );

          await destination.parent.create(recursive: true);
          await entity.copy(destination.path);
        }
      }

      // Attach the downloaded database.
      await database.customStatement(
        'ATTACH DATABASE ? AS backup_db',
        [snapshotFile.path],
      );

      try {
        await database.transaction(() async {
          // Remove existing records in child-first order.
          await database.customStatement(
            'DELETE FROM due_payments',
          );
          await database.customStatement(
            'DELETE FROM dues',
          );
          await database.customStatement(
            'DELETE FROM transactions',
          );
          await database.customStatement(
            'DELETE FROM categories',
          );
          await database.customStatement(
            'DELETE FROM stores',
          );
          await database.customStatement(
            'DELETE FROM accounts',
          );

          // Restore records in parent-first order.
          await database.customStatement(
            'INSERT INTO accounts SELECT * FROM backup_db.accounts',
          );
          await database.customStatement(
            'INSERT INTO categories SELECT * FROM backup_db.categories',
          );
          await database.customStatement(
            'INSERT INTO stores SELECT * FROM backup_db.stores',
          );
          await database.customStatement(
            'INSERT INTO transactions SELECT * FROM backup_db.transactions',
          );
          await database.customStatement(
            'INSERT INTO dues SELECT * FROM backup_db.dues',
          );
          await database.customStatement(
            'INSERT INTO due_payments SELECT * FROM backup_db.due_payments',
          );

          // Update saved image paths for this installation.
          await database.customStatement(
            '''
            UPDATE stores
            SET image_path = ? || '/' ||
              substr(
                image_path,
                instr(image_path, '/store_images/') +
                length('/store_images/')
              )
            WHERE image_path IS NOT NULL
              AND instr(image_path, '/store_images/') > 0
            ''',
            [destinationImages.path],
          );
        });
      } finally {
        await database.customStatement(
          'DETACH DATABASE backup_db',
        );
      }
    } finally {
      if (await restoreDirectory.exists()) {
        await restoreDirectory.delete(recursive: true);
      }
    }
  }
}