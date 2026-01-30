import 'package:flutter/material.dart';
import 'package:pushlock/model/appUiModel.dart';
import 'package:pushlock/util/time_formatter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartContainer extends StatefulWidget {
  final List<Appuimodel> topApps;

  const ChartContainer({super.key, required this.topApps});

  @override
  State<ChartContainer> createState() => _ChartContainerState();
}

class _ChartContainerState extends State<ChartContainer> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    // Take only top 4 apps
    final displayApps = widget.topApps.take(3).toList();

    // If no apps, show empty state
    if (displayApps.isEmpty) {
      return Container(
        width: double.infinity,
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: const Center(
          child: Text(
            "No app usage data yet",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
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
                ...displayApps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final app = entry.value;
                  final isSelected = selectedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = isSelected ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          // App icon
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey[700],
                            backgroundImage: app.icon != null
                                ? MemoryImage(app.icon!)
                                : null,
                            child: app.icon == null
                                ? const Icon(
                                    Icons.apps,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    app.appName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[400],
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  height: 10,
                                  width: 10,
                                  decoration: BoxDecoration(
                                    color: _getColorForIndex(index),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ───── Radial chart ─────
          Expanded(
            flex: 4,
            child: SfCircularChart(
              onSelectionChanged: (args) {
                setState(() {
                  selectedIndex = args.pointIndex;
                });
              },
              series: <CircularSeries>[
                RadialBarSeries<Appuimodel, String>(
                  dataSource: displayApps,
                  xValueMapper: (Appuimodel app, _) => app.appName,
                  yValueMapper: (Appuimodel app, _) =>
                      app.dailyUsageSeconds / 60, // Convert to minutes
                  dataLabelMapper: (Appuimodel app, _) =>
                      TimeFormatter.formatSecondsShort(app.dailyUsageSeconds),
                  name: "Most used apps",

                  radius: '90%',
                  innerRadius: '40%',
                  gap: '5%',
                  cornerStyle: CornerStyle.bothCurve,
                  trackColor: Colors.grey[700]!,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selectionBehavior: SelectionBehavior(
                    enable: true,
                    selectedColor: Colors.white,
                    unselectedOpacity: 0.5,
                  ),
                  pointColorMapper: (Appuimodel app, index) {
                    return _getColorForIndex(index);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple];
    return colors[index % colors.length];
  }
}
