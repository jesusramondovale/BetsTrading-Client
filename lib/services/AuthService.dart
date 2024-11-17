// ignore_for_file: constant_identifier_names, file_names
import 'package:betrader/services/FirebaseService.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../helpers/common.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Future<Map<String, dynamic>> logIn(String username, String password) async {
    final response = await Common().postRequestWrapper('Auth', 'LogIn', {'username': username, 'password': password});

    if (response['statusCode'] == 200) {
      final String token = response['body']['userId'];
      await _storage.write(key: 'sessionToken', value: token);
      AuthService().refreshFCM(token, FirebaseService().firebaseToken!);
      return {'success': true, 'message': response['body']['message']};
    } else {
      return {'success': false, 'message': response['body']['message']};
    }
  }

  Future<Map<String, dynamic>> googleLogIn(String username) async {
    final response = await Common().postRequestWrapper('Auth','GoogleLogIn', {'username': username});

    if (response['statusCode'] == 200) {
      final String token = response['body']['userId'];
      await _storage.write(key: 'sessionToken', value: token);
      AuthService().refreshFCM(token, FirebaseService().firebaseToken!);
      return {'success': true, 'message': response['body']['message']};
    } else {
      return {'success': false, 'message': response['body']['message']};
    }
  }

  Future<Map<String, dynamic>> logOut(String id) async {
    final response = await Common().postRequestWrapper('Auth', 'LogOut', {'id': id});

    if (response['statusCode'] == 200) {
      await _storage.write(key: 'sessionToken', value: "empty");
      return {'success': true, 'message': response['body']['message']};
    } else {
      return {'success': false, 'message': response['body']['message']};
    }
  }

  Future<bool> addCoins(String id, double coins) async {
    final response = await Common().postRequestWrapper('Store', 'AddCoins', {'user_id': id, 'reward': coins});

    if (response['statusCode'] == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<Map<String, dynamic>> register(
      String idCard,
      String fcm,
      String fullName,
      String password,
      String address,
      String country,
      String gender,
      String email,
      DateTime birthday,
      String creditCard,
      String username,
      String? profilePic) async {
    final Map<String, dynamic> data = {
      'idCard': idCard,
      'fcm': fcm,
      'fullName': fullName,
      'password': password,
      'address': address,
      'country': country,
      'gender': gender,
      'email': email,
      'birthday': birthday.toIso8601String(),
      'creditCard': creditCard,
      'username': username,
      'profilePic': profilePic
    };

    final response = await Common().postRequestWrapper('Auth','SignIn', data);

    if (response['statusCode'] == 200) {
      final String token = response['body']['userId'];
      await _storage.write(key: 'sessionToken', value: token);
      return {'success': true, 'message': response['body']['message']};
    } else {
      return {'success': false, 'message': response['body']['message']};
    }
  }

  Future<bool> isLoggedIn() async {
    String? sessionToken = await _storage.read(key: 'sessionToken');
    if (sessionToken == null) {
      return false;
    }
    final response = await _isLoggedIn(sessionToken);
    return response == 0;
  }

  Future<int> _isLoggedIn(String token) async {
    final response = await Common().postRequestWrapper('Auth','IsLoggedIn', {'id': token});
    if (response['statusCode'] == 200) {
      AuthService().refreshFCM(token, FirebaseService().firebaseToken!);
      return 0; // VALID TOKEN
    } else if (response['statusCode'] == 400) {
      return 2; // VALID TOKEN BUT EXPIRED SESSION
    } else {
      return 1; // INVALID TOKEN
    }
  }

  Future<int> changePassword(String token, String newPass) async {
    final response = await Common().postRequestWrapper('Auth','ChangePassword', {'username': token, 'password' : newPass});
    if (response['statusCode'] == 200) {
      return 0; // SUCCESS
    } else {
      return 1; // ERROR
    }
  }

  Future<bool> _googleQuickRegister(GoogleSignInAccount user, String country,DateTime birthday) async {
    final Map<String, dynamic> data = {
      'id': user.id,
      'fcm': FirebaseService().firebaseToken!,
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoUrl,
      'birthday': birthday.toUtc().toIso8601String(),
      'country': country
    };

    final response = await Common().postRequestWrapper('Auth','GoogleQuickRegister', data);

    return response['statusCode'] == 200;
  }

  Future<int?> googleSignIn() async {
    try {
      const List<String> scopes = <String>[
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
        'https://www.googleapis.com/auth/user.birthday.read',
        'https://www.googleapis.com/auth/user.addresses.read',
        'https://www.googleapis.com/auth/userinfo.profile'
      ];
      GoogleSignIn googleSignIn = GoogleSignIn(scopes: scopes);

      final user = await googleSignIn.signIn();
      String country = await Common().getUserCountry();

      if (user != null) {
        if (kDebugMode) {
          print("User OK : $user");
        }

        final accessToken = (await user.authentication).accessToken;
        final response = await http.get(
          Uri.parse('https://people.googleapis.com/v1/people/me?personFields=birthdays,addresses,locations'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['birthdays'] != null && data['birthdays'].isNotEmpty) {
            Map birthdayData = data['birthdays'][0]['date'];
            int year = birthdayData['year'];
            int month = birthdayData['month'];
            int day = birthdayData['day'];

            final int response = await _isLoggedIn(user.id);
            if (response == 0) {
              // USER ACTIVE
              await _storage.write(key: 'sessionToken', value: user.id);
              return 0;
            }
            if (response == 2) {
              // USER REGISTERED BUT SESSION EXPIRED OR NOT ACTIVE -> FORCE GOOGLE LOG IN
              await googleLogIn(user.id);
              return 0;
            } else {
              // NO USER REGISTER, NEED TO QUICK REGISTER IT
              bool successfullyRegistered = await _googleQuickRegister(user, country, DateTime(year, month, day));
              if (successfullyRegistered) {
                return 0;
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
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
      return 1;
    }
    return 1;
  }

  Future<int?> verifyAccount(String idCard) async {
    String? id = await _storage.read(key: 'sessionToken');
    final response = await Common().postRequestWrapper('Auth','Verify', {'id': id , 'idCard': idCard });
    if (response['statusCode'] == 200) {
      return 0; // OK
    } else {
      return 1; // ERROR
    }
  }

  Future<Map<String, dynamic>> refreshFCM(String userId, String token) async {
    final response = await Common().postRequestWrapper('Auth','RefreshFCM', {'user_id':userId ,'fcm_token': token});

    if (response['statusCode'] == 200) {
      await _storage.write(key: 'fcmToken', value: token);
      return {'success': true, 'message': response['body']['message']};
    } else {
      return {'success': false, 'message': response['body']['message']};
    }
  }
  //TODO
  Future<bool> appleSignIn() async {
    return true;
  }
}
