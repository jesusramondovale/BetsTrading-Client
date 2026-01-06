import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  String? _firebaseToken;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  Future<void> initFirebase() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? userId;

    try {
      userId = await _storage.read(key: 'sessionToken');
    } catch (e) {
      // Prevent decrypt failures on version changes
      await _storage.deleteAll();
      userId = null;
    }

    _firebaseToken = await messaging.getToken();
    if (kDebugMode) {
      print("Firebase Instance ID (Token): $_firebaseToken");
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _firebaseToken = newToken;
      if (kDebugMode) {
        print("New FCM Token: $newToken");
      }
      AuthService().refreshFCM(userId!, _firebaseToken!);
    });
  }

  String? get firebaseToken => _firebaseToken;
}
