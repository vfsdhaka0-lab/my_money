import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

      final media = drive.Media(
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

  Future<File?> downloadBackup() async {
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

      if (existingFiles.files == null ||
          existingFiles.files!.isEmpty) {
        return null;
      }

      final fileId = existingFiles.files!.first.id;

      if (fileId == null) {
        throw Exception('Backup file ID not found.');
      }

      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (response is! drive.Media) {
        throw Exception('Invalid backup download response.');
      }

      final directory = await getTemporaryDirectory();

      final backupFile = File(
        p.join(directory.path, 'mymoney_backup_download.zip'),
      );

      await response.stream.pipe(backupFile.openWrite());

      return backupFile;
    } finally {
      client.close();
    }
  }
}