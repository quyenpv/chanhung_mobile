import 'dart:io';

import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class TimelineRepo {
  final ApiClient apiClient;
  TimelineRepo({required this.apiClient});

  String get _base => '${UrlContainer.baseUrl}timeline';

  Future<ResponseModel> feed({int offset = 0}) => apiClient.request(
      '$_base/feed?offset=$offset&limit=15', Method.getMethod, null,
      passHeader: true);

  Future<ResponseModel> replies(int postId) =>
      apiClient.request('$_base/$postId/replies', Method.getMethod, null,
          passHeader: true);

  Future<ResponseModel> create(String description,
          {String visibility = 'all', List<PlatformFile> files = const []}) =>
      _multipart(
          '$_base/create',
          {
            'description': description,
            'visibility': visibility,
          },
          files);

  Future<ResponseModel> comment(int postId, String description,
          {List<PlatformFile> files = const []}) =>
      _multipart('$_base/$postId/comment', {'description': description}, files);

  Future<ResponseModel> update(int id, String description) => apiClient.request(
      '$_base/$id/update', Method.postMethod, {'description': description},
      passHeader: true);

  Future<ResponseModel> delete(int id) => apiClient
      .request('$_base/$id/delete', Method.postMethod, {}, passHeader: true);

  Future<ResponseModel> react(int postId, String emoji) => apiClient.request(
      '$_base/react', Method.postMethod, {'post_id': '$postId', 'emoji': emoji},
      passHeader: true);

  Future<ResponseModel> _multipart(
      String url, Map<String, String> fields, List<PlatformFile> files) async {
    if (files.isEmpty) {
      return apiClient.request(url, Method.postMethod, fields,
          passHeader: true);
    }
    apiClient.initToken();
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': '${apiClient.tokenType} ${apiClient.token}',
          'X-Auth-Token': apiClient.token,
        })
        ..fields.addAll(fields);
      for (final file in files) {
        if (file.path == null) continue;
        request.files.add(await http.MultipartFile.fromPath(
          'manualFiles[]',
          file.path!,
          filename: file.name,
        ));
      }
      final response = await http.Response.fromStream(await request.send());
      return ResponseModel(
        response.statusCode == 200 || response.statusCode == 201,
        response.reasonPhrase ?? '',
        response.statusCode,
        response.body,
      );
    } on SocketException {
      return ResponseModel(false, 'Không có kết nối mạng', 503, '');
    } catch (error) {
      return ResponseModel(false, error.toString(), 499, '');
    }
  }
}
