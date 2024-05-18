
class AUser {
  final String name;
  final String email;
  final String password;
  final String profileImageUrl;

  AUser({
    required this.name,
    required this.email,
    required this.password,
    required this.profileImageUrl,
  });

  static Future<AUser?> fromMap(Map userData) async {
    // Extract the user data from the map
    String name = userData['name'];
    String email = userData['email'];
    String password = userData['password'];
    String profileImageUrl = userData['profileImageUrl'];

    // Create and return an AUser object
    return AUser(
      name: name,
      email: email,
      password: password,
      profileImageUrl: profileImageUrl,
    );
  }
}
