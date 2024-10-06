import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class User {
  final String id;
  String? idcard;
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
  int failedAttempts;
  DateTime? lastLoginAttempt;
  DateTime? lastPasswordChange;
  String? profilePic;
  double points;

  User({
    required this.id,
    this.idcard,
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
    this.isActive = true,
    this.failedAttempts = 0,
    this.lastLoginAttempt,
    this.lastPasswordChange,
    this.profilePic,
  });

  // From Json
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      idcard: json['idcard'],
      fullname: json['fullname'],
      password: json['password'],
      country: json['country'],
      gender: json['gender'],
      email: json['email'],
      birthday: DateTime.parse(json['birthday']),
      signinDate: DateTime.parse(json['signin_date']),
      lastSession: DateTime.parse(json['last_session']),
      creditCard: json['credit_card'],
      username: json['username'],
      points: (json['points'] as num).toDouble(),
      tokenExpiration: json['token_expiration'] != null
          ? DateTime.parse(json['token_expiration'])
          : null,
      isActive: json['is_active'] ?? true,
      failedAttempts: json['failed_attempts'] ?? 0,
      lastLoginAttempt: json['last_login_attempt'] != null
          ? DateTime.parse(json['last_login_attempt'])
          : null,
      lastPasswordChange: json['last_password_change'] != null
          ? DateTime.parse(json['last_password_change'])
          : null,
      profilePic: json['profile_pic'],
    );
  }
}

class UserDialog extends StatelessWidget {
  final User user;

  UserDialog({super.key, required this.user});

  static get decodedBody => null;

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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(1)
                  : Colors.grey[200]!,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(message,
                style: GoogleFonts.josefinSans(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black87
          : Colors.grey[800],
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white70,
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]!
                    : Colors.deepPurple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Perfil y nombre
                    Row(
                      children: [
                        if (user.profilePic != null &&
                            user.profilePic!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50.0),
                            child: user.profilePic!.startsWith('http')
                                ? Image.network(
                                    user.profilePic!,
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  )
                                : Image.memory(
                                    base64Decode(user.profilePic!),
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              user.fullname,
                              maxLines: 1,
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            AutoSizeText(
                              '@${user.username}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Correo electrónico
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email,
                          color: Colors.white, size: 20),
                      title: Text(
                        maxLines: 1,
                        user.email,
                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16),
                      ),
                    ),
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
                      leading: Text(
                        '\u0e3f',
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w100,
                            color: Colors.yellowAccent),
                      ),
                      title: Text(
                        user.points.toString(),
                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20),
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
                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
