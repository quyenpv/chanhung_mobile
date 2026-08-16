import 'package:flutter/material.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/style.dart';

class ProjectMetricTile extends StatelessWidget {
  const ProjectMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 48) / 2,
      padding: const EdgeInsets.all(Dimensions.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: regularSmall.copyWith(color: ColorResources.blueGreyColor),
          ),
          const SizedBox(height: Dimensions.space8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: mediumLarge.copyWith(
              color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
