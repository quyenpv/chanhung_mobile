import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/project/project_controller.dart';
import 'package:chanhung/data/repo/project/project_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_bottom_nav_bar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/screens/project/section/project_dashboard_section.dart';
import 'package:chanhung/view/screens/project/widget/project_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(ProjectRepo(apiClient: Get.find()));
    final controller = Get.put(ProjectController(projectRepo: Get.find()));
    controller.isLoading = true;
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: LocalStrings.projects.tr,
        ),
        drawer: const AppDrawer(),
        bottomNavigationBar:
            const AppBottomNavBar(current: AppBottomNavItem.projects),
        body: Column(
          children: [
            TabBar(
              isScrollable: false,
              indicatorColor: ColorResources.primaryColor,
              labelColor: Theme.of(context).textTheme.bodyLarge?.color,
              unselectedLabelColor: ColorResources.blueGreyColor,
              labelStyle: regularDefault,
              tabs: [
                Tab(text: LocalStrings.dashboard.tr),
                Tab(text: LocalStrings.projectsList.tr),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const ProjectDashboardSection(),
                  GetBuilder<ProjectController>(
                    builder: (controller) {
                      return controller.isLoading
                          ? const CustomLoader()
                          : RefreshIndicator(
                              color: ColorResources.primaryColor,
                              onRefresh: () async {
                                await controller.initialData(shouldLoad: false);
                              },
                              child: controller.hasProjects
                                  ? ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(
                                          Dimensions.space15,
                                          Dimensions.space15,
                                          Dimensions.space15,
                                          90),
                                      itemBuilder: (context, index) {
                                        return ProjectCard(
                                          projectModel: controller
                                              .projectsModel.data![index],
                                          animationOrder: index.clamp(0, 5),
                                        );
                                      },
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(
                                              height: Dimensions.space10),
                                      itemCount: controller
                                          .projectsModel.data!.length)
                                  : ListView(
                                      children: const [
                                        SizedBox(height: 120),
                                        NoDataWidget(),
                                      ],
                                    ),
                            );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
