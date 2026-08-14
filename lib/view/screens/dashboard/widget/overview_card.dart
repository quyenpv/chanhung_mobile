import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:chanhung/core/utils/app_design.dart';
import 'package:chanhung/view/components/animation/template_entrance.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard(
      {super.key,
      this.icon,
      this.iconColor,
      this.onPress,
      required this.name,
      required this.number,
      required this.color,
      this.animationOrder = 0});
  final String name;
  final IconData? icon;
  final Color? iconColor;
  final String number;
  final Color color;
  final VoidCallback? onPress;
  final int animationOrder;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TemplateEntrance(
        order: animationOrder,
        child: GestureDetector(
          onTap: onPress,
          child: Container(
            constraints: const BoxConstraints(minHeight: 132),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: Dimensions.space5),
            decoration: BoxDecoration(
              gradient: AppDesign.cardGradient(color),
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              boxShadow: AppDesign.softShadow(color),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (icon != null) ...[
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius:
                          BorderRadius.circular(AppDesign.radiusSmall),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 21,
                    ),
                  )
                ],
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mediumLarge.copyWith(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: regularSmall.copyWith(
                        color: Colors.white.withValues(alpha: .86),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
