import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitspot/firestore/firestore_data_schema.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Sign in error: $e');
      throw e;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(displayName);
        
        // Create user document in Firestore
        await createUserDocument(result.user!, displayName);
      }
      
      return result;
    } catch (e) {
      print('Registration error: $e');
      throw e;
    }
  }

  // Create user document in Firestore
  Future<void> createUserDocument(User user, String displayName) async {
    try {
      // Check if this is the admin user
      final bool isAdmin = (user.email == 'admin@fitspot.com');
      
      final userDoc = UserDocument(
        id: user.uid,
        email: user.email ?? '',
        displayName: displayName,
        photoUrl: user.photoURL,
        isAdmin: isAdmin,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(FirestoreSchema.usersCollection)
          .doc(user.uid)
          .set(userDoc.toFirestore());
    } catch (e) {
      print('Create user document error: $e');
      throw e;
    }
  }

  // Get user document
  Future<UserDocument?> getUserDocument(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(FirestoreSchema.usersCollection)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserDocument.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Get user document error: $e');
      return null;
    }
  }

  // Update user document
  Future<void> updateUserDocument(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(FirestoreSchema.usersCollection)
          .doc(userId)
          .update(data);
    } catch (e) {
      print('Update user document error: $e');
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw e;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    // For now, throw an exception since Google Sign In requires additional setup
    throw Exception('Accesso Google non ancora configurato. Per ora utilizza email e password o "Esplora senza registrarti".');
  }

  // Sign in anonymously (skip authentication)
  Future<UserCredential?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      
      // Try to create anonymous user document, but don't fail if Firebase is not configured
      if (userCredential.user != null) {
        try {
          await createUserDocument(userCredential.user!, 'Ospite');
        } catch (e) {
          print('Warning: Could not create user document for anonymous user: $e');
          // Continue anyway - the user can still use the app
        }
      }
      
      return userCredential;
    } catch (e) {
      print('Anonymous sign in error: $e');
      throw e;
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final userDoc = await getUserDocument(userId);
      
      // Check if this is the specific admin user
      if (userDoc?.email == 'admin@fitspot.com') {
        return true;
      }
      
      return userDoc?.isAdmin ?? false;
    } catch (e) {
      print('Check admin error: $e');
      return false;
    }
  }
}