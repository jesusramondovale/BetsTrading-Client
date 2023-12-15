// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';



class AuthService {
  static const PRIVATE_IP = '192.168.1.37';
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
        final Map<String, dynamic> decodedBody = jsonDecode(await response.transform(utf8.decoder).join());
        final String message = decodedBody['message'];
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
      ) async {
    try {
      final Map<String, dynamic> data = {
        'idCard': idCard,
        'fullName': fullName,
        'password': password,
        'address': address,
        'country': country,
        'gender': gender,
        'email': email,
        'birthday': birthday.toIso8601String(),
        'creditCard': creditCard,
        'username': username,
      };

      bool certificateCheck(X509Certificate cert, String host, int port) => true;
      HttpClient client = HttpClient()..badCertificateCallback = (certificateCheck);

      final HttpClientRequest request = await client.postUrl(Uri.parse('$API_URL/Register'));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(data));

      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = jsonDecode(await response.transform(utf8.decoder).join());
        final String message = decodedBody['message'];
        return {'success': true, 'message': message};
      } else {
        final Map<String, dynamic> decodedBody = jsonDecode(await response.transform(utf8.decoder).join());
        final String message = decodedBody['message'];
        return {'success': false, 'message': message};
      }
    } catch (e) {
      if (e.runtimeType == TimeoutException) {
        return {'success': false, 'message': "Server not responding. Try again later"};
      }
      if (e.runtimeType == SocketException) {
        return {'success': false, 'message': "Can't connect. Check your internet connection"};
      }
      return {'success': false, 'message': '$e'};
    }
  }

}
