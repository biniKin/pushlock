import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pushlock/util/time_formatter.dart';

class Appslitstile extends StatelessWidget {
  final String name;
  final bool isLocked;
  final int usageTime;
  final VoidCallback onTap;
  final appImage;
  const Appslitstile({super.key, required this.appImage,required this.name, required this.isLocked, required this.onTap, required this.usageTime});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey[700],
              child: appImage,
            ),
            const SizedBox(width: 19),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  
                  
                  Row(
                    children: [
                      //Icon(Icons.timelapse, size: 16,),
                      Text(
                        TimeFormatter.formatSeconds(usageTime),
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isLocked ? SvgPicture.asset("assets/icons/locked-icon.svg") : SvgPicture.asset("assets/icons/unlocked-icon.svg")
            
          ],
        ),
      ),
    );
  }
}