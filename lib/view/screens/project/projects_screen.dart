import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/controller/project/project_controller.dart';
import 'package:chanhung/data/repo/project/project_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
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
    return Scaffold(
      appBar: CustomAppBar(
        title: LocalStrings.projects.tr,
      ),
      drawer: const AppDrawer(),
      body: GetBuilder<ProjectController>(
        builder: (controller) {
          return controller.isLoading
              ? const CustomLoader()
              : RefreshIndicator(
                  color: Theme.of(context).primaryColor,
                  onRefresh: () async {
                    await controller.initialData(shouldLoad: false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.space15),
                    child: controller.projectsModel.success!
                        ? ListView.separated(
                            itemBuilder: (context, index) {
                              return ProjectCard(
                                projectModel:
                                    controller.projectsModel.data![index],
                                animationOrder: index.clamp(0, 5),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: Dimensions.space10),
                            itemCount: controller.projectsModel.data!.length)
                        : const NoDataWidget(),
                  ),
                );
        },
      ),
    );
  }
}
