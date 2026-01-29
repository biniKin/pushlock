import 'package:flutter/material.dart';
import 'package:pushlock/model/chart_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartContainer extends StatelessWidget {
  const ChartContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ChartData> chartData = [
      ChartData(app: 'Instagram', usage: 40),
      ChartData(app: 'YouTube', usage: 30),
      ChartData(app: 'Telegram', usage: 20),
    
    ];

    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          // ───── Top apps list ─────
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Top Apps",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...chartData.map(
                  (data) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey[700],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data.app,
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              
                              ),
                              Container(
                                height: 10,
                                width: 10,
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ───── Radial chart ─────
          Expanded(
            flex: 4,
            child: SfCircularChart(
              
              series: <CircularSeries>[
                RadialBarSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.app,
                  yValueMapper: (ChartData data, _) => data.usage,
                  //maximumValue: 60, // max usage (minutes)
                  name: "Most used apps",
                  radius: '90%',
                  innerRadius: '40%',
                  gap: '5%',
                  cornerStyle: CornerStyle.bothCurve,
                  trackColor: Colors.grey.withOpacity(0.2),
                  pointColorMapper: (_, index) {
                    final colors = [
                      Colors.orange,
                      Colors.blue,
                      Colors.green,
                      Colors.purple,
                    ];
                    return colors[index % colors.length];
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
