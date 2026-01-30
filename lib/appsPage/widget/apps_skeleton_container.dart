import 'package:flutter/material.dart';

class AppsSkeletonContainer extends StatelessWidget {
  const AppsSkeletonContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // avatar / icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),

          // text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: double.infinity, color: Colors.grey.shade300),
                const SizedBox(height: 6),
                Container(height: 10, width: 150, color: Colors.grey.shade300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}