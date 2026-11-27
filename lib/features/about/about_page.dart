
 // ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color primary = Color(0xFF4FA38D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
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
        title: const Text(
          'About MyMoney',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 15),

            Image.asset(
              'assets/mymoney_logo.png',
              width: 310,
              height: 290,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 10),

            Text(
              'Your Personal Finance Manager',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 30),

            _infoCard(
              icon: Icons.info_outline,
              title: 'About the App',
              description:
                  'MyMoney helps you manage your personal '
                  'finances in one place. Track your income, '
                  'expenses, accounts, dues and savings '
                  'with an easy-to-use interface.',
            ),

            const SizedBox(height: 15),

            _infoCard(
              icon: Icons.stars_outlined,
              title: 'Features',
              description:
                  '• Account and balance management\n'
                  '• Income and expense tracking\n'
                  '• Money transfers\n'
                  '• Categories and stores\n'
                  '• Due management\n'
                  '• Borrow and lend tracking\n'
                  '• Financial reports and statistics\n'
                  '• Financial calendar\n'
                  '• Balance reconciliation\n'
                  '• Google Drive backup and restore',
            ),

            const SizedBox(height: 15),

            _infoCard(
              icon: Icons.security_outlined,
              title: 'Your Financial Data',
              description:
                  'MyMoney stores your financial records '
                  'on your device. You can also use the '
                  'Google Drive backup feature to back up '
                  'and restore your records.',
            ),

            const SizedBox(height: 15),

            _infoCard(
              icon: Icons.favorite_outline,
              title: 'Our Goal',
              description:
                  'Our goal is to make personal money '
                  'management simple, organized and '
                  'accessible for everyone.',
            ),

            const SizedBox(height: 25),

            Text(
              'MyMoney',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Made with care ❤️',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _infoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primary, size: 23),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
