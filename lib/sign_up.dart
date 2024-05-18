import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp/sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/user.dart';
import 'package:myapp/services/firebase_services.dart';

class SignUpPage extends StatelessWidget {
  final VoidCallback onSignIn;

  const SignUpPage({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create Account',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: RegistrationPage(onSignIn: onSignIn),
    );
  }
}


class RegistrationPage extends StatefulWidget {
  final VoidCallback onSignIn;

  const RegistrationPage({super.key, required this.onSignIn});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  File? _imageFile;
  FirebaseService firebaseService = FirebaseService();

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green,
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.file(
                            _imageFile!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Text(
                          'AS',
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Name', 'e.g. John Smith', _nameController),
              const SizedBox(height: 10),
              _buildTextField('Email', 'e.g. example@email.com', _emailController),
              const SizedBox(height: 10),
              _buildTextField('Password', 'Enter your password', _passwordController, obscureText: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  registerUser(context);
                },
                child: const Text('SIGN UP'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('Have an account? SIGN IN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  void registerUser(BuildContext context) async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty && _imageFile != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Registering user..."),
              ],
            ),
          );
        },
      );

      AUser? user = await firebaseService.registerWithEmail(name, email, password, _imageFile!);

      Navigator.of(context).pop();

      if (user != null) {
        print("User registered successfully");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignInPage(onSignIn: widget.onSignIn)),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Registration Failed'),
              content: const Text('An error occurred during registration. Please try again.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please fill all the fields and choose a profile picture.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
