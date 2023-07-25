import 'package:flutter/material.dart';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

class GraphPage extends StatefulWidget {
  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  List<List<dynamic>> _csvData = [];
  Map<String, List<int>> acidentesPorBairro = {};
  Map<String, List<int>> vitimasPorBairro = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    String csvString =
        await rootBundle.loadString('assets/acidentesRecife2015a2021.csv');
    List<List<dynamic>> csvData = CsvToListConverter().convert(csvString);
    setState(() {
      _csvData = csvData;
    });

    _processData();
  }

  void _processData() {
    for (var i = 1; i < _csvData.length; i++) {
      var row = _csvData[i];
      String bairro = row[3];
      int vitimas = row[4];

      if (!acidentesPorBairro.containsKey(bairro)) {
        acidentesPorBairro[bairro] = [];
        vitimasPorBairro[bairro] = [];
      }

      acidentesPorBairro[bairro].add(1);
      vitimasPorBairro[bairro].add(vitimas);
    }
  }

  LineChartOptions _buildChartOptions(List<List<dynamic>> data) {
    List<String> bairros = acidentesPorBairro.keys.toList();

    List<String> titles = ['Acidentes'];
    List<String> xLabels = bairros;

    return LineChartOptions(
      data: data,
      titlesData: ChartTitleData(
        chartTitle: 'Acidentes por bairro',
        chartTitleFontSize: 20,
        subTitle: '',
      ),
      legendOptions: LegendOptions(
        showLegends: true,
        legendPosition: LegendPosition.bottom,
        legendTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      gridOptions: GridOptions(
        showGridLine: true,
        gridLineColor: Colors.grey[300],
        gridLineLabel: true,
        gridLineInterval: 1,
      ),
      lineOptions: LineOptions(
        lineStrokeWidth: 3,
        lineGradient: LinearGradient(
          colors: [
            Colors.blue[800],
            Colors.blue[400],
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        dotOptions: const DotOptions(
          dotSize: 8,
          strokeWidth: 3,
          paint: Paint()..color = Colors.white,
          stroke: Paint()
            ..color = Colors.blueAccent
            ..strokeWidth = 3,
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value) {
    return Container(
      height: 100,
      width: 150,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Acidentes por Bairro'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = _processData(snapshot.data!);
            final averageDailyAccidents =
                _calculateAverageDailyAccidents(snapshot.data!);
            final averageDailyvitimas =
                _calculateAverageDailyvitimas(snapshot.data!);

            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 400,
                    margin: const EdgeInsets.all(16),
                    child: LineChart(
                      options: _buildChartOptions(data),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCard('Média Diária de Acidentes',
                          averageDailyAccidents.toStringAsFixed(2)),
                      _buildCard('Média Diária de Vítimas',
                          averageDailyvitimas.toStringAsFixed(2)),
                    ],
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar dados: ${snapshot.error}'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
