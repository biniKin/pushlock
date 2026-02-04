import 'package:flutter/material.dart';
import 'package:pushlock/homePage/homePage.dart';
import 'package:pushlock/service/appLockService.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage>
    with WidgetsBindingObserver {
  bool _hasOverlayPermission = false;
  bool _hasUsagePermission = false;
  bool _isChecking = true;
  final AppLockService _appLockService = AppLockService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check permissions when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  // Check for display over other apps and usage access permissions
  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);

    final canDrawOverlay = await _appLockService.canDrawOverlay();
    final hasUsagePer = await _appLockService.hasUsageAccess();

    setState(() {
      _hasOverlayPermission = canDrawOverlay;
      _hasUsagePermission = hasUsagePer;
      _isChecking = false;
    });
  }

  Future<void> _openSettingsForOverlay() async {
    await _appLockService.navigateToOverlaySettings();
  }

  Future<void> _openSettingsForUsageAccess() async {
    await _appLockService.navigateToUsageSettings();
  }

  // Navigate to home page
  void _continueToHomePage() async {
    if (_hasOverlayPermission && _hasUsagePermission) {
      // Start the app lock service
      await _appLockService.startAppLockService();

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const Homepage()));
    }
  }

  bool get _canContinue => _hasOverlayPermission && _hasUsagePermission;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.grey[900],
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

            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  /// 🔝 Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Permissions required",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: _canContinue ? _continueToHomePage : null,
                        child: Text(
                          "Continue",
                          style: TextStyle(
                            color: _canContinue
                                ? Colors.white
                                : Colors.grey[700],
                            fontWeight: _canContinue
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "To use PushLock properly, please grant the following permissions. "
                    "We only request what is necessary for core features.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  const SizedBox(height: 24),

                  if (_isChecking)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else ...[
                    /// 🪟 Display over other apps
                    _permissionCard(
                      isGranted: _hasOverlayPermission,
                      icon: Icons.layers,
                      title: "Display over other apps",
                      description:
                          "Allows PushLock to show a lock screen over selected apps "
                          "when they are opened.",
                      onGrant: _openSettingsForOverlay,
                      imageAsset: ["assets/images/appearPer.jpg"],
                    ),

                    const SizedBox(height: 16),

                    /// 📊 Usage access
                    _permissionCard(
                      isGranted: _hasUsagePermission,
                      icon: Icons.bar_chart,
                      title: "Usage access",
                      description:
                          "Used to detect which app is currently open so PushLock "
                          "can lock selected apps.",
                      onGrant: _openSettingsForUsageAccess,
                      imageAsset: ["assets/images/usagePer.jpg"],
                    ),

                    const SizedBox(height: 16),

                    /// 🔋 Battery optimization info
                    _permissionCard(
                      isGranted: null, // Not checked here, will be on home page
                      icon: Icons.battery_saver,
                      title: "Disable battery optimization",
                      description:
                          "Prevents the system from stopping PushLock in the background "
                          "so app locking works reliably. You'll be asked for this on the home page.",
                      onGrant: null,
                      imageAsset: ["assets/images/batteryPer.jpg"],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionCard({
    required bool? isGranted,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback? onGrant,
    required List<String> imageAsset,
  }) {
    final bool showGrantButton = isGranted == false && onGrant != null;
    final bool showCheckmark = isGranted == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showCheckmark
              ? Colors.green.withValues(alpha: 0.5)
              : const Color(0xFF403F3F),
          width: showCheckmark ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Icon + title + checkmark
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (showCheckmark)
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ],
          ),

          const SizedBox(height: 8),

          /// Description
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 12),

          /// Image row
          SizedBox(
            height: 100,
            child: ListView.builder(
              itemCount: imageAsset.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final image = imageAsset[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _imagePlaceholder(imageAsset: image),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          /// Grant button (only show if not granted)
          if (showGrantButton)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onGrant,
                child: const Text(
                  "Grant access",
                  style: TextStyle(color: Color(0xFFF89F1A)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder({required String imageAsset}) {
    return SizedBox(
      width: 160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 100,
          color: Colors.black26,
          child: Image.asset(imageAsset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
