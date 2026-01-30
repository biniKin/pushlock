import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushlock/data/pushup_session_cache.dart';
import 'package:pushlock/homePage/bloc/homePage_bloc.dart';
import 'package:pushlock/homePage/bloc/homePage_event.dart';
import 'package:pushlock/homePage/bloc/homePage_state.dart';
import 'package:pushlock/homePage/widgets/app_dialog.dart';
import 'package:pushlock/homePage/widgets/appsLitsTile.dart';
import 'package:pushlock/homePage/widgets/chart_container.dart';
import 'package:pushlock/homePage/widgets/home_skeleton_page.dart';
import 'package:pushlock/homePage/widgets/summary_container.dart';
import 'package:pushlock/homePage/widgets/unlock_app_dialog.dart';

class ActualHomePage extends StatefulWidget {
  const ActualHomePage({super.key});

  @override
  State<ActualHomePage> createState() => _ActualHomePageState();
}

class _ActualHomePageState extends State<ActualHomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<HomepageBloc>().add(LoadHomepageData());
  }

  

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomepageBloc, HomepageState>(
      builder: (context, state) {
        if(state is HomepageLoading){
          return HomeSkeletonPage();
        } else if(state is HomepageLoaded){
          final apps = state.mostUsedApps;
          final statapps = state.chartApps;
          statapps.forEach((element) {
            print(element.dailyUsageSeconds);
          },);

          return ListView(
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
              ChartContainer(topApps: state.chartApps,),
              const SizedBox(height: 20),
              // Summary container
              SummaryContainer(lockedAppsNumber: state.lockedAppsCount, totalApps: state.totalAppsCount),
              const SizedBox(height: 20),
              // Most used apps list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Most Used Apps",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Text(
                  //   "see more", 
                  //   style: TextStyle(
                  //     color: Colors.deepPurpleAccent
                  //   ),
                  // )
                ],
              ),
              const SizedBox(height: 12),
              // Non-scrollable list
              ListView.builder(
                itemCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final app = apps[index];
                  
                  
                  return  Appslitstile(
                    name: app.appName, 
                    isLocked: app.isLocked, 
                    onTap: ()async{
                      final pushUpCount = await PushupSessionCache().getPushupCount(app.packageName);
                      print("pushup count for ${app.appName}: $pushUpCount");
                      app.isLocked ? 
                      await unlockAppDialog(
                        context: context, 
                        appName: app.appName, 
                        packageName: app.packageName, 
                        appIcon: app.icon!, 
                        timeoutMinutes: app.timeoutSeconds!, 
                        pushups: pushUpCount
                        ) :

                        await appDialog(
                          context: context,
                          appIcon: app.icon ,
                          isLocked: false, 
                          appName: app.appName, 
                          packageName: app.packageName, 
                        );
                    }, 
                    usageTime: app.dailyUsageSeconds,
                    appImage: app.icon  != null ? Image.memory(app.icon!) : Icon(Icons.apps),
                  );
                },
              ),
              SizedBox(height: 100,),
            ],
          );
        } else{
          return HomeSkeletonPage();
        }

        
        
      }
    );
  }
}