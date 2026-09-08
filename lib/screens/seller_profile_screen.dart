import 'package:assignment/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/profile_service.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() =>
      _SellerProfileScreenState();
}

class _SellerProfileScreenState
    extends State<SellerProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _profile;

  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getSellerProfile();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _isUploadingImage = true;
      });

      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception('User is not logged in');
      }

      final file = File(image.path);

      final extension = image.path.split('.').last.toLowerCase();

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';

      final filePath =
          '${currentUser.id}/$fileName';

      await supabase.storage
          .from('profile-images')
          .upload(
        filePath,
        file,
        fileOptions: const FileOptions(
          upsert: true,
        ),
      );

      final imageUrl = supabase.storage
          .from('profile-images')
          .getPublicUrl(filePath);

      await supabase
          .from('user')
          .update({
        'profile_image_url': imageUrl,
      })
          .eq('id', currentUser.id);

      await _loadProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile image updated successfully!',
          ),
          backgroundColor: Color(0xFF38BB62),
        ),
      );
    } on StorageException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: ${error.message}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile image: $error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;
    Navigator.of(context).popUntil(
          (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Seller Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Profile icon
            Center(
              child: GestureDetector(
                onTap: _isUploadingImage
                    ? null
                    : _pickProfileImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFFE4F7EA),

                      backgroundImage:
                      _profile?['profile_image_url'] != null &&
                          _profile!['profile_image_url']
                              .toString()
                              .isNotEmpty
                          ? NetworkImage(
                        _profile!['profile_image_url']
                            .toString(),
                      )
                          : null,

                      child:
                      _profile?['profile_image_url'] == null ||
                          _profile!['profile_image_url']
                              .toString()
                              .isEmpty
                          ? const Icon(
                        Icons.storefront,
                        size: 48,
                        color: Color(0xFF38BB62),
                      )
                          : null,
                    ),

                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF38BB62),
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingImage
                            ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Tap the photo to change profile picture',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF777777),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _value('full_name'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333632),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              _value('email'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF777777),
              ),
            ),

            const SizedBox(height: 30),

            _buildSectionTitle(
              'Personal Information',
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Full Name',
              value: _value('full_name'),
            ),

            _buildInfoCard(
              icon: Icons.email_outlined,
              title: 'Email',
              value: _value('email'),
            ),

            _buildInfoCard(
              icon: Icons.phone_outlined,
              title: 'Phone Number',
              value: _value('phone'),
            ),

            _buildInfoCard(
              icon: Icons.badge_outlined,
              title: 'Role',
              value: _value('role'),
            ),

            const SizedBox(height: 25),

            _buildSectionTitle(
              'Premise Information',
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.store_outlined,
              title: 'Premise',
              value: _value('premise'),
            ),

            _buildInfoCard(
              icon: Icons.category_outlined,
              title: 'Premise Type',
              value: _value('premise_type'),
            ),

            _buildInfoCard(
              icon: Icons.location_on_outlined,
              title: 'Address',
              value: _value('address'),
            ),

            _buildInfoCard(
              icon: Icons.map_outlined,
              title: 'District',
              value: _value('district'),
            ),

            _buildInfoCard(
              icon: Icons.location_city_outlined,
              title: 'State',
              value: _value('state'),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: FilledButton.icon(
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        profile: _profile!,
                      ),
                    ),
                  );

                  if (updated == true) {
                    _loadProfile();
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'EDIT PROFILE',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_outline),
                label: const Text(
                  'CHANGE PASSWORD',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'LOGOUT',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _value(String key) {
    final value = _profile?[key];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return '-';
    }

    return value.toString();
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333632),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFDDEEE3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF38BB62),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333632),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}