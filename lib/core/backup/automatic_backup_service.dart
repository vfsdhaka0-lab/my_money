
import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;

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
  }

  void _scheduleBackup() {
    _backupTimer?.cancel();

    _backupTimer = Timer(_backupDelay, () async {
      try {
        await BackupManager.instance.backupAutomatically();
      } catch (error) {
        // Prevent automatic backup errors from crashing the app.
      }
    });
  }

  Future<void> stop() async {
    _backupTimer?.cancel();
    _backupTimer = null;

    await _databaseSubscription?.cancel();
    _databaseSubscription = null;

    _isStarted = false;
  }
}
