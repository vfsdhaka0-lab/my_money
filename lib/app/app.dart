
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/backup/google_drive_auth.dart';
import '../core/backup/backup_restore_service.dart';
import '../core/backup/automatic_backup_service.dart';
import '../shared/database_instance.dart';
import '../features/auth/login_page.dart';
import '../features/accounts/accounts_page.dart';
import '../features/transactions/transactions_page.dart';
import '../features/categories/categories_page.dart';
import '../features/dues/dues_page.dart';
import '../features/borrow_lend/borrow_lend_page.dart';
import '../features/backup/backup_page.dart';
import '../features/reports/reports_page.dart';
import '../features/calendar/financial_calendar_page.dart';
import '../features/about/about_page.dart';
import 'theme.dart';

class MyMoneyApp extends StatelessWidget {
  const MyMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyMoney',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const StartupRecoveryGate();
        }

        return const LoginPage();
      },
    );
  }
}

/// Checks for a cloud backup before opening the home screen.
///
/// Existing local financial data is never overwritten.
/// Automatic backup is enabled when financial data exists.
class StartupRecoveryGate extends StatefulWidget {
  const StartupRecoveryGate({super.key});

  @override
  State<StartupRecoveryGate> createState() =>
      _StartupRecoveryGateState();
}

class _StartupRecoveryGateState
    extends State<StartupRecoveryGate> {
  bool _isChecking = true;

  String? _message;

  @override
  void initState() {
    super.initState();
    _checkForBackup();
  }

  Future<void> _checkForBackup() async {
    try {
      final restored = await BackupRestoreService.instance
          .restoreFromGoogleDriveIfLocalDatabaseEmpty();

      if (restored) {
        _message = 'Your Google Drive backup was restored.';
      }

      // Check whether financial data is available locally.
      final hasExistingData =
          await database.hasExistingFinancialData();

      // Automatically enable backup for an account that
      // already has financial data, including restored data.
      if (hasExistingData) {
        await AutomaticBackupService.instance
            .enableAutomaticBackup();
      }
    } catch (error) {
      _message = 'Automatic backup/restore could not complete: $error';
    }

    if (!mounted) return;

    setState(() {
      _isChecking = false;
    });

    if (_message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message!),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 18),
              Text(
                'Checking your MyMoney backup...',
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return const HomePage();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  int selectedIndex = 0;

  static const Color primary = Color(0xFF4FA38D);

  void selectPage(int index) {
    setState(() {
      selectedIndex = index;
    });

    Navigator.pop(context);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _handleBack() {
    if (selectedIndex != 0) {
      setState(() {
        selectedIndex = 0;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTitles = [
      'Accounts',
      'Transactions',
      'Categories & Stores',
      'Due Management',
      'Borrow & Lend',
      'Backup & Restore',
      'Financial Reports',
      'Financial Calendar',
      'My Account',
    ];

    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (selectedIndex != 0) {
          _handleBack();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,

        appBar: selectedIndex == 2 ||
                selectedIndex == 4 ||
                selectedIndex == 5 ||
                selectedIndex == 6 ||
                selectedIndex == 7
            ? null
            : AppBar(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                title: Text(
                  pageTitles[selectedIndex],
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: primary,
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'MyMoney',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                ),
                title: const Text('Accounts'),
                selected: selectedIndex == 0,
                onTap: () => selectPage(0),
              ),

              ListTile(
                leading: const Icon(
                  Icons.receipt_long_outlined,
                ),
                title: const Text('Transactions'),
                selected: selectedIndex == 1,
                onTap: () => selectPage(1),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Categories & Stores'),
                selected: selectedIndex == 2,
                onTap: () => selectPage(2),
              ),

              ListTile(
                leading: const Icon(Icons.receipt_outlined),
                title: const Text('Due Management'),
                selected: selectedIndex == 3,
                onTap: () => selectPage(3),
              ),

              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text('Borrow & Lend'),
                selected: selectedIndex == 4,
                onTap: () => selectPage(4),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('Financial Reports'),
                selected: selectedIndex == 6,
                onTap: () => selectPage(6),
              ),

              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Financial Calendar'),
                selected: selectedIndex == 7,
                onTap: () => selectPage(7),
              ),

              ListTile(
                leading: const Icon(Icons.cloud_sync_outlined),
                title: const Text('Backup & Restore'),
                selected: selectedIndex == 5,
                onTap: () => selectPage(5),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('My Account'),
                selected: selectedIndex == 8,
                onTap: () => selectPage(8),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About MyMoney'),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        body: IndexedStack(
          index: selectedIndex,
          children: [
            const AccountsPage(),
            const TransactionsPage(),
            CategoriesPage(onMenuPressed: _openDrawer),
            const DuesPage(),
            BorrowLendPage(onMenuPressed: _openDrawer),
            BackupPage(onMenuPressed: _openDrawer),
            ReportsPage(onMenuPressed: _openDrawer),
            FinancialCalendarPage(onMenuPressed: _openDrawer),
            const MyAccountPage(),
          ],
        ),

        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex < 2 ? selectedIndex : 0,
          onDestinationSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Accounts',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
          ],
        ),
      ),
    );
  }
}

class MyAccountPage extends StatelessWidget {
  const MyAccountPage({super.key});

  static const Color primary = Color(0xFF4FA38D);

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out?'),
          content: const Text(
            'Are you sure you want to sign out of MyMoney?\n\n'
            'Your accounts, transactions and other financial '
            'records will remain saved on this device. '
            'Your Google Drive backups will not be deleted.',
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
              style: FilledButton.styleFrom(
                backgroundColor: primary,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) return;

    try {
      await GoogleDriveAuth.instance.signOutFromMyMoney();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 25),

          CircleAvatar(
            radius: 55,
            backgroundColor: primary.withValues(alpha: 0.15),
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: primary,
                  )
                : null,
          ),

          const SizedBox(height: 18),

          Text(
            user?.displayName ?? 'MyMoney User',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            user?.email ?? 'No email available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 35),

          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Google account connected',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: primary,
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  const Row(
                    children: [
                      Icon(
                        Icons.cloud_done_outlined,
                        color: primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Google Drive backup available',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: user == null
                  ? null
                  : () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
