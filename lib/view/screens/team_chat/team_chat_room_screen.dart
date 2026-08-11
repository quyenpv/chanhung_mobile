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
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamChatRoomScreen extends StatefulWidget {
  const TeamChatRoomScreen({super.key});
  @override
  State<TeamChatRoomScreen> createState() => _TeamChatRoomScreenState();
}

class _RichMessageText extends StatelessWidget {
  final String body;
  final List<dynamic> members;
  const _RichMessageText({required this.body, required this.members});

  @override
  Widget build(BuildContext context) {
    final names = <int, String>{};
    for (final item in members) {
      if (item is Map) {
        final id = int.tryParse('${item['id']}');
        if (id != null) names[id] = '${item['name']}';
      }
    }
    final pattern = RegExp(r'(https?://[^\s]+|www\.[^\s]+|@\[uid:\d+\])');
    final children = <Widget>[];
    var offset = 0;
    for (final match in pattern.allMatches(body)) {
      if (match.start > offset) {
        children.add(Text(body.substring(offset, match.start)));
      }
      final token = match.group(0)!;
      if (token.startsWith('@[uid:')) {
        final id = int.tryParse(token.replaceAll(RegExp(r'\D'), '')) ?? 0;
        children.add(Text('@${names[id] ?? 'nhân sự'}',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700)));
      } else {
        final uri =
            Uri.parse(token.startsWith('www.') ? 'https://$token' : token);
        children.add(InkWell(
            onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
            child: Text(token,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline))));
      }
      offset = match.end;
    }
    if (offset < body.length) children.add(Text(body.substring(offset)));
    return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center, children: children);
  }
}

class _MessageAttachments extends StatelessWidget {
  final List<dynamic> files;
  const _MessageAttachments({required this.files});

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: files.map((raw) {
        final file = Map<String, dynamic>.from(raw as Map);
        final url = '${file['view_url'] ?? file['download_url'] ?? ''}';
        final isImage =
            file['is_image'] == true || '${file['mime']}'.startsWith('image/');
        if (isImage) {
          return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                  onTap: () => _showImage(context, file, url),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                          imageUrl: '${file['thumbnail_url'] ?? url}',
                          fit: BoxFit.cover,
                          width: 260,
                          height: 190,
                          placeholder: (_, __) => const SizedBox(
                              height: 190,
                              child:
                                  Center(child: CircularProgressIndicator())),
                          errorWidget: (_, __, ___) => const SizedBox(
                              height: 100,
                              child: Center(
                                  child:
                                      Icon(Icons.broken_image_outlined)))))));
        }
        return Card(
            margin: const EdgeInsets.only(top: 8),
            child: ListTile(
                dense: true,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text('${file['name']}',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle:
                    Text(_formatBytes(int.tryParse('${file['size']}') ?? 0)),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _showFile(context, file, url)));
      }).toList());

  static Future<void> _showImage(
      BuildContext context, Map<String, dynamic> file, String url) async {
    await showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (dialogContext) => Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: SafeArea(
                  child: Stack(children: [
                Positioned.fill(
                    child: InteractiveViewer(
                        minScale: .5,
                        maxScale: 5,
                        child: Center(
                            child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white,
                                    size: 64))))),
                Positioned(
                    left: 8,
                    right: 8,
                    top: 4,
                    child: Row(children: [
                      IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close, color: Colors.white)),
                      Expanded(
                          child: Text('${file['name']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white))),
                      IconButton(
                          tooltip: 'Mở hoặc tải ảnh',
                          onPressed: () => _open(url),
                          icon: const Icon(Icons.open_in_new,
                              color: Colors.white)),
                    ])),
              ])),
            ));
  }

  static Future<void> _showFile(
      BuildContext context, Map<String, dynamic> file, String url) async {
    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.insert_drive_file_outlined, size: 56),
                const SizedBox(height: 12),
                Text('${file['name']}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(_formatBytes(int.tryParse('${file['size']}') ?? 0)),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Xem file'),
                        onPressed: () => _open(url))),
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Tải hoặc mở bằng ứng dụng khác'),
                        onPressed: () =>
                            _open('${file['download_url'] ?? url}'))),
              ]),
            )));
  }

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return 'Tệp đính kèm';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 12))
          ])));
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
    controller.availableConversations =
        args['conversations'] is List ? args['conversations'] as List : [];
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
                            final previousDate = i > 0
                                ? '${(c.messages[i - 1] as Map)['date_key'] ?? ''}'
                                : '';
                            final showDate = i == 0 ||
                                previousDate != '${m['date_key'] ?? ''}';
                            return Column(children: [
                              if (showDate)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Chip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(
                                            '${m['date_label'] ?? m['date_key'] ?? ''}',
                                            style: const TextStyle(
                                                fontSize: 12)))),
                              GestureDetector(
                                  onLongPress: () =>
                                      _showMessageActions(context, c, m, mine),
                                  child: Align(
                                      alignment: mine
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                .78),
                                        decoration: BoxDecoration(
                                            color: mine
                                                ? ColorResources.primaryColor
                                                    .withValues(alpha: .15)
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Column(
                                            crossAxisAlignment: mine
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                            children: [
                                              if (!mine)
                                                Text('${m['sender_name']}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12)),
                                              if (m['parent'] is Map)
                                                Container(
                                                    width: double.infinity,
                                                    margin: const EdgeInsets
                                                        .only(bottom: 6),
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: .06),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8)),
                                                    child: Text(
                                                        '${m['parent']['sender_name']}: ${m['parent']['body']}',
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 11))),
                                              if ('${m['body'] ?? ''}'
                                                  .isNotEmpty)
                                                _RichMessageText(
                                                    body: '${m['body']}',
                                                    members: c.members),
                                              if (m['files'] is List &&
                                                  (m['files'] as List)
                                                      .isNotEmpty)
                                                _MessageAttachments(
                                                    files: m['files'] as List),
                                              if (m['reactions'] is List &&
                                                  (m['reactions'] as List)
                                                      .isNotEmpty)
                                                Wrap(
                                                    spacing: 4,
                                                    children: (m['reactions']
                                                            as List)
                                                        .map((reaction) => ActionChip(
                                                            visualDensity:
                                                                VisualDensity
                                                                    .compact,
                                                            label: Text(
                                                                '${reaction['emoji']} ${reaction['count']}'),
                                                            onPressed: () => c
                                                                .toggleReaction(
                                                                    int.tryParse('${m['id']}') ??
                                                                        0,
                                                                    '${reaction['emoji']}')))
                                                        .toList()),
                                              Text(
                                                  '${m['created_at_relative'] ?? ''}',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors
                                                          .grey.shade600)),
                                            ]),
                                      )))
                            ]);
                          },
                        )),
              if (c.mentionSuggestions.isNotEmpty)
                Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(blurRadius: 8, color: Colors.black26)
                        ]),
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: c.mentionSuggestions.length,
                        itemBuilder: (_, i) {
                          final member = Map<String, dynamic>.from(
                              c.mentionSuggestions[i] as Map);
                          return ListTile(
                              dense: true,
                              leading: const CircleAvatar(
                                  child: Icon(Icons.person_outline)),
                              title: Text('${member['name']}'),
                              onTap: () => c.selectMention(member));
                        })),
              if (c.pendingAttachments.isNotEmpty)
                SizedBox(
                    height: 54,
                    child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: c.pendingAttachments.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => InputChip(
                            avatar: const Icon(Icons.attach_file, size: 18),
                            label: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 150),
                                child: Text(c.pendingAttachments[i].name,
                                    overflow: TextOverflow.ellipsis)),
                            onDeleted: () => c.removeAttachment(i)))),
              if (c.replyTo != null)
                Container(
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.reply, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              'Trả lời ${c.replyTo!['sender_name']}: ${c.replyTo!['body']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis)),
                      IconButton(
                          onPressed: c.cancelReply,
                          icon: const Icon(Icons.close, size: 18))
                    ])),
              SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(children: [
                        IconButton(
                            tooltip: 'Đính kèm ảnh hoặc tệp',
                            onPressed: c.isSending ? null : c.pickAttachments,
                            icon: const Icon(Icons.attach_file)),
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
                                onChanged: c.onComposerChanged,
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

  Future<void> _showMessageActions(BuildContext context,
      TeamChatRoomController c, Map<String, dynamic> message, bool mine) async {
    final messageId = int.tryParse('${message['id']}') ?? 0;
    final quickEmoji = ['❤️', '👍', '😂', '😮', '😢', '😡'];
    await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Đóng',
        barrierColor: Colors.black54,
        pageBuilder: (dialogContext, _, __) => SafeArea(
            child: Center(
                child: Material(
                    color: Colors.transparent,
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('${message['sender_name']}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            const SizedBox(height: 4),
                                            _RichMessageText(
                                                body:
                                                    '${message['body'] ?? ''}',
                                                members: c.members),
                                          ])),
                                  const SizedBox(height: 12),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(18)),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            ...quickEmoji.map((emoji) =>
                                                InkWell(
                                                    borderRadius: BorderRadius
                                                        .circular(24),
                                                    onTap: () async {
                                                      Navigator.pop(
                                                          dialogContext);
                                                      await c.toggleReaction(
                                                          messageId, emoji);
                                                    },
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        child: Text(emoji,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        28))))),
                                            IconButton(
                                                icon: const Icon(Icons.add,
                                                    size: 30),
                                                onPressed: () {
                                                  Navigator.pop(dialogContext);
                                                  _showAllEmoji(
                                                      context, c, messageId);
                                                })
                                          ])),
                                  const SizedBox(height: 12),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 8),
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(18)),
                                      child: GridView.count(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisCount: 4,
                                          childAspectRatio: .9,
                                          children: [
                                            _ActionTile(
                                                icon: Icons.reply,
                                                label: 'Trả lời',
                                                color: Colors.deepPurple,
                                                onTap: () {
                                                  Navigator.pop(dialogContext);
                                                  c.setReply(message);
                                                }),
                                            _ActionTile(
                                                icon: Icons.forward,
                                                label: 'Chuyển tiếp',
                                                color: Colors.blue,
                                                onTap: () {
                                                  Navigator.pop(dialogContext);
                                                  _showForward(
                                                      context, c, messageId);
                                                }),
                                            _ActionTile(
                                                icon: Icons.copy_outlined,
                                                label: 'Sao chép',
                                                color: Colors.indigo,
                                                onTap: () async {
                                                  await Clipboard.setData(
                                                      ClipboardData(
                                                          text:
                                                              '${message['body'] ?? ''}'));
                                                  if (dialogContext.mounted) {
                                                    Navigator.pop(
                                                        dialogContext);
                                                  }
                                                }),
                                            _ActionTile(
                                                icon: Icons.push_pin_outlined,
                                                label: 'Ghim',
                                                color: Colors.orange,
                                                onTap: () async {
                                                  Navigator.pop(dialogContext);
                                                  await c.pinMessage(messageId);
                                                }),
                                            if (mine)
                                              _ActionTile(
                                                  icon: Icons.edit_outlined,
                                                  label: 'Sửa',
                                                  color: Colors.teal,
                                                  onTap: () {
                                                    Navigator.pop(
                                                        dialogContext);
                                                    _showEdit(
                                                        context, c, message);
                                                  }),
                                            _ActionTile(
                                                icon: Icons.info_outline,
                                                label: 'Chi tiết',
                                                color: Colors.grey,
                                                onTap: () {
                                                  Navigator.pop(dialogContext);
                                                  _showDetails(
                                                      context, message);
                                                }),
                                            if (mine)
                                              _ActionTile(
                                                  icon: Icons.delete_outline,
                                                  label: 'Thu hồi',
                                                  color: Colors.red,
                                                  onTap: () async {
                                                    Navigator.pop(
                                                        dialogContext);
                                                    await _confirmDelete(
                                                        context, c, messageId);
                                                  }),
                                          ]))
                                ])))))));
  }

  Future<void> _showAllEmoji(
      BuildContext context, TeamChatRoomController c, int messageId) async {
    const emoji = ['👍', '❤️', '😂', '😮', '😢', '😡', '🙏', '🎉', '👏', '🔥'];
    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
                child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: emoji
                      .map((item) => InkWell(
                            onTap: () async {
                              Navigator.pop(sheetContext);
                              await c.toggleReaction(messageId, item);
                            },
                            child: Text(item,
                                style: const TextStyle(fontSize: 36)),
                          ))
                      .toList()),
            )));
  }

  Future<void> _showEdit(BuildContext context, TeamChatRoomController c,
      Map<String, dynamic> message) async {
    final input = TextEditingController(text: '${message['body'] ?? ''}');
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Sửa tin nhắn'),
              content: TextField(
                  controller: input, autofocus: true, minLines: 2, maxLines: 6),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Hủy')),
                FilledButton(
                    onPressed: () async {
                      if (await c.editMessage(
                              int.tryParse('${message['id']}') ?? 0,
                              input.text) &&
                          dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: const Text('Lưu'))
              ],
            ));
    input.dispose();
  }

  Future<void> _showForward(
      BuildContext context, TeamChatRoomController c, int messageId) async {
    final targets = c.availableConversations
        .where((item) => '${item['id']}' != '${c.conversationId}')
        .toList();
    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
                child: SizedBox(
              height: MediaQuery.of(context).size.height * .6,
              child: Column(children: [
                const Text('Chuyển tiếp đến',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Expanded(
                    child: ListView.builder(
                        itemCount: targets.length,
                        itemBuilder: (_, i) => ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(Icons.chat_bubble_outline)),
                              title: Text('${targets[i]['name']}'),
                              onTap: () async {
                                if (await c.forwardMessage(
                                        messageId,
                                        int.tryParse('${targets[i]['id']}') ??
                                            0) &&
                                    sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                            )))
              ]),
            )));
  }

  Future<void> _showDetails(
          BuildContext context, Map<String, dynamic> message) =>
      showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: const Text('Chi tiết tin nhắn'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Người gửi: ${message['sender_name']}'),
                      Text(
                          'Thời gian: ${message['created_at_relative'] ?? ''}'),
                      Text('Mã tin nhắn: ${message['id']}'),
                      Text(
                          'Số tệp: ${message['files'] is List ? (message['files'] as List).length : 0}'),
                    ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Đóng'))
                ],
              ));

  Future<void> _confirmDelete(
      BuildContext context, TeamChatRoomController c, int messageId) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Thu hồi tin nhắn?'),
              content: const Text('Tin nhắn sẽ bị thu hồi với mọi thành viên.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Hủy')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Thu hồi'))
              ],
            ));
    if (confirmed == true) await c.deleteMessage(messageId);
  }

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
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
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
                                    dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              },
                        child: const Text('Thêm'))
                  ],
                )));
  }
}
