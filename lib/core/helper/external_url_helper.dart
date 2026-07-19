import 'external_url_helper_stub.dart'
    if (dart.library.html) 'external_url_helper_web.dart' as opener;

Future<bool> openExternalUrl(String? url) {
  return opener.openExternalUrl(url);
}
