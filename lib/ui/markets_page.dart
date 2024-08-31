import 'dart:convert';

import 'package:client_0_0_1/services/AssetsService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../enums/financial_assets.dart';
import '../locale/localized_texts.dart';
import 'candlesticks_view.dart';
import 'layout_page.dart';

class MarketsView extends StatefulWidget {
  final MainMenuPageController controller;
  const MarketsView({super.key, required this.controller});

  @override
  MarketsViewState createState() => MarketsViewState();
}

class MarketsViewState extends State<MarketsView> {
  String? selectedGroup;
  List<String> groups = [];
  List<FinancialAsset> assets = [];
  late BuildContext _context;
  int groupId = 0;

  @override
  void initState() {
    super.initState();
    _loadAssets(groupId);
  }

  Future<void> _initGroups() async {
    final strings = LocalizedStrings.of(_context);
    groups = [
      strings?.shares ?? 'Shares',
       'ETFs',
      'Cryptos',
      strings?.indexes ?? 'Indexes',
      strings?.commodities ?? 'Commodities',
    ];
    if (selectedGroup == null && groups.isNotEmpty) {
      selectedGroup = groups.first;
    }
  }

  void _loadAssets(int id) {
    String? theGroup;
    switch (id) {
      case 0:
        theGroup = 'Shares';
        break;
      case 1:
        theGroup = 'ETFs';
        break;
      case 2:
        theGroup = 'Cryptos';
        break;
      case 3:
        theGroup = 'Indexes';
        break;
      case 4:
        theGroup = 'Commodities';
        break;
    }

    if (theGroup != null) {
      AssetsService().getFinancialAssetsByGroup(theGroup).then((newAssets) {
        setState(() {
          assets = newAssets ?? [];
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _context = context;

    return FutureBuilder(
      future: _initGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _buildContent();
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  void _onGroupChanged(String? newValue) {
    if (newValue == null) return;

    setState(() {
      selectedGroup = newValue;
      groupId = groups.indexOf(newValue);
      debugPrint('Selected group ID: $groupId');
      _loadAssets(groupId);
    });
  }

  List<DropdownMenuItem<String>> _buildDropdownMenuItems() {
    return groups.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
        alignment: Alignment.center,
      );
    }).toList();
  }

  Widget _buildContent() {
    Color dropDownColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    return Column(
      children: [
        Center(
          child: Container(

            child: DropdownButton<String>(
              value: selectedGroup,
              underline: SizedBox.shrink(),
              onChanged: _onGroupChanged,
              items: _buildDropdownMenuItems(),
              style: GoogleFonts.montserrat(
                color: dropDownColor,
                fontSize: 30.0,
                fontWeight: FontWeight.normal,
              ),
              dropdownColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              elevation: 16,
              borderRadius: BorderRadius.circular(25),
              isExpanded: false,
              iconEnabledColor: dropDownColor,
              iconDisabledColor: Colors.grey,
              itemHeight: 60,
              icon: Icon(Icons.arrow_drop_down_rounded, color: dropDownColor, size: 65),
              alignment: Alignment.center,

            ),
          ),
        ),

        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 7.0,
              childAspectRatio: 1.0,
            ),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final FinancialAsset asset = assets[index];
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(25.0),
                        ),
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            maxHeight: MediaQuery.of(context).size.height,
                            child: Column(
                              children: [
                                Expanded(
                                  child: CandlesticksView(asset.id.toString(), asset.name, controller: widget.controller,),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.black45,
                        blurRadius: 5.0,
                        spreadRadius: 5.0,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (asset.icon.isNotEmpty)
                        Image.memory(base64Decode(asset.icon), height: 55),
                      SizedBox(height: 10),
                      Text(
                        asset.name,
                        maxLines: 1,
                        style: GoogleFonts.comfortaa(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),


                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


}
