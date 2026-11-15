
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../shared/database_instance.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Orange', 'color': const Color(0xFFE58B42)},
    {'name': 'Blue', 'color': const Color(0xFF478BCB)},
    {'name': 'Purple', 'color': const Color(0xFFA36BCB)},
    {'name': 'Green', 'color': const Color(0xFF4D9A78)},
    {'name': 'Red', 'color': const Color(0xFFD65E70)},
    {'name': 'Yellow', 'color': const Color(0xFFD19A32)},
    {'name': 'Teal', 'color': const Color(0xFF4FA38D)},
    {'name': 'Pink', 'color': const Color(0xFFE47CA5)},
  ];

  final List<Map<String, dynamic>> _icons = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_bus},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Housing', 'icon': Icons.home},
    {'name': 'Health', 'icon': Icons.favorite},
    {'name': 'Entertainment', 'icon': Icons.sports_esports},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Bills', 'icon': Icons.receipt_long},
    {'name': 'Travel', 'icon': Icons.flight},
    {'name': 'Salary', 'icon': Icons.account_balance_wallet},
    {'name': 'Business', 'icon': Icons.business_center},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Gift', 'icon': Icons.card_giftcard},
    {'name': 'Other', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _parseColor(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData _getIcon(String name) {
    final item = _icons.firstWhere(
      (item) => item['name'] == name,
      orElse: () => {'icon': Icons.category},
    );

    return item['icon'] as IconData;
  }

  void _showAddCategoryDialog(String type) {
    final nameController = TextEditingController();
    String selectedIcon = 'Other';
    Color selectedColor = const Color(0xFF4FA38D);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                type == 'Expense'
                    ? 'Add Expense Category'
                    : 'Add Income Category',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose icon',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _icons.map((item) {
                        final isSelected =
                            selectedIcon == item['name'];

                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = item['name'] as String;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.15)
                                  : Colors.grey.shade100,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: selectedColor,
                              size: 25,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose color',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colors.map((item) {
                        final color = item['color'] as Color;
                        final isSelected = selectedColor == color;

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = color;
                            });
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: color,
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a category name',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await database.addCategory(
                        name: name,
                        type: type,
                        icon: selectedIcon,
                        color:
                            '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                      );

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('$name category added'),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not add category: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
    });
  }

  Widget _buildCategoryGrid(String type) {
    return StreamBuilder(
      stream: database.watchCategories(type: type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final categories = snapshot.data!;

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 55,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No $type categories yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add your first category',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            final color = _parseColor(category.color);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // FULL-COLOR ICON WITHOUT CIRCULAR BACKGROUND
                  Icon(
                    _getIcon(category.icon),
                    color: color,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4FA38D),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFB900),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryGrid('Expense'),
          _buildCategoryGrid('Income'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type =
              _tabController.index == 0 ? 'Expense' : 'Income';

          _showAddCategoryDialog(type);
        },
        backgroundColor: const Color(0xFFFFB900),
        foregroundColor: const Color(0xFF414331),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          size: 30,
        ),
      ),
    );
  }
}
