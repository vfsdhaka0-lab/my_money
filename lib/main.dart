
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/backup/automatic_backup_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AutomaticBackupService.instance.start();

  runApp(const MyMoneyApp());
}
