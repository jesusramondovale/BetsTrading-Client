import 'dart:convert';

import 'package:client_0_0_1/services/AssetsService.dart';
import 'package:flutter/material.dart';

import '../enums/financial_assets.dart';
import '../locale/localized_texts.dart';
import 'candlesticks_view.dart';

class MarketsView extends StatefulWidget {
  const MarketsView({super.key});

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
    _loadAssets(groupId); // Load assets initially with default groupId
  }

  Future<void> _initGroups() async {
    final strings = LocalizedStrings.of(_context);
    groups = [
      strings?.indexes ?? 'Indexes', // Assuming these are non-nullable fields
      'ETFs',
      'Cryptos',
      strings?.shares ?? 'Shares',
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
        theGroup = 'Indexes';
        break;
      case 1:
        theGroup = 'ETFs';
        break;
      case 2:
        theGroup = 'Cryptos';
        break;
      case 3:
        theGroup = 'Shares';
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      );
    }).toList();
  }

  Widget _buildContent() {
    return Column(
      children: [
        DropdownButton<String>(
          value: selectedGroup,
          onChanged: _onGroupChanged,
          items: _buildDropdownMenuItems(),
          style: const TextStyle(
            color: Colors.deepPurpleAccent,
            fontSize: 28.0,
            fontWeight: FontWeight.normal,
          ),
          icon: const Icon(Icons.arrow_drop_down,
              color: Colors.deepPurpleAccent, size: 45),
          underline: Container(height: 1, color: Colors.deepPurpleAccent),
          dropdownColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          elevation: 16,
          borderRadius: BorderRadius.circular(25),
          isExpanded: true,
          iconEnabledColor: Colors.deepPurple,
          iconDisabledColor: Colors.grey,
          itemHeight: 60,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final FinancialAsset asset = assets[index];
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
                      ? Image.memory(base64Decode(asset.icon))
                      : null,
                  title: Text(asset.name),
                  subtitle: Text('${asset.group} - ${asset.country}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
