import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/database_instance.dart';

class BackupFileService {
  BackupFileService._();

  static final BackupFileService instance =
      BackupFileService._();

  Future<File> createBackupArchive() async {
    final appDirectory =
        await getApplicationDocumentsDirectory();

    final temporaryDirectory =
        await getTemporaryDirectory();

    final snapshotFile = File(
      p.join(
        temporaryDirectory.path,
        'mymoney_database_snapshot.sqlite',
      ),
    );

    final backupFile = File(
      p.join(
        temporaryDirectory.path,
        'mymoney_backup.zip',
      ),
    );

    if (await snapshotFile.exists()) {
      await snapshotFile.delete();
    }

    if (await backupFile.exists()) {
      await backupFile.delete();
    }

    // Create a consistent SQLite database snapshot.
    await database.customStatement(
      'VACUUM INTO ?',
      [snapshotFile.path],
    );

    final encoder = ZipFileEncoder();

    try {
      encoder.create(backupFile.path);

      // Add the database.
      await encoder.addFile(
        snapshotFile,
        'my_money.sqlite',
      );

      // Add store images if the folder exists.
      final imageDirectory = Directory(
        p.join(appDirectory.path, 'store_images'),
      );

      if (await imageDirectory.exists()) {
        await encoder.addDirectory(
          imageDirectory,
          includeDirName: true,
        );
      }

      await encoder.close();

      return backupFile;
    } catch (_) {
      await backupFile.delete().catchError((_) => backupFile);
      rethrow;
    } finally {
      if (await snapshotFile.exists()) {
        await snapshotFile.delete();
      }
    }
  }
}