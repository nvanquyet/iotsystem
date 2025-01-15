import 'package:convenyor_system/Widgets/Indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartCircle extends StatefulWidget {
  final List<ColorStats> colorStats; // Dữ liệu truyền vào

  const PieChartCircle({super.key, required this.colorStats});

  @override
  State<StatefulWidget> createState() => PieChartCircleState();
}

class PieChartCircleState extends State<PieChartCircle> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: <Widget>[
          const SizedBox(
            height: 18,
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: showingSections(),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.colorStats.map((colorStat) {
              return Column(
                children: [
                  Indicator(
                    color: Color(int.parse(colorStat.color)), // Chuyển đổi mã hex
                    text: '${colorStat.count}', // Hiển thị phần trăm
                    isSquare: true,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(
            width: 28,
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return widget.colorStats.map((colorStat) {
      final isTouched = colorStat.count == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      return PieChartSectionData(
        color: Color(int.parse(colorStat.color)),  // Chuyển mã màu
        value: colorStat.percentage.toDouble(),  // Chuyển số lượng
        title: "${colorStat.percentage}%",  // Hiển thị % từ count
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Chọn màu chữ phù hợp
          shadows: shadows,
        ),
      );
    }).toList();
  }
}

class ColorStats {
  final String color;  // Mã màu trong định dạng hex
  final int count; 
  final double percentage;    // Số lượng

  ColorStats(this.color, this.count, this.percentage);
}
