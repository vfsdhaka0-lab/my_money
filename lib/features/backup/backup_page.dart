
 // ignore_for_file: deprecated_member_use

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

class _BackupPageState extends State<BackupPage> {
  bool _isLoading = false;

  String _status = 'Your data has not been backed up yet.';

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
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
            const SizedBox(height: 30),
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
