import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../helpers/common.dart';


class PortfolioScreenPage extends StatefulWidget {
  const PortfolioScreenPage({super.key});

  @override
  _PortfolioPageState createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioScreenPage>{

  @override
  void initState() {
    super.initState();
    const FlutterSecureStorage _storage = FlutterSecureStorage();
  }

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '49,18 €',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                '+0,28 %',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_upward, color: Colors.green.shade600),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildMiniLineChart(Common().createRandomSpots(5)),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Inversiones',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const InvestmentCard(
          title: 'Core S&P 500 USD (Acc)',
          value: '49,18 €',
          change: '-0,82 €',

        ),
      ],
    );
  }

  Widget _buildMiniLineChart(List<FlSpot> spots) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9, // use the full width of the screen
      height: 100, // give more height to the chart
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
              barWidth: 3,
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


class LineChartSample2 extends StatelessWidget {
  const LineChartSample2({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 1),
                const FlSpot(1, 3),
                const FlSpot(2, 10),
              ],
              isCurved: true,
              barWidth: 5,
              color: Colors.blue,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
    );
  }
}

class InvestmentCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;

  const InvestmentCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        trailing: Text(
          change,
          style: TextStyle(
            color: change.startsWith('-') ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }
}