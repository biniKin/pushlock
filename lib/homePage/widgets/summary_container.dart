import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SummaryContainer extends StatelessWidget {
  final int lockedAppsNumber;
  final int totalApps;
  final int totalPushups;

  const SummaryContainer({super.key, required this.lockedAppsNumber, required this.totalApps, required this.totalPushups});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
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
                  Icon(Icons.lock_clock, color: const Color.fromARGB(255, 186, 172, 123), size: 15,),
                  SizedBox(width: 5,),
                  Text(
                    "Locked Apps",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                lockedAppsNumber.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            height: 20,
            width: 1,
            decoration: BoxDecoration(
              color: Colors.grey[800]
            ),
          ),
          // Total apps
          Column(
            children: [
              Row(
                children: [
                  Icon(Icons.apps, color: Colors.lightGreen, size: 15,),
                  SizedBox(width: 5,),
                  Text(
                    "Total Apps",
                    style: TextStyle(color: Colors.white70,fontSize: 11),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                totalApps.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          Container(
            height: 20,
            width: 1,
            decoration: BoxDecoration(
              color: Colors.grey[800]
            ),
          ),

          Column(
            children: [
              Row(
                children: [
                  SvgPicture.asset("assets/icons/push-man.svg", height: 7, width: 5,color: const Color.fromARGB(255, 142, 157, 191),),
                  SizedBox(width: 5,),
                  Text(
                    "Total pushups",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                totalPushups.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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