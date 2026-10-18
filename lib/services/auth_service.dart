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
import '../helpers/web_console_log.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Último error de Google Sign-In (para mostrarlo en UI).
  static String? lastError;

  void _authLog(String message) {
    final line = '[AuthEmail] $message';
    webConsoleLog(line);
    // ignore: avoid_print
    print(line);
  }

  Future<Map<String, dynamic>> logIn(String username, String password) async {
    _authLog(
      'LogIn START username="$username" passwordLen=${password.length} '
      'kIsWeb=$kIsWeb host=${Uri.base.host}:${Uri.base.port}',
    );
    try {
      final response = await Common().postRequestWrapper(
        'Auth',
        'LogIn',
        {'username': username, 'password': password},
        includeJwt: false,
      );
      final status = response['statusCode'];
      final body = response['body'];
      _authLog('LogIn RESPONSE HTTP $status body=$body');

      if (status == 200) {
        final String token = body['userId']?.toString() ?? '';
        final String jwtToken = body['jwtToken']?.toString() ?? '';
        _authLog(
          'LogIn OK userId=${token.isEmpty ? "(empty)" : "${token.substring(0, token.length.clamp(0, 8))}…"} '
          'jwtLen=${jwtToken.length}',
        );
        await _storage.write(key: 'sessionToken', value: token);
        await _storage.write(key: 'jwtToken', value: jwtToken);
        final fcm = FirebaseService().firebaseToken;
        if (fcm != null && fcm.isNotEmpty) {
          AuthService().refreshFCM(token, fcm);
        } else {
          _authLog('LogIn: FCM token null/empty (ok on web)');
        }
        return {'success': true, 'message': _readMessage(response)};
      } else {
        final msg = _readMessage(response);
        _authLog('LogIn FAIL message=$msg');
        return {'success': false, 'message': msg};
      }
    } catch (e, st) {
      _authLog('LogIn EXCEPTION: $e\n$st');
      return {'success': false, 'message': e.toString()};
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
    _authLog(
      'SignIn(register) START username="$username" email="$email" '
      'country="$country" gender="$gender" emailCodeLen=${emailCode.length} '
      'passwordLen=${password.length} fcm=${fcm.isEmpty ? "(empty)" : "len=${fcm.length}"} '
      'hasProfilePic=${profilePic != null && profilePic.isNotEmpty} '
      'creditCardLen=${creditCard.length} birthday=${birthday.toIso8601String()} '
      'kIsWeb=$kIsWeb',
    );
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

    try {
      final response = await Common().postRequestWrapper(
        'Auth',
        'SignIn',
        data,
        includeJwt: false,
      );
      final status = response['statusCode'];
      final body = response['body'];
      _authLog('SignIn(register) RESPONSE HTTP $status body=$body');

      if (status == 200) {
        final String token = body['userId']?.toString() ?? '';
        final String jwtToken = body['jwtToken']?.toString() ?? '';
        _authLog(
          'SignIn(register) OK userId=${token.isEmpty ? "(empty)" : "${token.substring(0, token.length.clamp(0, 8))}…"} '
          'jwtLen=${jwtToken.length}',
        );
        await _storage.write(key: 'sessionToken', value: token);
        await _storage.write(key: 'jwtToken', value: jwtToken);
        return {'success': true, 'message': _readMessage(response)};
      } else {
        final msg = _readMessage(response);
        _authLog('SignIn(register) FAIL message=$msg');
        return {'success': false, 'message': msg};
      }
    } catch (e, st) {
      _authLog('SignIn(register) EXCEPTION: $e\n$st');
      return {'success': false, 'message': e.toString()};
    }
  }

  String _readMessage(Map<String, dynamic> response) {
    final body = response['body'];
    if (body is Map) {
      final msg = body['message'] ?? body['Message'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString();
      }
      final errors = body['errors'] ?? body['Errors'];
      if (errors != null) {
        return errors.toString();
      }
    }
    final status = response['statusCode'];
    return status != null ? 'Request failed (HTTP $status)' : 'Request failed';
  }

  Future<bool> isLoggedIn() async {
    String? sessionToken = await _storage.read(key: 'sessionToken');
    if (sessionToken == null || sessionToken.isEmpty) {
      return false;
    }
    final jwt = await _storage.read(key: 'jwtToken');
    if (jwt == null || jwt.isEmpty) {
      await _storage.delete(key: 'sessionToken');
      return false;
    }
    final response = await _isLoggedIn(sessionToken, clearingOnForbidden: false);
    if (response != 0) {
      return false;
    }
    final probe = await Common().postRequestWrapper(
      'Info',
      'UserInfo',
      {'userId': sessionToken},
      clearingOnForbidden: false,
    );
    if (probe['statusCode'] != 200) {
      _googleLog(
        'isLoggedIn: JWT rejected by API (HTTP ${probe['statusCode']}); clearing session',
      );
      await _storage.delete(key: 'jwtToken');
      await _storage.delete(key: 'sessionToken');
      return false;
    }
    return true;
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

    _googleLog('GoogleQuickRegister HTTP ${response['statusCode']} body=${response['body']}');
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
    lastError =
        'GoogleQuickRegister HTTP ${response['statusCode']}: ${_readMessage(response)}';
    return false;
  }

  void _googleLog(String message) {
    final line = '[GoogleSignIn] $message';
    webConsoleLog(line);
    // ignore: avoid_print
    print(line);
  }

  /// Login/registro Google a partir del JWT de One Tap / GIS (`credential`).
  Future<int?> googleSignInWithIdToken(String idToken) async {
    lastError = null;
    try {
      _googleLog('OneTap START idTokenLen=${idToken.length}');
      await _storage.delete(key: 'jwtToken');
      final claims = _decodeJwtPayload(idToken);
      final sub = claims['sub']?.toString();
      if (sub == null || sub.isEmpty) {
        lastError = 'One Tap: JWT sin sub';
        _googleLog('ABORT: no sub in idToken');
        return 1;
      }
      final email = claims['email']?.toString() ?? '';
      final name = claims['name']?.toString() ??
          claims['given_name']?.toString() ??
          email.split('@').first;
      final picture = claims['picture']?.toString();
      _googleLog('OneTap sub=$sub email=$email');

      final country = await Common().getUserCountry();
      final birthday = DateTime(1990, 1, 1);

      final loginStatus =
          await _isLoggedIn(sub, clearingOnForbidden: false);
      _googleLog('OneTap IsLoggedIn status=$loginStatus');

      if (loginStatus == 0 || loginStatus == 2 || loginStatus == 3) {
        await _storage.write(key: 'sessionToken', value: sub);
        final loginRes = await googleLogIn(sub, idToken: idToken);
        final ok = loginRes['success'] == true;
        _googleLog(
          'OneTap googleLogIn success=$ok msg=${loginRes['message']}',
        );
        if (ok) {
          return loginStatus == 3 ? 3 : 0;
        }
        final msg = (loginRes['message'] ?? '').toString().toLowerCase();
        if (!msg.contains('user not found')) {
          lastError = 'GoogleLogIn: ${loginRes['message']}';
          return 1;
        }
      }

      final registered = await _googleQuickRegisterFromClaims(
        googleId: sub,
        idToken: idToken,
        email: email.isNotEmpty ? email : '$sub@users.noreply.google.com',
        displayName: name.isNotEmpty ? name : 'user',
        photoUrl: picture,
        country: country,
        birthday: birthday,
      );
      _googleLog('OneTap GoogleQuickRegister success=$registered');
      if (registered) {
        await _storage.write(key: 'sessionToken', value: sub);
        return 2;
      }
      lastError ??= 'GoogleQuickRegister falló (One Tap)';
      return 1;
    } catch (e, st) {
      lastError = 'Excepción One Tap: $e';
      _googleLog('OneTap EXCEPTION: $e\n$st');
      return 1;
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return {};
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }
    try {
      final decoded = utf8.decode(base64.decode(payload));
      final map = jsonDecode(decoded);
      if (map is Map<String, dynamic>) return map;
      if (map is Map) return Map<String, dynamic>.from(map);
    } catch (e) {
      _googleLog('JWT decode error: $e');
    }
    return {};
  }

  Future<bool> _googleQuickRegisterFromClaims({
    required String googleId,
    required String idToken,
    required String email,
    required String displayName,
    required String country,
    required DateTime birthday,
    String? photoUrl,
  }) async {
    final bdayStr =
        "${birthday.year.toString().padLeft(4, '0')}-"
        "${birthday.month.toString().padLeft(2, '0')}-"
        "${birthday.day.toString().padLeft(2, '0')}";
    final data = {
      'id': googleId,
      'idToken': idToken,
      'fcm': FirebaseService().firebaseToken ?? '-',
      'birthday': bdayStr,
      'country': country,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
    };
    final response =
        await Common().postRequestWrapper('Auth', 'GoogleQuickRegister', data);
    _googleLog(
      'GoogleQuickRegister(claims) HTTP ${response['statusCode']} body=${response['body']}',
    );
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
    lastError =
        'GoogleQuickRegister HTTP ${response['statusCode']}: ${_readMessage(response)}';
    return false;
  }

  Future<int?> googleSignIn() async {
    lastError = null;
    try {
      _googleLog(
        'START kIsWeb=$kIsWeb host=${Uri.base.host}:${Uri.base.port} '
        'clientId=${kIsWeb ? Config.googleWebClientId : "(n/a)"}',
      );
      await _storage.delete(key: 'jwtToken');

      final List<String> scopes = kIsWeb
          ? <String>['openid', 'email', 'profile']
          : <String>['https://www.googleapis.com/auth/user.birthday.read'];

      final googleSignIn = GoogleSignIn(
        scopes: scopes,
        clientId: kIsWeb ? Config.googleWebClientId : null,
        serverClientId: kIsWeb ? null : Config.serverClientId,
      );

      if (!kIsWeb) {
        try {
          await googleSignIn.signOut();
        } catch (e) {
          _googleLog('signOut ignore: $e');
        }
        try {
          await googleSignIn.disconnect();
        } catch (e) {
          _googleLog('disconnect ignore: $e');
        }
      }

      GoogleSignInAccount? user;
      _googleLog('calling signIn()…');
      user = await googleSignIn.signIn().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          lastError =
              'Google Sign-In timeout. Cierra el popup o revisa bloqueadores.';
          _googleLog('signIn() TIMEOUT');
          return null;
        },
      );
      if (user == null) {
        lastError ??=
            'Inicio de sesión Google cancelado o bloqueado por el navegador';
        _googleLog('signIn() cancelled or returned null');
        return 1;
      }
      _googleLog('user ok id=${user.id} email=${user.email}');

      final String country = await Common().getUserCountry();
      _googleLog('country=$country');

      var auth = await user.authentication;
      var idToken = auth.idToken;
      var accessToken = auth.accessToken;
      _googleLog(
        'tokens: idToken=${idToken != null && idToken.isNotEmpty} '
        'accessToken=${accessToken != null && accessToken.isNotEmpty}',
      );

      if ((idToken == null || idToken.isEmpty) && kIsWeb) {
        _googleLog('idToken vacío → signInSilently(reAuthenticate: true)…');
        try {
          final reauth = await googleSignIn
              .signInSilently(reAuthenticate: true)
              .timeout(const Duration(seconds: 60));
          if (reauth != null) {
            user = reauth;
            auth = await user.authentication;
            idToken = auth.idToken;
            accessToken = auth.accessToken;
            _googleLog(
              'reauth tokens: idToken=${idToken != null && idToken.isNotEmpty} '
              'accessToken=${accessToken != null && accessToken.isNotEmpty}',
            );
          } else {
            _googleLog('reAuthenticate returned null');
          }
        } catch (e) {
          _googleLog('reAuthenticate error: $e');
        }
      }

      if (idToken == null || idToken.isEmpty) {
        lastError =
            'Google no devolvió idToken (flujo GIS). Prueba en ventana de incógnito '
            'o permite cookies de terceros para accounts.google.com.';
        _googleLog('ABORT: idToken vacío tras reauth');
        return 1;
      }

      DateTime birthday = DateTime(1990, 1, 1);
      if (!kIsWeb) {
        try {
          if (accessToken != null && accessToken.isNotEmpty) {
            final peopleRes = await http.get(
              Uri.parse(
                'https://people.googleapis.com/v1/people/me?personFields=birthdays',
              ),
              headers: {'Authorization': 'Bearer $accessToken'},
            );
            _googleLog('People API status=${peopleRes.statusCode}');
            if (peopleRes.statusCode == 200) {
              final data = jsonDecode(peopleRes.body);
              if (data['birthdays'] != null && data['birthdays'].isNotEmpty) {
                final birthdays = data['birthdays'] as List;
                Map birthdayData = birthdays[0]['date'] as Map? ?? {};
                int year = birthdayData['year'] as int? ?? 1990;
                int month = birthdayData['month'] as int? ?? 1;
                int day = birthdayData['day'] as int? ?? 1;
                for (final entry in birthdays) {
                  final date = entry['date'] as Map?;
                  if (date != null && date['year'] != null) {
                    year = date['year'] as int? ?? year;
                    month = date['month'] as int? ?? month;
                    day = date['day'] as int? ?? day;
                    break;
                  }
                }
                birthday = DateTime(year, month, day);
                _googleLog('birthday from People API: $birthday');
              }
            }
          }
        } catch (e) {
          _googleLog('People API exception (continuing): $e');
        }
      } else {
        _googleLog('web: birthday fallback $birthday');
      }

      final GoogleSignInAccount account = user!;
      final int loginStatus =
          await _isLoggedIn(account.id, clearingOnForbidden: false);
      _googleLog('IsLoggedIn status=$loginStatus');

      if (loginStatus == 0 || loginStatus == 2 || loginStatus == 3) {
        await _storage.write(key: 'sessionToken', value: account.id);
        final loginRes = await googleLogIn(account.id, idToken: idToken);
        final ok = loginRes['success'] == true;
        _googleLog(
          'googleLogIn (status=$loginStatus) success=$ok msg=${loginRes['message']}',
        );
        if (ok) {
          return loginStatus == 3 ? 3 : 0;
        }
        final msg = (loginRes['message'] ?? '').toString().toLowerCase();
        if (msg.contains('user not found')) {
          _googleLog('googleLogIn user not found → GoogleQuickRegister…');
        } else {
          lastError = 'GoogleLogIn: ${loginRes['message']}';
          return 1;
        }
      } else {
        _googleLog('new user → GoogleQuickRegister…');
      }

      final registered =
          await _googleQuickRegister(account, country, birthday);
      _googleLog('GoogleQuickRegister success=$registered');
      if (registered) {
        await _storage.write(key: 'sessionToken', value: account.id);
        return 2;
      }
      lastError ??= 'GoogleQuickRegister falló';
      return 1;
    } catch (error, stack) {
      lastError = 'Excepción Google: $error';
      _googleLog('EXCEPTION: $error');
      _googleLog('STACK: $stack');
      if (error.toString().contains('ApiException: 10') ||
          error.toString().contains('sign_in_failed') ||
          error.toString().contains('DEVELOPER_ERROR') ||
          error.toString().contains('invalid_client') ||
          error.toString().contains('idpiframe')) {
        lastError =
            'OAuth mal configurado: revisa orígenes JS (http://localhost:5000) y Client ID web.';
        _googleLog(
          'OAuth/config hint: check JS origins, clientId web, '
          'and GCP authorized origins for this host.',
        );
      }
      return 1;
    }
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
