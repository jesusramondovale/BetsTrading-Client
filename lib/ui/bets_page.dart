import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';  // Necesario para DateFormat

import '../locale/localized_texts.dart';
import '../models/bets.dart';

class BetConfirmationPage extends StatefulWidget {
  final Bet bet;
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const BetConfirmationPage({
    Key? key,
    required this.bet,
    required this.onAccept,
    required this.onCancel,
  }) : super(key: key);

  @override
  _BetConfirmationPageState createState() => _BetConfirmationPageState();
}

class _BetConfirmationPageState extends State<BetConfirmationPage> {
  double _betAmount = 0.0;
  double _potentialPrize = 0.0;
  bool _isAcceptButtonEnabled = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _betAmountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _betAmountFocusNode.addListener(() {
      if (_betAmountFocusNode.hasFocus) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _betAmountFocusNode.dispose();
    super.dispose();
  }

  void _calculatePotentialPrize(String value) {
    setState(() {
      _betAmount = double.tryParse(value) ?? 0.0;
      _potentialPrize = _betAmount * widget.bet.targetOdds;
      _isAcceptButtonEnabled = _betAmount > 0.00999;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.black,
        title: Text(strings?.confirmOperation ?? 'Confirm Order',

          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.memory(
              base64Decode(widget.bet.iconPath),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Desenfoque
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          // Contenido de la página
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBetHeader(context),
                      const SizedBox(height: 2),
                      _buildBetDetails(context),
                      _buildBetMultiplier(context),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildPotentialPrize(context),
                ],
              ),
              _buildActionButtons(context),
            ],
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _buildBetHeader(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bet.name,
                style: GoogleFonts.openSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 34,
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ticker: ${widget.bet.ticker}',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBetDetails(BuildContext context) {
    final strings = LocalizedStrings.of(context);

    return GridView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 10),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 1.0,
        mainAxisSpacing: 0.0,
        childAspectRatio: 1,
      ),
      children: [
        _buildGridItem(
          context,
          icon: Icons.update,
          value: '${widget.bet.originValue.toStringAsFixed(2)}€',
          label: strings?.originValue ?? "Origin value",
        ),
        _buildGridItem(
          context,
          icon: Icons.crop_sharp,
          value: '${widget.bet.targetValue.toStringAsFixed(2)}€',
          label: strings?.targetValue ?? "Target value",
        ),
        _buildGridItem(
          context,
          icon: Icons.date_range,
          value: DateFormat('dd-MM-yyyy').format(widget.bet.targetDate),
          label: strings?.targetDate ?? "Target date",
        ),
        _buildGridItem(
          context,
          icon: Icons.data_object_sharp,
          value: '${widget.bet.targetMargin.toStringAsFixed(2)}%',
          label: strings?.targetMargin ?? "Target margin",
        ),
      ],
    );
  }

  Widget _buildGridItem(
      BuildContext context, {
        required IconData icon,
        required String value,
        required String label,
      }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 70,
          color: Colors.white
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color:  Colors.white
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white70
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBetMultiplier(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final multiplierString = strings?.multiplier ?? "Multiplier";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${multiplierString} x${widget.bet.targetOdds.toStringAsFixed(2)}',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color:  Colors.white
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              strings?.enterBetAmount ?? 'Enter Bet Amount',
              style: GoogleFonts.montserrat(fontSize: 20.0, color: Colors.white),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                textAlign: TextAlign.end,
                style: GoogleFonts.montserrat(fontSize: 20.0, fontWeight: FontWeight.w800, color: Colors.greenAccent),
                cursorColor: Colors.white,
                focusNode: _betAmountFocusNode,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  focusColor: Colors.white,
                  suffixIcon: Icon(CupertinoIcons.money_euro, size: 30, color: Colors.white),
                ),
                onChanged: _calculatePotentialPrize,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPotentialPrize(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, right: 50.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            strings?.potentialPrize ?? 'Potential Prize:',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color:  Colors.white
            ),
          ),
          Text(
            '${_potentialPrize.toStringAsFixed(2)}€',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.greenAccent
                  : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAcceptPressed() {
    if (!_isAcceptButtonEnabled) {
      _betAmountFocusNode.requestFocus();
      setState(() {});
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {});
      });
    } else {
      widget.onAccept();
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: widget.onCancel,
            icon: Icon(CupertinoIcons.clear, color: Colors.black),
            label: Text(strings?.cancel ?? 'Cancel',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isAcceptButtonEnabled ? widget.onAccept : _handleAcceptPressed,
            icon: Icon(CupertinoIcons.check_mark, color: Colors.black),
            label: Text(strings?.accept ?? 'Accept',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAcceptButtonEnabled ? Colors.green[300] : Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
