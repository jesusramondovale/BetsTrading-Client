// ignore_for_file: file_names

import '../enums/financial_assets.dart';
import '../helpers/common.dart';

class AssetsService {

  Future<List<FinancialAsset>?> getFinancialAssetsByGroup(String group, {String? currency}) async {
    final requestBody = {'id': group};
    // Agregar currency si se proporciona
    if (currency != null) {
      requestBody['currency'] = currency;
    }
    
    final response = await Common().postRequestWrapper(
      "FinancialAssets",
      "ByGroup",
      requestBody,
    );

    if (response['statusCode'] == 200) {
      final List<dynamic> data = response['body'];
      return data.map((json) => FinancialAsset.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load [$group] financial assets');
    }
  }
}
