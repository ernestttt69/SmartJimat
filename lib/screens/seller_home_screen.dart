import 'package:flutter/material.dart';
import 'seller_dashboard_screen.dart';
import 'seller_profile_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() =>
      _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SellerDashboardScreen(),

    Center(
      child: Text('Products'),
    ),

    Center(
      child: Text('Add Product'),
    ),

    SellerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        backgroundColor: const Color(0xFF38BB62),

        indicatorColor: Colors.white,

        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),

          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add Product',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}