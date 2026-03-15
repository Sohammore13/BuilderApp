import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Auth state stream
  // ---------------------------------------------------------------------------
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Current user
  // ---------------------------------------------------------------------------
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // Sign In
  // ---------------------------------------------------------------------------
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // ---------------------------------------------------------------------------
  // Register (site engineers + purchase team only)
  // ---------------------------------------------------------------------------
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    // Safety guard — owner cannot be registered via the app
    if (role == kRoleOwner) {
      throw FirebaseAuthException(
        code: 'invalid-role',
        message: 'Owner accounts cannot be created through the app.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Save user document to Firestore
    await _firestore
        .collection(kUsersCollection)
        .doc(credential.user!.uid)
        .set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
    });

    return credential;
  }

  // ---------------------------------------------------------------------------
  // Get role from Firestore
  // ---------------------------------------------------------------------------
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore
          .collection(kUsersCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Get full UserModel from Firestore
  // ---------------------------------------------------------------------------
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _firestore
          .collection(kUsersCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
