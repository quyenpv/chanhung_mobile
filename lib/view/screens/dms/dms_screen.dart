import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/dms_status_helper.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/dms/dms_controller.dart';
import 'package:chanhung/data/model/dms/dms_document_model.dart';
import 'package:chanhung/data/repo/dms/dms_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_bottom_nav_bar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';

class DmsScreen extends StatefulWidget {
  const DmsScreen({super.key});

  @override
  State<DmsScreen> createState() => _DmsScreenState();
}

class _DmsScreenState extends State<DmsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    _searchController = TextEditingController();
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(DmsRepo(apiClient: Get.find()));
    final controller = Get.put(DmsController(dmsRepo: Get.find()));
    controller.isLoading = true;
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: LocalStrings.dmsOffice.tr),
      drawer: const AppDrawer(),
      body: GetBuilder<DmsController>(
        builder: (controller) {
          final documents = controller.documentsModel.data ?? [];

          return RefreshIndicator(
            color: Theme.of(context).primaryColor,
            onRefresh: () async {
              await controller.initialData(shouldLoad: false);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Dimensions.space15),
              children: [
                _DmsSearchField(
                  controller: _searchController,
                  onSubmitted: controller.searchDocuments,
                  onClear: () async {
                    _searchController.clear();
                    await controller.clearSearch();
                  },
                ),
                const SizedBox(height: Dimensions.space15),
                _DmsFilterBar(controller: controller),
                const SizedBox(height: Dimensions.space15),
                if (controller.isLoading)
                  const CustomLoader()
                else if (documents.isEmpty)
                  const NoDataWidget(margin: 12)
                else
                  ...documents.map((document) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: Dimensions.space10),
                        child: _DmsDocumentCard(document: document),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DmsSearchField extends StatelessWidget {
  const _DmsSearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: LocalStrings.search.tr,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.close),
          tooltip: LocalStrings.clearSearch.tr,
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DmsFilterBar extends StatelessWidget {
  const _DmsFilterBar({required this.controller});

  final DmsController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(controller.filters.length, (index) {
          final filter = controller.filters[index];
          final selected = controller.selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: Dimensions.space10),
            child: ChoiceChip(
              label: Text(filter.label.tr),
              selected: selected,
              onSelected: (_) => controller.setFilter(index),
            ),
          );
        }),
      ),
    );
  }
}

class _DmsDocumentCard extends StatelessWidget {
  const _DmsDocumentCard({required this.document});

  final DmsDocument document;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(document.status);
    return GestureDetector(
      onTap: () {
        final documentId = document.id ?? '';
        Get.toNamed(
          '${RouteHelper.dmsDocumentDetailsScreen}?id=${Uri.encodeComponent(documentId)}',
          arguments: documentId,
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.space15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      document.docCode?.isNotEmpty == true
                          ? document.docCode!
                          : LocalStrings.documents.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mediumLarge.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    ),
                  ),
                  _Pill(
                    text: dmsStatusLabel(document.status),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.space10),
              Text(
                document.title ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: regularDefault.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: Dimensions.space10),
              Wrap(
                spacing: Dimensions.space10,
                runSpacing: Dimensions.space5,
                children: [
                  _MetaText(
                    icon: Icons.swap_horiz_outlined,
                    text: _groupLabel(document.docGroup),
                  ),
                  if (document.typeTitle?.isNotEmpty == true)
                    _MetaText(
                      icon: Icons.description_outlined,
                      text: document.typeTitle!,
                    ),
                  if (document.organization?.isNotEmpty == true)
                    _MetaText(
                      icon: Icons.business_outlined,
                      text: document.organization!,
                    ),
                  if (document.issuedDate?.isNotEmpty == true)
                    _MetaText(
                      icon: Icons.calendar_today_outlined,
                      text: document.issuedDate!,
                    ),
                  if (document.attachmentCount > 0)
                    _MetaText(
                      icon: Icons.attach_file,
                      text: document.attachmentCount.toString(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Text(
        text,
        style: lightSmall.copyWith(color: color),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ColorResources.blueGreyColor),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: lightSmall.copyWith(color: ColorResources.blueGreyColor),
          ),
        ),
      ],
    );
  }
}

String _groupLabel(String? group) {
  if (group == 'incoming') {
    return LocalStrings.incoming.tr;
  }
  if (group == 'outgoing') {
    return LocalStrings.outgoing.tr;
  }
  return group ?? '';
}

Color _statusColor(String? status) {
  switch (status) {
    case 'published':
    case 'completed':
      return ColorResources.greenColor;
    case 'pending':
    case 'processing':
      return ColorResources.yellowColor;
    case 'cancelled':
    case 'rejected':
      return ColorResources.redColor;
    default:
      return ColorResources.primaryColor;
  }
}
