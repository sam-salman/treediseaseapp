import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/forgotpassword.dart';
import 'package:myapp/models/user.dart';
import 'package:myapp/sign_up.dart';
import 'package:myapp/services/firebase_services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import FirebaseService class

class SignInPage extends StatefulWidget {
  final VoidCallback onSignIn;
  const SignInPage({super.key, required this.onSignIn});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  late BuildContext _currentContext;

  @override
  Widget build(BuildContext context) {
    _currentContext = context;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green,
                        child: Text(
                          'AS',
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('Email', 'example@email.com', _emailController),
                      const SizedBox(height: 10),
                      _buildTextField('Password', 'Enter your password', _passwordController, obscureText: true),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: signIn,
                        child: const Text('SIGN IN'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                          );
                        },
                        child: const Text('Forgot Password?'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegistrationPage(onSignIn: widget.onSignIn),
                            ),
                          );
                        },
                        child: const Text("Don't have an account? SIGN UP"),
                      ),

                    ],
                  ),
                ),
              ),
            );
          },
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

  void signIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isNotEmpty && password.isNotEmpty) {
      showDialog(
        context: _currentContext,
        barrierDismissible: false,
        builder: (context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Signing in..."),
              ],
            ),
          );
        },
      );

      User? user = await _firebaseService.signInWithEmail(email, password);

      Navigator.of(_currentContext).pop();

      if (user != null) {
        AUser? auser = await _firebaseService.getUser(user.email);
        if (auser != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool('loggedin', true);
          prefs.setString('email', auser.email);
          prefs.setString('name', auser.name);
          prefs.setString('profileImageUrl', auser.profileImageUrl);

          widget.onSignIn(); // Update the state in MainPage
        } else {
          print("User not found");
        }
      } else {
        _showErrorDialog("Sign In Failed", "Invalid email or password. Please try again.");
      }
    } else {
      _showErrorDialog("Error", "Please enter email and password.");
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: _currentContext,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
