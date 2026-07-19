import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/data/controller/team_chat/team_chat_controller.dart';
import 'package:chanhung/data/repo/team_chat/team_chat_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TeamChatRoomScreen extends StatefulWidget {
  const TeamChatRoomScreen({super.key});

  @override
  State<TeamChatRoomScreen> createState() => _TeamChatRoomScreenState();
}

class _TeamChatRoomScreenState extends State<TeamChatRoomScreen> {
  late TeamChatRoomController controller;

  @override
  void initState() {
    super.initState();
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(TeamChatRepo(apiClient: Get.find()));
    controller = Get.put(TeamChatRoomController(repo: Get.find()));
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    controller.initRoom(
      int.tryParse('${args['id']}') ?? 0,
      '${args['name'] ?? 'Chat'}',
      userId: int.tryParse('${args['current_user_id']}') ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeamChatRoomController>(builder: (c) {
      return Scaffold(
        drawer: const AppDrawer(),
        appBar: CustomAppBar(
          isShowBackBtn: true,
          title: c.title,
          isShowActionBtn: true,
          actionWidget: IconButton(
            icon: const Icon(Icons.video_call_outlined, color: Colors.white),
            tooltip: 'Họp Online',
            onPressed: c.startMeeting,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: c.isLoading
                  ? const CustomLoader()
                  : ListView.builder(
                      padding: const EdgeInsets.all(Dimensions.space12),
                      itemCount: c.messages.length,
                      itemBuilder: (_, i) {
                        final m = c.messages[i] as Map<String, dynamic>;
                        final mine = '${m['sender_id']}' == '${c.currentUserId}';
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                            decoration: BoxDecoration(
                              color: mine ? ColorResources.primaryColor.withValues(alpha: 0.15) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!mine) Text('${m['sender_name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                Text('${m['body']}'),
                                Text('${m['created_at_relative'] ?? ''}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.space8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: c.inputController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => c.send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: c.isSending ? null : c.send,
                      icon: c.isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: ColorResources.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
