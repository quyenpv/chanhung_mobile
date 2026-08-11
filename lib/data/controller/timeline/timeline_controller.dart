import 'dart:convert';
import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/repo/timeline/timeline_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TimelineController extends GetxController {
  final TimelineRepo repo;
  TimelineController({required this.repo});
  bool isLoading = true;
  bool isPosting = false;
  List<dynamic> posts = [];
  final composer = TextEditingController();

  @override
  void onClose() {
    composer.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading = true;
    update();
    final response = await repo.feed();
    if (response.statusCode == 200) {
      final payload = apiPayload(jsonDecode(response.responseJson));
      posts = payload['posts'] is List ? payload['posts'] as List : [];
    }
    isLoading = false;
    update();
  }

  Future<void> publish() async {
    final text = composer.text.trim();
    if (text.isEmpty || isPosting) return;
    isPosting = true;
    update();
    final response = await repo.create(text);
    if (response.statusCode == 200 || response.statusCode == 201) {
      composer.clear();
      await load();
    }
    isPosting = false;
    update();
  }

  Future<void> react(int postId, String emoji) async {
    if ((await repo.react(postId, emoji)).statusCode == 200) await load();
  }
}
