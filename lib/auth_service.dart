import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Registration failed";
    }
  }

  Future<void> saveUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    String? referral,
  }) async {
    await _firestore.collection("users").doc(uid).set({
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "address": address,
      "referral": referral,
      "createdAt": DateTime.now(),
    });
  }
}
