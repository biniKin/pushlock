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
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Locked apps
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.lock_clock, color: const Color.fromARGB(255, 186, 172, 123), size: 19,),
                  SizedBox(width: 5,),
                  Text(
                    "Locked Apps",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
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
              color: Colors.grey[700]
            ),
          ),
          // Total apps
          Column(
            children: [
              Row(
                children: [
                  Icon(Icons.apps, color: Colors.lightGreen, size: 19,),
                  SizedBox(width: 5,),
                  Text(
                    "Total Apps",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
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