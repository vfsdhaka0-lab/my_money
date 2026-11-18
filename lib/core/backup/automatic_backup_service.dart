
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
  bool _isReady = false;

  static const Duration _backupDelay =
      Duration(seconds: 5);

  Future<File> _getFile(String name) async {
    final directory =
        await getApplicationDocumentsDirectory();

    return File(p.join(directory.path, name));
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
        if (_isReady) {
          _scheduleBackup();
        }
      },
      onError: (Object error) {},
    );

    unawaited(_loadReadiness());
  }

  Future<void> _loadReadiness() async {
    try {
      final file =
          await _getFile('automatic_backup_enabled.txt');

      _isReady = await file.exists();

      if (_isReady) {
        await _checkDailyBackup();
      }
    } catch (_) {
      _isReady = false;
    }
  }

  Future<void> markBackupReady() async {
    final file =
        await _getFile('automatic_backup_enabled.txt');

    await file.writeAsString('enabled');

    _isReady = true;

    await _saveSuccessfulBackupTime();
  }

  void _scheduleBackup() {
    if (!_isReady) return;

    _backupTimer?.cancel();

    _backupTimer = Timer(_backupDelay, () async {
      try {
        await BackupManager.instance.backupAutomatically();
        await _saveSuccessfulBackupTime();
      } catch (_) {
        // Retry on a later database change or app launch.
      }
    });
  }

  Future<void> _checkDailyBackup() async {
    final file =
        await _getFile('automatic_backup_last_success.txt');

    DateTime? lastBackup;

    if (await file.exists()) {
      lastBackup = DateTime.tryParse(
        await file.readAsString(),
      );
    }

    final now = DateTime.now();

    final backupIsDue = lastBackup == null ||
        lastBackup.year != now.year ||
        lastBackup.month != now.month ||
        lastBackup.day != now.day;

    if (!backupIsDue) return;

    await BackupManager.instance.backupAutomatically();

    await _saveSuccessfulBackupTime();
  }

  Future<void> _saveSuccessfulBackupTime() async {
    final file =
        await _getFile('automatic_backup_last_success.txt');

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
