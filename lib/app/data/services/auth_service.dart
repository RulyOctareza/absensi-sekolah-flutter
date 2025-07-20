import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan stream status login user
  Stream<User?> get user => _auth.authStateChanges();

  // Fungsi untuk Sign In
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Mengembalikan null jika ada error
      print('Firebase Auth Error: ${e.message}');
      return null;
    }
  }

  // Fungsi untuk Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
