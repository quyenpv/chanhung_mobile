import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/data/controller/project/project_controller.dart';
import 'package:chanhung/data/repo/project/project_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/screens/invoice/widget/invoice_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProjectInvoices extends StatefulWidget {
  const ProjectInvoices({super.key, required this.id});
  final String id;

  @override
  State<ProjectInvoices> createState() => _ProjectInvoicesState();
}

class _ProjectInvoicesState extends State<ProjectInvoices> {
  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(ProjectRepo(apiClient: Get.find()));
    final controller = Get.put(ProjectController(projectRepo: Get.find()));
    controller.isInvoicesLoading = true;
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.loadProjectInvoices(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectController>(
      builder: (controller) {
        return Scaffold(
          body: controller.isInvoicesLoading
              ? const CustomLoader()
              : (controller.invoicesModel.data?.isNotEmpty ?? false)
                  ? RefreshIndicator(
                      onRefresh: () async {
                        await controller.loadProjectInvoices(widget.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView.separated(
                            itemBuilder: (context, index) {
                              return InvoiceCard(
                                  currency: controller.currency ?? '',
                                  invoiceModel:
                                      controller.invoicesModel.data![index]);
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: Dimensions.space10),
                            itemCount: controller.invoicesModel.data!.length),
                      ),
                    )
                  : const Center(child: NoDataWidget()),
        );
      },
    );
  }
}
