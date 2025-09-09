import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitspot/firestore/auth_service.dart';
import 'package:fitspot/firestore/firestore_service.dart';
import 'package:fitspot/firestore/firestore_data_schema.dart';

class FirebaseProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  UserDocument? _userDocument;
  bool _isLoading = true;
  String _error = '';

  User? get user => _user;
  UserDocument? get userDocument => _userDocument;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _userDocument?.isAdmin ?? false;

  AuthService get authService => _authService;
  FirestoreService get firestoreService => _firestoreService;

  FirebaseProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      _userDocument = null;
      _error = '';
      
      if (user != null) {
        try {
          _userDocument = await _authService.getUserDocument(user.uid);
        } catch (e) {
          _error = 'Failed to load user data: $e';
        }
      }
      
      _isLoading = false;
      notifyListeners();
    });
  }

  // Authentication methods
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      // Check if this is the admin trying to login and doesn't exist yet
      if (email.toLowerCase() == 'admin@fitspot.com' && password == 'fitspot') {
        try {
          await _authService.signInWithEmailAndPassword(email, password);
        } catch (authError) {
          print('Admin sign in failed: $authError');
          // If admin doesn't exist, create it
          if (authError.toString().contains('user-not-found') || 
              authError.toString().contains('invalid-credential') ||
              authError.toString().contains('wrong-password')) {
            try {
              print('Creating admin account...');
              await _authService.registerWithEmailAndPassword(
                'admin@fitspot.com', 
                'fitspot', 
                'Amministratore'
              );
              print('Admin account created successfully');
              return true;
            } catch (registerError) {
              print('Failed to create admin: $registerError');
              // If already exists, try to sign in again
              if (registerError.toString().contains('email-already-in-use')) {
                print('Admin already exists, trying sign in again...');
                await _authService.signInWithEmailAndPassword(email, password);
                return true;
              }
              throw registerError;
            }
          } else {
            throw authError;
          }
        }
      } else {
        await _authService.signInWithEmailAndPassword(email, password);
      }
      return true;
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      await _authService.registerWithEmailAndPassword(email, password, displayName);
      return true;
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      final result = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return result != null;
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();
      
      final result = await _authService.signInAnonymously();
      return result != null;
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      if (_user == null) return;
      
      await _authService.updateUserDocument(_user!.uid, data);
      
      // Refresh user document
      _userDocument = await _authService.getUserDocument(_user!.uid);
      notifyListeners();
    } catch (e) {
      _error = _getErrorMessage(e.toString());
      notifyListeners();
    }
  }

  // Alias for backward compatibility
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await updateUserProfile(data);
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'Utente non trovato';
    } else if (error.contains('wrong-password')) {
      return 'Password non corretta';
    } else if (error.contains('invalid-credential')) {
      return 'Credenziali non valide. Verifica email e password.';
    } else if (error.contains('email-already-in-use')) {
      return 'Email già in uso';
    } else if (error.contains('weak-password')) {
      return 'Password troppo debole';
    } else if (error.contains('invalid-email')) {
      return 'Email non valida';
    } else if (error.contains('user-disabled')) {
      return 'Account disabilitato';
    } else if (error.contains('network-request-failed')) {
      return 'Errore di connessione. Verifica la tua connessione internet.';
    } else if (error.contains('too-many-requests')) {
      return 'Troppi tentativi. Riprova tra qualche minuto.';
    } else if (error.contains('operation-not-allowed')) {
      return 'Operazione non consentita. Contatta l\'amministratore.';
    } else if (error.contains('Google')) {
      return 'Errore durante l\'accesso con Google. Riprova.';
    } else {
      // Clean up the error message
      String cleanError = error.replaceAll('Exception: ', '').replaceAll('firebase_auth/', '');
      return cleanError.length > 100 ? 'Si è verificato un errore. Riprova.' : cleanError;
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}