import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/dio_client.dart';
import '../../../../core/services/secure_storage.dart';
import '../../../../core/contstans/api_constants.dart';


// Representasi kondisi autentikasi
enum AuthStatus {
  initial,          // Belum ada action
  loading,          // Proses berlangsung
  authenticated,    // Login berhasil + token backend ada
  unauthenticated,  // Belum login / logout
  emailNotVerified, // Login tapi email belum dikonfirmasi
  error,            // Ada error
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();


  // ─── State ───────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  User?     _firebaseUser;
  String?   _backendToken;   // Token dari backend (bukan Firebase token)
  String?   _errorMessage;

  String? _tempEmail;
   String? _tempPassword;


  // ─── Getters ─────────────────────────────────────────────
  AuthStatus get status       => _status;
  User?      get firebaseUser  => _firebaseUser;
  String?    get backendToken  => _backendToken;
  String?    get errorMessage  => _errorMessage;
  bool       get isLoading     => _status == AuthStatus.loading; 

// ─── Register dengan Email & Password ────────────────────
void _setLoading() {
  _status = AuthStatus.loading;
  notifyListeners();
}

Future<bool> register({
  required String name,
  required String email,
  required String password}) 
  async {
  _setLoading(); 
 
  
  final credential = await _auth.createUserWithEmailAndPassword(
    email: email, password: password,
  );
  _firebaseUser = credential.user;
 
  await _firebaseUser?.updateDisplayName(name); 
  await _firebaseUser?.sendEmailVerification();
   
  _tempEmail = email;
  _tempPassword = password;
 
  _status = AuthStatus.emailNotVerified;
  notifyListeners();
  return true;
}

Future<bool> loginAfterEmailVerification() async {
  _setLoading();
 
  await _firebaseUser?.reload();
  _firebaseUser = _auth.currentUser;
 
  if (!(_firebaseUser?.emailVerified ?? false)) {
    _status = AuthStatus.emailNotVerified;
    return false;
  }
 
 
  final credential = await _auth.signInWithEmailAndPassword(
    email: _tempEmail!,
    password: _tempPassword!,
  );
  _firebaseUser = credential.user;
  _tempEmail = null;  
  _tempPassword = null;
 
 
  return await _verifyTokenToBackend();
}

Future<bool> _verifyTokenToBackend() async {
  final firebaseToken = await _firebaseUser?.getIdToken();
 
  
  final response = await DioClient.instance.post(
    ApiConstants.verifyToken,
    data: {'firebase_token': firebaseToken},
  );
 
 
  final data = response.data['data'] as Map<String, dynamic>;
  final backendToken = data['access_token'] as String;
 
  
  await SecureStorageService.saveToken(backendToken);
 
  _status = AuthStatus.authenticated;
  notifyListeners();
  return true;
}

// ─── Login dengan Email & Password ───────────────────────

void _setError(String message) {
  _status = AuthStatus.error;
  _errorMessage = message;
  notifyListeners();
}

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _firebaseUser = credential.user;

      if (!(_firebaseUser?.emailVerified ?? false)) {
        _status = AuthStatus.emailNotVerified;
        notifyListeners();
        return false;
      }

      return await _verifyTokenToBackend();
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      return false;
    }

    
  }

  String _mapFirebaseError(String code) {
  switch (code) {
    case 'user-not-found':
      return 'User tidak ditemukan';
    case 'wrong-password':
      return 'Password salah';
    case 'invalid-email':
      return 'Email tidak valid';
    case 'email-already-in-use':
      return 'Email sudah digunakan';
    case 'weak-password':
      return 'Password terlalu lemah';
    default:
      return 'Terjadi kesalahan';
  }
}

// ─── Login dengan Google ──────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _setLoading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setError('Login Google dibatalkan');
        return false;
      }


      final googleAuth  = await googleUser.authentication;
      final credential  = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      _firebaseUser  = userCred.user;


     
      return await _verifyTokenToBackend();
    } catch (e) {
      _setError('Gagal login dengan Google: $e');
      return false;
    }
  }



}
