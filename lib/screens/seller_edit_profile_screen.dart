import 'package:flutter/material.dart';

import '../services/profile_service.dart';

class SellerEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const SellerEditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<SellerEditProfileScreen> createState() =>
      _SellerEditProfileScreenState();
}

class _SellerEditProfileScreenState
    extends State<SellerEditProfileScreen> {
  final _formKey =
  GlobalKey<FormState>();

  final ProfileService _profileService =
  ProfileService();

  late TextEditingController
  _nameController;

  late TextEditingController
  _phoneController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(
          text:
          widget.profile['full_name'] ??
              '',
        );

    _phoneController =
        TextEditingController(
          text:
          widget.profile['phone'] ??
              '',
        );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _profileService
          .updateSellerAccountInfo(
        fullName:
        _nameController.text.trim(),
        phone:
        _phoneController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully',
          ),
          backgroundColor:
          Color(0xFF38BB62),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: $e',
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
        ),
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
      ),
      body: SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets.all(
            20,
          ),
          child:
          Form(
            key:
            _formKey,
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
              children: [
                const Text(
                  'Account Information',
                  style:
                  TextStyle(
                    fontSize:
                    22,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'You can update your personal account information here.',
                  style:
                  TextStyle(
                    fontSize:
                    13,
                    color:
                    Color(
                      0xFF777777,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                TextFormField(
                  controller:
                  _nameController,
                  textInputAction:
                  TextInputAction.next,
                  decoration:
                  InputDecoration(
                    labelText:
                    'Full Name',
                    prefixIcon:
                    const Icon(
                      Icons.person_outline,
                    ),
                    filled:
                    true,
                    fillColor:
                    Colors.white,
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  validator:
                      (
                      value,
                      ) {
                    if (value ==
                        null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter your name';
                    }

                    if (value
                        .trim()
                        .length <
                        2) {
                      return 'Name is too short';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                TextFormField(
                  controller:
                  _phoneController,
                  keyboardType:
                  TextInputType.phone,
                  textInputAction:
                  TextInputAction.done,
                  decoration:
                  InputDecoration(
                    labelText:
                    'Phone Number',
                    prefixIcon:
                    const Icon(
                      Icons.phone_outlined,
                    ),
                    filled:
                    true,
                    fillColor:
                    Colors.white,
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  validator:
                      (
                      value,
                      ) {
                    if (value ==
                        null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter your phone number';
                    }

                    final phone =
                    value
                        .trim();

                    if (!RegExp(
                      r'^[0-9+\-\s]{8,15}$',
                    ).hasMatch(
                      phone,
                    )) {
                      return 'Please enter a valid phone number';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 32,
                ),
                SizedBox(
                  height:
                  52,
                  child:
                  FilledButton(
                    onPressed:
                    _isLoading
                        ? null
                        : _saveProfile,
                    style:
                    FilledButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xFF38BB62,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child:
                    _isLoading
                        ? const SizedBox(
                      width:
                      24,
                      height:
                      24,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Text(
                      'SAVE CHANGES',
                      style:
                      TextStyle(
                        fontSize:
                        16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
