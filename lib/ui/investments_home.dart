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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              strings?.totalBet ?? 'total bets',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
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

                  return Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        Text(
                          '${data.totalProfit >= 0 ? "↑" : "↓"}${data.totalProfit.toStringAsFixed(2)}€',
                          style: TextStyle(
                            color: data.totalProfit >= 0 ? Colors.green : Colors.red,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Text('No data available');
                }
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 80,
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
            const SizedBox(height: 15),
            Text(
              strings?.liveBets ?? 'Live bets',
              style: const TextStyle(
                fontSize: 22,
              ),
            ),
            Divider(
                color: Theme.of(context).brightness ==
                    Brightness.dark
                    ? Colors.white
                    : Colors.black,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: 3,
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
                        return Column(
                          children: <Widget>[
                            ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: Image.asset(
                                  data.investList[index].iconPath,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: '${data.investList[index].name} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '(${data.investList[index].betAmount.toStringAsFixed(2)}€ @ ${data.investList[index].originValue})',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '${data.investList[index].targetDate.year}-'
                                          '${data.investList[index].targetDate.month}-'
                                          '${data.investList[index].targetDate.day} @ ${data.investList[index].targetValue} ± ${data.investList[index].targetMargin * 100}%',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).brightness ==
                                              Brightness.dark
                                              ? const Color.fromRGBO(
                                              4, 216, 195, 1)
                                              : Colors.deepPurple,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ]),
                              trailing: Container(
                                padding: const EdgeInsets.fromLTRB(6.0, 2.0, 6.0, 2.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                      Brightness.dark
                                      ? Colors.black
                                      : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 1,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      data.investList[index].targetWon!
                                          ? '✔ ${data.investList[index].currentValue}€'
                                          : '❌ ${data.investList[index].currentValue}€',
                                      style: TextStyle(
                                        color: data.investList[index].targetWon!
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      data.investList[index].profitLoss! > 0
                                          ? '+${data.investList[index].profitLoss}€'
                                          : '${data.investList[index].profitLoss}€',
                                      style: TextStyle(
                                        color:
                                        data.investList[index].profitLoss! >
                                            0
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    return const Text('No data available');
                  }
                },
              ),
            ),
            const SizedBox(height: 15),
            Text(
              strings?.recentBets ?? 'Recent bets',
              style: const TextStyle(
                fontSize: 22,
              ),
            ),
            Divider(
                color: Theme.of(context).brightness ==
                    Brightness.dark
                    ? Colors.white
                    : Colors.black,
                thickness: 0.5,
                height: 0.5),
            Expanded(
              flex: 2,
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
                        return Column(
                          children: <Widget>[
                            ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: Image.asset(
                                  data.investList[index].iconPath,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: '${data.investList[index].name} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '(${data.investList[index].betAmount.toStringAsFixed(2)}€ @ ${data.investList[index].originValue})',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '${data.investList[index].targetDate.year}-'
                                      '${data.investList[index].targetDate.month}-'
                                      '${data.investList[index].targetDate.day} @ ${data.investList[index].targetValue} ± ${data.investList[index].targetMargin * 100}%',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color.fromRGBO(
                                                  4, 216, 195, 1)
                                              : Colors.deepPurple,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ]),
                              trailing: Container(
                                padding: const EdgeInsets.fromLTRB(6.0, 2.0, 6.0, 2.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.black
                                      : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 1,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      data.investList[index].targetWon!
                                          ? '✔ ${data.investList[index].currentValue}€'
                                          : '❌ ${data.investList[index].currentValue}€',
                                      style: TextStyle(
                                        color: data.investList[index].targetWon!
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      data.investList[index].profitLoss! > 0
                                          ? '+${data.investList[index].profitLoss}€'
                                          : '${data.investList[index].profitLoss}€',
                                      style: TextStyle(
                                        color:
                                            data.investList[index].profitLoss! >
                                                    0
                                                ? Colors.green
                                                : Colors.red,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    await Future.delayed(const Duration(milliseconds: 50));

    List<InvestmentData> investments = [
      InvestmentData(
        48.0,
        false,
        -500.0,
        name: 'Core S&P 500 USD (Acc)',
        iconPath: 'assets/sp.png',
        originValue: 45,
        targetValue: 49.18,
        betAmount: 500,
        targetMargin: 0.05,
        targetDate: DateTime.now().add(const Duration(days: 5)),
        targetOdds: 1.75,
      ),
      InvestmentData(
        1555,
        false,
        -1200,
        name: 'MSCI World',
        iconPath: 'assets/msci.png',
        originValue: 1650,
        targetValue: 1600,
        betAmount: 1200,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 15)),
        targetOdds: 3.75,
      ),
      InvestmentData(
        1.11,
        true,
        300,
        name: 'FOREX (EURUSD)',
        iconPath: 'assets/forex.png',
        originValue: 1.08,
        targetValue: 1.10,
        betAmount: 300,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 3)),
        targetOdds: 1.65,
      ),
      InvestmentData(
        751,
        false,
        -300,
        name: 'iShares NASDAQ',
        iconPath: 'assets/nasdaq.png',
        originValue: 750.56,
        targetValue: 755,
        betAmount: 300,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 3)),
        targetOdds: 1.65,
      ),
      InvestmentData(
        35500,
        true,
        4050,
        name: 'Bitcoin',
        iconPath: 'assets/bitcoin.png',
        originValue: 35000,
        targetValue: 35500,
        betAmount: 1200,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 3)),
        targetOdds: 3.65,
      ),
      InvestmentData(
        1.11,
        true,
        300,
        name: 'FOREX (EURUSD)',
        iconPath: 'assets/forex.png',
        originValue: 1.09,
        targetValue: 1.15,
        betAmount: 3000,
        targetMargin: 0.01,
        targetDate: DateTime.now().add(const Duration(days: 7)),
        targetOdds: 7.65,
      ),
      InvestmentData(
        751,
        false,
        -300,
        name: 'Core S&P 500 USD (Acc)',
        iconPath: 'assets/sp.png',
        originValue: 45,
        targetValue: 49.18,
        betAmount: 500,
        targetMargin: 0.05,
        targetDate: DateTime.now().add(const Duration(days: 5)),
        targetOdds: 1.75,
      ),
      InvestmentData(
        751,
        false,
        -300,
        name: 'MSCI World',
        iconPath: 'assets/msci.png',
        originValue: 1650,
        targetValue: 1600,
        betAmount: 1200,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 15)),
        targetOdds: 3.75,
      ),
      InvestmentData(
        1.11,
        true,
        300,
        name: 'FOREX (EURUSD)',
        iconPath: 'assets/forex.png',
        originValue: 1.09,
        targetValue: 1.15,
        betAmount: 3000,
        targetMargin: 0.01,
        targetDate: DateTime.now().add(const Duration(days: 7)),
        targetOdds: 7.65,
      ),
      InvestmentData(
        751,
        false,
        -300,
        name: 'iShares NASDAQ',
        iconPath: 'assets/nasdaq.png',
        originValue: 1650,
        targetValue: 1600,
        betAmount: 300,
        targetMargin: 0.1,
        targetDate: DateTime.now().add(const Duration(days: 3)),
        targetOdds: 1.65,
      ),
    ];

    double totalBetAmount =
        investments.fold(0, (sum, item) => sum + item.betAmount);
    double totalProfit =
        investments.fold(0, (sum, item) => sum + item.profitLoss!);

    return InvestmentsList(totalBetAmount, totalProfit, investments.length,
        investList: investments);
  }
}

class InvestmentsList {
  final List<InvestmentData> investList;
  final double totalBetAmount;
  final double totalProfit;
  final int length;

  InvestmentsList(this.totalBetAmount, this.totalProfit, this.length,
      {required this.investList});
}

class InvestmentData {
  final String name;
  final String iconPath;

  final double betAmount;
  final double originValue;
  final double currentValue;
  final double targetValue;
  final double targetMargin;
  final DateTime targetDate;
  final double targetOdds;

  final bool? targetWon;
  final double? profitLoss;

  InvestmentData(
    this.currentValue,
    this.targetWon,
    this.profitLoss, {
    required this.name,
    required this.iconPath,
    required this.betAmount,
    required this.originValue,
    required this.targetValue,
    required this.targetMargin,
    required this.targetDate,
    required this.targetOdds,
  });
}
