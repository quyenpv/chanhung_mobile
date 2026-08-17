import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/service/staff_location_tracking_service.dart';
import 'package:chanhung/core/service/staff_emergency_audio_service.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/core/utils/app_design.dart';
import 'package:chanhung/core/utils/images.dart';
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
    Get.put(ApiClient(sharedPreferences: Get.find()), permanent: true);
    Get.put(DashboardRepo(apiClient: Get.find()), permanent: true);
    final controller = Get.put(
      DashboardController(dashboardRepo: Get.find()),
      permanent: true,
    );
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

    try {
      if (!Get.isRegistered<StaffEmergencyAudioService>()) {
        await Get.putAsync(
            () => StaffEmergencyAudioService().init(),
            permanent: true);
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
              toolbarHeight: 72,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              leading: dashboardData == null
                  ? const SizedBox.shrink()
                  : Builder(builder: (context) {
                      return IconButton(
                        icon: const Icon(
                          Icons.menu_rounded,
                          size: 24,
                          color: AppDesign.ink,
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
                logo: MyImages.appLogo,
                height: 52,
                fit: BoxFit.contain,
              ),
              actions: [
                ActionButtonIconWidget(
                  pressed: () => Get.toNamed(RouteHelper.settingsScreen),
                  icon: Icons.settings,
                  size: 28,
                  iconColor: AppDesign.ink,
                ),
              ],
            ),
            drawer: dashboardData == null
                ? null
                : HomeDrawer(dashboardModel: controller.dashboardModel),
            bottomNavigationBar:
                const AppBottomNavBar(current: AppBottomNavItem.home),
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
                          padding: const EdgeInsets.fromLTRB(
                            AppDesign.pagePadding,
                            8,
                            AppDesign.pagePadding,
                            90,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(
                                      AppDesign.radiusLarge),
                                  boxShadow: AppDesign.softShadow(
                                      Theme.of(context).shadowColor),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: ColorResources
                                          .primaryColor
                                          .withValues(alpha: .12),
                                      radius: 32,
                                      child: CircleImageWidget(
                                        imagePath:
                                            '${UrlContainer.profileImgUrl}${clientData?.avatar ?? ''}',
                                        isAsset: false,
                                        isProfile: true,
                                        width: 60,
                                        height: 60,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                              text: TextSpan(children: [
                                            TextSpan(
                                              text:
                                                  '${LocalStrings.welcome.tr} ',
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
                                                    .color,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ])),
                                          const SizedBox(
                                              height: Dimensions.space5),
                                          Text(
                                            '${clientData?.jobTitle ?? ''} - ${clientData?.companyName ?? ''}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: regularSmall.copyWith(
                                                color: AppDesign.mutedInk),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
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
                                        color: ColorResources.blueColor,
                                        animationOrder: 0),
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
                                        color: ColorResources.redColor,
                                        animationOrder: 1),
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
                                        color: ColorResources.yellowColor,
                                        animationOrder: 2),
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
                                        color: ColorResources.greenColor,
                                        animationOrder: 3),
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
                                          color: ColorResources.purpleColor,
                                          animationOrder: 4),
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
                                          color: ColorResources.primaryColor,
                                          animationOrder: 5),
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
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          return ProjectCard(
                                            projectModel: projects[index],
                                            animationOrder: index.clamp(0, 5),
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
