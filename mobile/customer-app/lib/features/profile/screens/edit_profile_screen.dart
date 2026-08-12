import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/config/app_config.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pinController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  
  String? _selectedGender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pinController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();

    // Populate current data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(profileProvider);
      profileState.whenData((profile) {
        setState(() {
          _nameController.text = profile.fullName;
          _emailController.text = profile.email;
          _phoneController.text = profile.phoneNumber;
          _dobController.text = profile.dateOfBirth ?? '';
          _selectedGender = profile.gender;
          _addressController.text = profile.address ?? '';
          _cityController.text = profile.city ?? '';
          _stateController.text = profile.state ?? '';
          _pinController.text = profile.pinCode ?? '';
          _emergencyNameController.text = profile.emergencyContactName ?? '';
          _emergencyPhoneController.text = profile.emergencyContactNumber ?? '';
        });
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 18)); // default to 18 years ago
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobController.text);
      } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF16A34A),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (file != null) {
        setState(() {
          _isSaving = true;
        });
        final bytes = await file.readAsBytes();
        await ref.read(profileProvider.notifier).uploadPhoto(bytes, file.name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final profileState = ref.read(profileProvider);
        final hasPhoto = profileState.maybeWhen(
          data: (p) => p.profileImageUrl != null && p.profileImageUrl!.isNotEmpty,
          orElse: () => false,
        );

        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF16A34A)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  context.pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF16A34A)),
                title: const Text('Take a Photo'),
                onTap: () {
                  context.pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Existing Photo', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    context.pop();
                    setState(() {
                      _isSaving = true;
                    });
                    try {
                      await ref.read(profileProvider.notifier).removePhoto();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile photo removed.')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to remove photo: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSaving = false;
                        });
                      }
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentProfile = ref.read(profileProvider).value;
      if (currentProfile == null) return;

      final updated = UserProfile(
        id: currentProfile.id,
        email: currentProfile.email,
        firstName: _nameController.text.trim(),
        lastName: '',
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _dobController.text.isEmpty ? null : _dobController.text,
        gender: _selectedGender,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        pinCode: _pinController.text.trim().isEmpty ? null : _pinController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim().isEmpty ? null : _emergencyNameController.text.trim(),
        emergencyContactNumber: _emergencyPhoneController.text.trim().isEmpty ? null : _emergencyPhoneController.text.trim(),
        profileImageUrl: currentProfile.profileImageUrl,
      );

      await ref.read(profileProvider.notifier).updateProfile(updated);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception:', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg.isNotEmpty ? errorMsg : 'Failed to update profile.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: profileState.when(
        data: (profile) {
          final host = AppConfig.baseUrl.replaceAll('/api/v1', '');
          final avatarUrl = profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
              ? '$host${profile.profileImageUrl}'
              : null;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF16A34A).withOpacity(0.1),
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, size: 50, color: Color(0xFF16A34A))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isSaving ? null : _showImagePickerOptions,
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFF16A34A),
                            radius: 18,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Full Name
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email (Read Only)
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Email Address (Registered)',
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Mobile Number
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mobile Number is required';
                    }
                    final phoneExp = RegExp(r'^\+?[0-9]{10,14}$');
                    if (!phoneExp.hasMatch(value.trim())) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date of Birth
                TextFormField(
                  controller: _dobController,
                  enabled: !_isSaving,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF16A34A)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Gender
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  onChanged: _isSaving ? null : (val) => setState(() => _selectedGender = val),
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Male', 'Female', 'Other', 'Prefer not to say']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  enabled: !_isSaving,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // City
                TextFormField(
                  controller: _cityController,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // State
                TextFormField(
                  controller: _stateController,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // PIN Code
                TextFormField(
                  controller: _pinController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'PIN Code',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final pinExp = RegExp(r'^[0-9]{6}$');
                      if (!pinExp.hasMatch(value.trim())) {
                        return 'PIN code must be exactly 6 digits';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Emergency Contact Name
                TextFormField(
                  controller: _emergencyNameController,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Contact Number
                TextFormField(
                  controller: _emergencyPhoneController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final phoneExp = RegExp(r'^\+?[0-9]{10,14}$');
                      if (!phoneExp.hasMatch(value.trim())) {
                        return 'Please enter a valid emergency phone number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      disabledBackgroundColor: const Color(0xFF16A34A).withOpacity(0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF16A34A)),
        ),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading profile: $err', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(profileProvider.notifier).fetchProfile(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
