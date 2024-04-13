// ignore_for_file: constant_identifier_names, file_names
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const PUBLIC_DOMAIN = '108.pool90-175-130.dynamic.orange.es';
  static const API_URL = 'https://$PUBLIC_DOMAIN:44346/api/Auth';

  Future<Map<String, dynamic>> logIn(String username, String password) async {
    try {
      final Map<String, dynamic> data = {
        'username': username,
        'password': password
      };
      bool certificateCheck(X509Certificate cert, String host, int port) =>
          true;
      HttpClient client = HttpClient()
        ..badCertificateCallback = (certificateCheck);

      final HttpClientRequest request =
          await client.postUrl(Uri.parse("$API_URL/LogIn"));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody =
            await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);
        final String token = decodedBody['userId'];
        await _storage.write(key: 'sessionToken', value: token);

        return {'success': true, 'message': decodedBody['message']};
      } else {
        final String responseBody =
            await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);
        return {'success': false, 'message': decodedBody['message']};
      }
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111) {
        //Connection Refused
        return {
          'success': false,
          'message': "Server not responding. Try again later"
        };
      }
      if (e.osError?.errorCode == 7) {
        // Can't resolve -> No internet (DNS) access
        return {
          'success': false,
          'message': "Can't connect. Check your internet connection"
        };
      }
      return {
        'success': false,
        'message': "Server not responding. Try again later"
      };
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  Future<Map<String, dynamic>> logOut(String id) async {
    try {
      final Map<String, dynamic> data = {'id': id};
      bool certificateCheck(X509Certificate cert, String host, int port) =>
          true;
      HttpClient client = HttpClient()
        ..badCertificateCallback = (certificateCheck);

      final HttpClientRequest request =
          await client.postUrl(Uri.parse("$API_URL/LogOut"));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody =
            await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);
        await _storage.write(key: 'sessionToken', value: "empty");

        return {'success': true, 'message': decodedBody['message']};
      } else {
        final String responseBody =
            await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);
        return {'success': false, 'message': decodedBody['message']};
      }
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111) {
        //Connection Refused
        return {
          'success': false,
          'message': "Server not responding. Try again later"
        };
      }
      if (e.osError?.errorCode == 7) {
        // Can't resolve -> No internet (DNS) access
        return {
          'success': false,
          'message': "Can't connect. Check your internet connection"
        };
      }
      return {
        'success': false,
        'message': "Server not responding. Try again later"
      };
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  Future<Map<String, dynamic>> register(
      String idCard,
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
    try {
      final Map<String, dynamic> data = {
        'idCard': idCard,
        'fullName': fullName,
        'password': password,
        'address': address,
        'country': country,
        'gender': gender,
        'email': email,
        'birthday': birthday.toUtc().toIso8601String(),
        'creditCard': creditCard,
        'username': username,
        'profilePic': profilePic
      };

      bool certificateCheck(X509Certificate cert, String host, int port) =>
          true;
      HttpClient client = HttpClient()
        ..badCertificateCallback = (certificateCheck);

      final HttpClientRequest request =
          await client.postUrl(Uri.parse('$API_URL/SignIn'));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody =
            jsonDecode(await response.transform(utf8.decoder).join());
        final String message = decodedBody['message'];
        final String token = decodedBody['userId'];
        await _storage.write(key: 'sessionToken', value: token);
        return {'success': true, 'message': message};
      } else {
        final Map<String, dynamic> decodedBody =
            jsonDecode(await response.transform(utf8.decoder).join());
        final String message = decodedBody['message'];
        return {'success': false, 'message': message};
      }
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111) {
        //Connection Refused
        return {
          'success': false,
          'message': "Server not responding. Try again later"
        };
      }
      if (e.osError?.errorCode == 7) {
        // Can't resolve -> No internet (DNS) access
        return {
          'success': false,
          'message': "Can't connect. Check your internet connection"
        };
      }
      return {
        'success': false,
        'message': "Server not responding. Try again later"
      };
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
    bool certificateCheck(X509Certificate cert, String host, int port) => true;
    HttpClient client = HttpClient()..badCertificateCallback = certificateCheck;
    final HttpClientRequest request;

    try {
      request = await client.postUrl(Uri.parse('$API_URL/IsLoggedIn'));
      request.headers.set('Content-Type', 'application/json');
      final Map<String, dynamic> data = {'id': token};
      request.write(jsonEncode(data));
      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        //VALID TOKEN
        return 0;
      }
      if (response.statusCode == 400) {
        //VALID TOKEN BUT EXPIRED SESSION
        return 2;
      } //INVALID TOKEN
      else {
        return 1;
      }
    } catch (e) {
      return 1;
    } finally {
      client.close();
    }
  }

  Future<bool> _googleQuickRegister(
      GoogleSignInAccount user, DateTime birthday) async {
    bool certificateCheck(X509Certificate cert, String host, int port) => true;
    HttpClient client = HttpClient()..badCertificateCallback = certificateCheck;
    final HttpClientRequest request;

    try {
      request = await client.postUrl(Uri.parse('$API_URL/GoogleQuickRegister'));
      request.headers.set('Content-Type', 'application/json');
      final Map<String, dynamic> data = {
        'id': user.id,
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'birthday': birthday.toIso8601String()
      };
      request.write(jsonEncode(data));
      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<int?> googleSignIn() async {
    try {
      const List<String> scopes = <String>[
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
        'https://www.googleapis.com/auth/user.birthday.read',
        'https://www.googleapis.com/auth/user.addresses.read'
      ];
      GoogleSignIn googleSignIn = GoogleSignIn(scopes: scopes);

      final user = await googleSignIn.signIn();
      if (user != null) {
        if (kDebugMode) {
          print("User OK : $user");
        }

        final accessToken = (await user.authentication).accessToken;
        final response = await http.get(
          Uri.parse(
              'https://people.googleapis.com/v1/people/me?personFields=birthdays,addresses'),
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
              // USER REGISTERED BUT SESSION EXPIRED, FORCE LOG IN
              await logIn(user.email, "noPassword");
              await _storage.write(key: 'sessionToken', value: user.id);
              return 0;
            } else {
              // NO USER REGISTER, NEED TO QUICK REGISTER IT
              bool successfullyRegistered =
                  await _googleQuickRegister(user, DateTime(year, month, day));
              if (successfullyRegistered) {
                return 0;
              } else {
                return 1;
              }
            }
          } else {
            if (kDebugMode) {
              print(
                  'Failed to fetch additional user info: ${response.statusCode}');
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

  //TODO
  Future<bool> appleSignIn() async {
    return true;
  }
}
