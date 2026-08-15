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
        // Mỗi tab chiếm 1/5 chiều rộng màn hình: tâm tại (index + 0.5) / 5
        final centerFraction = (currentIndex + 0.5) / 5.0;
        final activeCenterX = screenWidth * centerFraction;
        final circleLeft = activeCenterX - 32.0; // 64 / 2 = 32

        return SizedBox(
          height: 84 + bottomInset,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Nền thanh điều hướng với đường cong Notch ôm theo vị trí tab đang chọn
              PhysicalShape(
                color: Theme.of(context).cardColor,
                elevation: 18,
                shadowColor: const Color(0xFF17262A).withValues(alpha: 0.16),
                clipper: _DynamicCurvedNotchClipper(
                  centerFraction: centerFraction,
                  radius: 34,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 10, 8, bottomInset),
                  child: SizedBox(
                    height: 62,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: tabs.map((t) {
                        final isSelected = t.item == current;
                        return Expanded(
                          child: isSelected
                              ? const SizedBox.shrink()
                              : _buildInactiveItem(t.item, t.icon, t.label),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // Nút tròn nổi lớn (64x64) di chuyển theo Tab Active
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
                        width: 64,
                        height: 64,
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
                            size: 30,
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

  Widget _buildInactiveItem(AppBottomNavItem item, IconData icon, String label) {
    return Tooltip(
      message: label,
      child: InkResponse(
        onTap: () => _open(item),
        radius: 28,
        child: Center(
          child: Icon(
            icon,
            size: 26,
            color: const Color(0xFF2E3E5C),
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

/// Custom Clipper tạo đường cong uốn lõm chính xác tại vị trí tab đang Active
class _DynamicCurvedNotchClipper extends CustomClipper<Path> {
  final double centerFraction;
  final double radius;

  const _DynamicCurvedNotchClipper({
    required this.centerFraction,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final center = size.width * centerFraction;
    final notchWidth = radius * 2.5;
    const cornerRadius = 18.0;

    final path = Path()..moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    final notchLeft = (center - notchWidth / 2).clamp(0.0, size.width);
    final notchRight = (center + notchWidth / 2).clamp(0.0, size.width);

    // Kẻ đường thẳng mép trên đến vị trí bắt đầu uốn lõm
    if (notchLeft > cornerRadius) {
      path.lineTo(notchLeft, 0);
    }

    // Vẽ đường cong mềm mại uốn cong xuống dưới
    path.cubicTo(
      center - radius * 1.15,
      0,
      center - radius * 1.02,
      radius * 0.88,
      center,
      radius * 0.88,
    );
    path.cubicTo(
      center + radius * 1.02,
      radius * 0.88,
      center + radius * 1.15,
      0,
      notchRight,
      0,
    );

    // Kẻ tiếp đường thẳng sang góc phải
    if (notchRight < size.width - cornerRadius) {
      path.lineTo(size.width - cornerRadius, 0);
    }

    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    return path..close();
  }

  @override
  bool shouldReclip(covariant _DynamicCurvedNotchClipper oldClipper) =>
      oldClipper.centerFraction != centerFraction || oldClipper.radius != radius;
}
