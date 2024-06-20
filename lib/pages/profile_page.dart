import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:abadinursery/models/user_model.dart';
import 'package:abadinursery/services/api_service.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:abadinursery/widgets/ios_styled_notification.dart';
import 'package:abadinursery/widgets/customrefresh.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  final Function(User) onUserUpdated;

  const ProfilePage({super.key, required this.user, required this.onUserUpdated});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  late User _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _nameController = TextEditingController(text: _user.namaLengkap);
    _addressController = TextEditingController(text: _user.address);
    _isLoading = false;
    print('Profile Picture URL: ${_user.profilePicture}');
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
      }
    });
  }

  Future<void> _updateProfile() async {
    try {
      print('Updating profile...');
      User updatedUser = await ApiService.updateUserProfile(
        _nameController.text,
        _addressController.text,
        _profileImage,
      );
      print('Profile updated: ${updatedUser.toJson()}');
      widget.onUserUpdated(updatedUser);
      setState(() {
        _user = updatedUser;
        _profileImage = null;
      });
      showOverlayNotification(
        (context) {
          return const IOSStyledNotification(
            message: 'Profil berhasil diperbarui',
            icon: Icons.check_circle,
            backgroundColor: Colors.green,
          );
        },
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Error during profile update: $e');
      showOverlayNotification(
        (context) {
          return IOSStyledNotification(
            message: 'Gagal memperbarui profil: $e',
            icon: Icons.error,
            backgroundColor: Colors.grey,
          );
        },
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = await ApiService.getUserDataById(_user.id);
      print('User data after refresh: ${updatedUser.toJson()}');
      setState(() {
        _user = updatedUser;
        _nameController.text = _user.namaLengkap;
        _addressController.text = _user.address;
        _isLoading = false;
      });
      widget.onUserUpdated(updatedUser);
    } catch (e) {
      print('Error during profile refresh: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  ImageProvider<Object> _getImageProvider() {
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_user.profilePicture.isNotEmpty) {
      return NetworkImage(_user.profilePicture);
    } else {
      return const AssetImage('assets/images/default_avatar.jpg');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        title: const Text('Ubah Profil Kamu',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 19, color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : CustomRefreshIndicator(
              onRefresh: _refreshProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Add this line
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade700, Colors.green.shade300],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30)),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickProfileImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _getImageProvider(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _user.namaLengkap,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _user.role,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nama Lengkap',
                            style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Alamat',
                            style:
                                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Perbarui Profil'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}