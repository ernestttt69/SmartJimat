import 'package:flutter/material.dart';

import '../models/premise.dart';
import '../services/premise_service.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final ProfileService _profileService = ProfileService();
  final PremiseService _premiseService = PremiseService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  List<Premise> _premises = [];

  int? _selectedPremiseCode;

  bool _isLoading = false;
  bool _isLoadingPremises = true;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.profile['full_name'] ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.profile['phone'] ?? '',
    );

    _selectedPremiseCode =
    widget.profile['premise_code'];

    _loadPremises();
  }

  Future<void> _loadPremises() async {
    try {
      final premises =
      await _premiseService.getPremises();

      if (!mounted) return;

      setState(() {
        _premises = premises;
        _isLoadingPremises = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingPremises = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load premises: $e',
          ),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPremiseCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a premise',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _profileService.updateSellerProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        premiseCode: _selectedPremiseCode!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: $e',
          ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration:
                  const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon:
                    Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType:
                  TextInputType.phone,
                  decoration:
                  const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon:
                    Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                if (_isLoadingPremises)
                  const Center(
                    child:
                    CircularProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedPremiseCode,
                    isExpanded: true,
                    decoration:
                    const InputDecoration(
                      labelText: 'Premise',
                      prefixIcon:
                      Icon(Icons.store_outlined),
                    ),
                    items: _premises.map((premise) {
                      return DropdownMenuItem<int>(
                        value:
                        premise.premiseCode,
                        child: Text(
                          premise.premise,
                          overflow:
                          TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPremiseCode =
                            value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a premise';
                      }

                      return null;
                    },
                  ),

                const SizedBox(height: 32),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed:
                    _isLoading
                        ? null
                        : _saveProfile,
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
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