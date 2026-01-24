import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class FinancialAsset {
   final String name;
  final String ticker;
  final String group;
  final String icon;
  final String country;
  // Campos opcionales para precios (vienen del backend)
  final double? current;
  final double? close;
  final double? dailyGain;

  FinancialAsset({
    required this.name,
    required this.group,
    required this.icon,
    required this.country,
    required this.ticker,
    this.current,
    this.close,
    this.dailyGain,
  });

  factory FinancialAsset.fromJson(Map<String, dynamic> json) {
    return FinancialAsset(
      name: (json['name']?.toString()) ?? '',
      group: (json['group']?.toString()) ?? '',
      icon: (json['icon']?.toString()) ?? '',
      country: (json['country']?.toString()) ?? '',
      ticker: (json['ticker']?.toString()) ?? '',
      current: json['current'] != null ? (json['current'] as num).toDouble() : null,
      close: json['close'] != null ? (json['close'] as num).toDouble() : null,
      dailyGain: json['dailyGain'] != null ? (json['dailyGain'] as num).toDouble() : null,
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
