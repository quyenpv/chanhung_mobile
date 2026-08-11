import 'dart:convert';

import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/repo/timeline/timeline_repo.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TimelineController extends GetxController {
  final TimelineRepo repo;
  TimelineController({required this.repo});

  bool isLoading = true;
  bool isLoadingMore = false;
  bool isPosting = false;
  bool hasMore = false;
  int nextOffset = 0;
  List<dynamic> posts = [];
  List<PlatformFile> attachments = [];
  String visibility = 'all';
  final composer = TextEditingController();

  @override
  void onClose() {
    composer.dispose();
    super.onClose();
  }

  Future<void> load({bool append = false}) async {
    if (append && (!hasMore || isLoadingMore)) return;
    append ? isLoadingMore = true : isLoading = true;
    update();
    final response = await repo.feed(offset: append ? nextOffset : 0);
    if (response.statusCode == 200) {
      final payload = apiPayload(jsonDecode(response.responseJson));
      final incoming = payload['posts'] is List ? payload['posts'] as List : [];
      posts = append ? [...posts, ...incoming] : incoming;
      hasMore = payload['has_more'] == true;
      nextOffset = int.tryParse('${payload['next_offset']}') ?? posts.length;
    } else {
      Get.snackbar('Timeline', response.message);
    }
    isLoading = false;
    isLoadingMore = false;
    update();
  }

  Future<void> pickFiles({bool imagesOnly = false}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: imagesOnly ? FileType.image : FileType.any,
    );
    if (result != null) {
      attachments = [...attachments, ...result.files]
          .where((file) => file.path != null)
          .take(10)
          .toList();
      update();
    }
  }

  void removeAttachment(int index) {
    attachments.removeAt(index);
    update();
  }

  Future<void> publish() async {
    final text = composer.text.trim();
    if ((text.isEmpty && attachments.isEmpty) || isPosting) return;
    isPosting = true;
    update();
    final response =
        await repo.create(text, visibility: visibility, files: attachments);
    if (response.statusCode == 200 || response.statusCode == 201) {
      composer.clear();
      attachments = [];
      visibility = 'all';
      await load();
    } else {
      Get.snackbar('Không thể đăng bài', response.message);
    }
    isPosting = false;
    update();
  }

  Future<void> react(int postId, String emoji) async {
    final response = await repo.react(postId, emoji);
    if (response.statusCode == 200) await load();
  }

  Future<void> edit(int id, String text) async {
    final response = await repo.update(id, text.trim());
    if (response.statusCode == 200) await load();
  }

  Future<void> delete(int id) async {
    final response = await repo.delete(id);
    if (response.statusCode == 200) {
      posts.removeWhere((post) => '${post['id']}' == '$id');
      update();
    }
  }
}
