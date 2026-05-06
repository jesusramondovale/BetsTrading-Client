import 'dart:convert';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../locale/localized_texts.dart';
import '../ui/copy_betting_profile_page.dart';

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
    final isActive = user.isActive;
    final statusColor = isActive ? Colors.green : Colors.red;

    // No usar Dialog (centra en pantalla); solo el contenido para respetar posición del padre.
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white70.withValues(alpha: 0.28),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: avatar + nombre + cerrar en una sola fila
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.4),
                                  Colors.white.withValues(alpha: 0.15),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor.withValues(alpha: isActive ? 0.5 : 0.3),
                              ),
                              child: user.profilePic != null && user.profilePic!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(50.0),
                                      child: user.profilePic!.startsWith('http')
                                          ? Image.network(
                                              user.profilePic!,
                                              height: 56,
                                              width: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Image.asset(
                                                "assets/neon_icon.png",
                                                height: 56,
                                                width: 56,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Image.memory(
                                              base64Decode(user.profilePic!),
                                              height: 56,
                                              width: 56,
                                              fit: BoxFit.cover,
                                            ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(50.0),
                                      child: Image.asset(
                                        "assets/neon_icon.png",
                                        height: 56,
                                        width: 56,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AutoSizeText(
                                user.fullname.length < 14
                                    ? user.fullname
                                    : '${user.fullname.substring(0, 12)}...',
                                maxLines: 1,
                                style: GoogleFonts.syncopate(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 1),
                              AutoSizeText(
                                '@${user.username}',
                                maxLines: 1,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
                    const SizedBox(height: 8),

                    // País, Puntos y Copy-betting en fila compacta (menos ancho a país, más al botón)
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                const SizedBox(width: 3),
                                CountryFlag.fromCountryCode(
                                  user.country,
                                  height: 14,
                                  width: 20,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/coin.png',
                                  width: 22,
                                  height: 22,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    NumberFormat.compact().format(user.points),
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      color: const Color(0xFFFFD54F),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          SizedBox(
                            width: 116,
                            child: Center(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) => CopyBettingProfilePage(user: user),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.copy_all,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'Copy-Trade',
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
