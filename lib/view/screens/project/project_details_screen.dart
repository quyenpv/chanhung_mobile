import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/project/project_controller.dart';
import 'package:chanhung/data/repo/project/project_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/screens/project/section/project_comments.dart';
import 'package:chanhung/view/screens/project/section/project_invoices.dart';
import 'package:chanhung/view/screens/project/section/project_overview.dart';
import 'package:chanhung/view/screens/project/section/project_tasks.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key, required this.id});
  final String id;

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(ProjectRepo(apiClient: Get.find()));
    final controller = Get.put(ProjectController(projectRepo: Get.find()));
    controller.isLoading = true;
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.loadProjectDetails(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: LocalStrings.projectDetails.tr,
      ),
      drawer: const AppDrawer(),
      body: GetBuilder<ProjectController>(
        builder: (controller) {
          final project = controller.projectDetailsModel.data;
          if (controller.isLoading) {
            return const CustomLoader();
          }
          if (project == null) {
            return const Center(child: NoDataWidget());
          }
          return ContainedTabBarView(
            tabBarProperties: TabBarProperties(
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                unselectedLabelColor: ColorResources.blueGreyColor,
                labelColor: Theme.of(context).textTheme.bodyLarge!.color,
                labelStyle: regularDefault,
                indicatorColor: ColorResources.secondaryColor,
                labelPadding: const EdgeInsets.symmetric(
                    vertical: Dimensions.space15,
                    horizontal: Dimensions.space16)),
            tabs: [
              Text(LocalStrings.overview.tr, style: regularDefault),
              Text(LocalStrings.tasks.tr, style: regularDefault),
              Text(LocalStrings.comments.tr, style: regularDefault),
              Text(LocalStrings.invoices.tr, style: regularDefault),
            ],
            views: [
              RefreshIndicator(
                  color: ColorResources.primaryColor,
                  onRefresh: () async {
                    await controller.loadProjectDetails(widget.id);
                  },
                  child: ProjectOverview(
                      currency: controller.currency ?? '', project: project)),
              ProjectTasks(id: widget.id),
              ProjectComments(comments: project.comments),
              ProjectInvoices(id: widget.id),
            ],
          );
        },
      ),
    );
  }
}
