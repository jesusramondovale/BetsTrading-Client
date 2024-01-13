import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../helpers/common.dart';

class InvestmentScreen extends StatelessWidget {
  InvestmentScreen({super.key});

  final List<FlSpot> _spots = Common().createRandomSpots(15);

  @override
  Widget build(BuildContext context) {
    Future<InvestmentsList> investmentData = fetchInvestmentData();
    final strings = LocalizedStrings.of(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16,6,16,16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              strings?.wallet ?? 'My wallet',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<InvestmentsList>(
              future: investmentData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  final data = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.totalValue.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${data.totalChange >= 0 ? "↑" : "↓"}${data.totalChange.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color:
                              data.totalChange >= 0 ? Colors.green : Colors.red,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Text('No data available');
                }
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots,
                      isCurved: true,
                      color: Common().isBullSpots(_spots)
                          ? Colors.green
                          : Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              strings?.recentBets ?? 'Recent bets',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Padding(padding: EdgeInsets.all(6.0),),
            Expanded(
              child: FutureBuilder<InvestmentsList>(
                future: investmentData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData) {
                    final data = snapshot.data!;
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: Image.asset(
                              data.investList[index].iconPath,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            data.investList[index].name,
                            style: const TextStyle(fontSize: 18),
                          ),
                          subtitle: Text(
                            '${data.investList[index].value.toStringAsFixed(2)} €',
                            style: const TextStyle(fontSize: 16),
                          ),
                          trailing: Text(
                            data.investList[index].change,
                            style: TextStyle(
                              color: data.investList[index].change.contains('↑')
                                  ? Colors.green
                                  : data.investList[index].change.contains('↓')
                                      ? Colors.red
                                      : Colors.grey, // Default color if no ↑ or ↓ is present
                              fontSize: 18,
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Text('No data available');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<InvestmentsList> fetchInvestmentData() async {
    await Future.delayed(const Duration(seconds: 1));

    List<InvestmentData> investments = [
      InvestmentData(
        name: 'Core S&P 500 USD (Acc)',
        value: 49.18,
        change: '↓0,82%',
        iconPath: 'assets/sp.png',
      ),
      InvestmentData(
        name: 'MSCI World',
        value: 155.26,
        change: '↑0.4%',
        iconPath: 'assets/msci.png',
      ),
      InvestmentData(
        name: 'FOREX (EURUSD)',
        value: 1.095,
        change: '↓0.12%',
        iconPath: 'assets/forex.png',
      ),
      InvestmentData(
        name: 'iShares NASDAQ',
        value: 89.85,
        change: '↑1.82%',
        iconPath: 'assets/nasdaq.png',
      ),
      InvestmentData(
        name: 'Bitcoin',
        value: 35612.18,
        change: '↓0.6%',
        iconPath: 'assets/bitcoin.png',
      ),
      InvestmentData(
        name: 'FOREX (EURUSD)',
        value: 1.095,
        change: '↓0.12%',
        iconPath: 'assets/forex.png',
      ),
      InvestmentData(
        name: 'iShares NASDAQ',
        value: 89.85,
        change: '↑1.82%',
        iconPath: 'assets/nasdaq.png',
      ),
      InvestmentData(
        name: 'Bitcoin',
        value: 35612.18,
        change: '↓0.6%',
        iconPath: 'assets/bitcoin.png',
      ),
    ];

    double totalValue = investments.fold(0, (sum, item) => sum + item.value);
    double totalChange = 1.82;

    return InvestmentsList(totalValue, totalChange, investments.length, investList: investments);
  }
}

class InvestmentsList {
  final List<InvestmentData> investList;
  final double totalValue;
  final double totalChange;
  final int length;

  InvestmentsList(this.totalValue, this.totalChange, this.length,
      {required this.investList});
}

class InvestmentData {
  final String name;
  final double value;
  final String change;
  final String iconPath;

  InvestmentData({
    required this.name,
    required this.value,
    required this.change,
    required this.iconPath,
  });
}
