import 'package:client_0_0_1/services/AssetsService.dart';
import 'package:flutter/material.dart';

import '../enums/financial_assets.dart';
import '../locale/localized_texts.dart';
import 'candlesticks_view.dart';

class FinancialAssetsView extends StatefulWidget {
  const FinancialAssetsView({super.key});

  @override
  FinancialAssetsViewState createState() => FinancialAssetsViewState();
}

class FinancialAssetsViewState extends State<FinancialAssetsView> {
  String? selectedGroup;
  List<String> groups = [];
  List<FinancialAsset> assets = [];
  late BuildContext _context;
  int groupId = 1;

  @override
  void initState() {
    super.initState();
    selectedGroup = 'ETFs';

    _loadAssets(groupId);
  }

  Future<void> _initGroups() async {
    final strings = LocalizedStrings.of(_context);
    groups = [
      'ETFs',
      strings?.indexes ?? 'Indexes',
      'Cryptos',
      strings?.shares ?? 'Shares',
      strings?.commodities ?? 'Commodities',
    ];
  }

  void _loadAssets(int id) {
    String theGroup = '';
    switch (id){
      case 0: theGroup = 'ETFs';
      case 1: theGroup = 'Indexes';
      case 2: theGroup = 'Cryptos';
      case 3: theGroup = 'Shares';
      case 4: theGroup = 'Commodities';
    }

    AssetsService().getFinancialAssetsByGroup(theGroup).then((assets) {
      setState(() {
        this.assets = assets!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _context = context;

    return FutureBuilder(
      future: _initGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _buildContent(groupId);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildContent(groupId) {
    return Column(
      children: [
        DropdownButton<String>(
          value: selectedGroup,
          onChanged: (value) {
            setState(() {
              selectedGroup = value!;
              groupId = groups.indexOf(selectedGroup!);
              print("$groupId");
              _loadAssets(groupId!);
            });
          },
          items: groups.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              FinancialAsset asset = assets[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SafeArea(
                        child: CandlesticksView(asset.id),
                      ),
                    ),
                  );
                },
                child: ListTile(
                  leading: asset.icon.isNotEmpty
                      ? asset.imageFromBase64String()
                      : null,
                  title: Text(
                    asset.name,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${asset.group} - ${asset.country}',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  contentPadding: const EdgeInsets.only(left: 16),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
