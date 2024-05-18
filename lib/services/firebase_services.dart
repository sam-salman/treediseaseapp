import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:myapp/models/disease.dart';
import 'package:myapp/models/user.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  FirebaseService() {
    initializeFirebase();
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Register with email and password
  Future<AUser?> registerWithEmail(
      String name, String email, String password, File? profileImage) async {
    try {
      // Create user with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the newly created user
      User? firebaseUser = userCredential.user;

      // Check if user is not null and profile image is selected
      if (firebaseUser != null && profileImage != null) {
        // Upload profile image to Firebase Storage
        String imageUrl = await uploadProfileImage(profileImage);

        // Create User object with profile image URL
        AUser user = AUser(
          name: name,
          email: email,
          password: password,
          profileImageUrl: imageUrl,
        );

        // Store user details in Firebase Realtime Database
        await storeUserData(user);

        await updateProfile(email, imageUrl);

        return user;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e);
    }
  }

  // Send OTP Verification to email
  Future<void> sendOTPVerification(String email) async {
    try {
      int otp = _generateOTP();
      await _database.ref('otps').child(email.replaceAll('.', '_')).set({
        'otp': otp,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Send the OTP to the user's email using Firebase's sendPasswordResetEmail or a custom email service
      await _auth.sendPasswordResetEmail(email: email);
      print("OTP sent to $email: $otp"); // This is for testing purposes only
    } catch (e) {
      print(e);
    }
  }

  // Verify OTP
// Verify OTP
Future<bool> verifyOTP(String email, String otp) async {
  try {
    DatabaseReference otpRef = _database.ref('otps').child(email.replaceAll('.', '_'));
    DataSnapshot snapshot = await otpRef.get();

    if (snapshot.exists) {
      int storedOTP = snapshot.child('otp').value as int;
      String createdAt = snapshot.child('createdAt').value as String;
      DateTime otpCreationTime = DateTime.parse(createdAt);

      if (storedOTP == int.parse(otp) && DateTime.now().difference(otpCreationTime).inMinutes <= 10) {
        await otpRef.remove();
        return true;
      } else {
        throw Exception('Invalid or expired OTP');
      }
    } else {
      throw Exception('OTP not found');
    }
  } catch (e) {
    print(e);
    throw e;
  }
}


  // Reset Password
  Future<void> resetPasswordWithOTP(String email, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('No user is signed in');
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }

  int _generateOTP() {
    Random random = Random();
    int otp = random.nextInt(900000) + 100000; // Generates a 6-digit OTP
    return otp;
  }

  Future<String?> uploadDiseasePicture(File diseaseImage) async {
    try {
      // Upload image to Firebase Storage
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('disease_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final UploadTask uploadTask = storageRef.putFile(diseaseImage);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      // Get image download URL
      final String imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }


  Future<void> addDisease(Disease disease) async {
    try {
      DatabaseReference diseaseRef = _database.ref().child('diseases').push();
      await diseaseRef.set({
        'name': disease.name,
        'description': disease.description,
        'imageUrl': disease.imageUrl,
      });
    } catch (e) {
      print(e);
    }
  }

Future<List<Disease>> getDiseases() async {
  try {
    DatabaseReference diseasesRef = _database.ref().child('diseases');
    DataSnapshot snapshot = await diseasesRef.get();
    if (snapshot.exists) {
      print(snapshot.value);
      Map<dynamic, dynamic>? diseasesData = snapshot.value as Map<dynamic, dynamic>?;

      if (diseasesData != null) {
        print("diseases not null");
        List<Disease> diseases = [];
        diseasesData.forEach((key, value) {
          if (value is Map) {
            print("value is map");
            diseases.add(Disease.fromMap(Map<String, dynamic>.from(value)));
          } else {
            print("value is not map");
          }
        });
        print("disease in firebase service");
        print(diseases);

        return diseases;
      } else {
        return [];
      }
    } else {
      return [];
    }
  } catch (e) {
    print(e);
    return [];
  }
}


  Future<String> uploadProfileImage(File profileImage) async {
    try {
      // Create a reference to the Firebase Storage location
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${DateTime.now().millisecondsSinceEpoch}');

      // Upload the file to Firebase Storage
      UploadTask uploadTask = storageRef.putFile(profileImage);

      // Get the download URL of the uploaded file
      String imageUrl = await (await uploadTask).ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      print("Error uploading profile image: $e");
      return '';
    }
  }

  Future<void> updateProfile(String email, String photoURL) async {
    try {
      //change the profile imageurl in realtime database
      await _database
          .ref()
          .child('users')
          .child(email.replaceAll('.', '_'))
          .update({
        'profileImageUrl': photoURL,
      });
    } catch (e) {
      print("Error updating user profile: $e");
    }
  }

  Future<void> storeUserData(AUser user) async {
    try {
      DatabaseReference userRef =
          _database.ref().child('users').child(user.email.replaceAll('.', '_'));

      // Store the user data in Firebase Realtime Database
      await userRef.set({
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'profileImageUrl': user.profileImageUrl,
      });
    } catch (e) {
      print("Error storing user data: $e");
    }
  }

  Future<AUser?> getUser(String? email) async {
    //check if email is null
    if (email == null) {
      return null;
    }

    try {
      DatabaseReference userRef =
          _database.ref().child('users').child(email.replaceAll('.', '_'));
      DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> userData =
            snapshot.value as Map<dynamic, dynamic>;
        return AUser.fromMap(userData);
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _database.goOffline();
  }

   Future<bool> saveProfileDetails(String name,String email,String profileImageUrl) async {
    try {
      DatabaseReference userRef = _database.ref().child('users').child(email.replaceAll('.', '_'));
      await userRef.update({
        'name': name,
        'profileImageUrl': profileImageUrl,
      });
      return true;
    } catch (e) {
      print("Error saving profile details: $e");
      return false;
    }

  }
  
    
}
