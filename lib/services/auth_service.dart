// ignore_for_file: constant_identifier_names, file_names
import 'package:betrader/services/firebase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/config.dart';
import '../helpers/common.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Future<Map<String, dynamic>> logIn(String username, String password) async {
    final response = await Common().postRequestWrapper('Auth', 'LogIn', {'username': username, 'password': password});

    if (response['statusCode'] == 200) {
      final String token = response['body']['userId'];
      final String jwtToken = response['body']['jwtToken'];
      await _storage.write(key: 'sessionToken', value: token);
      await _storage.write(key: 'jwtToken', value: jwtToken);
      final fcm = FirebaseService().firebaseToken;
      if (fcm != null && fcm.isNotEmpty) {
        AuthService().refreshFCM(token, fcm);
      }
      return {'success': true, 'message': _readMessage(response)};
    } else {
      return {'success': false, 'message': _readMessage(response)};
    }
  }

  Future<Map<String, dynamic>> googleLogIn(String googleUserId, {String? idToken}) async {
    final response = await Common().postRequestWrapper('Auth','GoogleLogIn', {
      'userId': googleUserId,
      if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
    });

    if (response['statusCode'] == 200) {
      final body = response['body'] as Map<String, dynamic>? ?? {};
      final String token = body['userId']?.toString() ?? '';
      final String? jwtToken = body['jwtToken']?.toString();
      await _storage.write(key: 'sessionToken', value: token);
      if (jwtToken != null && jwtToken.isNotEmpty) {
        await _storage.write(key: 'jwtToken', value: jwtToken);
      }
      final fcm = FirebaseService().firebaseToken;
      if (fcm != null && fcm.isNotEmpty) {
        AuthService().refreshFCM(token, fcm);
      }
      return {'success': true, 'message': body['message']};
    } else {
      return {'success': false, 'message': _readMessage(response)};
    }
  }

  Future<Map<String, dynamic>> logOut() async {
    final response = await Common().postRequestWrapper('Auth', 'LogOut', {});

    if (response['statusCode'] == 200) {
      await _storage.deleteAll();
      return {'success': true, 'message': _readMessage(response)};
    } else {
      return {'success': false, 'message': _readMessage(response)};
    }
  }

  Future<Map<String, dynamic>> register(
      String fcm,
      String fullName,
      String password,
      String address,
      String country,
      String gender,
      String email,
      String emailCode,
      DateTime birthday,
      String creditCard,
      String username,
      String? profilePic) async {
    final Map<String, dynamic> data = {
      'fcm': fcm,
      'fullName': fullName,
      'password': password,
      'address': address,
      'country': country,
      'gender': gender,
      'email': email,
      'emailCode': emailCode,
      'birthday': birthday.toIso8601String(),
      'creditCard': creditCard,
      'username': username,
      'profilePic': profilePic
    };

    final response = await Common().postRequestWrapper('Auth','SignIn', data);

    if (response['statusCode'] == 200) {
      final String token = response['body']['userId'];
      final String jwtToken = response['body']['jwtToken'];
      await _storage.write(key: 'sessionToken', value: token);
      await _storage.write(key: 'jwtToken', value: jwtToken);
      return {'success': true, 'message': _readMessage(response)};
    } else {
      return {'success': false, 'message': _readMessage(response)};
    }
  }

  String _readMessage(Map<String, dynamic> response) {
    final body = response['body'];
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return 'Request failed';
  }

  Future<bool> isLoggedIn() async {
    String? sessionToken = await _storage.read(key: 'sessionToken');
    if (sessionToken == null) {
      return false;
    }
    final response = await _isLoggedIn(sessionToken);
    return response == 0;
  }

  Future<int> _isLoggedIn(String token, {clearingOnForbidden = true}) async {
    final response = await Common().postRequestWrapper('Auth','IsLoggedIn', {'id': token}, clearingOnForbidden: clearingOnForbidden);
    if (response['statusCode'] == 200) {
      final fcm = FirebaseService().firebaseToken;
      if (fcm != null && fcm.isNotEmpty) {
        AuthService().refreshFCM(token, fcm);
      }
      return 0; // VALID TOKEN
    } else if (response['statusCode'] == 400) {
      return 2; // VALID TOKEN BUT EXPIRED SESSION
    } else if (response['statusCode'] == 201) {
      return 3; // VALID TOKEN BUT PASSWORD NOT SET
    }
    else {
      return 1; // INVALID TOKEN
    }
  }

  Future<int> changePassword(
    String token,
    String currentPassword,
    String newPass, {
    String stepUpToken = "",
  }) async {
    final response = await Common().postRequestWrapper('Auth', 'ChangePassword', {
      'currentPassword': currentPassword,
      'newPassword': newPass,
      'stepUpToken': stepUpToken,
    });
    if (response['statusCode'] == 200) {
      return 0; // SUCCESS
    } else if (response['statusCode'] == 404) {
      return 1; // NOT FOUND
    } else {
      return 2; // ERROR
    }
  }

  Future<bool> _googleQuickRegister(GoogleSignInAccount user, String country,DateTime birthday) async {
    final bdayStr = "${birthday.year.toString().padLeft(4,'0')}-"
        "${birthday.month.toString().padLeft(2,'0')}-"
        "${birthday.day.toString().padLeft(2,'0')}";

    final auth = await user.authentication;
    final Map<String, dynamic> data = {
      'id': user.id,
      'idToken': auth.idToken,
      'fcm': FirebaseService().firebaseToken ?? '-',
      'birthday': bdayStr,
      'country': country,
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoUrl
    };

    final response = await Common().postRequestWrapper('Auth','GoogleQuickRegister', data);

    if (response['statusCode'] == 200) {
      final body = response['body'] as Map<String, dynamic>? ?? {};
      final String? uid = body['userId']?.toString();
      final String? jwtToken = body['jwtToken']?.toString();
      if (uid != null && uid.isNotEmpty) {
        await _storage.write(key: 'sessionToken', value: uid);
      }
      if (jwtToken != null && jwtToken.isNotEmpty) {
        await _storage.write(key: 'jwtToken', value: jwtToken);
      }
      return true;
    }
    return false;
  }

  Future<int?> googleSignIn() async {
    try {
      // Evita enviar un JWT viejo (otra cuenta o caducado) en llamadas posteriores;
      // si no, RefreshFCM/UserInfo pueden devolver 401/403 y vaciar el almacén.
      await _storage.delete(key: 'jwtToken');

      const List<String> scopes = <String>[
        'https://www.googleapis.com/auth/user.birthday.read',
      ];

      final googleSignIn = GoogleSignIn(
        scopes: scopes,
        serverClientId: Config.serverClientId,
      );
      
      // Limpiar sesiones previas de manera segura
      try {
        await googleSignIn.signOut();
      } catch (e) {
        if (kDebugMode) { print('Error en signOut (puede ignorarse): $e'); }
      }
      try {
        await googleSignIn.disconnect();
      } catch (e) {
        if (kDebugMode) { print('Error en disconnect (puede ignorarse): $e'); }
      }

      final user = await googleSignIn.signIn();
      String country = await Common().getUserCountry();

      if (user != null) {
        final auth = await user.authentication;

        final accessToken = auth.accessToken;

        final response = await http.get(
          Uri.parse('https://people.googleapis.com/v1/people/me?personFields=birthdays'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['birthdays'] != null && data['birthdays'].isNotEmpty) {
            final birthdays = data['birthdays'] as List;
            Map birthdayData = birthdays[0]['date'];
            int year = birthdayData['year'] as int? ?? 1970;
            int month = birthdayData['month'] as int? ?? 1;
            int day = birthdayData['day'] as int? ?? 1;
            for (final entry in birthdays) {
              final date = entry['date'] as Map?;
              if (date != null && date['year'] != null) {
                birthdayData = date;
                year = date['year'] as int? ?? year;
                month = date['month'] as int? ?? month;
                day = date['day'] as int? ?? day;
                break;
              }
            }

            final int response = await _isLoggedIn(user.id, clearingOnForbidden: false);
            final idToken = auth.idToken;
            if (response == 0) {
              await _storage.write(key: 'sessionToken', value: user.id);
              await googleLogIn(user.id, idToken: idToken);
              return 0;
            }
            if (response == 2) {
              await googleLogIn(user.id, idToken: idToken);
              return 0;
            }
            if (response == 3) {
              await _storage.write(key: 'sessionToken', value: user.id);
              await googleLogIn(user.id, idToken: idToken);
              return 3;
            } else {
              bool successfullyRegistered = await _googleQuickRegister(
                user,
                country,
                DateTime(year, month, day),
              );
              if (successfullyRegistered) {
                await _storage.write(key: 'sessionToken', value: user.id);
                return 2;
              } else {
                return 1;
              }
            }
          } else {
            if (kDebugMode) {
              print('Failed to fetch additional user info: ${response.statusCode}');
            }
            return 1;
          }
        }
      }
      else if (user == null){
        return 1;
      }
    } catch (error)
    {
      if (kDebugMode) { 
        print('Error en googleSignIn: $error');
        if (error.toString().contains('PlatformException') || 
            error.toString().contains('channel-error') ||
            error.toString().contains('Pigeon')) {
          print('Error de canal de plataforma detectado. Esto generalmente se resuelve:');
          print('1. Ejecutando: flutter clean');
          print('2. Ejecutando: flutter pub get');
          print('3. Reconstruyendo el proyecto completamente');
        }
        if (error.toString().contains('ApiException: 10') || 
            error.toString().contains('sign_in_failed') ||
            error.toString().contains('DEVELOPER_ERROR')) {
          print('═══════════════════════════════════════════════════════════');
          print('ERROR 10: DEVELOPER_ERROR - Problema de configuración');
          print('═══════════════════════════════════════════════════════════');
          print('Las huellas digitales SHA-1/SHA-256 no coinciden.');
          print('');
          print('SOLUCIÓN:');
          print('1. Obtén las huellas SHA ejecutando desde android/:');
          print('   .\\gradlew.bat signingReport');
          print('');
          print('2. Ve a Google Cloud Console:');
          print('   https://console.cloud.google.com/apis/credentials');
          print('');
          print('3. Encuentra tu OAuth 2.0 Client ID para Android');
          print('   (Package name: com.betstrading.betrader)');
          print('');
          print('4. Agrega/actualiza las huellas SHA-1 y SHA-256');
          print('   en la configuración del cliente OAuth');
          print('');
          print('5. Asegúrate de que el SERVER_CLIENT_ID coincida:');
          print('   ${Config.serverClientId}');
          print('═══════════════════════════════════════════════════════════');
        }
      }
      return 1;
    }
    return 1;
  }


  Future<Map<String, dynamic>> refreshFCM(String userId, String token) async {
    // No borrar sesión si FCM falla (401): IsLoggedIn puede ser 200 sin JWT válido,
    // p. ej. tras login Google antes de guardar el nuevo token.
    final response = await Common().postRequestWrapper(
      'Auth',
      'RefreshFCM',
      {'user_id': userId, 'token': token},
      clearingOnForbidden: false,
    );

    if (response['statusCode'] == 200) {
      await _storage.write(key: 'fcmToken', value: token);
      return {'success': true, 'message': response['body']['message']};
    } else {
      return {'success': false, 'message': response['body']['message']};
    }
  }


  Future<bool> appleSignIn() async {
    return false;
  }
}
