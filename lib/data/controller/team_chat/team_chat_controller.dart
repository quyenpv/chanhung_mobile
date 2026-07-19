import 'dart:async';
import 'dart:convert';

import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/repo/team_chat/team_chat_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamChatController extends GetxController {
  final TeamChatRepo repo;
  TeamChatController({required this.repo});

  bool isLoading = true;
  List<dynamic> conversations = [];
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
        conversations = payload['conversations'] is List ? payload['conversations'] as List : [];
      }
    }
    isLoading = false;
    update();
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
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => loadMessages(silent: true));
    loadMessages();
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
    if (body.isEmpty || isSending) return;
    isSending = true;
    update();
    final res = await repo.sendMessage(conversationId, body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      inputController.clear();
      await loadMessages();
    }
    isSending = false;
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
