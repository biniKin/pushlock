import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushlock/homePage/bloc/homePage_bloc.dart';
import 'package:pushlock/homePage/bloc/homePage_event.dart';
import 'package:pushlock/homePage/homePage.dart';
import 'package:pushlock/homePage/widgets/custom_time_picker.dart';
import 'package:pushlock/model/locked_app.dart';


Future<void> appDialog({
  required BuildContext context,
  required String appName,
  required bool isLocked,
  required String packageName,
  required dynamic appIcon,
}) {
  final lockTimeController = TextEditingController();
  double pushups = 10;

  String? errorText;
  int? selectedMinutes;


  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                            width: 150,
                            child: Text(
                              packageName, 
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isLocked
                              ? Icons.lock
                              : Icons.lock_open,
                          size: 14,
                          color:
                              isLocked ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ───── Lock time input ─────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Lock time interval (minutes)",
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                        ),
                      ),
                    ),

                    selectedMinutes != null ? Text(
                      selectedMinutes.toString() + "min", 
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 13,
                      ),
                    ) : SizedBox.shrink()
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _timeOption(
                        label: "1 hour",
                        selected: selectedMinutes == 60,
                        onTap: () => setState(() => selectedMinutes = 60),
                      ),
                      _timeOption(
                        label: "2 hours",
                        selected: selectedMinutes == 120,
                        onTap: () => setState(() => selectedMinutes = 120),
                      ),
                      _timeOption(
                        label: "3 hours",
                        selected: selectedMinutes == 180,
                        onTap: () => setState(() => selectedMinutes = 180),
                      ),
                      _timeOption(
                        label: "4 hours",
                        selected: selectedMinutes == 240,
                        onTap: () => setState(() => selectedMinutes = 240),
                      ),
                      _timeOption(
                        label: "6 hours",
                        selected: selectedMinutes == 360,
                        onTap: () => setState(() => selectedMinutes = 360),
                      ),
                      _timeOption(
                        label: "Custom",
                        selected: selectedMinutes == null,
                        onTap: () async {
                          final result = await showCustomDurationPicker(context);
                          if (result != null) {
                            print(result);
                            setState(() => selectedMinutes = result);
                          }
                          
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ───── Pushups slider ─────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Push-ups",
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      pushups.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                Slider(
                  value: pushups,
                  min: 5,
                  max: 100,
                  divisions: 19,
                  activeColor: Colors.orange,
                  inactiveColor: Colors.grey[700],
                  label: pushups.toInt().toString(),
                  onChanged: (value) {
                    setState(() => pushups = value);
                  },
                ),

                // ───── Validation error ─────
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
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

                  if (pushups < 5) {
                    setState(() {
                      errorText =
                          "Push-ups must be at least 5";
                    });
                    return;
                  }
                  print("time interval: ${selectedMinutes}");
                  print("no of push-ups: ${pushups}");
                  print("app Name: ${appName}");
                  print("package name: ${packageName}");
                  print("is Locked ${isLocked}");

                  context.read<HomepageBloc>().add(
                    LockAppRequested(
                      app: LockedApp(
                        packageName: packageName, 
                        appName: appName, 
                        isStrict: false, 
                        timeoutSeconds: selectedMinutes! *60,
                        
                      ),
                      pushupscount: pushups.toInt()
                    ),
                  );

                  // TODO:
                  // dispatch Bloc event OR call repository
                  // packageName, lockMinutes, pushups.toInt()

                  Navigator.pop(context);
                },
                child: const Text(
                  "Lock",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}



Widget _timeOption({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.orangeAccent : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? Colors.orange : Colors.grey[700]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
