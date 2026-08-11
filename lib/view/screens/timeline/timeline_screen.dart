import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/data/controller/timeline/timeline_controller.dart';
import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/repo/timeline/timeline_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

const _reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🎉', '👏', '🔥'];

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
    if (!Get.isRegistered<TimelineRepo>()) {
      Get.put(TimelineRepo(apiClient: Get.find<ApiClient>()));
    }
    final controller = Get.isRegistered<TimelineController>()
        ? Get.find<TimelineController>()
        : Get.put(TimelineController(repo: Get.find()));
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.load());
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
      Get.find<TimelineController>().load(append: true);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GetBuilder<TimelineController>(
      builder: (c) => Scaffold(
            backgroundColor: const Color(0xfff0f2f5),
            appBar: AppBar(
              title: const Text('Timeline',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              actions: [
                IconButton(
                    tooltip: 'Làm mới',
                    onPressed: () => c.load(),
                    icon: const Icon(Icons.refresh))
              ],
            ),
            bottomNavigationBar: NavigationBar(
                selectedIndex: 1,
                onDestinationSelected: (index) {
                  if (index == 0) Get.offAllNamed(RouteHelper.teamChatScreen);
                },
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
                  NavigationDestination(
                      icon: Icon(Icons.dynamic_feed_outlined),
                      label: 'Timeline')
                ]),
            body: RefreshIndicator(
                onRefresh: () => c.load(),
                child: ListView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    _Composer(controller: c),
                    if (c.isLoading)
                      const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()))
                    else if (c.posts.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: Text('Chưa có bài viết nào.'))),
                    ...c.posts.map((raw) => _PostCard(
                        post: Map<String, dynamic>.from(raw as Map),
                        controller: c)),
                    if (c.isLoadingMore)
                      const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()))
                  ],
                )),
          ));
}

class _Composer extends StatelessWidget {
  final TimelineController controller;
  const _Composer({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: controller.composer,
                  minLines: 2,
                  maxLines: 7,
                  decoration: InputDecoration(
                      hintText: 'Bạn đang nghĩ gì?',
                      filled: true,
                      fillColor: const Color(0xfff5f6f7),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none))))
        ]),
        if (controller.attachments.isNotEmpty)
          SizedBox(
              height: 86,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: controller.attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final file = controller.attachments[index];
                    final isImage = _isImageName(file.name);
                    return Stack(children: [
                      Container(
                          width: 112,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: const Color(0xffeef1f5),
                              borderRadius: BorderRadius.circular(10)),
                          child: isImage && file.path != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.file(File(file.path!),
                                      fit: BoxFit.cover))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      const Icon(Icons.insert_drive_file),
                                      Text(file.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center)
                                    ])),
                      Positioned(
                          right: 0,
                          child: InkWell(
                              onTap: () => controller.removeAttachment(index),
                              child: const CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close,
                                      size: 15, color: Colors.white))))
                    ]);
                  })),
        Row(children: [
          IconButton(
              tooltip: 'Thêm ảnh',
              onPressed: () => controller.pickFiles(imagesOnly: true),
              icon: const Icon(Icons.photo_outlined, color: Colors.green)),
          IconButton(
              tooltip: 'Thêm file',
              onPressed: () => controller.pickFiles(),
              icon: const Icon(Icons.attach_file, color: Colors.blue)),
          DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                  value: controller.visibility,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Mọi người')),
                    DropdownMenuItem(
                        value: 'departments', child: Text('Phòng ban của tôi')),
                    DropdownMenuItem(
                        value: 'only_me', child: Text('Chỉ mình tôi')),
                  ],
                  onChanged: (value) {
                    controller.visibility = value ?? 'all';
                    controller.update();
                  })),
          const Spacer(),
          FilledButton.icon(
              onPressed: controller.isPosting ? null : controller.publish,
              icon: controller.isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, size: 18),
              label: const Text('Đăng'))
        ])
      ]));
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final TimelineController controller;
  const _PostCard({required this.post, required this.controller});

  int get id => int.tryParse('${post['id']}') ?? 0;

  @override
  Widget build(BuildContext context) {
    final files = post['files'] is List ? post['files'] as List : const [];
    final reactions =
        post['reactions'] is List ? post['reactions'] as List : const [];
    return Container(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 9),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                backgroundImage: '${post['author_avatar']}'.isEmpty
                    ? null
                    : NetworkImage('${post['author_avatar']}'),
                child: '${post['author_avatar']}'.isEmpty
                    ? const Icon(Icons.person)
                    : null),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${post['author_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Row(children: [
                    Text('${post['created_at_relative']}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 5),
                    Icon(_visibilityIcon('${post['visibility']}'),
                        size: 13, color: Colors.grey)
                  ])
                ])),
            if (post['can_edit'] == true || post['can_delete'] == true)
              PopupMenuButton<String>(
                  onSelected: (value) => _handleMenu(context, value),
                  itemBuilder: (_) => [
                        if (post['can_edit'] == true)
                          const PopupMenuItem(
                              value: 'edit', child: Text('Chỉnh sửa bài viết')),
                        if (post['can_delete'] == true)
                          const PopupMenuItem(
                              value: 'delete', child: Text('Xóa bài viết'))
                      ])
          ]),
          if ('${post['description']}'.trim().isNotEmpty)
            Html(
                data: '${post['description']}',
                onLinkTap: (url, _, __) => _openUrl(url)),
          _MediaGrid(files: files),
          if (reactions.isNotEmpty || (post['total_replies'] ?? 0) != 0)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  Expanded(
                      child: Wrap(
                          spacing: 5,
                          children: reactions.map((raw) {
                            final reaction =
                                Map<String, dynamic>.from(raw as Map);
                            return Text(
                                '${reaction['emoji']} ${reaction['count']}',
                                style: TextStyle(
                                    color: reaction['reacted_by_me'] == true
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade700));
                          }).toList())),
                  if ((post['total_replies'] ?? 0) != 0)
                    InkWell(
                        onTap: () => _openComments(context),
                        child: Text('${post['total_replies']} bình luận'))
                ])),
          const Divider(height: 14),
          Row(children: [
            Expanded(
                child: TextButton.icon(
                    onPressed: () => _pickReaction(context),
                    icon: const Icon(Icons.thumb_up_outlined),
                    label: const Text('Cảm xúc'))),
            Expanded(
                child: TextButton.icon(
                    onPressed: () => _openComments(context, focusInput: true),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Bình luận'))),
            Expanded(
                child: TextButton.icon(
                    onPressed: () => _sharePost(context),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Chia sẻ')))
          ])
        ]));
  }

  Future<void> _handleMenu(BuildContext context, String value) async {
    if (value == 'edit') {
      final editor =
          TextEditingController(text: _plainText('${post['description']}'));
      final result = await showDialog<String>(
          context: context,
          builder: (dialog) => AlertDialog(
                  title: const Text('Chỉnh sửa bài viết'),
                  content:
                      TextField(controller: editor, minLines: 3, maxLines: 10),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialog),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () => Navigator.pop(dialog, editor.text),
                        child: const Text('Lưu'))
                  ]));
      editor.dispose();
      if (result != null && result.trim().isNotEmpty)
        await controller.edit(id, result);
    } else {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                  title: const Text('Xóa bài viết?'),
                  content: const Text(
                      'Bài viết và các bình luận sẽ không còn hiển thị.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialog, false),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () => Navigator.pop(dialog, true),
                        child: const Text('Xóa'))
                  ]));
      if (confirmed == true) await controller.delete(id);
    }
  }

  Future<void> _pickReaction(BuildContext context) =>
      showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                      alignment: WrapAlignment.spaceAround,
                      spacing: 16,
                      children: _reactions
                          .map((emoji) => InkWell(
                              onTap: () {
                                Navigator.pop(sheet);
                                controller.react(id, emoji);
                              },
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 34))))
                          .toList()))));

  Future<void> _openComments(BuildContext context, {bool focusInput = false}) =>
      showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => _CommentsSheet(
              postId: id, repo: controller.repo, focusInput: focusInput));

  void _sharePost(BuildContext context) {
    final text = _plainText('${post['description']}');
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
            child: ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Sao chép nội dung'),
                onTap: () {
                  Navigator.pop(sheet);
                  Get.snackbar(
                      'Timeline',
                      text.isEmpty
                          ? 'Bài viết không có nội dung chữ.'
                          : 'Đã chọn nội dung để chia sẻ.');
                })));
  }
}

class _MediaGrid extends StatelessWidget {
  final List files;
  const _MediaGrid({required this.files});
  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();
    return Column(
        children: files.map((raw) {
      final file = Map<String, dynamic>.from(raw as Map);
      final url = '${file['url']}';
      if (file['is_image'] == true) {
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (dialog) => Dialog.fullscreen(
                backgroundColor: Colors.black,
                child: Stack(children: [
                  Center(
                      child: InteractiveViewer(
                          child: CachedNetworkImage(imageUrl: url))),
                  SafeArea(
                      child: IconButton(
                          onPressed: () => Navigator.pop(dialog),
                          icon: const Icon(Icons.close, color: Colors.white)))
                ]),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: '${file['thumbnail_url'] ?? url}',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 240,
                errorWidget: (_, __, ___) => const SizedBox(
                    height: 100,
                    child: Center(child: Icon(Icons.broken_image))),
              ),
            ),
          ),
        );
      }
      return Card(
          margin: const EdgeInsets.only(top: 6),
          child: ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
              title: Text('${file['name']}'),
              subtitle:
                  Text(_formatBytes(int.tryParse('${file['size']}') ?? 0)),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openUrl(url)));
    }).toList());
  }
}

class _CommentsSheet extends StatefulWidget {
  final int postId;
  final TimelineRepo repo;
  final bool focusInput;
  const _CommentsSheet(
      {required this.postId, required this.repo, required this.focusInput});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final input = TextEditingController();
  final focus = FocusNode();
  List<dynamic> comments = [];
  List<PlatformFile> files = [];
  bool loading = true;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.focusInput)
      WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
  }

  Future<void> _load() async {
    final response = await widget.repo.replies(widget.postId);
    if (response.statusCode == 200 && mounted) {
      final payload = apiPayload(jsonDecode(response.responseJson));
      setState(() {
        comments = payload['replies'] is List ? payload['replies'] as List : [];
        loading = false;
      });
    } else if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null)
      setState(() =>
          files = result.files.where((f) => f.path != null).take(5).toList());
  }

  Future<void> _send() async {
    if (sending || (input.text.trim().isEmpty && files.isEmpty)) return;
    setState(() => sending = true);
    final response = await widget.repo
        .comment(widget.postId, input.text.trim(), files: files);
    if (response.statusCode == 200 || response.statusCode == 201) {
      input.clear();
      files = [];
      await _load();
      if (Get.isRegistered<TimelineController>())
        Get.find<TimelineController>().load();
    }
    if (mounted) setState(() => sending = false);
  }

  @override
  void dispose() {
    input.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
          child: Column(children: [
            const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Bình luận',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            const Divider(height: 1),
            Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : comments.isEmpty
                        ? const Center(
                            child: Text('Hãy là người đầu tiên bình luận.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: comments.length,
                            itemBuilder: (_, index) {
                              final c = Map<String, dynamic>.from(
                                  comments[index] as Map);
                              return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                            radius: 17,
                                            backgroundImage: NetworkImage(
                                                '${c['author_avatar']}')),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xfff0f2f5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14)),
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          '${c['author_name']}',
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700)),
                                                      Html(
                                                          data:
                                                              '${c['description']}'),
                                                      _MediaGrid(
                                                          files:
                                                              c['files'] is List
                                                                  ? c['files']
                                                                      as List
                                                                  : const []),
                                                      Text(
                                                          '${c['created_at_relative']}',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall)
                                                    ])))
                                      ]));
                            })),
            if (files.isNotEmpty)
              Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Chip(
                          label: Text('${files.length} file đã chọn'),
                          onDeleted: () => setState(() => files = [])))),
            SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    child: Row(children: [
                      IconButton(
                          onPressed: _pick,
                          icon: const Icon(Icons.attach_file)),
                      Expanded(
                          child: TextField(
                              controller: input,
                              focusNode: focus,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                  hintText: 'Viết bình luận...',
                                  filled: true,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      borderSide: BorderSide.none)))),
                      IconButton(
                          onPressed: sending ? null : _send,
                          icon: sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: Colors.blue))
                    ])))
          ])));
}

bool _isImageName(String name) =>
    RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)$', caseSensitive: false)
        .hasMatch(name);
IconData _visibilityIcon(String value) => value == 'only_me'
    ? Icons.lock
    : value == 'all'
        ? Icons.public
        : Icons.groups;
String _plainText(String html) => html
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
String _formatBytes(int bytes) => bytes <= 0
    ? 'Tệp đính kèm'
    : bytes < 1048576
        ? '${(bytes / 1024).toStringAsFixed(1)} KB'
        : '${(bytes / 1048576).toStringAsFixed(1)} MB';
Future<void> _openUrl(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}
