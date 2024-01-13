import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../helpers/common.dart';

class InvestmentScreen extends StatelessWidget {
  InvestmentScreen({super.key});

  final List<FlSpot> _spots = Common().createRandomSpots(15);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Cartera',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '49,18 €',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '↓1,64 %',
              style: TextStyle(
                color: Colors.red,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots,
                      isCurved: true,
                      color: Common().isBullSpots(_spots) ? Colors.green : Colors.red,
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
            const Text(
              'Inversiones',
              style: TextStyle(

                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const ListTile(
              leading: Icon(Icons.pie_chart, color: Colors.blue),
              title: Text(
                'Core S&P 500 USD (Acc)',
                style: TextStyle(fontSize: 18),
              ),
              subtitle: Text(
                '49,18 €',
                style: TextStyle(fontSize: 16),
              ),
              trailing: Text(
                '↓0,82 €',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
