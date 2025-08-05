import 'dart:convert';
import 'dart:ui';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/common.dart';
import '../helpers/slider.dart';
import 'layout_page.dart';
import 'notifications_page.dart'; // Tu slider custom
import 'package:intl/intl.dart';

class WithdrawPage extends StatefulWidget {
  final int coins;
  final int euros;
  final MainMenuPageController controller;
  const WithdrawPage({
    super.key,
    required this.coins,
    required this.euros,
    required this.controller
  });

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  String? _coinIconBase64;
  String? _selectedMethod;

  final Map<String, String> _userAvailableMethods = {};
  // TODO Get current user methods -> details map from backend


  @override
  void initState() {
    super.initState();
    _loadCoinImage();

    if (_userAvailableMethods.isNotEmpty) {
      _selectedMethod = _userAvailableMethods.keys.first;
    }
  }

  Future<void> _loadCoinImage() async {
    final bytes = await rootBundle.load('assets/coin.png');
    final base64 = base64Encode(bytes.buffer.asUint8List());
    setState(() => _coinIconBase64 = base64);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent.withValues(alpha: 0.0),
        elevation: 0,
        title: Text(
          LocalizedStrings.of(context)?.get("withdrawTitle") ?? "Withdrawal money",
          style: GoogleFonts.montserrat(
            fontSize: 25,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo blur
          Positioned.fill(
            child: Image.asset(
              'assets/android12splash.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ),

          // Contenido principal
          Positioned.fill(
            child: SafeArea(
              child: _coinIconBase64 == null
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      child: Column(
                        children: [
                          // Header info
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    NumberFormat.compact().format(widget.coins),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 50,
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(width: 6),
                                  Image.asset(
                                    'assets/coin.png',
                                    width: 45,
                                    height: 45,
                                  ),
                                ],
                              ),
                              Text(
                                '${widget.euros} €',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 35,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                LocalizedStrings.of(context)?.get('chooseMethod') ?? 'Choose your withdrawal method:',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Expanded(
                            child: _userAvailableMethods.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.white24, width: 1),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded,
                                            color: Colors.yellow,
                                            size: 60),
                                        const SizedBox(height: 20),
                                        Text(
                                          textAlign: TextAlign.center,
                                          LocalizedStrings.of(context)?.get('noMethods') ??
                                              "You don't have any withdrawal methods configured. Please add one in your profile settings.",
                                          style: GoogleFonts.rajdhani(
                                            fontSize: 26,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        Center(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(50),
                                              splashColor: Colors.white24,
                                              highlightColor: Colors.white12, // <-- menos transparente al pulsar
                                              onTap: () {
                                                Common().vibrate(40, 30);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => SettingsView(
                                                      onPersonalInfoTap: () {
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                        widget.controller.updateIndex(4);
                                                      },
                                                      onShowNotifications: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) => NotificationsPage(
                                                              onBack: () => Navigator.pop(context),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(50),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.arrow_forward_ios_rounded, size: 25, color: Colors.white),
                                                    SizedBox(width: 12),
                                                    Icon(Icons.settings, size: 45, color: Colors.white),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _userAvailableMethods.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final method = _userAvailableMethods.keys.elementAt(index);
                                  final detail = _userAvailableMethods[method]!;
                                  final isSelected = _selectedMethod == method;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () => setState(() => _selectedMethod = method),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.deepPurple.withValues(alpha: 0.8)
                                                : Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? Colors.deepPurpleAccent : Colors.white24,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isSelected
                                                    ? Icons.radio_button_checked
                                                    : Icons.radio_button_off,
                                                color: isSelected ? Colors.white : Colors.white54,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                LocalizedStrings.of(context)?.get(method) ?? LocalizedStrings.localizedValues['en']![method]!,
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 48.0, top: 6.0, bottom: 6.0),
                                          child: Text(
                                            detail,
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 20,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }
                                  ),
                          ),

                          const SizedBox(height: 20),

                          const SizedBox(height: 20),

                          ...(_userAvailableMethods.isNotEmpty
                              ? [
                            Text(
                              LocalizedStrings.of(context)?.get('slideToConfirm') ?? 'Slide to Confirm',
                              maxLines: 1,
                              style: GoogleFonts.syncopate(
                                fontSize: 16,
                                color: Colors.white60,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SlideToConfirm(
                              icon: _coinIconBase64!,
                              betAmount: widget.coins.toDouble(),
                              transformedAmount: widget.euros.toDouble(),
                              transformThumb: true,
                              onSlideComplete: () {
                                // TODO
                              },
                            ),
                          ]
                              : [ const SizedBox(height: 80)]),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
