import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../helpers/common.dart';
import 'package:client_0_0_1/locale/localized_texts.dart';

class StockMarketHomePage extends StatelessWidget {

  const StockMarketHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle sectionTitleStyle = const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w300,
      color: Colors.indigo,
    );
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      body: CustomScrollView(

        slivers: <Widget>[
          SliverAppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: true,
            snap: true,
            backgroundColor: Colors.white.withOpacity(1),
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildBalanceSection(sectionTitleStyle, context),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSectionTitle(strings?.favs ?? 'Favourites', sectionTitleStyle),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                return _buildStockItem(
                  'Stock ${index + 1}',
                  '€${(1000 + Random().nextInt(1000)).toStringAsFixed(2)}',
                  '${Random().nextBool() ? '' : '-'}${(Random().nextDouble() * 10).toStringAsFixed(2)}%',
                  Random().nextBool(),
                  Common().createRandomSpots(5),
                );
              },
              childCount: 2,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSectionTitle(strings?.mostCommon ?? 'Most common', sectionTitleStyle),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                return _buildStockItem(
                  'Common ${index + 1}',
                  '€${(1000 + Random().nextInt(1000)).toStringAsFixed(2)}',
                  '${Random().nextBool() ? '' : '-'}${(Random().nextDouble() * 10).toStringAsFixed(2)}%',
                  Random().nextBool(),
                  Common().createRandomSpots(5),
                );
              },
              childCount: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(TextStyle titleStyle, context) {
    final strings = LocalizedStrings.of(context);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings?.currentBalance ?? 'Current Balance', style: titleStyle),
              const Text(
                '€15,230.50 (+5.3%)',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          _buildMiniLineChart(Common().createRandomSpots(5))
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, TextStyle titleStyle) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(title, style: titleStyle),
    );
  }

  Widget _buildStockItem(
      String title, String price, String percentage, bool isPositive, List<FlSpot> spots) {
      TextStyle subtitleStyle = TextStyle(
        fontSize: 16,
        color: Colors.indigo[800],
      );

      TextStyle valueStyle = const TextStyle(
        fontSize: 16,
        color: Colors.black54,
      );

      TextStyle percentageStyle = TextStyle(
        color: isPositive ? Colors.green : Colors.red,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1.3),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex:3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(title, style: subtitleStyle),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(right: 26.0),
                  child: _buildMiniLineChart(spots),
                )
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: valueStyle),
                    const SizedBox(height: 4),
                    Text(percentage, style: percentageStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMiniLineChart(List<FlSpot> spots) {
    return SizedBox(
      width: 60,
      height: 20,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Common().isBullSpots(spots) ? Colors.green : Colors.red,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
