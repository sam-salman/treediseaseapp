import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/edit_profile.dart';
import 'package:myapp/forgotpassword.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  String _profileImageUrl = '';
  final String _defaultImage = 'assets/images/default_profile.png';

  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? 'Unknown User';
      _email = prefs.getString('email') ?? 'example@example.com';
      _profileImageUrl = prefs.getString('profileImageUrl') ?? '';
    });
  }

  Future<void> _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await FirebaseAuth.instance.signOut();
    await prefs.clear();
    // replace page with sign in
    Navigator.pushReplacementNamed(context, '/');

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.person),
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfileImage(),
                const SizedBox(height: 16.0),
                Text(
                  _name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  _email,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPassword()),
                    );
                  },
                  child: const Text('Forgot Password'),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _signOut,
                  child: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return ClipOval(
      child: _profileImageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: _profileImageUrl,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => Image.asset(_defaultImage),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            )
          : Image.asset(
              _defaultImage,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
    );
  }
}
