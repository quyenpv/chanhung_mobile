import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum AppBottomNavItem { home, projects, dms, hr, settings }

class AppTabController extends GetxController {
  AppBottomNavItem current = AppBottomNavItem.home;

  int get index => switch (current) {
        AppBottomNavItem.home => 0,
        AppBottomNavItem.projects => 1,
        AppBottomNavItem.dms => 2,
        AppBottomNavItem.hr => 3,
        AppBottomNavItem.settings => 4,
      };

  void select(AppBottomNavItem item) {
    if (current == item) return;
    current = item;
    update();
  }
}

class AppTabNavigation {
  static AppBottomNavItem? tabItemFor(String route) {
    return switch (route) {
      RouteHelper.dashboardScreen => AppBottomNavItem.home,
      RouteHelper.projectScreen => AppBottomNavItem.projects,
      RouteHelper.dmsScreen => AppBottomNavItem.dms,
      RouteHelper.hrScreen => AppBottomNavItem.hr,
      RouteHelper.settingsScreen => AppBottomNavItem.settings,
      _ => null,
    };
  }

  static bool isCurrent(String route) {
    final item = tabItemFor(route);
    if (item != null &&
        Get.isRegistered<AppTabController>() &&
        Get.currentRoute == RouteHelper.dashboardScreen) {
      return Get.find<AppTabController>().current == item;
    }
    return Get.currentRoute == route;
  }

  static void selectTab(AppBottomNavItem item) {
    if (Get.isRegistered<AppTabController>() &&
        Get.currentRoute == RouteHelper.dashboardScreen) {
      Get.find<AppTabController>().select(item);
      return;
    }
    if (Get.isRegistered<AppTabController>()) {
      Get.find<AppTabController>().select(item);
    }
    Get.offAllNamed(RouteHelper.dashboardScreen, arguments: item);
  }

  static void open(String route) {
    final item = tabItemFor(route);
    if (item != null) {
      selectTab(item);
      return;
    }
    if (Get.currentRoute == route) return;
    Get.toNamed(route);
  }
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.current});

  final AppBottomNavItem current;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      return const SizedBox.shrink();
    }
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final tabs = [
      (
        item: AppBottomNavItem.home,
        icon: Icons.home_rounded,
        label: LocalStrings.home.tr
      ),
      (
        item: AppBottomNavItem.projects,
        icon: Icons.grid_view_rounded,
        label: LocalStrings.projects.tr
      ),
      (
        item: AppBottomNavItem.dms,
        icon: Icons.folder_copy_rounded,
        label: LocalStrings.dmsOffice.tr
      ),
      (
        item: AppBottomNavItem.hr,
        icon: Icons.groups_rounded,
        label: LocalStrings.humanResources.tr
      ),
      (
        item: AppBottomNavItem.settings,
        icon: Icons.person_rounded,
        label: LocalStrings.settings.tr
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + bottomInset),
      child: Material(
        color: Theme.of(context).cardColor,
        elevation: 10,
        shadowColor: const Color(0xFF17262A).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 64,
          child: Row(
            children: tabs.map((t) {
              final selected = t.item == current;
              return Expanded(
                child: InkWell(
                  onTap: () => AppTabNavigation.selectTab(t.item),
                  borderRadius: BorderRadius.circular(22),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: selected ? 48 : 36,
                      height: selected ? 48 : 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? const Color(0xFF2646C4)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        t.icon,
                        size: selected ? 24 : 22,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF2E3E5C),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
