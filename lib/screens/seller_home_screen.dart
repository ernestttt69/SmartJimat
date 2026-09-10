import 'package:flutter/material.dart';

import 'seller_products_screen.dart';
import 'add_product_screen.dart';
import 'seller_profile_screen.dart';
import 'delete_product_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({
    super.key,
  });

  @override
  State<SellerHomeScreen> createState() =>
      _SellerHomeScreenState();
}

class _SellerHomeScreenState
    extends State<SellerHomeScreen> {
  static const Color smartJimatGreen =
  Color(0xFF38BB62);

  static const Color darkGreen =
  Color(0xFF2E9F52);

  static const Color darkText =
  Color(0xFF333632);

  static const Color secondaryText =
  Color(0xFF666666);

  static const Color lightGreen =
  Color(0xFFE8F8ED);

  int _currentIndex = 0;

  final GlobalKey<SellerProductsScreenState>
  _productsKey =
  GlobalKey<SellerProductsScreenState>();

  void _changeTab(
      int index,
      ) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      WidgetsBinding.instance
          .addPostFrameCallback(
            (_) {
          _productsKey.currentState
              ?.loadProducts();
        },
      );
    }
  }

  void _goToProducts() {
    _changeTab(1);
  }

  void _goToAddProduct() {
    _changeTab(2);
  }

  void _goToProfile() {
    _changeTab(3);
  }

  Future<void>
  _openDeletedProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const DeletedProductsScreen(),
      ),
    );

    _productsKey.currentState
        ?.loadProducts();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final pages = [
      _buildDashboard(),
      SellerProductsScreen(
        key: _productsKey,
      ),
      AddProductScreen(
        onProductAdded: () {
          _goToProducts();
        },
      ),
      const SellerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor:
      Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar:
      NavigationBar(
        selectedIndex:
        _currentIndex,
        backgroundColor:
        smartJimatGreen,
        indicatorColor:
        Colors.white,
        labelBehavior:
        NavigationDestinationLabelBehavior
            .alwaysShow,
        onDestinationSelected:
        _changeTab,
        destinations:
        const [
          NavigationDestination(
            tooltip: 'Seller Home',
            icon: Icon(
              Icons.home_outlined,
              color: Colors.white,
            ),
            selectedIcon: Icon(
              Icons.home,
              color: darkGreen,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            tooltip:
            'View Products',
            icon: Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
            ),
            selectedIcon: Icon(
              Icons.inventory_2,
              color: darkGreen,
            ),
            label: 'Products',
          ),
          NavigationDestination(
            tooltip:
            'Add Product',
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.white,
            ),
            selectedIcon: Icon(
              Icons.add_circle,
              color: darkGreen,
            ),
            label: 'Add',
          ),
          NavigationDestination(
            tooltip:
            'Seller Profile',
            icon: Icon(
              Icons.person_outline,
              color: Colors.white,
            ),
            selectedIcon: Icon(
              Icons.person,
              color: darkGreen,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF8FAF8,
      ),
      appBar: AppBar(
        automaticallyImplyLeading:
        false,
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
        elevation: 0,
        title: Semantics(
          header: true,
          label:
          'SmartJimat Seller Dashboard',
          child: Row(
            children: [
              Image.asset(
                'assets/images/smartjimat_logo.png',
                width: 48,
                height: 42,
                fit: BoxFit.contain,
                semanticLabel:
                'SmartJimat logo',
              ),
              const SizedBox(
                width: 10,
              ),
              const Expanded(
                child: Text(
                  'Seller Dashboard',
                  style:
                  TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    darkText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            32,
          ),
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Semantics(
                header:
                true,
                child:
                const Text(
                  'Welcome Back!',
                  style:
                  TextStyle(
                    fontSize:
                    28,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    darkText,
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              const Text(
                'Manage your products quickly and easily.',
                style:
                TextStyle(
                  color:
                  secondaryText,
                  fontSize:
                  15,
                  height:
                  1.4,
                ),
              ),
              const SizedBox(
                height: 28,
              ),
              Semantics(
                header:
                true,
                child:
                const Text(
                  'Quick Actions',
                  style:
                  TextStyle(
                    fontSize:
                    20,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    darkText,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              LayoutBuilder(
                builder:
                    (
                    context,
                    constraints,
                    ) {
                  if (constraints
                      .maxWidth >=
                      600) {
                    return Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Expanded(
                          child:
                          _actionCard(
                            icon:
                            Icons
                                .add_circle_outline,
                            title:
                            'Add Product',
                            description:
                            'Add a new product and selling price.',
                            semanticLabel:
                            'Add a new product',
                            onTap:
                            _goToAddProduct,
                          ),
                        ),
                        const SizedBox(
                          width:
                          16,
                        ),
                        Expanded(
                          child:
                          _actionCard(
                            icon:
                            Icons
                                .inventory_2_outlined,
                            title:
                            'My Products',
                            description:
                            'View and manage your active products.',
                            semanticLabel:
                            'View your active products',
                            onTap:
                            _goToProducts,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _actionCard(
                        icon:
                        Icons
                            .add_circle_outline,
                        title:
                        'Add Product',
                        description:
                        'Add a new product and selling price.',
                        semanticLabel:
                        'Add a new product',
                        onTap:
                        _goToAddProduct,
                      ),
                      const SizedBox(
                        height:
                        14,
                      ),
                      _actionCard(
                        icon:
                        Icons
                            .inventory_2_outlined,
                        title:
                        'My Products',
                        description:
                        'View and manage your active products.',
                        semanticLabel:
                        'View your active products',
                        onTap:
                        _goToProducts,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(
                height: 28,
              ),
              Semantics(
                header:
                true,
                child:
                const Text(
                  'Product Recovery',
                  style:
                  TextStyle(
                    fontSize:
                    20,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    darkText,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              _actionCard(
                icon:
                Icons.restore_from_trash_outlined,
                title:
                'Deleted Products',
                description:
                'View deleted products and restore them.',
                semanticLabel:
                'View deleted products and restore them',
                onTap:
                _openDeletedProducts,
              ),
              const SizedBox(
                height: 28,
              ),
              Semantics(
                header:
                true,
                child:
                const Text(
                  'Account',
                  style:
                  TextStyle(
                    fontSize:
                    20,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    darkText,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              _accountCard(
                icon:
                Icons.person_outline,
                title:
                'Seller Profile',
                subtitle:
                'View your account and premise information.',
                onTap:
                _goToProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String description,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label:
      semanticLabel,
      child:
      Material(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        child:
        InkWell(
          onTap:
          onTap,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          child:
          Container(
            width:
            double.infinity,
            constraints:
            const BoxConstraints(
              minHeight:
              120,
            ),
            padding:
            const EdgeInsets.all(
              18,
            ),
            decoration:
            BoxDecoration(
              borderRadius:
              BorderRadius.circular(
                16,
              ),
              border:
              Border.all(
                color:
                const Color(
                  0xFFD5ECDD,
                ),
                width:
                1.2,
              ),
            ),
            child:
            Row(
              children: [
                Container(
                  width:
                  58,
                  height:
                  58,
                  decoration:
                  BoxDecoration(
                    color:
                    lightGreen,
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                  Icon(
                    icon,
                    size:
                    30,
                    color:
                    darkGreen,
                  ),
                ),
                const SizedBox(
                  width:
                  16,
                ),
                Expanded(
                  child:
                  Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                        const TextStyle(
                          fontSize:
                          17,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          darkText,
                        ),
                      ),
                      const SizedBox(
                        height:
                        6,
                      ),
                      Text(
                        description,
                        style:
                        const TextStyle(
                          fontSize:
                          13,
                          height:
                          1.35,
                          color:
                          secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width:
                  8,
                ),
                const Icon(
                  Icons.chevron_right,
                  color:
                  darkGreen,
                  size:
                  28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button:
      true,
      label:
      '$title. $subtitle',
      child:
      Material(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        child:
        InkWell(
          onTap:
          onTap,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          child:
          Container(
            width:
            double.infinity,
            constraints:
            const BoxConstraints(
              minHeight:
              84,
            ),
            padding:
            const EdgeInsets.symmetric(
              horizontal:
              18,
              vertical:
              16,
            ),
            decoration:
            BoxDecoration(
              borderRadius:
              BorderRadius.circular(
                16,
              ),
              border:
              Border.all(
                color:
                const Color(
                  0xFFE1E7E3,
                ),
              ),
            ),
            child:
            Row(
              children: [
                Container(
                  width:
                  48,
                  height:
                  48,
                  decoration:
                  BoxDecoration(
                    color:
                    lightGreen,
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                  Icon(
                    icon,
                    color:
                    darkGreen,
                    size:
                    26,
                  ),
                ),
                const SizedBox(
                  width:
                  16,
                ),
                Expanded(
                  child:
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                        const TextStyle(
                          fontSize:
                          16,
                          fontWeight:
                          FontWeight.w600,
                          color:
                          darkText,
                        ),
                      ),
                      const SizedBox(
                        height:
                        4,
                      ),
                      Text(
                        subtitle,
                        style:
                        const TextStyle(
                          fontSize:
                          13,
                          height:
                          1.3,
                          color:
                          secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color:
                  darkGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}