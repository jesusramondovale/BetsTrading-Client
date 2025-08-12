import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/BetsService.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import '../services/FirebaseService.dart';
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
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPrice = widget.currentValue;
    _priceController.text = _selectedPrice.toStringAsFixed(2);
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

  double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: '\$$text', style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.size.width * 0.75;
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
                      Common().vibrate(40, 30);
                      final prefs = await SharedPreferences.getInstance();
                      bool _bettingNotifications =
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
                        int result = await BetsService().postNewExactPriceBet(
                            userId!,
                            fcm,
                            widget.ticker,
                            _selectedPrice,
                            _getMarginAsDouble(_selectedMargin),
                            _selectedDate);

                        if (result == 200) {
                          if (_bettingNotifications) {
                            Common().showFloatingSnack(context,
                                (LocalizedStrings.of(context)!.get('betPlacedSuccessfully') != null ? "${LocalizedStrings.of(context)!.get('betPlacedSuccessfully')} ► ${_getBetAmountFromMargin(_selectedMargin).toStringAsFixed(2)}"
                                    : "Bet placed successfully! ► ${_getBetAmountFromMargin(_selectedMargin)}"),
                                showIcon: true);

                          }

                          await BetsService().getUserInfo(userId);
                          Navigator.pop(context);
                          Navigator.pop(context);
                          homeScreenKey.currentState?.loadUserIdAndData();
                          exchangePageKey.currentState?.loadData();
                        } else if (result == 410) {
                          Common().showFloatingSnack(context, (LocalizedStrings.of(context)!.get('errorMakingBet') ?? "Error creating price bet!") + "(NO TIME)", backgroundColor: Colors.red);
                        } else if (result == 420) {
                          Common().showFloatingSnack(context, (LocalizedStrings.of(context)!.get('betErrorPoints') ?? "Not enough points!"), backgroundColor: Colors.red);
                        } else if (result == 430) {
                          Common().showFloatingSnack(context, (LocalizedStrings.of(context)!.get('betAlreadyExists') ?? "Bet already exists!"), backgroundColor: Colors.red);
                        } else {
                          if (_bettingNotifications) {
                            Common().showFloatingSnack(context, (LocalizedStrings.of(context)!.get('errorMakingBet') ?? "Error creating price bet!"), backgroundColor: Colors.red);
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
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withValues(alpha: 0.7)),
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
                      "${LocalizedStrings.of(context)?.get('nowLabel') ?? 'Now:'}",
                      style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w200,
                          color: Colors.white),
                    ),
                    Text(
                      '\$ ${widget.currentValue.toStringAsFixed(2)}', //TODO
                      style: GoogleFonts.montserrat(
                          fontSize: 36,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      ("${LocalizedStrings.of(context)?.get('exactClosingValue') ?? 'Exact closing value'}")
                          .toUpperCase(),
                      style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white),
                    ),
                    StatefulBuilder(
                      builder: (context, setPriceState) {
                        void adjustPrice(double delta) {
                          Common().vibrate(40, 30);
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
                                      prefixText: '\$',
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
                      ("${LocalizedStrings.of(context)?.get('atDate') ?? 'At date'}")
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
                        ;

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
                                        ), dialogTheme: DialogThemeData(backgroundColor: Colors.grey[900]),
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
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "${LocalizedStrings.of(context)?.get('enterBetAmount') ?? 'Bet amount'}: ",
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w200,
                                  color: _isAcceptEnabled
                                      ? Colors.white
                                      : Colors.red,
                                ),
                              ),
                              TextSpan(
                                text: _getBetAmountFromMargin(_selectedMargin)
                                    .toString(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
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
