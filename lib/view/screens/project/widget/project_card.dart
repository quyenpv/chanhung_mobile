import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/model/project/project_model.dart';
import 'package:chanhung/view/components/divider/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/app_design.dart';
import 'package:chanhung/view/components/animation/template_entrance.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.projectModel,
    this.animationOrder = 0,
  });
  final Project projectModel;
  final int animationOrder;

  @override
  Widget build(BuildContext context) {
    return TemplateEntrance(
      order: animationOrder,
      child: GestureDetector(
        onTap: () {
          Get.toNamed(RouteHelper.withId(
              RouteHelper.projectDetailsScreen, projectModel.id));
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          ),
          margin: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                boxShadow: AppDesign.softShadow(Theme.of(context).shadowColor),
              ),
              child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              projectModel.title!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: regularLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: ShapeDecoration(
                                shape: StadiumBorder(
                                  side: BorderSide(
                                      color: ColorResources.projectStatusColor(
                                          projectModel.statusId!)),
                                ),
                              ),
                              child: Text(
                                projectModel.statusTitle!.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: lightSmall.copyWith(
                                    color: ColorResources.projectStatusColor(
                                        projectModel.statusId!)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.space5),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          projectModel.description ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: regularSmall.copyWith(
                              color: ColorResources.blueGreyColor),
                        ),
                      ),
                      const CustomDivider(space: Dimensions.space10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _ProjectMeta(
                              text: projectModel.companyName!,
                              icon: Icons.account_box_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            flex: 2,
                            child: _ProjectMeta(
                              text: projectModel.deadline ?? '',
                              icon: Icons.calendar_month_rounded,
                              alignEnd: true,
                            ),
                          ),
                        ],
                      )
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectMeta extends StatelessWidget {
  const _ProjectMeta({
    required this.text,
    required this.icon,
    this.alignEnd = false,
  });

  final String text;
  final IconData icon;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: ColorResources.blueGreyColor, size: 15),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: regularSmall.copyWith(color: ColorResources.blueGreyColor),
          ),
        ),
      ],
    );
  }
}
