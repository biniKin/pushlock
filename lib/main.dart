import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pushlock/appsPage/bloc/apps_bloc.dart';
import 'package:pushlock/camerPage/camera_page.dart';
import 'package:pushlock/camerPage/unlockPage.dart';
import 'package:pushlock/data/installed_apps_cache.dart';
import 'package:pushlock/data/pushup_session_cache.dart';
import 'package:pushlock/data/pushup_session_model.dart';
import 'package:pushlock/homePage/bloc/homePage_bloc.dart';
import 'package:pushlock/homePage/homePage.dart';
import 'package:pushlock/repositories/app_stats_repository.dart';
import 'package:pushlock/repositories/installed_apps_repository.dart';
import 'package:pushlock/repositories/locked_apps_repository.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

late List<CameraDescription> cameras;

void main()async {
  
  final LockedAppsRepository lockedAppsRepo = LockedAppsRepository(); 
  final AppStatsRepository appStatsRepo = AppStatsRepository();
  final InstalledAppsCache cache = InstalledAppsCache();
  final InstalledAppsRepository installedAppsRepo = InstalledAppsRepository(cache, appStatsRepo, lockedAppsRepo);
  final PushupSessionCache pushupSessionCache = PushupSessionCache();
  
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  cameras = await availableCameras();
  runApp(
    MultiBlocProvider( 
      providers: [
        BlocProvider<HomepageBloc>(create: (_) => HomepageBloc(installedAppsRepo: installedAppsRepo, lockedAppsRepo: lockedAppsRepo, appStatsRepo: appStatsRepo, pushupSessionCache: pushupSessionCache)),
        BlocProvider<AppsBloc>(create: (_) => AppsBloc(installedAppsRepo)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('com.example.pushlock/navigation');
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Listen for navigation events from native Android
    platform.setMethodCallHandler((call) async {
      if (call.method == 'navigateToUnlock') {
        navigatorKey.currentState?.pushNamed('/unlock');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Homepage(),
        '/unlock': (context) => const Unlockpage(),

      },
    );
  }
}
