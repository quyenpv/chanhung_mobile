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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 82 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          PhysicalShape(
            color: Theme.of(context).cardColor,
            elevation: 18,
            shadowColor: AppDesign.ink.withValues(alpha: .18),
            clipper: const _CenterNotchClipper(radius: 34),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, bottomInset),
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    _item(AppBottomNavItem.home, Icons.home_rounded,
                        LocalStrings.home.tr),
                    _item(AppBottomNavItem.projects, Icons.grid_view_rounded,
                        LocalStrings.projects.tr),
                    const SizedBox(width: 76),
                    _item(AppBottomNavItem.hr, Icons.groups_rounded,
                        LocalStrings.humanResources.tr),
                    _item(AppBottomNavItem.settings, Icons.person_rounded,
                        LocalStrings.settings.tr),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              label: LocalStrings.dmsOffice.tr,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _open(AppBottomNavItem.dms),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: current == AppBottomNavItem.dms
                            ? const [AppDesign.brightBlue, AppDesign.accentBlue]
                            : const [Color(0xFF6A88E5), AppDesign.accentBlue],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppDesign.accentBlue.withValues(alpha: .35),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.folder_copy_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(AppBottomNavItem item, IconData icon, String label) {
    final selected = current == item;
    return Expanded(
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: () => _open(item),
          radius: 28,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  icon,
                  size: 23,
                  color: selected ? AppDesign.accentBlue : AppDesign.mutedInk,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selected ? 18 : 4,
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? AppDesign.accentBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
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
    Get.offAllNamed(route);
  }
}

class _CenterNotchClipper extends CustomClipper<Path> {
  const _CenterNotchClipper({required this.radius});

  final double radius;

  @override
  Path getClip(Size size) {
    final center = size.width / 2;
    final notchWidth = radius * 2.5;
    final path = Path()..moveTo(0, 18);

    path.quadraticBezierTo(0, 0, 18, 0);
    path.lineTo(center - notchWidth / 2, 0);
    path.cubicTo(
      center - radius * 1.15,
      0,
      center - radius * 1.05,
      radius * .88,
      center,
      radius * .88,
    );
    path.cubicTo(
      center + radius * 1.05,
      radius * .88,
      center + radius * 1.15,
      0,
      center + notchWidth / 2,
      0,
    );
    path.lineTo(size.width - 18, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 18);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    return path..close();
  }

  @override
  bool shouldReclip(covariant _CenterNotchClipper oldClipper) =>
      oldClipper.radius != radius;
}
