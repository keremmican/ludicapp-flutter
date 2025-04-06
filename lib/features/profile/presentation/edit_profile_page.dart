import 'package:flutter/material.dart';
import 'package:ludicapp/core/enums/profile_photo_type.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ludicapp/services/repository/user_repository.dart';
import 'package:ludicapp/features/splash/presentation/splash_screen.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = false;

  // Placeholder data - replace with actual user data from provider/state
  String _currentUsername = "CurrentUsername"; 
  ProfilePhotoType _currentProfilePhotoType = ProfilePhotoType.DEFAULT_1;
  String? _currentProfilePhotoUrl = null;
  // Placeholder for background
  String? _currentBackgroundUrl = null; 

  // State for selected photos
  ProfilePhotoType? _selectedProfilePhotoType;
  String? _selectedProfilePhotoUrl; // For custom upload preview
  // TODO: State for selected background


  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: _currentUsername);
    _loadCurrentUserData();
    // Initialize selection state with current values
    _selectedProfilePhotoType = _currentProfilePhotoType;
    _selectedProfilePhotoUrl = _currentProfilePhotoUrl;
  }

  void _loadCurrentUserData() {
    // Load data from cache if available
    if (SplashScreen.profileData != null) {
      setState(() {
        _currentUsername = SplashScreen.profileData!.username;
        _currentProfilePhotoType = SplashScreen.profileData!.profilePhotoType;
        _currentProfilePhotoUrl = SplashScreen.profileData!.profilePhotoUrl;
        
        // Update controller with username
        _usernameController.text = _currentUsername;
        
        _selectedProfilePhotoType = _currentProfilePhotoType;
        _selectedProfilePhotoUrl = _currentProfilePhotoUrl;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Get the updated values
        final String newUsername = _usernameController.text;
        final ProfilePhotoType newPhotoType = _selectedProfilePhotoType ?? ProfilePhotoType.DEFAULT_1;
        final String? newPhotoUrl = _selectedProfilePhotoUrl;
        
        // Call the repository method
        await _userRepository.updateUserProfile(
          username: newUsername,
          profilePhotoType: newPhotoType,
          profilePhotoUrl: newPhotoUrl,
        );
        
        // Success! Navigate back with update signal
        if (mounted) {
          Navigator.pop(context, 'updated');
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showProfilePhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library), 
                title: const Text('Choose Default'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _showDefaultPhotoSelection();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload), 
                title: const Text('Upload Photo'),
                onTap: () {
                  // TODO: Implement photo upload functionality
                  print("Upload Photo tapped - To be implemented");
                  setState(() {
                     // Simulate selecting an uploaded file (placeholder)
                     _selectedProfilePhotoType = ProfilePhotoType.CUSTOM;
                     _selectedProfilePhotoUrl = "https://via.placeholder.com/150/FF0000/FFFFFF?Text=Uploaded"; // Placeholder URL
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDefaultPhotoSelection() {
      showDialog(
          context: context,
          builder: (context) {
              return AlertDialog(
                  title: const Text("Select Default Photo"),
                  content: SizedBox(
                      width: double.maxFinite,
                      child: GridView.builder(
                          shrinkWrap: true,
                          itemCount: ProfilePhotoType.values.length - 1, // Exclude CUSTOM
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                              final type = ProfilePhotoType.values[index];
                              final assetPath = type.assetPath;
                              final bool isSelected = _selectedProfilePhotoType == type;

                              return GestureDetector(
                                  onTap: () {
                                      setState(() {
                                          _selectedProfilePhotoType = type;
                                          _selectedProfilePhotoUrl = null; // Clear custom URL if default is chosen
                                      });
                                      Navigator.of(context).pop(); // Close dialog
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                            width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6), // Slightly smaller radius for clipping
                                      child: assetPath != null
                                          ? Image.asset(
                                              assetPath, 
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                print('Error loading profile grid image: $error');
                                                return Container(color: Colors.grey);
                                              },
                                            )
                                          : Container(color: Colors.grey), // Fallback
                                    )
                                  ),
                              );
                          },
                      ),
                  ),
                  actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                      ),
                  ],
              );
          },
      );
  }

  void _showBackgroundPhotoOptions() {
    // TODO: Implement similar options for background photo
    print("Change Background Photo tapped - To be implemented");
     showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library), 
                title: const Text('Choose Default Background'), // Or gradients?
                onTap: () {
                  // TODO: Implement default background selection
                  print("Choose Default Background tapped - To be implemented");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload), 
                title: const Text('Upload Background'),
                onTap: () {
                  // TODO: Implement background upload functionality
                  print("Upload Background tapped - To be implemented");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          _isLoading 
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Profile Photo Section ---
              Center(
                child: Column(
                  children: [
                    _buildEditableProfilePhoto(),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _showProfilePhotoOptions,
                      child: const Text('Change Profile Photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Username Section ---
              Text('Username', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  // TODO: Add more specific username validation if needed
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Background Photo Section ---
              Text('Background Photo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildEditableBackgroundPhoto(),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _showBackgroundPhotoOptions,
                  child: const Text('Change Background Photo'),
                ),
              ),
              
              // Optional: Add Divider
              // const Divider(height: 40),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableProfilePhoto() {
    Widget imageWidget;
    final String? displayUrl = _selectedProfilePhotoUrl; // Use selection state
    final ProfilePhotoType displayType = _selectedProfilePhotoType ?? ProfilePhotoType.DEFAULT_1;

    if (displayType == ProfilePhotoType.CUSTOM && displayUrl != null && displayUrl.isNotEmpty) {
      // Custom URL (either existing or placeholder for upload)
      imageWidget = CachedNetworkImage(
        imageUrl: displayUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey.shade800), 
        errorWidget: (context, url, error) => _buildDefaultPhotoPlaceholder(context), 
      );
    } else {
      // Default asset - use exact same code as in ProfileHeader for consistency
      final String? assetPath = displayType.assetPath;
      if (assetPath != null) {
        imageWidget = Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading profile image: $error');
            return _buildDefaultPhotoPlaceholder(context);
          },
        );
      } else {
        imageWidget = _buildDefaultPhotoPlaceholder(context);
      }
    }

    return Container(
      width: 120, // Larger size for editing preview
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade800, 
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageWidget,
    );
  }

  Widget _buildDefaultPhotoPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade700,
      child: Icon(
        Icons.person, 
        color: Colors.white.withOpacity(0.5), 
        size: 60,
      ),
    );
  }

  Widget _buildEditableBackgroundPhoto() {
    // Placeholder for background display
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade500)
        ),
        child: Center(
          child: Icon(
            Icons.image, 
            color: Colors.white.withOpacity(0.5), 
            size: 50,
          )
        ),
      ),
    );
    // TODO: Replace with actual image display logic (CachedNetworkImage or Asset)
  }

} 