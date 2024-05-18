import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/services/firebase_services.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _email = '';
  String _profileImageUrl = '';
  final String _defaultImage = 'assets/images/default_profile.png';
  File? _newProfileImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // If not logged in, redirect to login page
    if (prefs.getBool('loggedin') != true) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _nameController.text = prefs.getString('name') ?? 'Unknown User';
      _email = prefs.getString('email') ?? 'example@example.com';
      _profileImageUrl = prefs.getString('profileImageUrl') ?? _defaultImage;
      _isLoading = false;
    });
  }

  Future<void> _saveProfileDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        FirebaseService firebaseService = FirebaseService();
        if (_newProfileImage != null) {
          String imageUrl = await firebaseService.uploadProfileImage(_newProfileImage!);
          _profileImageUrl = imageUrl;
        }

        bool success = await firebaseService.saveProfileDetails(_nameController.text, _email, _profileImageUrl);

        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save profile details. Please try again later.')),
          );
          return;
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', _nameController.text);
        await prefs.setString('profileImageUrl', _profileImageUrl);

        Navigator.pop(context, true); // Return to the previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile details: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
        _profileImageUrl = pickedFile.path; // Update the UI immediately
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheet(
        onClosing: () {},
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _profileImageUrl.startsWith('assets')
                                ? AssetImage(_profileImageUrl) as ImageProvider
                                : FileImage(File(_profileImageUrl)),
                          ),
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can change the image by clicking on it.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _email,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveProfileDetails,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
