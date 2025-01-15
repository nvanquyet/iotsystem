// import 'package:convenyor_system/screens/conveyor_system.dart';
// import 'package:flutter/material.dart';
// import 'package:charts_flutter/flutter.dart' as charts;

// class DatumLegendWithMeasures extends StatelessWidget {
//   final List<charts.Series> seriesList;
//   final bool animate;

//   /// Constructor nhận `data` đầu vào
//   DatumLegendWithMeasures({required List<ColorStats> data, required this.animate})
//       : seriesList = _createSeriesFromData(data);

//   @override
//   Widget build(BuildContext context) {
//     return charts.PieChart(
//       seriesList,
//       animate: animate,
//       behaviors: [
//         charts.DatumLegend(
//           position: charts.BehaviorPosition.end,
//           horizontalFirst: false,
//           cellPadding: EdgeInsets.only(right: 4.0, bottom: 4.0),
//           showMeasures: true,
//           legendDefaultMeasure: charts.LegendDefaultMeasure.firstValue,
//           measureFormatter: (num? value) => '${value}',
//         ),
//       ],
//     );
//   }

//   /// Hàm tạo `series` từ dữ liệu truyền vào
//   static List<charts.Series<ColorStats, String>> _createSeriesFromData(
//       List<ColorStats> data) {
//     return [
//       charts.Series<ColorStats, String>(
//         id: 'ColorStats',
//         domainFn: (ColorStats stat, _) => stat.colorName,
//         measureFn: (ColorStats stat, _) => stat.count,
//         data: data,
//       ),
//     ];
//   }
// }