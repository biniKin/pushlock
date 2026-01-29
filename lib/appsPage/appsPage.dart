import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushlock/appsPage/bloc/apps_bloc.dart';
import 'package:pushlock/appsPage/bloc/apps_event.dart';
import 'package:pushlock/appsPage/bloc/apps_state.dart';
import 'package:pushlock/homePage/widgets/appsLitsTile.dart';

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

        if (state is AppsLoading) {return Center(child: CircularProgressIndicator(),);}

        else if(state is AppsLoaded){
          final apps = state.apps;
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
                    onTap: (){}, 
                    usageTime: app.dailyUsageSeconds,
                    appImage: app.icon != null ? Image.memory(app.icon!) : Icon(Icons.apps),
                  );
                },
              ),
              SizedBox(height: 100,),
            ],
          );
        } else{
          return CircularProgressIndicator();
        }
      }
    );
  }
}