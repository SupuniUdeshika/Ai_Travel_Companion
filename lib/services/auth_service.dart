import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userEmail => _auth.currentUser?.email;
  String? get userName => _auth.currentUser?.displayName;
  String? get userId => _auth.currentUser?.uid;

  // Save user data to Firestore with better error handling
  Future<void> _saveUserToFirestore(
    User user, {
    String? name,
    String? provider = 'email',
  }) async {
    try {
      print('💾 Attempting to save user to Firestore: ${user.uid}');

      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': name ?? user.displayName ?? 'Travel Explorer',
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'provider': provider,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('📝 User data to save: $userData');

      // Use set with merge to update existing or create new
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      print('✅ User data successfully saved to Firestore: ${user.uid}');

      // Verify the data was saved
      final savedDoc = await _firestore.collection('users').doc(user.uid).get();
      if (savedDoc.exists) {
        print('✅ Firestore document verified: ${savedDoc.data()}');
      } else {
        print('❌ Firestore document not found after save');
      }
    } catch (error) {
      print('❌ Error saving user to Firestore: $error');
      print('📧 User email: ${user.email}');
      print('🆔 User UID: ${user.uid}');
      throw 'Failed to save user data: $error';
    }
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('🔐 Attempting email sign in: $email');

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ Email authentication successful: ${result.user!.uid}');

      // Update last login time
      await _saveUserToFirestore(result.user!, provider: 'email');

      notifyListeners();
      print('✅ Email sign in completed successfully');
      return result.user;
    } catch (error) {
      print('❌ Login Error: $error');
      throw _getAuthErrorMessage(error);
    }
  }

  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      print('👤 Starting email sign up process...');
      print('📧 Email: $email');
      print('👤 Name: $name');

      // Step 1: Create user in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ Firebase user created: ${result.user!.uid}');

      // Step 2: Update user profile with display name
      if (result.user != null) {
        print('🔄 Updating user profile with display name...');
        await result.user!.updateDisplayName(name);
        await result.user!.reload();
        print('✅ User profile updated');

        // Step 3: Save user data to Firestore
        print('💾 Saving user data to Firestore...');
        await _saveUserToFirestore(result.user!, name: name, provider: 'email');

        // Step 4: Get the updated user
        final updatedUser = _auth.currentUser;
        print('✅ User data saved successfully');

        notifyListeners();
        print('🎉 Sign up process completed successfully');
        return updatedUser;
      }

      return result.user;
    } catch (error) {
      print('❌ Signup Error: $error');
      print('🔍 Error type: ${error.runtimeType}');
      throw _getAuthErrorMessage(error);
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign In...');

      if (kIsWeb) {
        print('🌐 Web platform detected, using signInWithPopup');
        return await _signInWithGoogleWeb();
      } else {
        print('📱 Mobile platform detected, using Google Sign In');
        return await _signInWithGoogleMobile();
      }
    } catch (error) {
      print('❌ Google Sign In Error: $error');
      throw _getGoogleSignInErrorMessage(error);
    }
  }

  Future<User?> _signInWithGoogleMobile() async {
    try {
      print('📱 Starting mobile Google Sign In flow...');

      // Check if user is already signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        print('🔄 Signed out existing Google user');
      }

      // Start Google Sign In
      print('🔄 Triggering Google Sign In dialog...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('🚫 Google sign in cancelled by user');
        throw 'Sign in cancelled';
      }

      print('✅ Google user obtained: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw 'Google authentication failed - no tokens received';
      }

      print('✅ Google auth tokens obtained');

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        throw 'Firebase sign in failed - no user returned';
      }

      print('✅ Firebase sign in successful: ${userCredential.user!.uid}');

      // Save user data to Firestore
      await _saveUserToFirestore(userCredential.user!, provider: 'google');

      notifyListeners();
      return userCredential.user;
    } catch (error) {
      print('❌ Mobile Google Sign In Error: $error');
      rethrow;
    }
  }

  Future<User?> _signInWithGoogleWeb() async {
    try {
      print('🌐 Starting web Google Sign In flow...');

      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      final UserCredential userCredential = await _auth.signInWithPopup(
        googleProvider,
      );

      print('✅ Web Google sign in successful: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!, provider: 'google');
      }

      notifyListeners();
      return userCredential.user;
    } catch (error) {
      print('❌ Web Google Sign In Error: $error');
      rethrow;
    }
  }

  String _getGoogleSignInErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email. Please sign in using your email and password.';
        case 'invalid-credential':
          return 'The authentication credential is invalid or has expired.';
        case 'operation-not-allowed':
          return 'Google sign-in is not enabled. Please contact support.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found with these credentials.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'internal-error':
          return 'Internal error occurred. Please try again.';
        default:
          return error.message ?? 'Google Sign In failed. Please try again.';
      }
    }

    final errorString = error.toString();

    if (errorString.contains('cancelled') || errorString.contains('canceled')) {
      return 'Sign in was cancelled';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('SIGN_IN_FAILED') ||
        errorString.contains('sign_in_failed')) {
      return 'Google Sign In failed. Please ensure:\n\n• Google Play Services are installed and updated\n• You have an active internet connection\n• Try using a different Google account';
    }

    return 'Google Sign In failed. Please try again.';
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      notifyListeners();
      print('✅ Signed out successfully');
    } catch (error) {
      print('❌ Sign Out Error: $error');
      throw 'Sign out failed. Please try again.';
    }
  }

  // Additional helper methods
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (error) {
      throw _getAuthErrorMessage(error);
    }
  }

  Future<void> updateUserProfile({
    required String displayName,
    String? photoURL,
  }) async {
    try {
      if (_auth.currentUser != null) {
        if (displayName.isNotEmpty) {
          await _auth.currentUser!.updateDisplayName(displayName);
        }
        if (photoURL != null && photoURL.isNotEmpty) {
          await _auth.currentUser!.updatePhotoURL(photoURL);
        }

        // Update Firestore
        await _saveUserToFirestore(_auth.currentUser!);

        await _auth.currentUser!.reload();
        notifyListeners();
      }
    } catch (error) {
      throw _getAuthErrorMessage(error);
    }
  }

  // Helper method to get user-friendly error messages
  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many unsuccessful attempts. Please try again later.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'The password is too weak. Please choose a stronger password.';
        case 'operation-not-allowed':
          return 'This operation is not allowed. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in method.';
        case 'invalid-credential':
          return 'The credential is malformed or has expired.';
        default:
          return error.message ??
              'An unexpected error occurred. Please try again.';
      }
    }
    return error.toString();
  }

  // Stream for real-time auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (error) {
      throw _getAuthErrorMessage(error);
    }
  }

  // Reload user data
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      notifyListeners();
    } catch (error) {
      throw _getAuthErrorMessage(error);
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (error) {
      print('Error getting user data: $error');
      return null;
    }
  }

  // Check if user exists in Firestore
  Future<bool> userExistsInFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (error) {
      print('Error checking user existence: $error');
      return false;
    }
  }
}
