import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  User? _user;
  bool _biometricEnabled = false;

  AuthProvider() {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
    _loadBiometricPreference();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get biometricEnabled => _biometricEnabled;

  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool('biometric_login') ?? false;
    notifyListeners();
  }

  Future<void> toggleBiometricLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_login', value);
    _biometricEnabled = value;
    if (!value) {
      await _storage.deleteAll();
    }
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (_biometricEnabled) {
        await _storage.write(key: 'email', value: email);
        await _storage.write(key: 'password', value: password);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> biometricLogin() async {
    try {
      final email = await _storage.read(key: 'email');
      final password = await _storage.read(key: 'password');

      if (email == null || password == null) {
        throw Exception(
          'Please log in manually first to securely save your credentials.',
        );
      }

      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        throw Exception(
          'Biometric authentication is not supported or not enrolled on this device.',
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        await login(email, password);
      } else {
        throw Exception('Authentication cancelled or failed.');
      }
    } catch (e) {
      debugPrint('Biometric login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
