import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor:
              Color(0xFFE1F6E8),
              child: Icon(
                Icons.person,
                size: 58,
                color: Color(0xFF38BB62),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              'SmartJimat User',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 6),

          const Center(
            child: Text(
              'Manage your SmartJimat profile',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 32),

          _ProfileOption(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () {},
          ),

          const SizedBox(height: 12),

          _ProfileOption(
            icon: Icons.location_on_outlined,
            title: 'Location',
            onTap: () {},
          ),

          const SizedBox(height: 12),

          _ProfileOption(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {},
          ),

          const SizedBox(height: 12),

          _ProfileOption(
            icon: Icons.info_outline,
            title: 'About SmartJimat',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(16),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFE7F8EC),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                  const Color(0xFF38BB62),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}