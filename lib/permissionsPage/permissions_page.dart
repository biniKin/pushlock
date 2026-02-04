import 'package:flutter/material.dart';
import 'package:pushlock/homePage/homePage.dart';
import 'package:pushlock/service/appLockService.dart';


class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool canContinue = false;
  final AppLockService appLockService = AppLockService();

  // check for display over other apps permission is allowed
  void _initial() async{
    final canDrawOverlay = await appLockService.canDrawOverlay(); 
    final hasUsagePer = await appLockService.hasUsageAccess();
    if(hasUsagePer && canDrawOverlay){
      setState(() {
        canContinue = true;
      });
    } 
  }

  Future openSettingsForOverlay() async{
    await appLockService.navigateToOverlaySettings();
  }

  Future openSettingsForUsageAccess() async{
    await appLockService.navigateToUsageSettings();
  }



  // navigate to home page
  void continueToHomePage() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => Homepage()), 
      (route)=>false
    );
  }

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
                //crossAxisAlignment: CrossAxisAlignment.start,
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
                        onPressed: () {
                          // navigate to next page
                          canContinue ? continueToHomePage() : (){};
                        },
                        child: Text(
                          "Continue",
                          style: TextStyle(
                            color: canContinue ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "To use PushLock properly, please grant the following permissions. "
                    "We only request what is necessary for core features.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  const SizedBox(height: 24),

                  /// 🪟 Display over other apps
                  _permissionCard(
                    isForbattery: false,
                    icon: Icons.layers,
                    title: "Display over other apps",
                    description:
                        "Allows PushLock to show a lock screen over selected apps "
                        "when they are opened.",
                    onGrant: () {
                      // open overlay permission settings
                    },
                    imageAsset: [
                      "assets/images/appearPer.jpg",
                    ]
                  ),

                  const SizedBox(height: 16),

                  /// 📊 Usage access
                  _permissionCard(
                    isForbattery: false,
                    icon: Icons.bar_chart,
                    title: "Usage access",
                    description:
                        "Used to detect which app is currently open so PushLock "
                        "can lock selected apps.",
                    onGrant: () {
                      // open usage access settings
                    },
                    imageAsset: ["assets/images/usagePer.jpg"]
                  ),

                  const SizedBox(height: 16),

                  /// 🔋 Battery optimization
                  _permissionCard(
                    isForbattery: true,
                    icon: Icons.battery_saver,
                    title: "Disable battery optimization",
                    description:
                        "Prevents the system from stopping PushLock in the background "
                        "so app locking works reliably.",
                    onGrant: () {
                      // open battery optimization settings
                    },
                    imageAsset: [
                      "assets/images/batteryPer.jpg"
                    ]
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onGrant,
    required List<String> imageAsset,
    required bool isForbattery,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF403F3F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Icon + title
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
            ],
          ),

          const SizedBox(height: 8),

          /// Description
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 12),

          /// Image row placeholder
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

          /// Grant button
          isForbattery ? SizedBox.shrink() : Align(
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

  Widget _imagePlaceholder({
    required String imageAsset,
  }) {
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
