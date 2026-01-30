import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pushlock/appsPage/bloc/apps_bloc.dart';
import 'package:pushlock/camerPage/camera_page.dart';
import 'package:pushlock/camerPage/unlockPage.dart';
import 'package:pushlock/data/installed_apps_cache.dart';
import 'package:pushlock/data/pushup_session_cache.dart';
import 'package:pushlock/homePage/bloc/homePage_bloc.dart';
import 'package:pushlock/homePage/homePage.dart';
import 'package:pushlock/overlayPage/overlay_lock_page.dart';
import 'package:pushlock/repositories/app_stats_repository.dart';
import 'package:pushlock/repositories/installed_apps_repository.dart';
import 'package:pushlock/repositories/locked_apps_repository.dart';

late List<CameraDescription> cameras;

// Separate entry point for overlay - runs in separate FlutterEngine
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const OverlayApp());
}

class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key});

  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> {
  static const platform = MethodChannel('overlay_channel');
  String packageName = '';
  String appName = '';

  @override
  void initState() {
    super.initState();

    // Listen for overlay data from Kotlin
    platform.setMethodCallHandler((call) async {
      if (call.method == 'showOverlay') {
        setState(() {
          packageName = call.arguments['packageName'] ?? '';
          appName = call.arguments['appName'] ?? '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayLockPage(packageName: packageName, appName: appName),
    );
  }
}

void main() async {
  final LockedAppsRepository lockedAppsRepo = LockedAppsRepository();
  final AppStatsRepository appStatsRepo = AppStatsRepository();
  final InstalledAppsCache cache = InstalledAppsCache();
  final InstalledAppsRepository installedAppsRepo = InstalledAppsRepository(
    cache,
    appStatsRepo,
    lockedAppsRepo,
  );
  final PushupSessionCache pushupSessionCache = PushupSessionCache();

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  //installedAppsRepo.cache.clearCachedApps();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  cameras = await availableCameras();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<HomepageBloc>(
          create: (_) => HomepageBloc(
            installedAppsRepo: installedAppsRepo,
            lockedAppsRepo: lockedAppsRepo,
            appStatsRepo: appStatsRepo,
            pushupSessionCache: pushupSessionCache,
          ),
        ),
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
  static const navigationChannel = MethodChannel(
    'com.example.pushlock/navigation',
  );
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Listen for navigation commands from MainActivity
    navigationChannel.setMethodCallHandler((call) async {
      if (call.method == 'openCamera') {
        final packageName = call.arguments['packageName'] as String;
        final appName = call.arguments['appName'] as String? ?? '';

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) =>
                CameraPage(packageName: packageName, appName: appName),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const Homepage(),
        '/unlock': (context) => const Unlockpage(),
      },
    );
  }
}
