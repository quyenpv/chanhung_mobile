import 'package:chanhung/data/controller/dashboard/dashboard_controller.dart';
import 'package:chanhung/view/screens/dashboard/widget/drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reuses the authenticated user's navigation drawer on feature pages.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    return HomeDrawer(dashboardModel: dashboardController.dashboardModel);
  }
}
