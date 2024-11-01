import 'dart:async';
import '../helpers/common.dart';
import '../models/users.dart';

class TopService {

  Future<List<User>> fetchTopUsers(String userId) async {
    final response = await Common().postRequestWrapper('Info','TopUsers', {'id': userId});

    if (response['statusCode'] == 200) {
      List<User> topUsers = (response['body']['users'] as List).map((json) => User.fromJson(json)).toList();
      return topUsers;

    } else {
      return [];
    }
  }

  Future<List<User>> fetchTopUsersByCountry(String countryCode) async {
    final response = await Common().postRequestWrapper('Info','TopUsersByCountry', {'id': countryCode});

    if (response['statusCode'] == 200) {
      List<User> topUsers = (response['body']['users'] as List).map((json) => User.fromJson(json)).toList();
      return topUsers;

    } else {
      return [];
    }
  }


}
