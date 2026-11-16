
 // ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/database_instance.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final ImagePicker _imagePicker = ImagePicker();

  final List<Map<String, dynamic>> _icons = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Housing', 'icon': Icons.home},
    {'name': 'Health', 'icon': Icons.medical_services},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Bills', 'icon': Icons.receipt_long},
    {'name': 'Travel', 'icon': Icons.flight},
    {'name': 'Salary', 'icon': Icons.payments},
    {'name': 'Business', 'icon': Icons.business},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Gift', 'icon': Icons.card_giftcard},
    {'name': 'Other', 'icon': Icons.category},
  ];

  final List<Color> _colors = [
    const Color(0xFF4FA38D),
    const Color(0xFF5795D1),
    const Color(0xFFE887A5),
    const Color(0xFFE6A04B),
    const Color(0xFF9575CD),
    const Color(0xFFD4B64C),
    const Color(0xFF45A6A6),
    const Color(0xFFE57373),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getIcon(String name) {
    for (final item in _icons) {
      if (item['name'] == name) {
        return item['icon'] as IconData;
      }
    }
    return Icons.category;
  }

  Color _getColor(String hex) {
    try {
      final value = hex.replaceFirst('#', '');
      return Color(int.parse('FF$value', radix: 16));
    } catch (_) {
      return const Color(0xFF4FA38D);
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _showAddCategoryDialog(String type) {
    final nameController = TextEditingController();

    String selectedIcon = 'Other';
    Color selectedColor = _colors.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add $type Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Category name',
                        hintText: 'Enter category name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose an icon',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _icons.map((item) {
                        final name = item['name'] as String;
                        final icon = item['icon'] as IconData;
                        final selected = selectedIcon == name;

                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = name;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: selected
                                  ? selectedColor.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? selectedColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: selected
                                  ? selectedColor
                                  : Colors.grey.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose a color',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colors.map((color) {
                        final selected = selectedColor == color;

                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = color;
                            });
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 19,
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a category name.'),
                        ),
                      );
                      return;
                    }

                    try {
                      await database.addCategory(
                        name: name,
                        type: type,
                        icon: selectedIcon,
                        color: _colorToHex(selectedColor),
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not add category: $e'),
                          ),
                        );
                      }
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

  Future<String> _saveStoreImage(XFile image) async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final imageDirectory = Directory(
      p.join(appDirectory.path, 'store_images'),
    );

    await imageDirectory.create(recursive: true);

    final extension = p.extension(image.path).isNotEmpty
        ? p.extension(image.path)
        : '.jpg';

    final fileName =
        'store_${DateTime.now().microsecondsSinceEpoch}$extension';

    final savedFile = await File(image.path).copy(
      p.join(imageDirectory.path, fileName),
    );

    return savedFile.path;
  }

  void _showAddStoreDialog() {
    final nameController = TextEditingController();
    final noteController = TextEditingController();

    XFile? selectedImage;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              try {
                final image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                  maxWidth: 1200,
                );

                if (image != null) {
                  setDialogState(() {
                    selectedImage = image;
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not select image: $e'),
                    ),
                  );
                }
              }
            }

            return AlertDialog(
              title: const Text('Add Store'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isSaving ? null : pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: selectedImage != null
                            ? Image.file(
                                File(selectedImage!.path),
                                fit: BoxFit.cover,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 32,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Add image',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Store name',
                        hintText: 'e.g. Agora, Shwapno',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a store name.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            String? imagePath;

                            if (selectedImage != null) {
                              imagePath = await _saveStoreImage(
                                selectedImage!,
                              );
                            }

                            await database.addStore(
                              name: name,
                              imagePath: imagePath,
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not add store: $e'),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      noteController.dispose();
    });
  }

  Widget _buildCategoryTab(String type) {
    return StreamBuilder(
      stream: database.watchCategories(type: type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not load categories.'),
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
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                const Text('Tap + to add your first category.'),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final color = _getColor(category.color);

            return Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.18),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(category.icon),
                      color: color,
                      size: 25,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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

  Widget _buildStoresTab() {
    return StreamBuilder(
      stream: database.watchStores(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not load stores.'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final stores = snapshot.data!;

        if (stores.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No stores added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Add stores where you usually shop.'),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.4),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: store.imagePath != null &&
                              store.imagePath!.isNotEmpty
                          ? Image.file(
                              File(store.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _storeImagePlaceholder();
                              },
                            )
                          : _storeImagePlaceholder(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (store.note != null &&
                            store.note!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            store.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
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

  Widget _storeImagePlaceholder() {
    return Container(
      color: Colors.grey.withOpacity(0.10),
      child: Center(
        child: Icon(
          Icons.store_outlined,
          size: 48,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Material(
            color: const Color(0xFF4FA38D),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorColor: const Color(0xFFFFB900),
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelColor: Colors.white70,
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Expense'),
                Tab(text: 'Income'),
                Tab(text: 'Stores'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryTab('Expense'),
                _buildCategoryTab('Income'),
                _buildStoresTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          switch (_tabController.index) {
            case 0:
              _showAddCategoryDialog('Expense');
              break;
            case 1:
              _showAddCategoryDialog('Income');
              break;
            case 2:
              _showAddStoreDialog();
              break;
          }
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
