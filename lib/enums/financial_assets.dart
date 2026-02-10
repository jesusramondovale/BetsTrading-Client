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

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory FinancialAsset.fromJson(Map<String, dynamic> json) {
    final current = _parseDouble(json['current']) ?? _parseDouble(json['price']) ?? _parseDouble(json['last']);
    final close = _parseDouble(json['close']) ?? _parseDouble(json['previousClose']);
    final dailyGain = _parseDouble(json['dailyGain']) ?? _parseDouble(json['changePercent']) ?? _parseDouble(json['variation']);
    return FinancialAsset(
      name: (json['name']?.toString()) ?? '',
      group: (json['group']?.toString()) ?? '',
      icon: (json['icon']?.toString()) ?? '',
      country: (json['country']?.toString()) ?? '',
      ticker: (json['ticker']?.toString()) ?? '',
      current: current,
      close: close,
      dailyGain: dailyGain,
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
