import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuthService {
  static const String apiUrl = 'https://192.168.1.38:44346/api/Auth/LogIn';

  Future<Map<String, dynamic>> logIn(String username, String password) async {
    try {

      final Map<String, dynamic> data = {'username': username, 'password': password};
      bool _certificateCheck(X509Certificate cert, String host, int port) => true;
      HttpClient client = new HttpClient()..badCertificateCallback = (_certificateCheck);

      final HttpClientRequest request = await client.postUrl(Uri.parse(apiUrl));
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
      if (e.runtimeType.toString() == "_ClientSocketException") {
        return {'success': false, 'message': "Can't connect. Check your internet connection"};
      }
      return {'success': false, 'message': '$e'};
    }
  }

}
