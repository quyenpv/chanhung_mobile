import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/local_strings.dart';

enum AppBottomNavItem { home, projects, dms, hr, settings }

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.current});

  final AppBottomNavItem current;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: current.index,
      onTap: (index) => _open(AppBottomNavItem.values[index]),
      selectedItemColor: ColorResources.primaryColor,
      unselectedItemColor: ColorResources.blueGreyColor,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: LocalStrings.home.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.task_outlined),
          activeIcon: const Icon(Icons.task),
          label: LocalStrings.projects.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.folder_copy_outlined),
          activeIcon: const Icon(Icons.folder_copy),
          label: LocalStrings.dmsOffice.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.groups_outlined),
          activeIcon: const Icon(Icons.groups),
          label: LocalStrings.humanResources.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined),
          activeIcon: const Icon(Icons.settings),
          label: LocalStrings.settings.tr,
        ),
      ],
    );
  }

  void _open(AppBottomNavItem item) {
    final route = switch (item) {
      AppBottomNavItem.home => RouteHelper.dashboardScreen,
      AppBottomNavItem.projects => RouteHelper.projectScreen,
      AppBottomNavItem.dms => RouteHelper.dmsScreen,
      AppBottomNavItem.hr => RouteHelper.hrScreen,
      AppBottomNavItem.settings => RouteHelper.settingsScreen,
    };

    if (item == current && Get.currentRoute == route) {
      return;
    }

    Get.offAllNamed(route);
  }
}
