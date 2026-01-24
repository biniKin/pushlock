import 'package:flutter/material.dart';
import 'package:pushlock/appLockService.dart';

class Unlockpage extends StatelessWidget {
  const Unlockpage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLockService appLockService = AppLockService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Page'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Unlock App',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Click unlock to reset the timer',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                // For now, unlock Instagram (hardcoded)
                // TODO: Get actual package name from context
                final success = await appLockService.unlockApp(
                  'com.instagram.android',
                );

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App unlocked! Timer reset.')),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
              ),
              child: const Text('Unlock', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
