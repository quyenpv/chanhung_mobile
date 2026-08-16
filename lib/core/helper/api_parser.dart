class ApiParser {
  static String? asString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static double asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool asBool(dynamic value) {
    return value == true || value == 1 || value == '1' || value == 'true';
  }

  static List<dynamic> asList(dynamic json, {String? nestedKey}) {
    final data = json is Map ? json['data'] : json;
    if (data is List) return data;
    if (data is Map) {
      if (nestedKey != null && data[nestedKey] is List) {
        return List<dynamic>.from(data[nestedKey]);
      }
      for (final key in ['projects', 'tasks', 'invoices', 'comments']) {
        if (data[key] is List) {
          return List<dynamic>.from(data[key]);
        }
      }
    }
    return const [];
  }

  static Map<String, dynamic>? asObject(dynamic json, {String? nestedKey}) {
    final data = json is Map ? json['data'] : json;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    if (nestedKey != null && map[nestedKey] is Map) {
      return Map<String, dynamic>.from(map[nestedKey]);
    }
    return map;
  }
}
