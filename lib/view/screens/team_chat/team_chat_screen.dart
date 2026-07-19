import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/data/controller/team_chat/team_chat_controller.dart';
import 'package:chanhung/data/repo/team_chat/team_chat_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TeamChatScreen extends StatefulWidget {
  const TeamChatScreen({super.key});

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(TeamChatRepo(apiClient: Get.find()));
    final c = Get.put(TeamChatController(repo: Get.find()));
    WidgetsBinding.instance.addPostFrameCallback((_) => c.load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(isShowBackBtn: true, title: 'Team Chat'),
      drawer: const AppDrawer(),
      body: GetBuilder<TeamChatController>(builder: (c) {
        if (c.isLoading) return const CustomLoader();
        if (c.conversations.isEmpty) {
          return const NoDataWidget(text: 'Chưa có cuộc trò chuyện');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Dimensions.space12),
          itemCount: c.conversations.length,
          separatorBuilder: (_, __) => const SizedBox(height: Dimensions.space8),
          itemBuilder: (_, i) {
            final item = c.conversations[i] as Map<String, dynamic>;
            final unread = int.tryParse('${item['unread_count']}') ?? 0;
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
              leading: CircleAvatar(
                backgroundColor: ColorResources.primaryColor.withValues(alpha: 0.12),
                child: Text('${item['name']}'.isNotEmpty ? '${item['name']}'.substring(0, 1) : '?'),
              ),
              title: Text('${item['name']}', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${item['last_sender'] ?? ''}: ${item['last_message'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: unread > 0 ? CircleAvatar(radius: 12, backgroundColor: ColorResources.primaryColor, child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11))) : Text('${item['last_message_at'] ?? ''}', style: const TextStyle(fontSize: 11)),
              onTap: () {
                Get.toNamed(RouteHelper.teamChatRoomScreen, arguments: {
                  'id': int.tryParse('${item['id']}') ?? 0,
                  'name': '${item['name']}',
                  'current_user_id': c.currentUserId,
                });
              },
            );
          },
        );
      }),
    );
  }
}
