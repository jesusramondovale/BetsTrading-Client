import '../enums/financial_assets.dart';
import '../helpers/common.dart';

class AssetsService {

  Future<List<FinancialAsset>?> getFinancialAssetsByGroup(String group) async {
    final response = await Common().postRequestWrapper(
      "FinancialAssets",
      "ByGroup",
      {'id': group},
    );

    if (response['statusCode'] == 200) {
      final List<dynamic> data = response['body'];
      return data.map((json) => FinancialAsset.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load [$group] financial assets');
    }
  }
  /*** UNUSED **********
  Future<List<FinancialAsset>> getFinancialAssets() async {
    final response = await Common().postRequestWrapper(
      "FinancialAssets",
      "FinancialAssets",
      {}
    );

    if (response['statusCode'] == 200) {
      final List<dynamic> data = response['body'];
      return data.map((json) => FinancialAsset.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load allfinancial assets');
    }
  }****************************/
}
