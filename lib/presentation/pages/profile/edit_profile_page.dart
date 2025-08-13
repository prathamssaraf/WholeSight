import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_event.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';
import 'package:whole_sight/presentation/widgets/common/loading_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  final UserEntity user;

  const EditProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  String? _selectedPhotoUrl;
  bool _isLoading = false;
  // Local storage helper methods
  Future<String> _getLocalStoragePath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String profileImagesPath = '${appDocDir.path}/profile_images';
    
    // Create directory if it doesn't exist
    final Directory profileImagesDir = Directory(profileImagesPath);
    if (!await profileImagesDir.exists()) {
      await profileImagesDir.create(recursive: true);
    }
    
    return profileImagesPath;
  }

  Future<String> _saveImageLocally(File imageFile) async {
    try {
      final String localPath = await _getLocalStoragePath();
      final String fileName = 'profile_${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String fullPath = '$localPath/$fileName';
      
      // Copy the image to local storage
      final File localFile = await imageFile.copy(fullPath);
      
      print('✅ Profile image saved locally: ${localFile.path}');
      return localFile.path;
    } catch (e) {
      print('❌ Failed to save image locally: $e');
      throw Exception('Failed to save image locally: $e');
    }
  }

  Future<void> _deleteOldProfileImages() async {
    try {
      final String localPath = await _getLocalStoragePath();
      final Directory profileImagesDir = Directory(localPath);
      
      if (await profileImagesDir.exists()) {
        final List<FileSystemEntity> files = profileImagesDir.listSync();
        
        // Delete old profile images for this user
        for (final file in files) {
          if (file is File && file.path.contains('profile_${widget.user.id}_')) {
            await file.delete();
            print('🗑️ Deleted old profile image: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('⚠️ Could not clean up old profile images: $e');
      // Non-critical error, continue
    }
  }

  // Helper method to get the correct ImageProvider for CircleAvatar
  ImageProvider? _getImageProvider(String imagePath) {
    // Check if it's a local file path
    if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
      final File imageFile = File(imagePath);
      if (imageFile.existsSync()) {
        return FileImage(imageFile);
      }
      return null;
    } else {
      // Network URL
      return NetworkImage(imagePath);
    }
  }

  // Helper method to build image widget that handles both local and network images
  Widget _buildImageWidget(String? imagePath, {required double width, required double height, required double borderRadius}) {
    if (imagePath == null) {
      return Icon(
        Icons.person,
        size: width * 0.6,
        color: AppColors.primary,
      );
    }

    // Check if it's a local file path
    if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
      // Local file
      final File imageFile = File(imagePath);
      if (imageFile.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            imageFile,
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
        );
      } else {
        // File doesn't exist, show default icon
        return Icon(
          Icons.person,
          size: width * 0.6,
          color: AppColors.primary,
        );
      }
    } else {
      // Network URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imagePath,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: width * 0.6,
              color: AppColors.primary,
            );
          },
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _selectedPhotoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Using the existing UpdateProfileEvent
      context.read<AuthBloc>().add(
            UpdateProfileEvent(
              name: _nameController.text.trim(),
              photoUrl: _selectedPhotoUrl,
            ),
          );

      // No need to navigate back here - we'll do it in the BlocListener
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    // Let the user choose between taking a photo or selecting from gallery
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.face),
                title: const Text('Choose Avatar'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAvatarOptions();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add this method to handle image picking and upload directly with Firebase Storage
  Future<void> _getImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Save image locally instead of Firebase Storage
        final File imageFile = File(image.path);
        
        print('💾 Saving profile image locally...');
        
        // Delete old profile images to save space
        await _deleteOldProfileImages();
        
        // Save the new image locally
        final String localImagePath = await _saveImageLocally(imageFile);

        // Update the selected photo URL with local path
        setState(() {
          _selectedPhotoUrl = localImagePath;
          _isLoading = false;
        });
        
        print('✅ Profile image saved successfully: $localImagePath');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        print('Profile image save error: $e');
        
        String errorMessage;
        if (e.toString().contains('permission') || e.toString().contains('denied')) {
          errorMessage = 'Storage permission denied. Please check app permissions.';
        } else if (e.toString().contains('space') || e.toString().contains('storage')) {
          errorMessage = 'Not enough storage space. Please free up some space.';
        } else if (e.toString().contains('path') || e.toString().contains('directory')) {
          errorMessage = 'Could not access storage directory.';
        } else {
          errorMessage = 'Failed to save image: ${e.toString().length > 100 ? e.toString().substring(0, 100) + '...' : e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showAvatarOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Avatar'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            children: [
              _buildAvatarOption(null),
              _buildAvatarOption(
                  'https://ui-avatars.com/api/?name=${widget.user.name}&background=random'),
              _buildAvatarOption(
                  'https://ui-avatars.com/api/?name=${widget.user.name}&background=0D8ABC'),
              _buildAvatarOption(
                  'https://ui-avatars.com/api/?name=${widget.user.name}&background=FFC107'),
              _buildAvatarOption(
                  'https://ui-avatars.com/api/?name=${widget.user.name}&background=4CAF50'),
              _buildAvatarOption(
                  'https://ui-avatars.com/api/?name=${widget.user.name}&background=9C27B0'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarOption(String? url) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPhotoUrl = url;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPhotoUrl == url
                ? AppColors.primary
                : Colors.transparent,
            width: 2,
          ),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: url != null ? _getImageProvider(url) : null,
          child: url == null
              ? Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.headline4.copyWith(
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            // Profile updated successfully
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            Navigator.pop(context);
          } else if (state is AuthError) {
            // Error updating profile
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            setState(() {
              _isLoading = false;
            });
          }
        },
        child: _isLoading
            ? const Center(child: LoadingIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            backgroundImage: _selectedPhotoUrl != null ? _getImageProvider(_selectedPhotoUrl!) : null,
                            child: _selectedPhotoUrl == null
                                ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : 'U',
                                    style: AppTextStyles.headline1.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email field - readonly as typically email is used as identifier
                    TextFormField(
                      initialValue: widget.user.email,
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.email),
                        helperText: 'Email cannot be changed',
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
