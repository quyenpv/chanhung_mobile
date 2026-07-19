class TaskComment {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final String createdAt;
  final List<String> attachments;

  const TaskComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.attachments = const [],
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    final List<dynamic> attachRaw = json['attachments'] ?? [];
    return TaskComment(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] as String? ?? 'Unknown',
      userAvatar: json['user_avatar'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      attachments: attachRaw.map((e) => e.toString()).toList(),
    );
  }
}
