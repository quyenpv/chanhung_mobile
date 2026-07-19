import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/controller/estimate/estimate_controller.dart';
import 'package:chanhung/data/repo/estimate/estimate_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_bottom_nav_bar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/screens/estimate/widget/estimate_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EstimateScreen extends StatefulWidget {
  const EstimateScreen({super.key});

  @override
  State<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends State<EstimateScreen> {
  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(EstimateRepo(apiClient: Get.find()));
    final controller = Get.put(EstimateController(estimateRepo: Get.find()));
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
        title: LocalStrings.estimates.tr,
      ),
      drawer: const AppDrawer(),
      body: GetBuilder<EstimateController>(
        builder: (controller) {
          return controller.isLoading
              ? const CustomLoader()
              : RefreshIndicator(
                  onRefresh: () async {
                    await controller.initialData(shouldLoad: false);
                  },
                  color: Theme.of(context).primaryColor,
                  child: controller.estimatesModel.success!
                      ? Padding(
                          padding: const EdgeInsets.all(Dimensions.space15),
                          child: ListView.separated(
                              itemBuilder: (context, index) {
                                return EstimateCard(
                                  currency: controller.currency ?? '',
                                  estimateModel:
                                      controller.estimatesModel.data![index],
                                );
                              },
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: Dimensions.space10),
                              itemCount:
                                  controller.estimatesModel.data!.length),
                        )
                      : const NoDataWidget(),
                );
        },
      ),
    );
  }
}
