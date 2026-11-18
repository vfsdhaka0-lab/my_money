
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/database_instance.dart';
import 'backup_manager.dart';

class AutomaticBackupService {
  AutomaticBackupService._();

  static final AutomaticBackupService instance =
      AutomaticBackupService._();

  Timer? _backupTimer;
  StreamSubscription? _databaseSubscription;

  bool _isStarted = false;

  static const Duration _backupDelay =
      Duration(seconds: 5);

  Future<File> _getBackupTimeFile() async {
    final directory =
        await getApplicationDocumentsDirectory();

    return File(
      p.join(
        directory.path,
        'automatic_backup_last_success.txt',
      ),
    );
  }

  void start() {
    if (_isStarted) return;

    _isStarted = true;

    _databaseSubscription = database
        .tableUpdates(
          TableUpdateQuery.onAllTables(database.allTables),
        )
        .listen(
      (_) {
        _scheduleBackup();
      },
      onError: (Object error) {
        // Prevent listener errors from crashing the app.
      },
    );

    unawaited(_checkDailyBackup());
  }

  void _scheduleBackup() {
    _backupTimer?.cancel();

    _backupTimer = Timer(_backupDelay, () async {
      try {
        await BackupManager.instance.backupAutomatically();
        await _saveSuccessfulBackupTime();
      } catch (error) {
        // A failed upload must not be recorded as successful.
      }
    });
  }

  Future<void> _checkDailyBackup() async {
    try {
      final file = await _getBackupTimeFile();

      DateTime? lastBackup;

      if (await file.exists()) {
        final savedTime = await file.readAsString();
        lastBackup = DateTime.tryParse(savedTime);
      }

      final now = DateTime.now();

      final backupIsDue = lastBackup == null ||
          lastBackup.year != now.year ||
          lastBackup.month != now.month ||
          lastBackup.day != now.day;

      if (!backupIsDue) return;

      await BackupManager.instance.backupAutomatically();

      await _saveSuccessfulBackupTime();
    } catch (error) {
      // Try again the next time the app opens.
    }
  }

  Future<void> _saveSuccessfulBackupTime() async {
    final file = await _getBackupTimeFile();

    await file.writeAsString(
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> stop() async {
    _backupTimer?.cancel();
    _backupTimer = null;

    await _databaseSubscription?.cancel();
    _databaseSubscription = null;

    _isStarted = false;
  }
}
