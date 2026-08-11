import 'package:cached_network_image/cached_network_image.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/data/controller/timeline/timeline_controller.dart';
import 'package:chanhung/data/repo/timeline/timeline_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(TimelineRepo(apiClient: Get.find<ApiClient>()));
    final controller = Get.put(TimelineController(repo: Get.find()));
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.load());
  }

  @override
  Widget build(BuildContext context) => GetBuilder<TimelineController>(
      builder: (c) => Scaffold(
            appBar: AppBar(title: const Text('Timeline'), actions: [
              IconButton(onPressed: c.load, icon: const Icon(Icons.refresh))
            ]),
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
                onRefresh: c.load,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(children: [
                              TextField(
                                  controller: c.composer,
                                  minLines: 2,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                      hintText: 'Bạn đang nghĩ gì?',
                                      border: InputBorder.none)),
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                      onPressed: c.isPosting ? null : c.publish,
                                      icon: const Icon(Icons.send),
                                      label: const Text('Đăng'))),
                            ]))),
                    if (c.isLoading)
                      const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator())),
                    ...c.posts.map((raw) => _PostCard(
                        post: Map<String, dynamic>.from(raw as Map),
                        controller: c)),
                  ],
                )),
          ));
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final TimelineController controller;
  const _PostCard({required this.post, required this.controller});
  @override
  Widget build(BuildContext context) {
    final files = post['files'] is List ? post['files'] as List : const [];
    return Card(
        margin: const EdgeInsets.only(top: 10),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                      Text('${post['created_at_relative']}',
                          style: Theme.of(context).textTheme.bodySmall)
                    ]))
              ]),
              Html(data: '${post['description']}'),
              ...files.map((raw) {
                final file = Map<String, dynamic>.from(raw as Map);
                final url = '${file['url']}';
                return file['is_image'] == true
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: InkWell(
                            onTap: () => launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                    imageUrl: '${file['thumbnail_url'] ?? url}',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 220))))
                    : ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text('${file['name']}'),
                        onTap: () => launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication));
              }),
              if (post['reactions'] is List &&
                  (post['reactions'] as List).isNotEmpty)
                Wrap(
                    spacing: 4,
                    children: (post['reactions'] as List)
                        .map((r) =>
                            Chip(label: Text('${r['emoji']} ${r['count']}')))
                        .toList()),
              const Divider(),
              Row(children: [
                TextButton.icon(
                    onPressed: () => _pickReaction(context),
                    icon: const Icon(Icons.thumb_up_outlined),
                    label: const Text('Cảm xúc')),
                const Spacer(),
                Text('${post['total_replies']} bình luận')
              ]),
            ])));
  }

  Future<void> _pickReaction(BuildContext context) =>
      showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: [
                        '👍',
                        '❤️',
                        '😂',
                        '😮',
                        '😢',
                        '🙏',
                        '🎉',
                        '👏',
                        '🔥'
                      ]
                          .map((emoji) => InkWell(
                              onTap: () {
                                Navigator.pop(sheet);
                                controller.react(
                                    int.tryParse('${post['id']}') ?? 0, emoji);
                              },
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 36))))
                          .toList()))));
}
