import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import 'products_screen.dart';

class SubcategoryScreen extends StatefulWidget {
  final String itemGroup;

  const SubcategoryScreen({
    super.key,
    required this.itemGroup,
  });

  @override
  State<SubcategoryScreen> createState() =>
      _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  final SupabaseService supabaseService = SupabaseService();

  bool isLoading = true;
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final result =
      await supabaseService.getCategoriesByGroup(
        widget.itemGroup,
      );

      if (!mounted) return;

      setState(() {
        categories = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load subcategories: $e',
          ),
        ),
      );
    }
  }

  IconData getCategoryIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('sayur')) {
      return Icons.eco;
    }

    if (value.contains('buah')) {
      return Icons.apple;
    }

    if (value.contains('ayam')) {
      return Icons.restaurant;
    }

    if (value.contains('daging')) {
      return Icons.restaurant_menu;
    }

    if (value.contains('ikan')) {
      return Icons.set_meal;
    }

    if (value.contains('telur')) {
      return Icons.egg_alt_outlined;
    }

    if (value.contains('susu')) {
      return Icons.local_drink_outlined;
    }

    if (value.contains('beras')) {
      return Icons.rice_bowl;
    }

    if (value.contains('minyak')) {
      return Icons.water_drop_outlined;
    }

    if (value.contains('roti')) {
      return Icons.bakery_dining_outlined;
    }

    if (value.contains('kopi') ||
        value.contains('teh')) {
      return Icons.coffee_outlined;
    }

    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.itemGroup,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : categories.isEmpty
          ? const Center(
        child: Text(
          'No subcategories found',
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.itemGroup,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Choose a subcategory to view products.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 22),

          ...categories.map(
                (category) {

              return Padding(
                padding:
                const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Colors.white,
                  elevation: 0,
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFFE7F8EC),
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: Icon(
                        getCategoryIcon(category),
                        color:
                        const Color(0xFF38BB62),
                      ),
                    ),
                    title: Text(
                      category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductsScreen(
                                // Keep original values
                                // for Supabase query
                                itemGroup:
                                widget.itemGroup,
                                itemCategory:
                                category,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
