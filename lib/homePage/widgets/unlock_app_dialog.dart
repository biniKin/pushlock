import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pushlock/homePage/bloc/homePage_bloc.dart';
import 'package:pushlock/homePage/bloc/homePage_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> unlockAppDialog({
  required BuildContext context,
  required String appName,
  required String packageName,
  required Uint8List appIcon,
  required int timeoutMinutes,
  required int pushups,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ───── App header ─────
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    appIcon,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 25,
                        child: Text(
                          packageName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.lock,
                  color: Colors.red,
                  size: 16,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ───── Static info cards ─────
            _infoRow("Lock duration", "$timeoutMinutes min"),
            const SizedBox(height: 8),
            _infoRow("Required push-ups", pushups.toString()),

            const SizedBox(height: 16),

            Text(
              "Unlocking this app will remove all restrictions.",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<HomepageBloc>().add(
                UnlockAppRequested(packageName),
              );

              Navigator.pop(context);
            },
            child: const Text(
              "Unlock",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      );
    },
  );
}


Widget _infoRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 13,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
