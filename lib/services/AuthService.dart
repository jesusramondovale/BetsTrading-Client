// ignore_for_file: constant_identifier_names, file_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  //static const PRIVATE_IP = '192.168.1.37';
  static const PUBLIC_DOMAIN = '108.pool90-175-130.dynamic.orange.es';
  static const API_URL = 'https://$PUBLIC_DOMAIN:44346/api/Auth';


  Future<Map<String, dynamic>> logIn(String username, String password) async {
    try {
      final Map<String, dynamic> data = {'username': username, 'password': password};
      bool certificateCheck(X509Certificate cert, String host, int port) => true;
      HttpClient client = HttpClient()..badCertificateCallback = (certificateCheck);

      final HttpClientRequest request = await client.postUrl(Uri.parse("$API_URL/LogIn"));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);
        final String token = decodedBody['userId'];
        await _storage.write(key: 'sessionToken', value: token);

        return {'success': true, 'message': decodedBody['message']};
      } else {
        final String responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);
        return {'success': false, 'message': decodedBody['message']};
      }
    } on SocketException catch (e) {

      if (e.osError?.errorCode == 111) { //Connection Refused
        return {'success': false, 'message': "Server not responding. Try again later"};
      }
      if (e.osError?.errorCode == 7) { // Can't resolve -> No internet (DNS) access
        return {'success': false, 'message': "Can't connect. Check your internet connection"};
      }
      return {'success': false, 'message': "Server not responding. Try again later"};
    }
    catch (e){
      return {'success': false, 'message': '$e'};
    }
  }

  Future<Map<String,dynamic>> logOut(String id) async {
    try {
      final Map<String, dynamic> data = {'id': id};
      bool certificateCheck(X509Certificate cert, String host, int port) => true;
      HttpClient client = HttpClient()..badCertificateCallback = (certificateCheck);

      final HttpClientRequest request = await client.postUrl(Uri.parse("$API_URL/LogOut"));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final String responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);
        await _storage.write(key: 'sessionToken', value: "empty");

        return {'success': true, 'message': decodedBody['message']};
      } else {
        final String responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> decodedBody = jsonDecode(responseBody);
        return {'success': false, 'message': decodedBody['message']};
      }
    } on SocketException catch (e) {

      if (e.osError?.errorCode == 111) { //Connection Refused
        return {'success': false, 'message': "Server not responding. Try again later"};
      }
      if (e.osError?.errorCode == 7) { // Can't resolve -> No internet (DNS) access
        return {'success': false, 'message': "Can't connect. Check your internet connection"};
      }
      return {'success': false, 'message': "Server not responding. Try again later"};
    }
    catch (e){
      return {'success': false, 'message': '$e'};
    }


  }


  Future<Map<String, dynamic>> register(String idCard,String fullName,String password,String address,
      String country,String gender,String email,DateTime birthday,String creditCard,String username,String? profilePic
      ) async {
    try {
      final Map<String,dynamic> data =
        {
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

      bool certificateCheck(X509Certificate cert, String host, int port) => true;
      HttpClient client = HttpClient()..badCertificateCallback = (certificateCheck);

      final HttpClientRequest request = await client.postUrl(Uri.parse('$API_URL/SignIn'));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = jsonDecode(await response.transform(utf8.decoder).join());
        final String message = decodedBody['message'];
        final String token = decodedBody['userId'];
        await _storage.write(key: 'sessionToken', value: token);
        return {'success': true, 'message': message};
      } else {
        final Map<String, dynamic> decodedBody = jsonDecode(await response.transform(utf8.decoder).join());
        final String message = decodedBody['message'];
        return {'success': false, 'message': message};
      }
    } on SocketException catch (e) {

      if (e.osError?.errorCode == 111) { //Connection Refused
        return {'success': false, 'message': "Server not responding. Try again later"};
      }
      if (e.osError?.errorCode == 7) { // Can't resolve -> No internet (DNS) access
        return {'success': false, 'message': "Can't connect. Check your internet connection"};
      }
      return {'success': false, 'message': "Server not responding. Try again later"};

    }
  }

  Future<bool> isLoggedIn() async {
    String? sessionToken = await _storage.read(key: 'sessionToken');
    if (sessionToken == null) {
      return false;
    }
    return await _verifyTokenWithServer(sessionToken);
  }

  Future<bool> _verifyTokenWithServer(String token) async {

    bool certificateCheck(X509Certificate cert, String host, int port) => true;
    HttpClient client = HttpClient()..badCertificateCallback = certificateCheck;

    try {
      final HttpClientRequest request = await client.postUrl(Uri.parse('$API_URL/IsLoggedIn'));
      request.headers.set('Content-Type', 'application/json');
      final Map<String, dynamic> data = {'id': token};
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200)
      { //VALID TOKEN
        return true;
      } //INVALID TOKEN
      else {
        return false;
      }
    }
    on SocketException catch (e) {

      if (e.osError?.errorCode == 111) { //Connection Refused
        return false;
      }
      if (e.osError?.errorCode == 7) { // Can't resolve -> No internet (DNS) access
        return false;
      }
      return false;
    }
    catch (e) {
      return false;
    }

    finally {
      client.close();
    }
  }

}
