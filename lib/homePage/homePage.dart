import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:pushlock/appsPage/appsPage.dart';
import 'package:pushlock/homePage/actual_home_page.dart';
import 'package:pushlock/homePage/widgets/appsLitsTile.dart';
import 'package:pushlock/homePage/widgets/chart_container.dart';
import 'package:pushlock/homePage/widgets/summary_container.dart';
import 'package:pushlock/service/appLockService.dart';
import 'package:pushlock/model/locked_app.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

@override
Widget build(BuildContext context) {
  return SafeArea(
    child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey[500],
      
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
          IndexedStack(
            index: currentIndex,
            children: [
              ActualHomePage(),
              Appspage(),
            ],
          ),
          

          Positioned(
            left: 60,
            right: 60,
            bottom: 20,
            child: _FloatingBottomNav(
              currentIndex: currentIndex, 
              onTap: (index){
              setState(() {
                currentIndex = index;
              });
            }),
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
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 56, 56, 56),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey[600]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[900]!,
            
            blurRadius: 5,
            blurStyle: BlurStyle.outer,
            offset: Offset(0, 0)
          ),
    
         
        ]
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
    );
  }
}
