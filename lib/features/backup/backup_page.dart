
 // ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/backup/automatic_backup_service.dart';
import '../../core/backup/backup_manager.dart';
import '../../core/backup/backup_restore_service.dart';
import '../../core/backup/google_drive_auth.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _automaticEnabled = false;
  bool _loadingBackupInfo = true;

  DateTime? _lastBackupTime;
  String? _lastBackupError;

  Timer? _refreshTimer;

  String _status = 'Your data has not been backed up yet.';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _refreshBackupInfo();

    // Automatically refresh backup status every 3 seconds.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshBackupInfo(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBackupInfo();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshBackupInfo() async {
    final service = AutomaticBackupService.instance;

    try {
      final enabled =
          await service.getAutomaticBackupEnabled();

      final lastBackup =
          await service.getLastSuccessfulBackupTime();

      final lastError =
          await service.getLastBackupError();

      if (!mounted) return;

      setState(() {
        _automaticEnabled = enabled;
        _lastBackupTime = lastBackup;
        _lastBackupError = lastError;
        _loadingBackupInfo = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingBackupInfo = false;
      });
    }
  }

  String _formatBackupTime(DateTime? dateTime) {
    if (dateTime == null) return 'No successful backup yet';

    final localTime = dateTime.toLocal();

    return localTime.toString().split('.').first;
  }

  Future<void> _connectAndBackup() async {
    setState(() {
      _isLoading = true;
      _status = 'Connecting to Google...';
    });

    try {
      await GoogleDriveAuth.instance.signIn();

      if (!mounted) return;

      setState(() {
        _status = 'Creating your backup...';
      });

      await BackupManager.instance.backupNow();

      await AutomaticBackupService.instance.markBackupReady();

      await _refreshBackupInfo();

      if (!mounted) return;

      setState(() {
        _status = 'Your backup was uploaded successfully! '
            'Automatic backup is now enabled.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Backup completed. Automatic backup enabled.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = 'Backup failed: $e';
      });

      await _refreshBackupInfo();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restore backup?'),
          content: const Text(
            'This will replace all current MyMoney records '
            'with the records saved in Google Drive.\n\n'
            'Please make sure you have backed up your '
            'current data before continuing.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _status = 'Downloading backup from Google Drive...';
    });

    try {
      await BackupRestoreService.instance.restoreFromGoogleDrive();

      await AutomaticBackupService.instance.markBackupReady();

      await _refreshBackupInfo();

      if (!mounted) return;

      setState(() {
        _status = 'Your data was restored successfully! '
            'Automatic backup is now enabled.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Data restored. Automatic backup enabled.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = 'Restore failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $e'),
          backgroundColor: Colors.red,
        ),
      );

      await _refreshBackupInfo();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            onPressed: _loadingBackupInfo
                ? null
                : _refreshBackupInfo,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh backup status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.cloud_sync_outlined,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'Google Drive Backup',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep your accounts, transactions, categories, '
              'dues and store images safe in Google Drive.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backup Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_loadingBackupInfo)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.autorenew,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Automatic backup'),
                          ),
                          Text(
                            _automaticEnabled
                                ? 'Enabled'
                                : 'Not enabled',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _automaticEnabled
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Last successful backup',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatBackupTime(_lastBackupTime),
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Latest automatic backup error',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _lastBackupError == null
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _lastBackupError == null
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastBackupError ??
                                  'No recent errors',
                              style: TextStyle(
                                color: _lastBackupError == null
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isLoading ? null : _connectAndBackup,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _isLoading ? 'Please wait...' : 'Backup Now',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _restoreBackup,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Restore from Google Drive'),
            ),
          ],
        ),
      ),
    );
  }
}
