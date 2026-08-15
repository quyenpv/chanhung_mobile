import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum AppBottomNavItem { home, projects, dms, hr, settings }

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

    final currentIndex = switch (current) {
      AppBottomNavItem.home => 0,
      AppBottomNavItem.projects => 1,
      AppBottomNavItem.dms => 2,
      AppBottomNavItem.hr => 3,
      AppBottomNavItem.settings => 4,
    };

    final activeTab = tabs[currentIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final tabWidth = screenWidth / 5.0;
        final circleLeft = (currentIndex * tabWidth) + (tabWidth / 2.0) - 30.0;

        return SizedBox(
          height: 80 + bottomInset,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Thanh nền trắng đổ bóng hiện đại bo góc
              Container(
                height: 64 + bottomInset,
                padding: EdgeInsets.fromLTRB(4, 4, 4, bottomInset),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: tabs.map((t) {
                    final isSelected = t.item == current;
                    return Expanded(
                      child: InkWell(
                        onTap: () => _open(t.item),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Center(
                          child: Opacity(
                            opacity: isSelected ? 0.0 : 1.0,
                            child: Icon(
                              t.icon,
                              size: 26,
                              color: const Color(0xFF2E3E5C),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Nút tròn nổi lớn (60x60) có hiệu ứng trượt mượt mà theo Tab Active
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                top: 0,
                left: circleLeft,
                child: Semantics(
                  button: true,
                  label: activeTab.label,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _open(current),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF4168E8),
                              Color(0xFF2646C4),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2646C4).withOpacity(0.42),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            activeTab.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

    if (item == current && Get.currentRoute == route) return;
    Get.offNamed(route);
  }
}
