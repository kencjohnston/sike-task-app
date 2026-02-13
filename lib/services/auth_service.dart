import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      AppLogger.info('Signed in anonymously: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      AppLogger.error('Failed to sign in anonymously', e);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.info('Signed out');
    } catch (e) {
      AppLogger.error('Failed to sign out', e);
      rethrow;
    }
  }
}
