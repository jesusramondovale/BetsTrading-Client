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
  Map<int, List<FinancialAsset>> assetsPerTab = {}; // Mapa con los activos por pestaña
  bool _isLoading = true; // Se inicializa en true hasta que se carguen todos los datos

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initGroups();
    _loadAllAssets();
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

  void _loadAllAssets() async {
    Map<int, String> groupMapping = {
      0: 'Shares',
      1: 'Cryptos',
      2: 'Indexes',
      3: 'Commodities',
    };

    for (int id = 0; id < groups.length; id++) {
      String? theGroup = groupMapping[id];
      if (theGroup != null) {
        final newAssets = await AssetsService().getFinancialAssetsByGroup(theGroup);
        assetsPerTab[id] = newAssets ?? [];
      }
    }

    setState(() {
      _isLoading = false; // Desactivar loading después de cargar todo
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      verticalDirection: VerticalDirection.up,
      children: [
        TabBar(
          tabAlignment: TabAlignment.center,
          isScrollable: true,
          controller: _tabController,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
          labelPadding: const EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
          unselectedLabelStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
          tabs: groups.map((String group) => Tab(text: group)).toList(),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
            controller: _tabController,
            children: List.generate(groups.length, (index) {
              final List<FinancialAsset> assets = assetsPerTab[index] ?? [];

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5.0,
                  mainAxisSpacing: 7.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: assets.length,
                itemBuilder: (context, assetIndex) {
                  final FinancialAsset asset = assets[assetIndex];
                  return GestureDetector(
                    onTap: () {
                      Common().vibrate(40,30);
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
                        color: Colors.transparent.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white10
                                : Colors.black45,
                            blurRadius: 5.0,
                            spreadRadius: 2.0,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (asset.icon.isNotEmpty &&
                              asset.icon != "null" &&
                              !asset.icon.contains("http")) ...[
                            Image.memory(base64Decode(asset.icon), height: 55,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                    asset.name,
                                    maxLines: 1,
                                    style: GoogleFonts.roboto(
                                        fontSize: 36, fontWeight: FontWeight.w100),
                                    textAlign: TextAlign.center,
                                  ),),
                          ] else if (asset.icon.isNotEmpty &&
                              asset.icon.contains("http")) ...[
                            Image.network(
                                asset.icon,
                                height: 55,
                                errorBuilder: (context, error, StackTrace) =>
                                    Text(
                                      Common().createTrendViewNameFromName(asset.name),
                                      maxLines: 1,
                                      style: GoogleFonts.roboto(
                                          fontSize: 36, fontWeight: FontWeight.w100),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ] else ...[
                            Text(
                              Common().createTrendViewNameFromName(asset.name),
                              maxLines: 1,
                              style: GoogleFonts.roboto(
                                  fontSize: 36, fontWeight: FontWeight.w100),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 10),
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
              );
            }),
          ),
        ),
      ],
    );
  }
}
