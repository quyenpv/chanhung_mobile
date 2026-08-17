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
        const corner = 18.0;
        const radius = 33.0;
        final minX = corner + radius + 4.0;
        final maxX = screenWidth - corner - radius - 4.0;
        final centerFraction = (currentIndex + 0.5) / 5.0;
        final rawCenterX = screenWidth.isFinite ? screenWidth * centerFraction : 0.0;
        final activeCenterX = _safeCenterX(rawCenterX, minX, maxX, screenWidth);
        final circleLeft = activeCenterX - 31.0;

        return SizedBox(
          height: 84 + bottomInset,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Thanh nền trắng với đường cong vòm lõm (Curved Notch) ôm lấy nút tròn
              PhysicalShape(
                color: Theme.of(context).cardColor,
                elevation: 18,
                shadowColor: const Color(0xFF17262A).withValues(alpha: 0.16),
                clipper: _SafeCurvedNotchClipper(
                  activeCenterX: activeCenterX,
                  radius: radius,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(6, 10, 6, bottomInset),
                  child: SizedBox(
                    height: 62,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: tabs.map((t) {
                        final isSelected = t.item == current;
                        return Expanded(
                          child: InkResponse(
                            onTap: () => _open(t.item),
                            radius: 28,
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
                ),
              ),

              // Nút tròn nổi lớn (62x62) màu xanh 3D phát sáng đặt chính xác trong vòm lõm
              Positioned(
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
                        width: 62,
                        height: 62,
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
                              color: const Color(0xFF2646C4).withValues(alpha: 0.42),
                              blurRadius: 18,
                              offset: const Offset(0, 9),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            activeTab.icon,
                            color: Colors.white,
                            size: 29,
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

double _safeCenterX(double value, double min, double max, double width) {
  if (!width.isFinite || width <= 0) return 0;
  if (!min.isFinite || !max.isFinite || min > max) {
    return width / 2;
  }
  if (!value.isFinite) return (min + max) / 2;
  return value.clamp(min, max);
}

/// Clipper vẽ đường cong uốn lõm mềm mại (Curved Concave Notch) an toàn 100% không bao giờ lỗi toạ độ
class _SafeCurvedNotchClipper extends CustomClipper<Path> {
  final double activeCenterX;
  final double radius;

  const _SafeCurvedNotchClipper({
    required this.activeCenterX,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    const corner = 18.0;

    final notchHalfWidth = radius * 1.2;
    final minCenter = corner + notchHalfWidth;
    final maxCenter = w - corner - notchHalfWidth;
    if (!w.isFinite || w <= minCenter * 2 || minCenter > maxCenter) {
      return Path()..addRect(Rect.fromLTWH(0, 0, w.isFinite ? w : 0, h.isFinite ? h : 0));
    }
    final center = _safeCenterX(activeCenterX, minCenter, maxCenter, w);
    final p1x = center - notchHalfWidth;
    final p2x = center + notchHalfWidth;

    final path = Path();
    path.moveTo(0, corner);
    path.quadraticBezierTo(0, 0, corner, 0);

    path.lineTo(p1x, 0);

    // Đường cong Bezier uốn lõm mềm mại ôm lấy nút tròn
    path.cubicTo(
      center - radius * 0.95,
      0,
      center - radius * 0.82,
      radius * 0.88,
      center,
      radius * 0.88,
    );
    path.cubicTo(
      center + radius * 0.82,
      radius * 0.88,
      center + radius * 0.95,
      0,
      p2x,
      0,
    );

    path.lineTo(w - corner, 0);
    path.quadraticBezierTo(w, 0, w, corner);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _SafeCurvedNotchClipper oldClipper) =>
      oldClipper.activeCenterX != activeCenterX || oldClipper.radius != radius;
}
