import 'backup_file_service.dart';
import 'google_drive_service.dart';

class BackupManager {
  BackupManager._();

  static final BackupManager instance = BackupManager._();

  Future<void> backupNow() async {
    final backupFile =
        await BackupFileService.instance.createBackupArchive();

    await GoogleDriveService.instance.uploadBackup(backupFile);
  }

  Future<void> downloadBackup() async {
    final backupFile =
        await GoogleDriveService.instance.downloadBackup();

    if (backupFile == null) {
      throw Exception('No backup found in Google Drive.');
    }
  }
}