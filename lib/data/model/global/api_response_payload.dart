Map<String, dynamic> apiPayload(dynamic json) {
  if (json is! Map) {
    return <String, dynamic>{};
  }

  final root = Map<String, dynamic>.from(json);
  final data = root['data'];
  if (data is Map &&
      (data.containsKey('data') || data.containsKey('message'))) {
    return Map<String, dynamic>.from(data);
  }

  return root;
}

String? apiMessage(dynamic json) {
  final payload = apiPayload(json);
  final rootMessage = json is Map ? json['message'] : null;
  final message = payload['message'] ?? rootMessage;
  return message?.toString();
}

bool? apiSuccess(dynamic json) {
  final payload = apiPayload(json);
  final rootSuccess = json is Map ? json['success'] : null;
  final success = payload['success'] ?? rootSuccess;
  return success is bool ? success : null;
}

List<dynamic> apiListPayload(dynamic json, String resourceKey) {
  final payload = apiPayload(json);
  final payloadList = payload[resourceKey];
  if (payloadList is List) {
    return payloadList;
  }

  final data = payload['data'];
  if (data is List) {
    return data;
  }

  if (data is Map) {
    final resourceList = data[resourceKey];
    if (resourceList is List) {
      return resourceList;
    }

    final nestedData = data['data'];
    if (nestedData is List) {
      return nestedData;
    }
    if (nestedData is Map && nestedData[resourceKey] is List) {
      return nestedData[resourceKey] as List<dynamic>;
    }
  }

  return <dynamic>[];
}
