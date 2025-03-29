// lib/presentation/widgets/food/nutrition_chart.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';

class NutritionChart extends StatelessWidget {
  final double proteinPercentage;
  final double carbsPercentage;
  final double fatPercentage;

  const NutritionChart({
    Key? key,
    required this.proteinPercentage,
    required this.carbsPercentage,
    required this.fatPercentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<NutrientData> chartData = [
      NutrientData('Protein', proteinPercentage, AppColors.success),
      NutrientData('Carbs', carbsPercentage, AppColors.warning),
      NutrientData('Fat', fatPercentage, AppColors.secondary),
    ];

    return SfCircularChart(
      title: ChartTitle(
        text: 'Macronutrient Distribution',
        textStyle: AppTextStyles.subtitle1,
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
      ),
      annotations: <CircularChartAnnotation>[
        CircularChartAnnotation(
          widget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(proteinPercentage + carbsPercentage + fatPercentage).toInt()}%',
                style: AppTextStyles.headline6,
              ),
              Text(
                'Total',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
      series: <CircularSeries>[
        DoughnutSeries<NutrientData, String>(
          dataSource: chartData,
          xValueMapper: (NutrientData data, _) => data.nutrient,
          yValueMapper: (NutrientData data, _) => data.percentage,
          pointColorMapper: (NutrientData data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
          ),
          // Custom label to display nutrient name with percentage
          dataLabelMapper: (NutrientData data, _) =>
              '${data.nutrient}: ${data.percentage.toInt()}%',
          innerRadius: '60%',
          explode: true,
          explodeAll: false,
        ),
      ],
    );
  }
}

class NutrientData {
  final String nutrient;
  final double percentage;
  final Color color;

  NutrientData(this.nutrient, this.percentage, this.color);
}
