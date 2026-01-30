import 'package:flutter/material.dart';
import 'package:pushlock/appsPage/widget/apps_skeleton_container.dart';
import 'package:shimmer/shimmer.dart';

class HomeSkeletonPage extends StatelessWidget {
  const HomeSkeletonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Chart skeleton
          _box(height: 200),

          const SizedBox(height: 20),

          // Summary skeleton
          _box(height: 120),

          const SizedBox(height: 20),

          // Title skeleton
          _line(width: 160, height: 18),

          const SizedBox(height: 12),

          // List skeleton
          ListView.builder(
            itemCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, __) => const AppsSkeletonContainer(),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _box({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _line({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
