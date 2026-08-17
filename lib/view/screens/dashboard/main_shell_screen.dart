import 'package:chanhung/view/components/app_bottom_nav_bar.dart';
import 'package:chanhung/view/components/dialog/exit_dialog.dart';
import 'package:chanhung/view/screens/dashboard/dashboard_screen.dart';
import 'package:chanhung/view/screens/dms/dms_screen.dart';
import 'package:chanhung/view/screens/hr/hr_screen.dart';
import 'package:chanhung/view/screens/menu/menu_screen.dart';
import 'package:chanhung/view/screens/project/projects_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Khung 5 tab dưới: không dùng Get.offNamed nên dashboard/service nền không bị hủy.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final _visited = <AppBottomNavItem>{AppBottomNavItem.home};

  @override
  void initState() {
    final tabs = Get.isRegistered<AppTabController>()
        ? Get.find<AppTabController>()
        : Get.put(AppTabController());
    final arg = Get.arguments;
    tabs.current =
        arg is AppBottomNavItem ? arg : AppBottomNavItem.home;
    _visited.add(tabs.current);
    super.initState();
  }

  Widget _page(AppBottomNavItem item, Widget child) {
    if (!_visited.contains(item)) {
      return const SizedBox.shrink();
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppTabController>(
      builder: (tabs) {
        _visited.add(tabs.current);
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            if (tabs.current != AppBottomNavItem.home) {
              tabs.select(AppBottomNavItem.home);
              return false;
            }
            showExitDialog(context);
            return false;
          },
          child: Scaffold(
            body: IndexedStack(
              index: tabs.index,
              children: [
                const HomeScreen(nested: true),
                _page(
                  AppBottomNavItem.projects,
                  const ProjectsScreen(nested: true),
                ),
                _page(
                  AppBottomNavItem.dms,
                  const DmsScreen(nested: true),
                ),
                _page(
                  AppBottomNavItem.hr,
                  const HrScreen(nested: true),
                ),
                _page(
                  AppBottomNavItem.settings,
                  const MenuScreen(nested: true),
                ),
              ],
            ),
            bottomNavigationBar: AppBottomNavBar(current: tabs.current),
          ),
        );
      },
    );
  }
}
