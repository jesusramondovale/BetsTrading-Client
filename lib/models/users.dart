import 'dart:convert';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class User {
  final String id;
  final String fullname;
  final String password;
  final String country;
  final String gender;
  final String email;
  final DateTime birthday;
  final DateTime signinDate;
  DateTime lastSession;
  final String creditCard;
  final String username;
  DateTime? tokenExpiration;
  bool isActive;
  bool isVerified;
  int failedAttempts;
  DateTime? lastLoginAttempt;
  DateTime? lastPasswordChange;
  String? profilePic;
  double points;

  User({
    required this.id,
    required this.fullname,
    required this.password,
    required this.country,
    required this.gender,
    required this.email,
    required this.birthday,
    required this.signinDate,
    required this.lastSession,
    required this.creditCard,
    required this.username,
    this.points = 0.0,
    this.tokenExpiration,
    this.isVerified = false,
    this.isActive = true,
    this.failedAttempts = 0,
    this.lastLoginAttempt,
    this.lastPasswordChange,
    this.profilePic,
  });

  static DateTime? _parseDateOrNull(dynamic v) {
    if (v == null || v.toString().trim().isEmpty) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static DateTime _parseDate(dynamic v) =>
      _parseDateOrNull(v) ?? DateTime.now().toUtc();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id']?.toString()) ?? '',
      fullname: (json['fullname']?.toString()) ?? '',
      password: (json['password']?.toString()) ?? '',
      country: (json['country']?.toString()) ?? '',
      gender: (json['gender']?.toString()) ?? '',
      email: (json['email']?.toString()) ?? '',
      birthday: _parseDate(json['birthday']),
      signinDate: _parseDate(json['signinDate']),
      lastSession: _parseDate(json['lastSession']),
      creditCard: (json['creditCard']?.toString()) ?? '',
      username: (json['username']?.toString()) ?? '',
      points: (json['points'] == null) ? 0.0 : (json['points'] as num).toDouble(),
      tokenExpiration: _parseDateOrNull(json['tokenExpiration']),
      isVerified: json['isVerified'] == true,
      isActive: json['isActive'] != false,
      failedAttempts: (json['failedAttempts'] == null)
          ? 0
          : (json['failedAttempts'] as num).toInt(),
      lastLoginAttempt: _parseDateOrNull(json['lastLoginAttempt']),
      lastPasswordChange: _parseDateOrNull(json['lastPasswordChange']),
      profilePic: json['profilePic']?.toString(),
    );
  }
}

class UserDialog extends StatelessWidget {
  final User user;

  const UserDialog({super.key, required this.user});

  static Null get decodedBody => null;

  void showPopup(BuildContext context, String message, Offset position) {
    int xOffset;
    (message.length < 10) ? xOffset = -18 : xOffset = message.length - 15;

    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - xOffset,
        top: position.dy + 35,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color:Colors.black.withValues(alpha:1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(message,
                style: GoogleFonts.josefinSans(
                    fontSize: 12,
                    color: Colors.white)),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 1200), () {
      overlayEntry?.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.transparent.withValues(alpha: 0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white70.withValues(alpha: 0.12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .6),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (user.profilePic != null && user.profilePic!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50.0),
                            child: user.profilePic!.startsWith('http')
                                ? Image.network(
                              user.profilePic!,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                    "assets/new_icon.png",
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                            )
                                : Image.memory(
                              base64Decode(user.profilePic!),
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              (user.fullname.length < 12
                                  ? user.fullname
                                  : '${user.fullname.substring(0, 12)}...'),
                              maxLines: 1,
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            AutoSizeText(
                              '@${(user.username.length < 20 ? user.username : '${user.username.substring(0, 17)}...')}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Correo electrónico
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email,
                          color: Colors.white, size: 20),
                      title: Text(
                        (user.email.length < 35
                            ? user.email
                            : '${user.email.substring(0, 30)}...'),
                        maxLines: 1,
                        style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),

                    // País
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on,
                          color: Colors.white, size: 20),
                      title: Row(
                        children: [
                          CountryFlag.fromCountryCode(
                            user.country,
                            height: 18,
                            width: 25,
                          ),
                        ],
                      ),
                    ),

                    // Puntos
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        margin: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                        child: Image.asset(
                          'assets/coin.png',
                          width: 25,
                          height: 25,
                        ),
                      ),
                      title: Text(
                        user.points.toString(),
                        style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 20),
                      ),
                    ),

                    // Estado activo
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        user.isActive ? Icons.check_circle : Icons.block,
                        color: user.isActive ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      title: Text(
                        user.isActive ? 'Cuenta activa' : 'Cuenta inactiva',
                        style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

  }
}
