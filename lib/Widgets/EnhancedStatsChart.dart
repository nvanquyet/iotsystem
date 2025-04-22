import 'package:convenyor_system/screens/conveyor_system.dart';
import 'package:convenyor_system/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Improved chart component that replaces the original PieChartCircle
class EnhancedStatsChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  final Map<String, dynamic> currentStats;
  final Map<String, dynamic> limitStats;
  final Map<ColorLimit, ColorInfo> colorInfo;

  const EnhancedStatsChart({
    Key? key,
    required this.stats,
    required this.currentStats,
    required this.limitStats,
    required this.colorInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPieChart(),
        const SizedBox(height: 24),
        _buildLegend(),
      ],
    );
  }

  // Pie chart with animations and hover effect
  Widget _buildPieChart() {
    final total = (stats["total"] ?? 0) > 0 ? stats["total"] : 1;
    final List<PieChartSectionData> sections = [];
    
    // Add data sections for each color
    colorInfo.forEach((colorLimit, info) {
      final colorKey = _getColorKeyFromLimit(colorLimit);
      final count = stats[colorKey] ?? 0;
      final percentage = count / total * 100;
      
      if (percentage > 0) {
        sections.add(
          PieChartSectionData(
            color: info.color,
            value: percentage,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
            badgeWidget: _BadgeIcon(
              icon: Icons.lens,
              color: info.color,
            ),
            badgePositionPercentageOffset: 0.98,
          ),
        );
      }
    });
    
    // If no data, show empty state
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: 'Không có dữ liệu',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Could implement touch response here if needed
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: sections,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${stats["total"] ?? 0}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Tổng số',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Custom legend with color indicators and values
  Widget _buildLegend() {
    List<Widget> legendItems = [];
    
    colorInfo.forEach((colorLimit, info) {
      final colorKey = _getColorKeyFromLimit(colorLimit);
      final count = stats[colorKey] ?? 0;
      final total = (stats["total"] ?? 0) > 0 ? stats["total"] : 1;
      final percentage = count / total * 100;
      
      legendItems.add(
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // căn giữa theo chiều ngang
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: info.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center, // căn giữa nội dung text
                children: [
                  Text(
                    info.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$count (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

    });
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: legendItems,
      ),
    );
  }

  // Helper method to get color key from color limit enum
  String _getColorKeyFromLimit(ColorLimit limit) {
    switch (limit) {
      case ColorLimit.red: return "red";
      case ColorLimit.blue: return "blue";
      case ColorLimit.yellow: return "yellow";
      default: return "red";
    }
  }
}

// Badge widget for pie chart sections
class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _BadgeIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Icon(
        icon,
        size: 14,
        color: Colors.white,
      ),
    );
  }
}