import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pushlock/appsPage/bloc/apps_bloc.dart';
import 'package:pushlock/camerPage/camera_page.dart';
import 'package:pushlock/camerPage/unlockPage.dart';
import 'package:pushlock/data/installed_apps_cache.dart';
import 'package:pushlock/data/intro_page_flag.dart';
import 'package:pushlock/data/pushup_session_cache.dart';
import 'package:pushlock/homePage/bloc/homePage_bloc.dart';
import 'package:pushlock/homePage/homePage.dart';
import 'package:pushlock/introPage/introPage.dart';
import 'package:pushlock/overlayPage/overlay_lock_page.dart';
import 'package:pushlock/permissionsPage/permissions_page.dart';
import 'package:pushlock/repositories/app_stats_repository.dart';
import 'package:pushlock/repositories/installed_apps_repository.dart';
import 'package:pushlock/repositories/locked_apps_repository.dart';
import 'package:pushlock/service/local_pushup_count_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<CameraDescription> cameras;

// Separate entry point for overlay - runs in separate FlutterEngine
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  //await Hive.initFlutter();

  //await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
  bool isDataReceived = false;

  @override
  void initState() {
    super.initState();

    debugPrint("OVERLAY_APP: initState called");

    // Listen for overlay data from Kotlin
    platform.setMethodCallHandler((call) async {
      debugPrint("OVERLAY_APP: Received method call: ${call.method}");
      if (call.method == 'showOverlay') {
        final pkg = call.arguments['packageName'] ?? '';
        final name = call.arguments['appName'] ?? '';
        debugPrint("OVERLAY_APP: Received data - pkg=$pkg, name=$name");

        setState(() {
          packageName = pkg;
          appName = name;
          isDataReceived = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("OVERLAY_APP: Building with isDataReceived=$isDataReceived");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black87,
      ),
      home: isDataReceived
          ? OverlayLockPage(packageName: packageName, appName: appName)
          : const Scaffold(
              backgroundColor: Colors.black87,
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  final IntroPageFlag introPageFlag = IntroPageFlag(
    sharedPreferences: sharedPreferences,
  );
  final LockedAppsRepository lockedAppsRepo = LockedAppsRepository();
  final AppStatsRepository appStatsRepo = AppStatsRepository();
  final InstalledAppsCache cache = InstalledAppsCache();
  final InstalledAppsRepository installedAppsRepo = InstalledAppsRepository(
    cache,
    appStatsRepo,
    lockedAppsRepo,
  );
  final PushupSessionCache pushupSessionCache = PushupSessionCache();
  final LocalPushupCountService localPushupCountService =
      LocalPushupCountService(sharedPreferences: sharedPreferences);

  await Hive.initFlutter();
  //installedAppsRepo.cache.clearCachedApps();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
            localPushupCountService: localPushupCountService,
          ),
        ),
        BlocProvider<AppsBloc>(
          create: (_) => AppsBloc(
            appsRepository: installedAppsRepo,
            appStatsRepo: appStatsRepo,
            localPushupCountService: localPushupCountService,
            lockedAppsRepo: lockedAppsRepo,
            pushupSessionCache: pushupSessionCache,
          ),
        ),
      ],
      child: MyApp(introPageFlag: introPageFlag),
    ),
  );
}

class MyApp extends StatefulWidget {
  final IntroPageFlag introPageFlag;

  const MyApp({super.key, required this.introPageFlag});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const navigationChannel = MethodChannel(
    'com.example.pushlock/navigation',
  );
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isLoading = true;
  bool _showIntro = false;

  @override
  void initState() {
    super.initState();
    _checkIntroFlag();

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

  Future<void> _checkIntroFlag() async {
    final hasSeenIntro = await widget.introPageFlag.getIntroPageFlag();
    setState(() {
      _showIntro = !hasSeenIntro;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: _showIntro ? '/intro' : '/',
      routes: {
        '/': (context) => const PermissionsPage(),
        '/intro': (context) => Intropage(introPageFlag: widget.introPageFlag),
        '/unlock': (context) => const Unlockpage(),
      },
    );
  }
}
