import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../enums/financial_assets.dart';

class AssetsService {
  static const PUBLIC_DOMAIN = '108.pool90-175-130.dynamic.orange.es';
  static const API_URL = 'https://$PUBLIC_DOMAIN:44346/api/FinancialAssets';

  Future<List<FinancialAsset>?> getFinancialAssetsByGroup(String group) async {
    var client = HttpClient()
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);

    var request = await client.getUrl(Uri.parse('$API_URL/ByGroup/$group'));
    var response = await request.close();

    if (response.statusCode == 200) {
      var responseBody = await response.transform(utf8.decoder).join();
      List<dynamic> data = json.decode(responseBody);
      return data.map((json) => FinancialAsset.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load [$group] financial assets');
    }
  }

  Future<List<FinancialAsset>> getFinancialAssets() async {
    final response = await http.get(Uri.parse('$API_URL/FinancialAssets/'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => FinancialAsset.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load financial assets');
    }
  }
}
