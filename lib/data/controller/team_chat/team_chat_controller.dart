import 'dart:async';
import 'dart:convert';

import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/repo/team_chat/team_chat_repo.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamChatController extends GetxController {
  final TeamChatRepo repo;
  TeamChatController({required this.repo});

  bool isLoading = true;
  List<dynamic> conversations = [];
  List<dynamic> users = [];
  int currentUserId = 0;

  Map<String, dynamic> _payload(dynamic map) {
    final root = apiPayload(map);
    final data = root['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return root;
  }

  Future<void> load() async {
    isLoading = true;
    update();
    final res = await repo.bootstrap();
    if (res.statusCode == 200) {
      final map = jsonDecode(res.responseJson);
      final payload = _payload(map);
      if (payload.isNotEmpty) {
        currentUserId = int.tryParse('${payload['current_user_id']}') ?? 0;
        conversations = payload['conversations'] is List
            ? payload['conversations'] as List
            : [];
        users = payload['users'] is List ? payload['users'] as List : [];
      }
    }
    isLoading = false;
    update();
  }

  Future<int?> createConversation({
    required String type,
    required String name,
    required List<int> memberIds,
  }) async {
    final res = await repo.createConversation(
        type: type, name: name, memberIds: memberIds);
    if (res.statusCode != 200 && res.statusCode != 201) return null;
    final payload = _payload(jsonDecode(res.responseJson));
    await load();
    return int.tryParse('${payload['conversation_id']}');
  }
}

class TeamChatRoomController extends GetxController {
  final TeamChatRepo repo;
  TeamChatRoomController({required this.repo});

  Map<String, dynamic> _payload(dynamic map) {
    final root = apiPayload(map);
    final data = root['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return root;
  }

  int conversationId = 0;
  String title = 'Team Chat';
  int currentUserId = 0;
  bool isLoading = true;
  bool isSending = false;
  List<dynamic> messages = [];
  List<PlatformFile> pendingAttachments = [];
  List<dynamic> mentionSuggestions = [];
  final Map<String, int> _selectedMentions = {};
  List<dynamic> members = [];
  List<dynamic> availableUsers = [];
  List<dynamic> availableConversations = [];
  Map<String, dynamic>? replyTo;
  String conversationType = 'direct';
  bool canManageMembers = false;
  final TextEditingController inputController = TextEditingController();
  Timer? _pollTimer;

  @override
  void onClose() {
    _pollTimer?.cancel();
    inputController.dispose();
    super.onClose();
  }

  void initRoom(int id, String name, {int userId = 0}) {
    conversationId = id;
    title = name;
    currentUserId = userId;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 8), (_) => loadMessages(silent: true));
    loadMessages();
    loadDetails();
  }

  Future<void> loadDetails() async {
    final res = await repo.details(conversationId);
    if (res.statusCode != 200) return;
    final payload = _payload(jsonDecode(res.responseJson));
    members = payload['members'] is List ? payload['members'] as List : [];
    final conversation = payload['conversation'];
    if (conversation is Map) {
      conversationType = '${conversation['type'] ?? 'direct'}';
    }
    canManageMembers = payload['can_manage_members'] == true;
    update();
  }

  Future<bool> addMembers(List<int> ids) async {
    final res = await repo.addMembers(conversationId, ids);
    if (res.statusCode != 200) return false;
    await loadDetails();
    return true;
  }

  Future<bool> removeMember(int userId) async {
    final res = await repo.removeMember(conversationId, userId);
    if (res.statusCode != 200) return false;
    await loadDetails();
    return true;
  }

  Future<bool> leaveGroup() async {
    final res = await repo.leaveGroup(conversationId);
    return res.statusCode == 200;
  }

  Future<void> loadMessages({bool silent = false}) async {
    if (!silent) {
      isLoading = messages.isEmpty;
      update();
    }
    final res = await repo.loadMessages(conversationId);
    if (res.statusCode == 200) {
      final map = jsonDecode(res.responseJson);
      final payload = _payload(map);
      if (payload.isNotEmpty && payload['messages'] is List) {
        messages = payload['messages'] as List;
        if (silent) {
          update();
        }
      }
    }
    if (!silent) {
      isLoading = false;
      update();
    }
  }

  Future<void> send() async {
    final body = inputController.text.trim();
    if ((body.isEmpty && pendingAttachments.isEmpty) || isSending) return;
    isSending = true;
    update();
    var encodedBody = body;
    _selectedMentions.forEach((name, id) {
      encodedBody = encodedBody.replaceAll('@$name', '@[uid:$id]');
    });
    final res = await repo.sendMessage(conversationId, encodedBody,
        attachments: pendingAttachments,
        parentId: int.tryParse('${replyTo?['id'] ?? 0}') ?? 0);
    if (res.statusCode == 200 || res.statusCode == 201) {
      inputController.clear();
      pendingAttachments = [];
      mentionSuggestions = [];
      _selectedMentions.clear();
      replyTo = null;
      await loadMessages();
    }
    isSending = false;
    update();
  }

  void setReply(Map<String, dynamic> message) {
    replyTo = message;
    update();
  }

  void cancelReply() {
    replyTo = null;
    update();
  }

  Future<void> toggleReaction(int messageId, String emoji) async {
    final res = await repo.toggleReaction(messageId, emoji);
    if (res.statusCode == 200) await loadMessages(silent: true);
  }

  Future<bool> editMessage(int messageId, String body) async {
    final res = await repo.editMessage(messageId, body);
    if (res.statusCode == 200) await loadMessages(silent: true);
    return res.statusCode == 200;
  }

  Future<bool> deleteMessage(int messageId) async {
    final res = await repo.deleteMessage(messageId);
    if (res.statusCode == 200) await loadMessages(silent: true);
    return res.statusCode == 200;
  }

  Future<bool> pinMessage(int messageId) async {
    final res = await repo.pinMessage(conversationId, messageId);
    return res.statusCode == 200;
  }

  Future<bool> forwardMessage(int messageId, int targetConversationId) async {
    final res = await repo.forwardMessage(messageId, targetConversationId);
    return res.statusCode == 200;
  }

  Future<void> pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'csv',
        'txt',
        'zip'
      ],
      type: FileType.custom,
    );
    if (result == null) return;
    final available = 5 - pendingAttachments.length;
    pendingAttachments
        .addAll(result.files.where((f) => f.path != null).take(available));
    update();
  }

  void removeAttachment(int index) {
    if (index >= 0 && index < pendingAttachments.length) {
      pendingAttachments.removeAt(index);
      update();
    }
  }

  void onComposerChanged(String value) {
    if (conversationType == 'direct') {
      mentionSuggestions = [];
      return;
    }
    final cursor = inputController.selection.baseOffset;
    final beforeCursor = cursor >= 0 && cursor <= value.length
        ? value.substring(0, cursor)
        : value;
    final match = RegExp(r'(?:^|\s)@([^@\s]{0,30})$').firstMatch(beforeCursor);
    if (match == null) {
      if (mentionSuggestions.isNotEmpty) {
        mentionSuggestions = [];
        update();
      }
      return;
    }
    final query = (match.group(1) ?? '').toLowerCase();
    mentionSuggestions = members
        .where((member) =>
            int.tryParse('${member['id']}') != currentUserId &&
            '${member['name']}'.toLowerCase().contains(query))
        .take(8)
        .toList();
    update();
  }

  void selectMention(Map<String, dynamic> member) {
    final value = inputController.text;
    final cursor = inputController.selection.baseOffset;
    final beforeCursor = value.substring(0, cursor.clamp(0, value.length));
    final match = RegExp(r'(?:^|\s)@([^@\s]{0,30})$').firstMatch(beforeCursor);
    if (match == null) return;
    final name = '${member['name']}'.trim();
    final replacement = '${match.group(0)!.startsWith(' ') ? ' ' : ''}@$name ';
    final next = value.replaceRange(match.start, cursor, replacement);
    inputController.text = next;
    inputController.selection =
        TextSelection.collapsed(offset: match.start + replacement.length);
    _selectedMentions[name] = int.tryParse('${member['id']}') ?? 0;
    mentionSuggestions = [];
    update();
  }

  Future<void> startMeeting() async {
    final res = await repo.videoMeeting(conversationId);
    if (res.statusCode != 200) return;
    final map = jsonDecode(res.responseJson);
    final payload = _payload(map);
    final url = payload['url']?.toString();
    if (url != null && url.isNotEmpty) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
