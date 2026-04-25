import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _auth.currentUser;

  Future<User?> signUpWithEmailPassword(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(name);
        await _createUserDocument(user, name);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<User?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        try {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (!userDoc.exists) {
            await _createUserDocument(user, user.displayName ?? 'New User');
          }
        } catch (firestoreError) {
          print("FIRESTORE ERROR: $firestoreError");
          throw 'Sign-in successful, but failed to create user profile. Please check if Firestore is enabled in Firebase Console.';
        }
      }

      return user;
    } catch (e) {
      print("DETAILED GOOGLE ERROR: $e");
      
      if (e is String) throw e;

      String message = 'Google Sign-In failed. Check your SHA-1 fingerprint.';
      if (e.toString().contains('12500')) {
        message = 'Error 12500: Please set a "Support Email" in your Firebase Project Settings.';
      } else if (e.toString().contains('10')) {
        message = 'Error 10: SHA-1 fingerprint mismatch or package name mismatch.';
      } else if (e.toString().contains('permission-denied')) {
        message = 'Firestore permission denied. Check your Firestore Rules.';
      }
      
      throw message;
    }
  }

  Future<void> _createUserDocument(User user, String name) async {
    await _firestore.collection('users').doc(user.uid).set({
      'user_id': user.uid,
      'name': name,
      'email': user.email,
      'photo_url': user.photoURL ?? '',
      'resume_url': '',
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> updateProfilePhoto(File imageFile) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'User not logged in';

      final String fileName = '${user.uid}.jpg';

      await _supabase.storage.from('profile-photos').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      final String downloadUrl = _supabase.storage.from('profile-photos').getPublicUrl(fileName);

      await user.updatePhotoURL(downloadUrl);
      await _firestore.collection('users').doc(user.uid).update({
        'photo_url': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw 'Failed to update profile photo: $e';
    }
  }

  Future<String> uploadResume(File file) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'User not logged in';

      final String extension = file.path.split('.').last;
      final String fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _supabase.storage.from('resumes').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final String downloadUrl = _supabase.storage.from('resumes').getPublicUrl(fileName);

      await _firestore.collection('users').doc(user.uid).update({
        'resume_url': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload resume: $e';
    }
  }

  // Get User Stream
  Stream<DocumentSnapshot> getUserStream() {
    User? user = _auth.currentUser;
    if (user == null) throw 'User not logged in';
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  // NEW: Fetch latest analysis results from Supabase
  Future<Map<String, dynamic>?> getLatestAnalysis() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('resume_results')
          .select()
          .eq('user_id', user.uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      print("Error fetching analysis: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email': return 'The email address is badly formatted.';
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Wrong password provided.';
      case 'email-already-in-use': return 'An account already exists for this email.';
      case 'weak-password': return 'The password provided is too weak.';
      case 'user-disabled': return 'This user has been disabled.';
      case 'operation-not-allowed': return 'Too many requests. Try again later.';
      default: return e.message ?? 'Authentication failed.';
    }
  }
}
