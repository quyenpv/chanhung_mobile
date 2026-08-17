import 'package:chanhung/data/controller/dashboard/dashboard_controller.dart';
import 'package:chanhung/data/repo/dashboard/dashboard_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/screens/dashboard/widget/drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reuses the authenticated user's navigation drawer on feature pages.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = _ensureDashboardController();
    return HomeDrawer(dashboardModel: dashboardController.dashboardModel);
  }

  DashboardController _ensureDashboardController() {
    if (Get.isRegistered<DashboardController>()) {
      return Get.find<DashboardController>();
    }
    if (!Get.isRegistered<ApiClient>()) {
      Get.put(
        ApiClient(sharedPreferences: Get.find()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<DashboardRepo>()) {
      Get.put(
        DashboardRepo(apiClient: Get.find()),
        permanent: true,
      );
    }
    final controller = Get.put(
      DashboardController(dashboardRepo: Get.find()),
      permanent: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialData(shouldLoad: false);
    });
    return controller;
  }
}
