
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../features/accounts/accounts_page.dart';
import '../features/transactions/transactions_page.dart';
import '../features/categories/categories_page.dart';
import '../features/dues/dues_page.dart';
import '../features/borrow_lend/borrow_lend_page.dart';
import '../features/backup/backup_page.dart';
import '../features/reports/reports_page.dart';
import 'theme.dart';

class MyMoneyApp extends StatelessWidget {
  const MyMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyMoney',
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
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
    ];

    return Scaffold(
      key: _scaffoldKey,

      appBar: selectedIndex == 2 ||
              selectedIndex == 4 ||
              selectedIndex == 5 ||
              selectedIndex == 6
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
              leading: const Icon(
                Icons.category_outlined,
              ),
              title: const Text('Categories & Stores'),
              selected: selectedIndex == 2,
              onTap: () => selectPage(2),
            ),

            ListTile(
              leading: const Icon(
                Icons.receipt_outlined,
              ),
              title: const Text('Due Management'),
              selected: selectedIndex == 3,
              onTap: () => selectPage(3),
            ),

            ListTile(
              leading: const Icon(
                Icons.swap_horiz_rounded,
              ),
              title: const Text('Borrow & Lend'),
              selected: selectedIndex == 4,
              onTap: () => selectPage(4),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(
                Icons.cloud_sync_outlined,
              ),
              title: const Text('Backup & Restore'),
              selected: selectedIndex == 5,
              onTap: () => selectPage(5),
            ),

            ListTile(
              leading: const Icon(
                Icons.analytics_outlined,
              ),
              title: const Text('Financial Reports'),
              selected: selectedIndex == 6,
              onTap: () => selectPage(6),
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
          const BackupPage(),
          const ReportsPage(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 2
            ? selectedIndex
            : 0,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.account_balance_wallet_outlined,
            ),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
            ),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.receipt_long_outlined,
            ),
            selectedIcon: Icon(
              Icons.receipt_long,
            ),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}
