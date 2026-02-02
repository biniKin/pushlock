import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:installed_apps/app_category.dart';
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

class _AppspageState extends State<Appspage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<AppsBloc>().add(LoadApps());

    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    AppCategory? category;
    switch (index) {
      case 0:
        category = null; // All
        break;
      case 1:
        category = AppCategory.social;
        break;
      case 2:
        category = AppCategory.game;
        break;
      case 3:
        category = AppCategory.productivity;
        break;
    }
    context.read<AppsBloc>().add(CategoryChanged(appCategory: category));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppsBloc, AppsState>(
      builder: (context, state) {
        if (state is AppsLoading) {
          return _buildLoadingState();
        } else if (state is AppsLoaded) {
          return _buildLoadedState(state);
        } else {
          return _buildLoadingState();
        }
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade800,
            highlightColor: Colors.grey.shade700,
            child: ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) {
                return const AppsSkeletonContainer();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedState(AppsLoaded state) {
    final apps = state.filteredApps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<AppsBloc>().add(RefreshApps());
            },
            child: apps.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 15),
                      ListView.builder(
                        itemCount: apps.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return Appslitstile(
                            name: app.appName,
                            isLocked: app.isLocked,
                            onTap: () async {
                              if (!mounted) return;

                              final pushUpCount = await PushupSessionCache()
                                  .getPushupCount(app.packageName);

                              if (!mounted) return;

                              if (app.isLocked) {
                                await unlockAppDialog(
                                  context: context,
                                  appName: app.appName,
                                  packageName: app.packageName,
                                  appIcon: app.icon!,
                                  timeoutMinutes: app.timeoutSeconds!,
                                  pushups: pushUpCount,
                                );
                              } else {
                                await appDialog(
                                  context: context,
                                  appIcon: app.icon,
                                  isLocked: false,
                                  appName: app.appName,
                                  packageName: app.packageName,
                                );
                              }
                            },
                            usageTime: app.dailyUsageSeconds,
                            appImage: app.icon != null
                                ? Image.memory(app.icon!)
                                : const Icon(Icons.apps),
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            "PushLock",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Track and control your app usage",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: "All"),
          Tab(text: "Social"),
          Tab(text: "Games"),
          Tab(text: "Productivity"),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apps_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            "No apps in this category",
            style: TextStyle(color: Colors.grey[400], fontSize: 18),
          ),
        ],
      ),
    );
  }
}
