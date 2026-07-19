import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/data/controller/payment_request/payment_request_controller.dart';
import 'package:chanhung/data/model/payment_request/payment_request_model.dart';
import 'package:chanhung/data/repo/payment_request/payment_request_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_bottom_nav_bar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/screens/payment_request/create_payment_request_screen.dart';
import 'package:chanhung/view/screens/payment_request/widget/payment_request_card.dart';
import 'package:chanhung/view/screens/payment_request/widget/payment_request_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentRequestsScreen extends StatefulWidget {
  const PaymentRequestsScreen({super.key});

  @override
  State<PaymentRequestsScreen> createState() => _PaymentRequestsScreenState();
}

class _PaymentRequestsScreenState extends State<PaymentRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = '';
  String _searchQuery = '';

  final List<Map<String, String>> _statusOptions = [
    {'id': '', 'text': 'Tất cả trạng thái'},
    {'id': 'draft', 'text': 'Nháp'},
    {'id': 'signing', 'text': 'Chờ ký'},
    {'id': 'completed', 'text': 'Đã duyệt'},
    {'id': 'paid', 'text': 'Đã chi'},
    {'id': 'rejected', 'text': 'Bị từ chối'},
  ];

  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(PaymentRequestsRepo(apiClient: Get.find()));
    final controller = Get.put(PaymentRequestsController(repo: Get.find()));
    controller.isLoading = true;
    
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchOrFilterChanged() {
    final controller = Get.find<PaymentRequestsController>();
    if (_tabController.index == 1) {
      // payment request list reload
      controller.loadPaymentRequests(reload: true);
    } else if (_tabController.index == 2) {
      // settlement list reload
      controller.loadSettlements(reload: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "ĐNTT/ĐNTU & Hoàn ứng",
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Tab bar selector
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3.0,
              tabs: const [
                Tab(text: "Tổng quan"),
                Tab(text: "ĐNTT / ĐNTU"),
                Tab(text: "Hoàn ứng"),
              ],
              onTap: (index) {
                setState(() {});
              },
            ),
          ),

          // Filters row (hide on Overview tab)
          if (_tabController.index > 0) _buildFilterSection(context),

          // Main content
          Expanded(
            child: GetBuilder<PaymentRequestsController>(
              builder: (controller) {
                if (controller.isLoading) {
                  return const CustomLoader();
                }

                return TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(), // handle search manually
                  children: [
                    // Tab 1: Dashboard overview
                    RefreshIndicator(
                      onRefresh: () async {
                        await controller.initialData(shouldLoad: false);
                      },
                      color: Theme.of(context).primaryColor,
                      child: controller.dashboardStats != null
                          ? PaymentRequestDashboard(
                              stats: controller.dashboardStats!,
                              currency: controller.currency ?? 'đ',
                            )
                          : const NoDataWidget(),
                    ),

                    // Tab 2: Payment Requests list
                    RefreshIndicator(
                      onRefresh: () async {
                        await controller.loadPaymentRequests(reload: false);
                      },
                      color: Theme.of(context).primaryColor,
                      child: controller.isListLoading
                          ? const CustomLoader()
                          : _buildListView(controller.paymentRequests, controller.currency ?? 'đ'),
                    ),

                    // Tab 3: Settlements list
                    RefreshIndicator(
                      onRefresh: () async {
                        await controller.loadSettlements(reload: false);
                      },
                      color: Theme.of(context).primaryColor,
                      child: controller.isListLoading
                          ? const CustomLoader()
                          : _buildListView(controller.settlements, controller.currency ?? 'đ'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const CreatePaymentRequestScreen());
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.space15, vertical: Dimensions.space10),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // Search TextField
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo mã, tiêu đề...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        _onSearchOrFilterChanged();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
            onSubmitted: (_) => _onSearchOrFilterChanged(),
          ),
          const SizedBox(height: Dimensions.space10),

          // Status Dropdown
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      items: _statusOptions.map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt['id'],
                          child: Text(opt['text']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedStatus = val;
                          });
                          _onSearchOrFilterChanged();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: _onSearchOrFilterChanged,
                child: const Text("Lọc", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<PaymentRequestModel> list, String currency) {
    // Client-side local filtering if matching search query
    var filtered = list.where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final codeMatch = (item.requestCode ?? '').toLowerCase().contains(query);
      final titleMatch = (item.title ?? '').toLowerCase().contains(query);
      return codeMatch || titleMatch;
    }).toList();

    // Client-side local status filtering
    if (_selectedStatus.isNotEmpty) {
      filtered = filtered.where((item) => (item.status ?? '').toLowerCase() == _selectedStatus.toLowerCase()).toList();
    }

    if (filtered.isEmpty) {
      return const NoDataWidget();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(Dimensions.space15),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: Dimensions.space10),
      itemBuilder: (context, index) {
        return PaymentRequestCard(
          item: filtered[index],
          currency: currency,
        );
      },
    );
  }
}
