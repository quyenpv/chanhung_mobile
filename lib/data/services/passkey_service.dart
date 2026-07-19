import 'package:chanhung/core/utils/local_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PasskeyService {
  static const MethodChannel _channel = MethodChannel('chanhung/passkey');

  static bool get isSupportedBuild =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<String> getCredential(String requestJson) async {
    if (!isSupportedBuild) {
      throw const PasskeyException(LocalStrings.passkeyLoginUnavailable);
    }

    try {
      final result = await _channel.invokeMethod<String>(
        'getCredential',
        {'requestJson': requestJson},
      );
      if (result == null || result.isEmpty) {
        throw const PasskeyException(LocalStrings.noPasskeyResponse);
      }
      return result;
    } on MissingPluginException {
      throw const PasskeyException(LocalStrings.passkeyLoginUnavailable);
    } on PlatformException catch (error) {
      throw PasskeyException(
        error.message ?? LocalStrings.passkeyLoginUnavailable,
      );
    }
  }
}

class PasskeyException implements Exception {
  const PasskeyException(this.message);

  final String message;

  @override
  String toString() => message;
}
