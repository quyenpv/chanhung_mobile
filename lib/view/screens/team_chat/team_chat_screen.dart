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
import 'package:chanhung/core/config/app_mode.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      appBar: AppMode.chatOnly
          ? AppBar(
              title: const Text('ChanHung Chat'),
              actions: [
                IconButton(
                  tooltip: 'Đăng xuất',
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    final prefs = Get.find<SharedPreferences>();
                    await prefs.setBool(
                        SharedPreferenceHelper.rememberMeKey, false);
                    await prefs.remove(SharedPreferenceHelper.accessTokenKey);
                    await prefs.remove(SharedPreferenceHelper.accessTokenType);
                    Get.offAllNamed(RouteHelper.loginScreen);
                  },
                ),
              ],
            )
          : CustomAppBar(isShowBackBtn: true, title: 'ChanHung Chat'),
      drawer: AppMode.chatOnly ? null : const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateConversation(context),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Trò chuyện mới'),
      ),
      body: GetBuilder<TeamChatController>(builder: (c) {
        if (c.isLoading) return const CustomLoader();
        if (c.conversations.isEmpty) {
          return const NoDataWidget(text: 'Chưa có cuộc trò chuyện');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Dimensions.space12),
          itemCount: c.conversations.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: Dimensions.space8),
          itemBuilder: (_, i) {
            final item = c.conversations[i] as Map<String, dynamic>;
            final unread = int.tryParse('${item['unread_count']}') ?? 0;
            return ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300)),
              leading: CircleAvatar(
                backgroundColor:
                    ColorResources.primaryColor.withValues(alpha: 0.12),
                child: Text('${item['name']}'.isNotEmpty
                    ? '${item['name']}'.substring(0, 1)
                    : '?'),
              ),
              title: Text('${item['name']}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${item['last_sender'] ?? ''}: ${item['last_message'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              trailing: unread > 0
                  ? CircleAvatar(
                      radius: 12,
                      backgroundColor: ColorResources.primaryColor,
                      child: Text('$unread',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)))
                  : Text('${item['last_message_at'] ?? ''}',
                      style: const TextStyle(fontSize: 11)),
              onTap: () {
                Get.toNamed(RouteHelper.teamChatRoomScreen, arguments: {
                  'id': int.tryParse('${item['id']}') ?? 0,
                  'name': '${item['name']}',
                  'current_user_id': c.currentUserId,
                  'users': c.users,
                });
              },
            );
          },
        );
      }),
    );
  }

  Future<void> _showCreateConversation(BuildContext context) async {
    final c = Get.find<TeamChatController>();
    bool isGroup = false;
    final name = TextEditingController();
    final selected = <int>{};
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                  title: const Text('Tạo cuộc trò chuyện'),
                  content: SizedBox(
                      width: 520,
                      height: 480,
                      child: Column(children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                                value: false,
                                label: Text('Chat riêng'),
                                icon: Icon(Icons.person_outline)),
                            ButtonSegment(
                                value: true,
                                label: Text('Nhóm'),
                                icon: Icon(Icons.groups_outlined)),
                          ],
                          selected: {isGroup},
                          onSelectionChanged: (v) => setState(() {
                            isGroup = v.first;
                            selected.clear();
                          }),
                        ),
                        if (isGroup) ...[
                          const SizedBox(height: 12),
                          TextField(
                              controller: name,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                  labelText: 'Tên nhóm',
                                  border: OutlineInputBorder())),
                        ],
                        const SizedBox(height: 8),
                        Expanded(
                            child: ListView.builder(
                                itemCount: c.users.length,
                                itemBuilder: (_, i) {
                                  final user = Map<String, dynamic>.from(
                                      c.users[i] as Map);
                                  final id = int.tryParse('${user['id']}') ?? 0;
                                  return CheckboxListTile(
                                    value: selected.contains(id),
                                    title: Text('${user['name']}'),
                                    onChanged: (v) => setState(() {
                                      if (!isGroup) selected.clear();
                                      v == true
                                          ? selected.add(id)
                                          : selected.remove(id);
                                    }),
                                  );
                                })),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Hủy')),
                    FilledButton(
                      onPressed: selected.isEmpty ||
                              (isGroup && name.text.trim().isEmpty)
                          ? null
                          : () async {
                              final id = await c.createConversation(
                                  type: isGroup ? 'group' : 'direct',
                                  name: name.text.trim(),
                                  memberIds: selected.toList());
                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext);
                              if (id != null) {
                                final item = c.conversations.firstWhereOrNull(
                                    (e) => '${e['id']}' == '$id');
                                Get.toNamed(RouteHelper.teamChatRoomScreen,
                                    arguments: {
                                      'id': id,
                                      'name': item is Map
                                          ? '${item['name']}'
                                          : 'Chat',
                                      'current_user_id': c.currentUserId,
                                      'users': c.users,
                                    });
                              }
                            },
                      child: const Text('Tạo'),
                    ),
                  ],
                )));
    name.dispose();
  }
}
