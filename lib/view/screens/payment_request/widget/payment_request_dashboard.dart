import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/model/payment_request/payment_request_dashboard_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentRequestDashboard extends StatelessWidget {
  final PaymentRequestDashboardStats stats;
  final String currency;

  const PaymentRequestDashboard({
    super.key,
    required this.stats,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: currency);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(Dimensions.space15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Row 1: Personal Stats (Indigo & Teal gradients)
            Row(
              children: [
                Expanded(
                  child: _buildMiniImageCard(
                    context: context,
                    value: "${stats.myCreatedCount ?? 0}",
                    label: "CỦA TÔI LẬP",
                    icon: Icons.edit_note,
                    colors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                  ),
                ),
                const SizedBox(width: Dimensions.space12),
                Expanded(
                  child: _buildMiniImageCard(
                    context: context,
                    value: "${stats.mySignedCount ?? 0}",
                    label: "TÔI ĐÃ KÝ",
                    icon: Icons.draw_outlined,
                    colors: [const Color(0xFF0D9488), const Color(0xFF059669)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space20),

            // Row 2: General System Stats (using Rows instead of GridView to prevent vertical stretching on wide screens)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildSimpleStatsCard(
                      context: context,
                      value: "${stats.totalCount ?? 0}",
                      label: "TỔNG HỒ SƠ",
                      icon: Icons.folder_open,
                      colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                    ),
                  ),
                  const SizedBox(width: Dimensions.space12),
                  Expanded(
                    child: _buildSimpleStatsCard(
                      context: context,
                      value: "${stats.signingCount ?? 0}",
                      label: "ĐANG TRÌNH KÝ",
                      icon: Icons.hourglass_empty,
                      colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                      subLabel: (stats.signingOverSlaCount ?? 0) > 0
                          ? "${stats.signingOverSlaCount} hồ sơ quá SLA"
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildSimpleStatsCard(
                      context: context,
                      value: "${stats.paidCount ?? 0}",
                      label: "ĐÃ CHI TIỀN",
                      icon: Icons.check_circle_outline,
                      colors: [const Color(0xFF10B981), const Color(0xFF047857)],
                    ),
                  ),
                  const SizedBox(width: Dimensions.space12),
                  Expanded(
                    child: _buildSimpleStatsCard(
                      context: context,
                      value: "${stats.rejectedCount ?? 0}",
                      label: "BỊ TỪ CHỐI",
                      icon: Icons.cancel_outlined,
                      colors: [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space20),

            // Row 3: Financial Details Card (Rounded gradient progress)
            _buildFinancialBreakdownCard(context, formatCurrency),
            const SizedBox(height: Dimensions.space25),

            // Row 4: Budget Allocations list (Transaction Feed layout)
            if (stats.budgetData != null && stats.budgetData!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  "PHÂN BỔ NGÂN SÁCH (FIN)",
                  style: boldDefault.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.space12),
              _buildBudgetList(context, formatCurrency),
              const SizedBox(height: Dimensions.space20),
            ],
          ],
        ),
      ),
    ));
  }

  Widget _buildMiniImageCard({
    required BuildContext context,
    required String value,
    required String label,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -8,
            child: Icon(
              icon,
              size: 48,
              color: Colors.white.withOpacity(0.13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatsCard({
    required BuildContext context,
    required String value,
    required String label,
    required IconData icon,
    required List<Color> colors,
    String? subLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Left gradient indicator bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Styled icon badge
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.first.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: colors.first, size: 20),
                      ),
                      // Dot indicator
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.first,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.first.withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: boldLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: regularSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white60 : ColorResources.contentTextColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (subLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialBreakdownCard(BuildContext context, NumberFormat formatCurrency) {
    double total = stats.totalAmount ?? 0.0;
    double paid = stats.paidAmount ?? 0.0;
    double signing = stats.signingAmount ?? 0.0;

    double paidRatio = total > 0 ? (paid / total) : 0.0;
    double signingRatio = total > 0 ? (signing / total) : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.blue, size: 18),
              ),
              const SizedBox(width: Dimensions.space10),
              Text(
                "CHI TIẾT DÒNG TIỀN HỒ SƠ",
                style: boldDefault.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space20),

          // Paid Amount Row with gradient progress
          _buildAmountProgressRow(
            context: context,
            label: "Đã chi",
            amount: formatCurrency.format(paid),
            colors: [const Color(0xFF10B981), const Color(0xFF059669)],
            ratio: paidRatio,
          ),
          const SizedBox(height: 18.0),

          // Signing Amount Row with gradient progress
          _buildAmountProgressRow(
            context: context,
            label: "Chờ ký duyệt",
            amount: formatCurrency.format(signing),
            colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
            ratio: signingRatio,
          ),
          const SizedBox(height: Dimensions.space20),

          const Divider(height: 1, color: ColorResources.borderColor),
          const SizedBox(height: Dimensions.space20),

          // Total amount summary box (premium styled gradient card)
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2E3545), const Color(0xFF252932)]
                    : [const Color(0xFFF9FAFB), const Color(0xFFF3F4F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tổng số tiền:",
                      style: boldDefault.copyWith(
                        color: isDark ? Colors.white70 : ColorResources.contentTextColor,
                      ),
                    ),
                    Text(
                      formatCurrency.format(total),
                      style: boldLarge.copyWith(
                        color: isDark ? const Color(0xFF38BDF8) : ColorResources.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if ((stats.moreInfoCount ?? 0) > 0) ...[
                  const SizedBox(height: Dimensions.space12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Có ${stats.moreInfoCount} hồ sơ cần bổ sung thêm chứng từ.",
                          style: regularSmall.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAmountProgressRow({
    required BuildContext context,
    required String label,
    required String amount,
    required List<Color> colors,
    required double ratio,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: colors.first, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: regularDefault.copyWith(
                    color: isDark ? Colors.white70 : ColorResources.contentTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              amount,
              style: boldDefault.copyWith(
                color: colors.first,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 8,
                  width: constraints.maxWidth * ratio,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withOpacity(0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetList(BuildContext context, NumberFormat formatCurrency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.budgetData!.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark ? Colors.white.withOpacity(0.05) : ColorResources.borderColor,
        ),
        itemBuilder: (context, index) {
          final b = stats.budgetData![index];
          final rawCode = b.budgetCode ?? 'Khác';
          // Extract the FIN code prefix (e.g. FIN009) to show in the circle pill
          String pillText = 'FIN';
          if (rawCode.startsWith('FIN')) {
            final idx = rawCode.indexOf(' ');
            if (idx != -1) {
              pillText = rawCode.substring(0, idx);
            } else {
              pillText = rawCode;
            }
          } else {
            pillText = rawCode.length > 5 ? rawCode.substring(0, 5) : rawCode;
          }

          // Cycle gradients for budget items to look gorgeous
          final List<Color> pillColors = _getBudgetGradient(index);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Budget circular pill with gradient
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: pillColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: pillColors.first.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            pillText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rawCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: boldDefault.copyWith(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${b.count} hồ sơ",
                              style: regularSmall.copyWith(
                                color: isDark ? Colors.white54 : ColorResources.contentTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCurrency.format(b.amount ?? 0.0),
                  style: boldDefault.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Color> _getBudgetGradient(int index) {
    const gradients = [
      [Color(0xFF6366F1), Color(0xFF4F46E5)],
      [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      [Color(0xFFEC4899), Color(0xFFDB2777)],
      [Color(0xFFF59E0B), Color(0xFFD97706)],
      [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      [Color(0xFF10B981), Color(0xFF059669)],
    ];
    return gradients[index % gradients.length];
  }
}
