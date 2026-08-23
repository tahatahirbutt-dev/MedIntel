import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Web OAuth client ID from google-services.json (client_type 3) — Firebase's
  // GoogleAuthProvider needs the ID token audience to match this, and unlike
  // the old google_sign_in API, v7 no longer auto-derives it on Android.
  static const _googleServerClientId =
      '756161487540-9bhfpfu1vb8f8qr85qj63r1kbsug8rcs.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  User? get currentUser => _auth.currentUser;

  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e.code);
    }
  }

  Future<User?> register(String email, String password, String name) async {
    late UserCredential result;

    // Step 1: Create the account — critical step
    try {
      result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e.code);
    } catch (e) {
      throw 'Something went wrong. Please check your connection and try again.';
    }

    // Step 2: Update display name — non-critical, won't block login if it fails
    try {
      await result.user?.updateDisplayName(name.trim());
      await result.user?.reload();
    } catch (_) {
      // Silently ignore — display name can be updated later
    }

    return _auth.currentUser;
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (!_googleSignInInitialized) {
        await _googleSignIn.initialize(serverClientId: _googleServerClientId);
        _googleSignInInitialized = true;
      }

      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw 'Google sign-in failed. Please try again.';
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: code=${e.code} description=${e.description} details=${e.details}');
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw 'Google sign-in failed. Please try again.';
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during Google sign-in: code=${e.code} message=${e.message}');
      throw _mapFirebaseError(e.code);
    } catch (e, st) {
      debugPrint('Unexpected error during Google sign-in: $e\n$st');
      throw 'Google sign-in failed. Please try again.';
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      if (_googleSignInInitialized) _googleSignIn.signOut(),
    ]);
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}