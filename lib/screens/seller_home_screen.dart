import 'package:flutter/material.dart';
import '../widgets/adaptive_navigation_scaffold.dart';

import 'seller_dashboard_screen.dart';
import 'seller_products_screen.dart';
import 'add_product_screen.dart';
import 'seller_profile_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() =>
      _SellerHomeScreenState();
}

class _SellerHomeScreenState
    extends State<SellerHomeScreen> {
  int _currentIndex = 0;

  final GlobalKey<SellerProductsScreenState>
  _productsKey =
  GlobalKey<SellerProductsScreenState>();

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SellerDashboardScreen(),

      SellerProductsScreen(
        key: _productsKey,
      ),

      AddProductScreen(
        onProductAdded: () {
          _productsKey.currentState
              ?.loadProducts();

          setState(() {
            _currentIndex = 1;
          });
        },
      ),

      const SellerProfileScreen(),
    ];

    return AdaptiveNavigationScaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor:
        const Color(0xFF38BB62),
        indicatorColor: Colors.white,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 1) {
            _productsKey.currentState
                ?.loadProducts();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon:
            Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.inventory_2_outlined,
            ),
            selectedIcon:
            Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.add_circle_outline,
            ),
            selectedIcon:
            Icon(Icons.add_circle),
            label: 'Add Product',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon:
            Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
