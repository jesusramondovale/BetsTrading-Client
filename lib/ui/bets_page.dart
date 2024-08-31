import 'dart:convert';
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

  void _calculatePotentialPrize(String value) {
    setState(() {
      _betAmount = double.tryParse(value) ?? 0.0;
      _potentialPrize = _betAmount * widget.bet.targetOdds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Confirm Order',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBetHeader(context),
                  const SizedBox(height: 5),
                  _buildBetDetails(context),
                  const SizedBox(height: 20),
                  _buildBetMultiplier(context),
                  const SizedBox(height: 10),
                  _buildPotentialPrize(context),
                ],
              ),
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildBetHeader(BuildContext context) {
    return Row(
      children: [
        if (widget.bet.iconPath != "null") ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.memory(
              base64Decode("iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAIAAADTED8xAAADMElEQVR4nOzVwQnAIBQFQYXff81RUkQCOyDj1YOPnbXWPmeTRef+/3O/OyBjzh3CD95BfqICMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMK0CMO0TAAD//2Anhf4QtqobAAAAAElFTkSuQmCC"),
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
        ],
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bet.name,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ticker: ${widget.bet.ticker}',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
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
          size: 80,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black, // Color asegurado para contrastar con el fondo
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBetMultiplier(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Multiplier: x${widget.bet.targetOdds.toStringAsFixed(2)}',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Enter Bet Amount',
            labelStyle: GoogleFonts.montserrat(),
            border: const OutlineInputBorder(),
          ),
          onChanged: _calculatePotentialPrize,
        ),
      ],
    );
  }

  Widget _buildPotentialPrize(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Potential Prize:',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: widget.onCancel,
            icon: Icon(CupertinoIcons.clear, color: Colors.black),
            label: Text(
              'Cancel',
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
            onPressed: widget.onAccept,
            icon: Icon(CupertinoIcons.check_mark, color: Colors.black),
            label: Text(
              'Accept',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[300],
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
