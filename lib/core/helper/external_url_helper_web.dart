import 'package:web/web.dart' as web;

Future<bool> openExternalUrl(String? url) async {
  final value = url?.trim();
  if (value == null || value.isEmpty) {
    return false;
  }

  web.window.open(value, '_blank');
  return true;
}
