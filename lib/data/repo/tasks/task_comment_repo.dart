import 'dart:convert';
import 'dart:io';
import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:http/http.dart' as http;

class TaskCommentRepo {
  final ApiClient apiClient;
  TaskCommentRepo({required this.apiClient});

  String get _baseUrl => UrlContainer.baseUrl;

  Future<ResponseModel> getComments(String taskId) async {
    final url = '$_baseUrl/api/v1/tasks/$taskId/comments';
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> postComment({
    required String taskId,
    required String content,
    List<File>? images,
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/tasks/$taskId/comments');
    final token = apiClient.sharedPreferences.getString('access_token') ?? '';

    if (images != null && images.isNotEmpty) {
      // Multipart request for images
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['content'] = content;

      for (int i = 0; i < images.length; i++) {
        final bytes = await images[i].readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'attachments[]',
          bytes,
          filename: 'image_$i.jpg',
        ));
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final statusCode = streamedResponse.statusCode;
      final success = statusCode == 200 || statusCode == 201;
      return ResponseModel(success, '', statusCode, responseBody);
    } else {
      // Plain JSON
      final body = jsonEncode({'content': content});
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      final success = response.statusCode == 200 || response.statusCode == 201;
      return ResponseModel(success, '', response.statusCode, response.body);
    }
  }
}
