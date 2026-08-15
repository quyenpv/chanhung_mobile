import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/app_design.dart';
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

    final items = [
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

    return SizedBox(
      height: 72 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 64 + bottomInset,
            padding: EdgeInsets.fromLTRB(6, 4, 6, bottomInset),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: AppDesign.ink.withValues(alpha: .10),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items
                  .map((e) => _buildNavItem(context, e.item, e.icon, e.label))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, AppBottomNavItem item, IconData icon, String label) {
    final selected = current == item;

    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => _open(item),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                transform: selected
                    ? Matrix4.translationValues(0, -14, 0)
                    : Matrix4.translationValues(0, 0, 0),
                width: selected ? 48 : 34,
                height: selected ? 48 : 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppDesign.brightBlue, AppDesign.accentBlue],
                        )
                      : null,
                  color: selected ? null : Colors.transparent,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppDesign.accentBlue.withValues(alpha: .38),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: selected ? 24 : 22,
                    color: selected ? Colors.white : AppDesign.mutedInk,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppDesign.accentBlue
                      : AppDesign.mutedInk.withValues(alpha: .75),
                  fontFamily: 'Montserrat-Arabic',
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
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
