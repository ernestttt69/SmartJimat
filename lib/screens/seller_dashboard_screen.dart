import 'package:flutter/material.dart';
import 'seller_profile_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState
    extends State<SellerDashboardScreen> {

  static const Color smartJimatGreen = Color(0xFF38BB62);
  static const Color darkText = Color(0xFF333632);

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/smartjimat_logo.png',
              width: 55,
              height: 45,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 10),

            const Text(
              'Seller Dashboard',
              style: TextStyle(
                color: darkText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Manage your products and premise information.',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Product Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),

              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.05,

                children: [
                  _dashboardCard(
                    context,
                    icon: Icons.add_box_outlined,
                    title: 'Add Product',
                    subtitle: 'Create new item',
                    onTap: () {
                      // AddProductScreen later
                    },
                  ),

                  _dashboardCard(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: 'View Products',
                    subtitle: 'View all items',
                    onTap: () {
                      // ProductListScreen later
                    },
                  ),

                  _dashboardCard(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Update Product',
                    subtitle: 'Edit product details',
                    onTap: () {
                      // UpdateProductScreen later
                    },
                  ),

                  _dashboardCard(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Deleted Products',
                    subtitle: 'Restore products',
                    onTap: () {
                      // Soft deleted products later
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),

              const SizedBox(height: 16),

              _listTile(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'View and update your profile',
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SellerProfileScreen(),
                      ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _listTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () {
                  // ChangePasswordScreen later
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: const Color(0xFFF7FBF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFBDE8CA),
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,

              decoration: BoxDecoration(
                color: const Color(0xFFE4F7EA),
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Icon(
                Icons.store,
                color: smartJimatGreen,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Icon(
                  icon,
                  color: smartJimatGreen,
                  size: 20,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = smartJimatGreen,
    Color textColor = darkText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF777777),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }
}