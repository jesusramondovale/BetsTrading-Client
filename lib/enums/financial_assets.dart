import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class FinancialAsset {
  final int id;
  final String name;
  final String ticker;
  final String group;
  final String icon;
  final String country;

  FinancialAsset({
    required this.id,
    required this.name,
    required this.group,
    required this.icon,
    required this.country,
    required this.ticker,
  });

  factory FinancialAsset.fromJson(Map<String, dynamic> json) {
    return FinancialAsset(
      id: json['id'],
      name: json['name'],
      group: json['group'],
      icon: json['icon'],
      country: json['country'],
      ticker: json['ticker'],
    );
  }

  Widget imageFromBase64String() {
    if (icon.isEmpty) {
      return const SizedBox();
    }
    Uint8List bytes = base64Decode(icon);
    return Image.memory(bytes);
  }
}
