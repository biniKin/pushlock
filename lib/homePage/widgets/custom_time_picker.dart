import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<int?> showCustomDurationPicker(BuildContext context) async {
  int selectedHours = 1;
  int selectedMinutes = 0;

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Text(
              "Custom lock duration",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 180,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    pickerTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
                child: CupertinoTimerPicker(
                  
                  
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: const Duration(hours: 1),
                  onTimerDurationChanged: (duration) {
                    selectedHours = duration.inHours;
                    selectedMinutes = duration.inMinutes % 60;
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final totalMinutes =
                      (selectedHours * 60) + selectedMinutes;

                  Navigator.pop(context, totalMinutes);
                },
                child: const Text(
                  "Set duration",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
