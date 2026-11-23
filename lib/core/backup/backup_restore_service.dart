
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' show Variable, UpdateKind;
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

      await database.customStatement(
        'ATTACH DATABASE ? AS backup_db',
        [snapshotFile.path],
      );

      try {
        await database.transaction(() async {
          // =====================================
          // DELETE EXISTING RECORDS
          // Child records must be deleted first.
          // =====================================

          // Borrow & Lend repayment history.
          await database.customUpdate(
            'DELETE FROM borrow_lend_payments',
            updates: {database.borrowLendPayments},
            updateKind: UpdateKind.delete,
          );

          // Borrow & Lend records.
          await database.customUpdate(
            'DELETE FROM borrow_lends',
            updates: {database.borrowLends},
            updateKind: UpdateKind.delete,
          );

          // Transfer history.
          await database.customUpdate(
            'DELETE FROM transfers',
            updates: {database.transfers},
            updateKind: UpdateKind.delete,
          );

          // Store due payment history.
          await database.customUpdate(
            'DELETE FROM due_payments',
            updates: {database.duePayments},
            updateKind: UpdateKind.delete,
          );

          // Store dues.
          await database.customUpdate(
            'DELETE FROM dues',
            updates: {database.dues},
            updateKind: UpdateKind.delete,
          );

          // Transactions.
          await database.customUpdate(
            'DELETE FROM transactions',
            updates: {database.transactions},
            updateKind: UpdateKind.delete,
          );

          // Categories.
          await database.customUpdate(
            'DELETE FROM categories',
            updates: {database.categories},
            updateKind: UpdateKind.delete,
          );

          // Stores.
          await database.customUpdate(
            'DELETE FROM stores',
            updates: {database.stores},
            updateKind: UpdateKind.delete,
          );

          // Accounts must be deleted last.
          await database.customUpdate(
            'DELETE FROM accounts',
            updates: {database.accounts},
            updateKind: UpdateKind.delete,
          );

          // =====================================
          // RESTORE SAVED RECORDS
          // Parent records must be restored first.
          // =====================================

          // Accounts.
          await database.customInsert(
            '''
            INSERT INTO accounts
            SELECT * FROM backup_db.accounts
            ''',
            updates: {database.accounts},
          );

          // Categories.
          await database.customInsert(
            '''
            INSERT INTO categories
            SELECT * FROM backup_db.categories
            ''',
            updates: {database.categories},
          );

          // Stores.
          await database.customInsert(
            '''
            INSERT INTO stores
            SELECT * FROM backup_db.stores
            ''',
            updates: {database.stores},
          );

          // Transactions.
          await database.customInsert(
            '''
            INSERT INTO transactions
            SELECT * FROM backup_db.transactions
            ''',
            updates: {database.transactions},
          );

          // Store dues.
          await database.customInsert(
            '''
            INSERT INTO dues
            SELECT * FROM backup_db.dues
            ''',
            updates: {database.dues},
          );

          // Store due payment history.
          await database.customInsert(
            '''
            INSERT INTO due_payments
            SELECT * FROM backup_db.due_payments
            ''',
            updates: {database.duePayments},
          );

          // =====================================
          // RESTORE TRANSFER HISTORY
          // =====================================

          await database.customInsert(
            '''
            INSERT INTO transfers
            SELECT * FROM backup_db.transfers
            ''',
            updates: {database.transfers},
          );

          // =====================================
          // RESTORE BORROW & LEND RECORDS
          // =====================================

          await database.customInsert(
            '''
            INSERT INTO borrow_lends
            SELECT * FROM backup_db.borrow_lends
            ''',
            updates: {database.borrowLends},
          );

          // Restore repayment history after
          // restoring the original records.
          await database.customInsert(
            '''
            INSERT INTO borrow_lend_payments
            SELECT * FROM backup_db.borrow_lend_payments
            ''',
            updates: {database.borrowLendPayments},
          );

          // =====================================
          // CORRECT STORE IMAGE PATHS
          // =====================================

          await database.customUpdate(
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
            variables: [
              Variable.withString(destinationImages.path),
            ],
            updates: {database.stores},
            updateKind: UpdateKind.update,
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
