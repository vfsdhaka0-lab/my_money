
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../features/accounts/accounts_page.dart';
import '../features/transactions/transactions_page.dart';
import '../features/categories/categories_page.dart';
import '../features/dues/dues_page.dart';
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
  int selectedIndex = 0;

  final pages = const [
    AccountsPage(),
    TransactionsPage(),
  ];

  void openMenuPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],

      // TOP-RIGHT MENU
      appBar: AppBar(
        title: const Text('MyMoney'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'categories') {
                openMenuPage(const CategoriesPage());
              } else if (value == 'dues') {
                openMenuPage(const DuesPage());
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category_outlined),
                    SizedBox(width: 12),
                    Text('Categories & Stores'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'dues',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long),
                    SizedBox(width: 12),
                    Text('Due Management'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // ONLY TWO BOTTOM NAVIGATION ITEMS
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
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
    );
  }
}
