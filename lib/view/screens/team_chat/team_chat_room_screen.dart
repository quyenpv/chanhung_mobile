import 'package:chanhung/core/config/app_mode.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/color_resources.dart';
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
    controller.availableUsers =
        args['users'] is List ? args['users'] as List : [];
    controller.initRoom(
        int.tryParse('${args['id']}') ?? 0, '${args['name'] ?? 'Chat'}',
        userId: int.tryParse('${args['current_user_id']}') ?? 0);
  }

  @override
  Widget build(BuildContext context) => GetBuilder<TeamChatRoomController>(
      builder: (c) => Scaffold(
            drawer: AppMode.chatOnly ? null : const AppDrawer(),
            appBar: CustomAppBar(
              isShowBackBtn: true,
              title: c.title,
              isShowActionBtn: true,
              actionWidget: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.video_call_outlined,
                        color: Colors.white),
                    tooltip: 'Họp Online',
                    onPressed: c.startMeeting),
                if (c.conversationType != 'direct')
                  IconButton(
                      icon:
                          const Icon(Icons.group_outlined, color: Colors.white),
                      tooltip: 'Thành viên',
                      onPressed: () => _showMembers(context, c)),
              ]),
            ),
            body: Column(children: [
              Expanded(
                  child: c.isLoading
                      ? const CustomLoader()
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: c.messages.length,
                          itemBuilder: (_, i) {
                            final m =
                                Map<String, dynamic>.from(c.messages[i] as Map);
                            final mine =
                                '${m['sender_id']}' == '${c.currentUserId}';
                            return Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              .78),
                                  decoration: BoxDecoration(
                                      color: mine
                                          ? ColorResources.primaryColor
                                              .withValues(alpha: .15)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                      crossAxisAlignment: mine
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        if (!mine)
                                          Text('${m['sender_name']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12)),
                                        Text('${m['body']}'),
                                        Text(
                                            '${m['created_at_relative'] ?? ''}',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600)),
                                      ]),
                                ));
                          },
                        )),
              SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(children: [
                        Expanded(
                            child: TextField(
                                controller: c.inputController,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                    hintText: 'Nhập tin nhắn...',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(24))),
                                onSubmitted: (_) => c.send())),
                        IconButton(
                            onPressed: c.isSending ? null : c.send,
                            icon: c.isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.send_rounded,
                                    color: ColorResources.primaryColor)),
                      ]))),
            ]),
          ));

  Future<void> _showMembers(
      BuildContext context, TeamChatRoomController c) async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
            builder: (context, setState) => SafeArea(
                    child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                      height: MediaQuery.of(context).size.height * .72,
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                              child: Text('Thành viên (${c.members.length})',
                                  style:
                                      Theme.of(context).textTheme.titleLarge)),
                          if (c.canManageMembers)
                            IconButton(
                                icon: const Icon(Icons.person_add_alt_1),
                                onPressed: () async {
                                  await _showAddMembers(context, c);
                                  setState(() {});
                                })
                        ]),
                        Expanded(
                            child: ListView.builder(
                                itemCount: c.members.length,
                                itemBuilder: (_, i) {
                                  final member = Map<String, dynamic>.from(
                                      c.members[i] as Map);
                                  final id =
                                      int.tryParse('${member['id']}') ?? 0;
                                  return ListTile(
                                      leading: const CircleAvatar(
                                          child: Icon(Icons.person_outline)),
                                      title: Text('${member['name']}'),
                                      subtitle: Text(member['role'] == 'owner'
                                          ? 'Chủ nhóm'
                                          : 'Thành viên'),
                                      trailing: c.canManageMembers &&
                                              id != c.currentUserId &&
                                              member['role'] != 'owner'
                                          ? IconButton(
                                              icon: const Icon(
                                                  Icons.person_remove_outlined),
                                              onPressed: () async {
                                                await c.removeMember(id);
                                                setState(() {});
                                              })
                                          : null);
                                })),
                        OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red),
                            icon: const Icon(Icons.logout),
                            label: const Text('Rời nhóm'),
                            onPressed: () async {
                              if (await c.leaveGroup()) {
                                if (sheetContext.mounted)
                                  Navigator.pop(sheetContext);
                                Get.offAllNamed(RouteHelper.teamChatScreen);
                              }
                            }),
                      ])),
                ))));
  }

  Future<void> _showAddMembers(
      BuildContext context, TeamChatRoomController c) async {
    final existing =
        c.members.map((e) => int.tryParse('${e['id']}') ?? 0).toSet();
    final candidates = c.availableUsers
        .where((e) => !existing.contains(int.tryParse('${e['id']}') ?? 0))
        .toList();
    final selected = <int>{};
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                  title: const Text('Thêm thành viên'),
                  content: SizedBox(
                      width: 480,
                      height: 420,
                      child: ListView.builder(
                          itemCount: candidates.length,
                          itemBuilder: (_, i) {
                            final u =
                                Map<String, dynamic>.from(candidates[i] as Map);
                            final id = int.tryParse('${u['id']}') ?? 0;
                            return CheckboxListTile(
                                value: selected.contains(id),
                                title: Text('${u['name']}'),
                                onChanged: (v) => setState(() => v == true
                                    ? selected.add(id)
                                    : selected.remove(id)));
                          })),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: selected.isEmpty
                            ? null
                            : () async {
                                if (await c.addMembers(selected.toList()) &&
                                    dialogContext.mounted)
                                  Navigator.pop(dialogContext);
                              },
                        child: const Text('Thêm'))
                  ],
                )));
  }
}
