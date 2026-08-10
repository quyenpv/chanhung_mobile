import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class TeamChatRepo {
  final ApiClient apiClient;
  TeamChatRepo({required this.apiClient});

  Future<ResponseModel> bootstrap() async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.teamChatBootstrapUrl}';
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> loadMessages(int conversationId, {int beforeId = 0}) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.teamChatMessagesUrl}';
    return apiClient.request(url, Method.postMethod, {
      'conversation_id': conversationId.toString(),
      if (beforeId > 0) 'before_id': beforeId.toString(),
    }, passHeader: true);
  }

  Future<ResponseModel> sendMessage(int conversationId, String body) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.teamChatSendUrl}';
    return apiClient.request(url, Method.postMethod, {
      'conversation_id': conversationId.toString(),
      'body': body,
    }, passHeader: true);
  }

  Future<ResponseModel> videoMeeting(int conversationId) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.teamChatVideoUrl}';
    return apiClient.request(url, Method.postMethod, {
      'conversation_id': conversationId.toString(),
    }, passHeader: true);
  }

  Future<ResponseModel> createConversation({
    required String type,
    required String name,
    required List<int> memberIds,
    String description = '',
  }) {
    return apiClient.request(
      '${UrlContainer.baseUrl}${UrlContainer.teamChatCreateUrl}',
      Method.postMethod,
      {
        'type': type,
        'name': name,
        'description': description,
        'member_ids': memberIds.join(','),
      },
      passHeader: true,
    );
  }

  Future<ResponseModel> details(int conversationId) => apiClient.request(
        '${UrlContainer.baseUrl}${UrlContainer.teamChatDetailsUrl}?conversation_id=$conversationId',
        Method.getMethod,
        null,
        passHeader: true,
      );

  Future<ResponseModel> addMembers(int conversationId, List<int> memberIds) =>
      apiClient.request(
        '${UrlContainer.baseUrl}${UrlContainer.teamChatAddMembersUrl}',
        Method.postMethod,
        {'conversation_id': '$conversationId', 'member_ids': memberIds.join(',')},
        passHeader: true,
      );

  Future<ResponseModel> removeMember(int conversationId, int userId) =>
      apiClient.request(
        '${UrlContainer.baseUrl}${UrlContainer.teamChatRemoveMemberUrl}',
        Method.postMethod,
        {'conversation_id': '$conversationId', 'user_id': '$userId'},
        passHeader: true,
      );

  Future<ResponseModel> leaveGroup(int conversationId) => apiClient.request(
        '${UrlContainer.baseUrl}${UrlContainer.teamChatLeaveGroupUrl}',
        Method.postMethod,
        {'conversation_id': '$conversationId'},
        passHeader: true,
      );
}
