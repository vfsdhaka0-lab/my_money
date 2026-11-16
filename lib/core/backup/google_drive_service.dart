import 'dart:io';

import 'package:googleapis/common.dart' show Media;
import 'package:googleapis/drive/v3.dart' as drive;

import 'google_drive_auth.dart';

class GoogleDriveService {
  GoogleDriveService._();

  static final GoogleDriveService instance =
      GoogleDriveService._();

  static const String backupFileName = 'mymoney_backup.zip';

  Future<void> uploadBackup(File backupFile) async {
    if (!await backupFile.exists()) {
      throw Exception('Backup file does not exist.');
    }

    final client =
        await GoogleDriveAuth.instance.getAuthenticatedClient();

    try {
      final driveApi = drive.DriveApi(client);

      final existingFiles = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$backupFileName' and trashed = false",
        pageSize: 10,
        $fields: 'files(id,name,modifiedTime)',
      );

      final media = Media(
        backupFile.openRead(),
        await backupFile.length(),
        contentType: 'application/zip',
      );

      if (existingFiles.files != null &&
          existingFiles.files!.isNotEmpty) {
        final fileId = existingFiles.files!.first.id;

        if (fileId == null) {
          throw Exception('Existing backup file ID not found.');
        }

        await driveApi.files.update(
          drive.File(),
          fileId,
          uploadMedia: media,
          $fields: 'id,name,modifiedTime',
        );
      } else {
        final fileMetadata = drive.File()
          ..name = backupFileName
          ..parents = ['appDataFolder'];

        await driveApi.files.create(
          fileMetadata,
          uploadMedia: media,
          $fields: 'id,name,modifiedTime',
        );
      }
    } finally {
      client.close();
    }
  }
}