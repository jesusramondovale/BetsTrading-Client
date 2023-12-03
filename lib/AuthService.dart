import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuthService {
  static const String apiUrl = 'http://192.168.1.37:5000/api';

  Future<Map<String, dynamic>> logIn(String username, String password) async {
    try {
      final response = await http.post(
        
        Uri.parse('$apiUrl/Auth/LogIn'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
        
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = jsonDecode(response.body);
        final String message = decodedBody['message'];
        return {'success': true, 'message': message};
      }

      else {
        final Map<String, dynamic> decodedBody = jsonDecode(response.body);
        final String message = decodedBody['message'];
        return {'success': false, 'message': message};
      }

    } catch (e) {

      var theFuckingType = e.runtimeType;
      if (e.runtimeType == TimeoutException){
          return {'success': false, 'message': "Server not responding. Try again later"};
        }
        if (e.runtimeType.toString() == "_ClientSocketException"){
          return {'success': false, 'message': "Can't connect. Check your internet connection"};
        }
        return {'success': false, 'message': '$e'};
    }
  }
}
