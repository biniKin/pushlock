import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SummaryContainer extends StatelessWidget {
  final int lockedAppsNumber;
  final int totalApps;

  const SummaryContainer({super.key, required this.lockedAppsNumber, required this.totalApps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Locked apps
          Column(
            children: [
              Text(
                "Locked Apps",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 6),
              Text(
                lockedAppsNumber.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            height: 50,
            width: 1,
            decoration: BoxDecoration(
              color: Colors.grey
            ),
          ),
          // Total apps
          Column(
            children: [
              Text(
                "Total Apps",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 6),
              Text(
                totalApps.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}