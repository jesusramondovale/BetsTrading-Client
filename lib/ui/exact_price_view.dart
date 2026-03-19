import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bets_service.dart';
import '../config/config.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../services/firebase_service.dart';
import '../services/secure_auth_service.dart';
import 'layout_page.dart';
import 'package:intl/intl.dart';

/// A page for placing exact price bets on financial assets.
///
/// Allows users to select a target price, margin tolerance, and date
/// for betting that an asset will reach a specific price within a margin.
class ExactPricePage extends StatefulWidget {
  /// The current price value of the asset.
  final double currentValue;
  
  /// The path to the asset icon (can be asset path, URL, or base64).
  final String iconPath;
  
  /// The ticker symbol of the asset.
  final String ticker;
  
  /// The name of the asset.
  final String name;
  
  /// Whether this is a Forex asset (affects price formatting).
  final bool isForex;

  const ExactPricePage(
      {super.key,
      required this.name,
      required this.currentValue,
      required this.ticker,
      required this.iconPath,
      required this.isForex});

  @override
  State<ExactPricePage> createState() => _ExactPricePageState();
}

class _ExactPricePageState extends State<ExactPricePage> {
  double _selectedPrice = 0.0;
  DateTime _selectedDate = DateTime.now();
  Timer? _holdTimer;
  DateTime? _holdStart;
  String _selectedMargin = "±0%";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final SecureAuthService _secureAuthService = SecureAuthService();
  double _userPoints = 0.0;
  String _currency = "eur";
  bool _isAcceptEnabled = false;
  final TextEditingController _priceController = TextEditingController();

  /// Loads user points and currency preference from storage.
  ///
  /// Updates the accept button enabled state based on available points
  /// and selected margin requirements.
  Future<void> _loadUserPoints() async {
    final String? pointsStr = await _storage.read(key: 'points');
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userPoints = double.tryParse(pointsStr ?? '0') ?? 0.0;
      _isAcceptEnabled =
          _getBetAmountFromMargin(_selectedMargin) <= _userPoints;
      if (prefs.getBool('dollarCurrency') ?? false) {
        _currency = 'usd';
      }
    });
  }

  /// Gets the required bet amount for a given margin percentage.
  ///
  /// [margin] The margin string (e.g., "±0%", "±0.01%").
  /// Returns the bet amount in coins required for that margin.
  int _getBetAmountFromMargin(String margin) {
    switch (margin) {
      case "±0%":
        return 50;
      case "±0.01%":
        return 200;
      case "±0.05%":
        return 1000;
      case "±0.075%":
        return 1500;
      case "±0.1%":
        return 5000;
      default:
        return 0;
    }
  }

  /// Converts a margin string to a double percentage value.
  ///
  /// [margin] The margin string (e.g., "±0%", "±0.01%").
  /// Returns the margin as a double (e.g., 0.0, 0.01).
  double _getMarginAsDouble(String margin) {
    switch (margin) {
      case "±0%":
        return 0.0;
      case "±0.01%":
        return 0.01;
      case "±0.05%":
        return 0.05;
      case "±0.075%":
        return 0.075;
      case "±0.1%":
        return 0.1;
      default:
        return 0.0;
    }
  }

  /// Calculates the width of text with currency symbol for layout purposes.
  ///
  /// [text] The text to measure.
  /// [style] The text style to use for measurement.
  /// Returns the calculated width multiplied by 0.75 for padding.
  double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
          text: (_currency == "eur" ? '€' : '\$ ') + text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    return textPainter.size.width * 0.75;
  }

  Widget _buildMarginButtons(
      BuildContext context, void Function(String) onMarginChanged) {
    final List<String> options = [
      "±0%",
      "±0.01%",
      "±0.05%",
      "±0.075%",
      "±0.1%"
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 12),
      child: StatefulBuilder(
        builder: (context, setStateMargin) {
          return Row(
            children: options.map((text) {
              final bool isSelected = _selectedMargin == text;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.all(3),
                  child: ElevatedButton(
                    onPressed: () {
                      onMarginChanged(text);
                      setStateMargin(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.blue[300] : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: isSelected ? 3 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      maxLines: 1,
                      text,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSecondaryButtons(BuildContext context, bool isEnabled) {
    final strings = LocalizedStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Common().vibrate();
                Navigator.pop(context, null);
              },
              icon: Icon(CupertinoIcons.arrow_uturn_left, color: Colors.black),
              label: Text(
                maxLines: 1,
                strings?.get('cancel') ?? 'Cancel',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isEnabled
                  ? () async {
                      Common().vibrate();
                      final prefs = await SharedPreferences.getInstance();
                      bool bettingNotifications =
                          prefs.getBool('bettingNotifications') ?? true;
                      FocusScope.of(context).unfocus();
                      bool? confirmed = await Common()
                          .popConfirmOperationDialog(
                              context,
                              _getBetAmountFromMargin(_selectedMargin)
                                  .toDouble(),
                              widget.iconPath);
                      if (confirmed == true) {
                        String? userId =
                            await _storage.read(key: 'sessionToken');
                        _selectedPrice = double.tryParse(
                                _priceController.text.replaceAll(',', '.')) ??
                            _selectedPrice;
                        String fcm = FirebaseService().firebaseToken ?? "null";
                        final betCost = _getBetAmountFromMargin(_selectedMargin).toDouble();
                        String password = "";
                        String stepUpToken = "";
                        if (betCost >= 1000) {
                          final biometricEnabled = await _secureAuthService.isBiometricEnabled();
                          if (biometricEnabled) {
                            final token = await _secureAuthService.runStepUpWithBiometric(
                              context,
                              purpose: 'bet',
                              maxAmountCoins: betCost,
                            );
                            if (token == null) return;
                            stepUpToken = token;
                          } else {
                            final entered = await _secureAuthService.promptPasswordDialog(context);
                            if (entered == null || entered.isEmpty) return;
                            password = entered;
                          }
                        }
                        int result = await BetsService().postNewExactPriceBet(
                            userId!,
                            fcm,
                            widget.ticker,
                            _selectedPrice,
                            _getMarginAsDouble(_selectedMargin),
                            _selectedDate,
                            _currency.toUpperCase(),
                            password: password,
                            stepUpToken: stepUpToken);

                        if (result == 200) {
                          if (bettingNotifications) {
                            Common().showFloatingSnack(
                                context,
                                (LocalizedStrings.of(context)!
                                            .get('betPlacedSuccessfully') !=
                                        null
                                    ? "${LocalizedStrings.of(context)!.get('betPlacedSuccessfully')} ► ${_getBetAmountFromMargin(_selectedMargin).toStringAsFixed(2)}"
                                    : "Bet placed successfully! ► ${_getBetAmountFromMargin(_selectedMargin)}"),
                                showIcon: true);
                          }

                          await BetsService().getUserInfo(userId);
                          Navigator.pop(context);
                          Navigator.pop(context);
                          homeScreenKey.currentState?.loadUserIdAndData();
                          exchangePageKey.currentState?.loadData();
                        } else if (result == 410) {
                          Common().showFloatingSnack(
                              context,
                              "${LocalizedStrings.of(context)!
                                          .get('errorMakingBet') ??
                                      "Error creating price bet!"}(NO TIME)",
                              backgroundColor: Colors.red);
                        } else if (result == 420) {
                          Common().showFloatingSnack(
                              context,
                              (LocalizedStrings.of(context)!
                                      .get('betErrorPoints') ??
                                  "Not enough points!"),
                              backgroundColor: Colors.red);
                        } else if (result == 430) {
                          Common().showFloatingSnack(
                              context,
                              (LocalizedStrings.of(context)!
                                      .get('betAlreadyExists') ??
                                  "Bet already exists!"),
                              backgroundColor: Colors.red);
                        } else {
                          if (bettingNotifications) {
                            Common().showFloatingSnack(
                                context,
                                (LocalizedStrings.of(context)!
                                        .get('errorMakingBet') ??
                                    "Error creating price bet!"),
                                backgroundColor: Colors.red);
                          }
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      }
                    }
                  : () {
                      Common().vibrate(450, 80);
                    },
              icon: Icon(CupertinoIcons.checkmark_alt, color: Colors.black),
              label: Text(
                strings?.get('accept') ?? 'Accept',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isEnabled ? Colors.blue[300] : Colors.grey[600],
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedPrice = widget.currentValue;
    _priceController.text = _selectedPrice.toStringAsFixed(2);
    _loadUserPoints();
  }

  void _showHowItWorksDialog() {
    final strings = LocalizedStrings.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: .7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white24),
          ),
          title: Text(
            strings?.get('cv_exactprice_title') ?? 'Exact price',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  strings?.get('cv_exactprice_body') ??
                      'Place exact-close bets from here. Pick a target close price; if the candle closes exactly at that value, you can win prizes up to €100,000.',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  (strings?.get('exactPriceMarginExplanation') ??
                      'The smaller the margin of error you select, the cheaper the bet is. Choosing ±0% is cheaper, while ±0.1% is the most expensive.'),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber, // Highlighted text for explanation
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.iconPath == "null"
                ? Image.asset('assets/new_icon.png', fit: BoxFit.cover)
                : (widget.iconPath.startsWith("http")
                    ? Image.network(
                        widget.iconPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/new_icon.png',
                                fit: BoxFit.cover),
                      )
                    : Image.memory(
                        base64Decode(widget.iconPath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/new_icon.png',
                                fit: BoxFit.cover),
                      )),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: GoogleFonts.openSans(
                        fontSize: 50,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      LocalizedStrings.of(context)?.get('nowLabel')!.toUpperCase() ?? 'NOW:',
                      style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w200,
                          color: Colors.white),
                    ),
                    Text(
                      '${widget.isForex
                              ? ''
                              : (_currency == "eur" ? '€' : '\$')} ${widget.currentValue.toStringAsFixed(2)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 36,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      (LocalizedStrings.of(context)?.get('exactClosingValue') ?? 'Exact closing value')
                          .toUpperCase(),
                      style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white),
                    ),
                    StatefulBuilder(
                      builder: (context, setPriceState) {
                        void adjustPrice(double delta) {
                          Common().vibrate();
                          setPriceState(() {
                            _selectedPrice += delta;
                            if (_selectedPrice < 0) _selectedPrice = 0;
                            _priceController.text =
                                _selectedPrice.toStringAsFixed(2);
                          });
                        }

                        void startAdjusting(double delta) {
                          _holdStart = DateTime.now();
                          _holdTimer = Timer.periodic(
                              const Duration(milliseconds: 150), (_) {
                            final holdDuration =
                                DateTime.now().difference(_holdStart!);
                            if (holdDuration.inSeconds >= 3) {
                              adjustPrice(delta * 10);
                            } else {
                              adjustPrice(delta * 1);
                            }
                          });
                        }

                        void stopAdjusting() {
                          _holdTimer?.cancel();
                          _holdTimer = null;
                          _holdStart = null;
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white24),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => adjustPrice(-0.01),
                                onLongPressStart: (_) => startAdjusting(-1.0),
                                onLongPressEnd: (_) => stopAdjusting(),
                                child: const Icon(CupertinoIcons.minus_circle,
                                    color: Colors.redAccent, size: 36),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: SizedBox(
                                  width: _calculateTextWidth(
                                          _priceController.text,
                                          GoogleFonts.montserrat(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          )) +
                                      50,
                                  child: TextFormField(
                                    controller: _priceController,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      prefixText: (widget.isForex
                                          ? ''
                                          : (_currency == "eur"
                                              ? '€ '
                                              : '\$ ')),
                                      prefixStyle: GoogleFonts.montserrat(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      final parsed = double.tryParse(
                                          value.replaceAll(',', '.'));
                                      if (parsed != null && parsed >= 0) {
                                        _selectedPrice = parsed;
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => adjustPrice(0.01),
                                onLongPressStart: (_) => startAdjusting(1.0),
                                onLongPressEnd: (_) => stopAdjusting(),
                                child: const Icon(CupertinoIcons.add_circled,
                                    color: Colors.greenAccent, size: 36),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      (LocalizedStrings.of(context)?.get('atDate') ?? 'At date')
                          .toUpperCase(),
                      style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white),
                    ),
                    Builder(
                      builder: (context) {
                        DateTime minDate =
                            DateTime.now().add(const Duration(days: 3));
                        DateTime selectedDate = minDate;
                        _selectedDate =
                            DateTime(minDate.year, minDate.month, minDate.day);

                        return StatefulBuilder(
                          builder: (context, setStateDate) {
                            return GestureDetector(
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: minDate,
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: Colors.deepPurple,
                                          onPrimary: Colors.white,
                                          surface: Colors.black,
                                          onSurface: Colors.white,
                                        ),
                                        dialogTheme: DialogThemeData(
                                            backgroundColor: Colors.grey[900]),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (pickedDate != null) {
                                  setStateDate(() {
                                    selectedDate = pickedDate;
                                    _selectedDate = DateTime(selectedDate.year,
                                        selectedDate.month, selectedDate.day);
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Text(
                                  "${selectedDate.day.toString().padLeft(2, '0')}/"
                                  "${selectedDate.month.toString().padLeft(2, '0')}/"
                                  "${selectedDate.year}",
                                  style: GoogleFonts.openSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  (LocalizedStrings.of(context)?.get('toWin') ?? 'To earn')
                      .toUpperCase(),
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.white),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xCCFFE082), Color(0xCCFFB300)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 10),
                      Text(
                        NumberFormat('#,##0', 'es').format(Config.priceBetPrize),
                        style: GoogleFonts.syncopate(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Image(
                        image: AssetImage('assets/coin.png'),
                        width: 50,
                        height: 50,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    _showHowItWorksDialog();
                  },
                  child: Text(
                    (LocalizedStrings.of(context)?.get('howItWorks') ?? 'How does it work?')
                        .toUpperCase(),
                    style: GoogleFonts.syncopate(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Spacer(),
                StatefulBuilder(
                  builder: (context, setAcceptState) {
                    void updateMargin(String newMargin) {
                      Common().vibrate();
                      _selectedMargin = newMargin;
                      _isAcceptEnabled =
                          _getBetAmountFromMargin(_selectedMargin) <=
                              _userPoints;
                      setAcceptState(() {});
                    }

                    return Column(
                      children: [
                        Text(
                          (LocalizedStrings.of(context)!
                                  .get('selectPriceMargin') ??
                              "Select the price margin "),
                          style: GoogleFonts.syncopate(
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w200,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildMarginButtons(context, updateMargin),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "${LocalizedStrings.of(context)?.get('enterBetAmount') ?? 'Bet amount'}: ",
                                style: GoogleFonts.syncopate(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w200,
                                  color: _isAcceptEnabled
                                      ? Colors.white
                                      : Colors.red,
                                ),
                              ),
                              TextSpan(
                                text: _getBetAmountFromMargin(_selectedMargin)
                                    .toString(),
                                style: GoogleFonts.syncopate(
                                  decoration: _isAcceptEnabled
                                      ? TextDecoration.none
                                      : TextDecoration.underline,
                                  decorationColor: Colors.red,
                                  decorationThickness: 1,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: _isAcceptEnabled
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 6, bottom: 4),
                                  child: Image(
                                    image: AssetImage('assets/coin.png'),
                                    width: 25,
                                    height: 25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildSecondaryButtons(context, _isAcceptEnabled),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
