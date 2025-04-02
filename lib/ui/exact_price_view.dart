import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/BetsService.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import 'layout_page.dart';

class ExactPricePage extends StatefulWidget {
  final double currentValue;
  final String iconPath;
  final String ticker;
  final String name;

  const ExactPricePage({
    super.key,
    required this.name,
    required this.currentValue,
    required this.ticker,
    required this.iconPath,
  });

  @override
  State<ExactPricePage> createState() => _ExactPricePageState();
}

class _ExactPricePageState extends State<ExactPricePage> {
  double _selectedPrice = 0.0;
  DateTime _selectedDate = DateTime.now();
  Timer? _holdTimer;
  DateTime? _holdStart;
  String _selectedMargin = "0%";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  double _userPoints = 0.0;
  bool _isAcceptEnabled = false;

  @override
  void initState() {
    super.initState();
    _selectedPrice = widget.currentValue;
    _loadUserPoints();
  }

  Future<void> _loadUserPoints() async {
    final String? pointsStr = await _storage.read(key: 'points');
    setState(() {
      _userPoints = double.tryParse(pointsStr ?? '0') ?? 0.0;
      _isAcceptEnabled =
          _getBetAmountFromMargin(_selectedMargin) <= _userPoints;
    });
  }

  int _getBetAmountFromMargin(String margin) {
    switch (margin) {
      case "0%":
        return 200;
      case "1%":
        return 350;
      case "5%":
        return 500;
      case "7.5%":
        return 800;
      case "10%":
        return 1500;
      default:
        return 0;
    }
  }

  double _getMarginAsDouble(String margin) {
    switch (margin) {
      case "0%":
        return 0.0;
      case "1%":
        return 0.01;
      case "5%":
        return 0.05;
      case "7.5%":
        return 0.075;
      case "10%":
        return 0.1;
      default:
        return 0.0;
    }
  }

  Widget _buildMarginButtons(
      BuildContext context, void Function(String) onMarginChanged) {
    final List<String> options = ["0%", "1%", "5%", "7.5%", "10%"];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: StatefulBuilder(
        builder: (context, setStateMargin) {
          return Row(
            children: options.map((text) {
              final bool isSelected = _selectedMargin == text;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
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
                Common().vibrate(40, 30);
                Navigator.pop(context, null);
              },
              icon: Icon(CupertinoIcons.arrow_uturn_left, color: Colors.black),
              label: Text(
                maxLines: 1,
                strings?.cancel ?? 'Cancel',
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
                      Common().vibrate(40, 30);
                      //TODO
                      final prefs = await SharedPreferences.getInstance();
                      bool _bettingNotifications = prefs.getBool('bettingNotifications') ?? true;

                      FocusScope.of(context).unfocus();

                      bool? confirmed = await Common().popConfirmOperationDialog(context,  _getBetAmountFromMargin(_selectedMargin).toDouble(), widget.iconPath);
                      if (confirmed == true) {
                        String? userId = await _storage.read(key: 'sessionToken');
                        int result = await BetsService().postNewExactPriceBet(userId!, widget.ticker, _selectedPrice,
                            _getMarginAsDouble(_selectedMargin), _selectedDate);

                        if (result == 200) {
                          if (_bettingNotifications) {
                            Common().showLocalNotification(
                                "betting",
                                "Betrader",
                                (LocalizedStrings.of(context)!.betPlacedSuccessfully != null
                                    ? "${LocalizedStrings.of(context)!.betPlacedSuccessfully} (${_getBetAmountFromMargin(_selectedMargin).toStringAsFixed(2)}฿)"
                                    : "Bet placed successfully! (${_getBetAmountFromMargin(_selectedMargin)}฿)"),
                                {"TICKER": widget.ticker, "BET_AMOUNT": _getBetAmountFromMargin(_selectedMargin)});
                          }

                          await BetsService().getUserInfo(userId);

                          Navigator.pop(context);
                          Navigator.pop(context);
                          homeScreenKey.currentState?.loadUserIdAndData();
                        }
                        else if (result == 410){
                          Common().showLocalNotification(
                              "betting",
                              "Error",
                              (LocalizedStrings.of(context)!.errorMakingBet ??
                                  "Error creating price bet!") + " (NO TIME)",
                              {"ERROR_CODE": "BET-ERR-NOT-ENOUGH-TIMEE"});

                        }
                        else {
                          if (_bettingNotifications) {
                            Common().showLocalNotification(
                                "betting",
                                "Error",
                                (LocalizedStrings.of(context)!.errorMakingBet ??
                                    "Error creating price bet!"),
                                {"ERROR_CODE": "BET-ERR-002"});
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
                strings?.accept ?? 'Accept',
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.iconPath == "null"
                ? Image.asset('assets/logo_simple.png', fit: BoxFit.cover)
                : (widget.iconPath.startsWith("http")
                    ? Image.network(
                        widget.iconPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/logo_simple.png',
                                fit: BoxFit.cover),
                      )
                    : Image.memory(
                        base64Decode(widget.iconPath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/logo_simple.png',
                                fit: BoxFit.cover),
                      )),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
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
                      '${widget.currentValue.toStringAsFixed(2)}€',
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.w200,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    StatefulBuilder(
                      builder: (context, setPriceState) {
                        void adjustPrice(double delta) {
                          Common().vibrate(40, 30);
                          setPriceState(() {
                            _selectedPrice += delta;
                            if (_selectedPrice < 0) _selectedPrice = 0;
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
                                child: Text(
                                  _selectedPrice.toStringAsFixed(2) + "€",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                    Builder(
                      builder: (context) {
                        DateTime minDate =
                            DateTime.now().add(const Duration(days: 3));
                        DateTime selectedDate = minDate;
                        _selectedDate = minDate;

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
                                        dialogBackgroundColor: Colors.grey[900],
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (pickedDate != null) {
                                  setStateDate(() {
                                    selectedDate = pickedDate;
                                    _selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
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
                const Spacer(),
                StatefulBuilder(
                  builder: (context, setAcceptState) {
                    void updateMargin(String newMargin) {
                      Common().vibrate(40, 30);
                      _selectedMargin = newMargin;
                      _isAcceptEnabled =
                          _getBetAmountFromMargin(_selectedMargin) <=
                              _userPoints;
                      setAcceptState(() {});
                    }

                    return Column(
                      children: [
                        Text(
                          "${LocalizedStrings.of(context)?.enterBetAmount ?? 'Bet amount'}: ${_getBetAmountFromMargin(_selectedMargin)} ฿",
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w200,
                            color:
                                _isAcceptEnabled ? Colors.white70 : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildMarginButtons(context, updateMargin),
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
