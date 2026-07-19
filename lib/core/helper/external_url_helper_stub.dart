import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(String? url) async {
  final value = url?.trim();
  if (value == null || value.isEmpty) {
    return false;
  }

  final uri = Uri.tryParse(value);
  if (uri == null) {
    return false;
  }

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    return false;
  }
}

