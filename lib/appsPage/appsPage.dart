import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushlock/appsPage/bloc/apps_bloc.dart';
import 'package:pushlock/appsPage/bloc/apps_event.dart';
import 'package:pushlock/appsPage/bloc/apps_state.dart';
import 'package:pushlock/appsPage/widget/apps_skeleton_container.dart';
import 'package:pushlock/data/pushup_session_cache.dart';
import 'package:pushlock/homePage/widgets/app_dialog.dart';
import 'package:pushlock/homePage/widgets/appsLitsTile.dart';
import 'package:pushlock/homePage/widgets/unlock_app_dialog.dart';
import 'package:shimmer/shimmer.dart';

class Appspage extends StatefulWidget {
  const Appspage({super.key});

  @override
  State<Appspage> createState() => _AppspageState();
}

class _AppspageState extends State<Appspage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<AppsBloc>().add(LoadApps());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppsBloc, AppsState>(
      builder: (context, state) {

        if (state is AppsLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const Text(
                  "PushLock",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  "Track and control your app usage",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade800,
                  highlightColor: Colors.grey.shade700,
                  child: ListView.builder(
                    itemCount: 6,
                    itemBuilder: (context, index){
                    return AppsSkeletonContainer();
                  }),
                ),
              ),
            ],
          );
        }

        else if(state is AppsLoaded){
          final apps = state.apps;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                            Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const Text(
                  "PushLock",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  "Track and control your app usage",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: ()async{
                    // call refresh
                    context.read<AppsBloc>().add(RefreshApps());
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // App name
                      
                      const SizedBox(height: 15),
                      // Stats + chart container
                      // Non-scrollable list
                      ListView.builder(
                        itemCount: apps.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return Appslitstile(
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
                            appImage: app.icon != null ? Image.memory(app.icon!) : Icon(Icons.apps),
                          );
                        },
                      ),
                      SizedBox(height: 100,),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else{
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const Text(
                  "PushLock",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  "Track and control your app usage",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade800,
                  highlightColor: Colors.grey.shade700,
                  child: ListView.builder(
                    itemCount: 6,
                    itemBuilder: (context, index){
                    return AppsSkeletonContainer();
                  }),
                ),
              ),
            ],
          );
        }
      }
    );
  }
}