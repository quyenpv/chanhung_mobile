import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/service/staff_location_tracking_service.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/view/components/app-bar/action_button_icon_widget.dart';
import 'package:chanhung/view/components/app_bottom_nav_bar.dart';
import 'package:chanhung/view/components/circle_image_button.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/image/app_logo_image.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/screens/dashboard/widget/overview_card.dart';
import 'package:chanhung/view/screens/dashboard/widget/drawer.dart';
import 'package:chanhung/view/screens/project/widget/project_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/data/controller/dashboard/dashboard_controller.dart';
import 'package:chanhung/data/repo/dashboard/dashboard_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/will_pop_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(DashboardRepo(apiClient: Get.find()));
    final controller = Get.put(DashboardController(dashboardRepo: Get.find()));
    controller.isLoading = true;

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initialData();
      _startStaffLocationTracking();
    });
  }

  Future<void> _startStaffLocationTracking() async {
    try {
      if (!Get.isRegistered<StaffLocationTrackingService>()) {
        final service = await Get.putAsync(
            () => StaffLocationTrackingService().init(),
            permanent: true);
        await service.startIfNeeded();
      } else {
        await Get.find<StaffLocationTrackingService>().startIfNeeded();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return WillPopWidget(
      nextRoute: "",
      child: GetBuilder<DashboardController>(
        builder: (controller) {
          final dashboardData = controller.dashboardModel.data;
          final clientData = dashboardData?.clientData;
          final projects = dashboardData?.projects ?? [];
          final widgetsData = dashboardData?.widgetsData;
          final hasWorkplaceModules =
              controller.isHumanResourcesEnable || controller.isDmsOfficeEnable;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              toolbarHeight: 50,
              leading: dashboardData == null
                  ? const SizedBox.shrink()
                  : Builder(builder: (context) {
                      return IconButton(
                        icon: const Icon(
                          Icons.menu_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        tooltip: MaterialLocalizations.of(context)
                            .openAppDrawerTooltip,
                      );
                    }),
              centerTitle: true,
              title: AppLogoImage(
                logo: controller.appLogo,
                height: 30,
                color: Colors.white,
              ),
              actions: [
                ActionButtonIconWidget(
                  pressed: () => Get.toNamed(RouteHelper.settingsScreen),
                  icon: Icons.settings,
                  size: 35,
                  iconColor: Colors.white,
                ),
              ],
            ),
            drawer: dashboardData == null
                ? null
                : HomeDrawer(dashboardModel: controller.dashboardModel),
            body: controller.isLoading
                ? const CustomLoader()
                : dashboardData == null
                    ? const NoDataWidget(text: LocalStrings.somethingWentWrong)
                    : RefreshIndicator(
                        onRefresh: () async {
                          await controller.initialData(shouldLoad: false);
                        },
                        color: Theme.of(context).primaryColor,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(Dimensions.space10),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          ColorResources.blueGreyColor,
                                      radius: 31,
                                      child: CircleImageWidget(
                                        imagePath:
                                            '${UrlContainer.profileImgUrl}${clientData?.avatar ?? ''}',
                                        isAsset: false,
                                        isProfile: true,
                                        width: 60,
                                        height: 60,
                                      ),
                                    ),
                                    const SizedBox(width: Dimensions.space20),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                            text: TextSpan(children: [
                                          TextSpan(
                                            text: '${LocalStrings.welcome.tr} ',
                                            style: regularLarge.copyWith(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .color),
                                          ),
                                          TextSpan(
                                            text:
                                                '${clientData?.firstName ?? ''} ${clientData?.lastName ?? ''}',
                                            style: regularLarge.copyWith(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .color),
                                          ),
                                        ])),
                                        const SizedBox(
                                            height: Dimensions.space5),
                                        Text(
                                          '${clientData?.jobTitle ?? ''} - ${clientData?.companyName ?? ''}',
                                          style: regularSmall.copyWith(
                                              color:
                                                  ColorResources.blueGreyColor),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  if (controller.isProjectsEnable)
                                    OverviewCard(
                                        icon: Icons.grid_view,
                                        iconColor: ColorResources.blueColor,
                                        name: LocalStrings.projects.tr,
                                        onPress: () => Get.toNamed(
                                            RouteHelper.projectScreen),
                                        number:
                                            widgetsData?.projects?.toString() ??
                                                '0',
                                        color: ColorResources.blueColor),
                                  if (controller.isInvoicesEnable)
                                    OverviewCard(
                                        icon: Icons.article_outlined,
                                        iconColor: ColorResources.redColor,
                                        name: LocalStrings.totalInvoiced.tr,
                                        onPress: () => Get.toNamed(
                                            RouteHelper.invoiceScreen),
                                        number:
                                            controller.formatDashboardAmount(
                                                widgetsData?.totalInvoiced ??
                                                    0),
                                        color: ColorResources.redColor),
                                ],
                              ),
                              const SizedBox(height: Dimensions.space10),
                              Row(
                                children: [
                                  if (controller.isPaymentsEnable)
                                    OverviewCard(
                                        icon: Icons.check_box_outlined,
                                        iconColor: ColorResources.yellowColor,
                                        name: LocalStrings.payments.tr,
                                        onPress: () => Get.toNamed(
                                            RouteHelper.paymentScreen),
                                        number:
                                            controller.formatDashboardAmount(
                                                widgetsData?.payments ?? 0),
                                        color: ColorResources.yellowColor),
                                  if (controller.isInvoicesEnable)
                                    OverviewCard(
                                        icon: Icons.auto_mode_outlined,
                                        iconColor: ColorResources.greenColor,
                                        name: LocalStrings.amountDue.tr,
                                        onPress: () => Get.toNamed(
                                            RouteHelper.invoiceScreen),
                                        number:
                                            controller.formatDashboardAmount(
                                                widgetsData?.due ?? 0),
                                        color: ColorResources.greenColor),
                                ],
                              ),
                              if (hasWorkplaceModules) ...[
                                const SizedBox(height: Dimensions.space10),
                                Row(
                                  children: [
                                    if (controller.isHumanResourcesEnable)
                                      OverviewCard(
                                          icon: Icons.groups_outlined,
                                          iconColor: ColorResources.purpleColor,
                                          name: LocalStrings.humanResources.tr,
                                          onPress: () =>
                                              Get.toNamed(RouteHelper.hrScreen),
                                          number: (widgetsData
                                                      ?.hr?.totalEmployees ??
                                                  0)
                                              .toString(),
                                          color: ColorResources.purpleColor),
                                    if (controller.isDmsOfficeEnable)
                                      OverviewCard(
                                          icon: Icons.folder_copy_outlined,
                                          iconColor:
                                              ColorResources.primaryColor,
                                          name: LocalStrings.dmsOffice.tr,
                                          onPress: () => Get.toNamed(
                                              RouteHelper.dmsScreen),
                                          number:
                                              (widgetsData?.dmsAttentionCount ??
                                                      0)
                                                  .toString(),
                                          color: ColorResources.primaryColor),
                                  ],
                                ),
                              ],
                              const SizedBox(height: Dimensions.space10),
                              if (controller.isProjectsEnable)
                                Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 15,
                                      color: ColorResources.secondaryColor,
                                    ),
                                    const SizedBox(width: Dimensions.space5),
                                    Text(
                                      LocalStrings.projects.tr,
                                      style: regularLarge,
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        Get.toNamed(RouteHelper.projectScreen);
                                      },
                                      child: Text(
                                        LocalStrings.viewAll.tr,
                                        style: lightSmall.copyWith(
                                            color:
                                                ColorResources.blueGreyColor),
                                      ),
                                    )
                                  ],
                                ),
                              if (controller.isProjectsEnable)
                                projects.isNotEmpty
                                    ? ListView.separated(
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          return ProjectCard(
                                            projectModel: projects[index],
                                          );
                                        },
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(
                                                height: Dimensions.space10),
                                        itemCount: projects.length)
                                    : const NoDataWidget(),
                            ],
                          ),
                        ),
                      ),
          );
        },
      ),
    );
  }
}
