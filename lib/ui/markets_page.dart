import 'dart:convert';
import 'package:betrader/services/AssetsService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../enums/financial_assets.dart';
import '../helpers/common.dart';
import '../locale/localized_texts.dart';
import 'candlesticks_view.dart';
import 'layout_page.dart';

class MarketsView extends StatefulWidget {
  final MainMenuPageController controller;

  const MarketsView({super.key, required this.controller});

  @override
  MarketsViewState createState() => MarketsViewState();
}

class MarketsViewState extends State<MarketsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> groups = [];
  List<FinancialAsset> assets = [];
  int groupId = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadAssets(_tabController.index);
      }
    });
    _loadAssets(groupId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initGroups() {
    final strings = LocalizedStrings.of(context);
    groups = [
      strings?.shares ?? 'Shares',
      'Crypto',
      strings?.indexes ?? 'Indexes',
      strings?.commodities ?? 'Commodities',
    ];
  }

  void _loadAssets(int id) {
    String? theGroup;
    setState(() {
      _isLoading = true;
    });
    switch (id) {
      case 0:
        theGroup = 'Shares';
        break;
      case 1:
        theGroup = 'Cryptos';
        break;
      case 2:
        theGroup = 'Indexes';
        break;
      case 3:
        theGroup = 'Commodities';
        break;
    }

    if (theGroup != null) {
      AssetsService().getFinancialAssetsByGroup(theGroup).then((newAssets) {
        setState(() {
          assets = newAssets ?? [];
          _isLoading = false;
        });
      });
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initGroups();  // Mover aquí la inicialización de los grupos
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelStyle: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
              labelPadding: EdgeInsets.fromLTRB(0.0, 0.0,8.0, 0.0),
              unselectedLabelStyle: GoogleFonts.montserrat(
                fontSize: 16, // Tamaño más pequeño para los Tabs no seleccionados
                fontWeight: FontWeight.w300,
              ),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: groups.map((String group) => Tab(text: group)).toList(),
            ),
          ],
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
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
                          height:
                          MediaQuery.of(context).size.height * 0.55,
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            maxHeight: MediaQuery.of(context).size.height,
                            child: Column(
                              children: [
                                Expanded(
                                  child: CandlesticksView(
                                    ticker: asset.ticker,
                                    name: asset.name,
                                    controller: widget.controller,
                                    iconPath: asset.icon,
                                  ),
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
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness ==
                            Brightness.dark
                            ? Colors.white10
                            : Colors.black45,
                        blurRadius: 5.0,
                        spreadRadius: 2.0,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (asset.icon.isNotEmpty &&
                          asset.icon != "null" &&
                          !asset.icon.startsWith("http")) ...[
                        Image.memory(base64Decode(asset.icon),
                            height: 55),
                      ]
                      else if (asset.icon.isNotEmpty &&
                          asset.icon.startsWith("http")) ...[
                        Image.network((asset.icon), height: 55),
                      ]
                      else ...[
                          Text(
                            Common().createTrendViewNameFromName(asset.name),
                            maxLines: 1,
                            style: GoogleFonts.roboto(
                                fontSize: 36, fontWeight: FontWeight.w100),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      SizedBox(height: 10),
                      Text(
                        asset.name,
                        maxLines: 1,
                        style: GoogleFonts.montserrat(
                            fontSize: 14, fontWeight: FontWeight.w400),
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
