
import 'backup_file_service.dart';
import 'google_drive_service.dart';

class BackupManager {
  BackupManager._();

  static final BackupManager instance = BackupManager._();

  Future<void>? _backupInProgress;

  Future<void> backupNow() {
    return _runBackup(allowInteraction: true);
  }

  Future<void> backupAutomatically() {
    return _runBackup(allowInteraction: false);
  }

  Future<void> _runBackup({
    required bool allowInteraction,
  }) async {
    if (_backupInProgress != null) {
      await _backupInProgress;
      return;
    }

    final operation = _createAndUploadBackup(
      allowInteraction: allowInteraction,
    );

    _backupInProgress = operation;

    try {
      await operation;
    } finally {
      _backupInProgress = null;
    }
  }

  Future<void> _createAndUploadBackup({
    required bool allowInteraction,
  }) async {
    final backupFile =
        await BackupFileService.instance.createBackupArchive();

    await GoogleDriveService.instance.uploadBackup(
      backupFile,
      allowInteraction: allowInteraction,
    );
  }

  Future<void> downloadBackup() async {
    final backupFile =
        await GoogleDriveService.instance.downloadBackup();

    if (backupFile == null) {
      throw Exception('No backup found in Google Drive.');
    }
  }
}
