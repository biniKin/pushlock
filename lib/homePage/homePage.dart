import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:pushlock/service/appLockService.dart';
import 'package:pushlock/model/locked_app.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {


  @override
  void initState() {
    super.initState();
  }

@override
Widget build(BuildContext context) {
  return SafeArea(
    child: Scaffold(
      extendBodyBehindAppBar: true,
      // backgroundColor: Colors.black,
      
      body: Stack(
        children: [
          Opacity(
            opacity: 0.9,
            child: Image.asset(
              "assets/images/noise-bg.png",
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
      
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // App name
              const Text(
                "PushLock",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
      
              const SizedBox(height: 4),
      
              // Subtitle
              const Text(
                "Track and control your app usage",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
      
              const SizedBox(height: 20),
      
              // Stats + chart container
              Container(
                width: double.infinity,
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08), // glass feel
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Row(
                  children: [
                    // Four apps list (most used)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Top Apps",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
      
                          // Placeholder for 4 apps
                          ...List.generate(4, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "App Name",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
      
                    const SizedBox(width: 16),
      
                    // Chart placeholder
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Daily Usage Chart",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      
              const SizedBox(height: 20),
      
              // Summary container
              Container(
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
                      children: const [
                        Text(
                          "Locked Apps",
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "5",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
      
                    // Total apps
                    Column(
                      children: const [
                        Text(
                          "Total Apps",
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "43",
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
              ),
      
              const SizedBox(height: 20),
      
              // Most used apps list
              const Text(
                "Most Used Apps",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      
              const SizedBox(height: 12),
      
              // Non-scrollable list
              ListView.builder(
                itemCount: 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "App Name",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const Text(
                          "2h 15m",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          Positioned(
            left: 60,
            right: 60,
            bottom: 20,
            child: _FloatingBottomNav(currentIndex: 0, onTap: (index){}),
          ),

        ],
      ),
    ),
  );
}
}



class _FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black12.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apps),
              label: "Apps",
            ),
          ],
        ),
      ),
    );
  }
}
