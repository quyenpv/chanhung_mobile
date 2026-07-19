import 'dart:convert';
import 'dart:io';

import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/method.dart';

class ApiClient extends GetxService {
  SharedPreferences sharedPreferences;
  ApiClient({required this.sharedPreferences});

  Future<ResponseModel> request(
    String uri,
    String method,
    Map<String, dynamic>? params, {
    bool passHeader = false,
    bool isOnlyAcceptType = false,
  }) async {
    Uri url = Uri.parse(uri);
    http.Response response;

    try {
      if (passHeader && !_hasAuthToken()) {
        await _clearAuthData();
        if (Get.currentRoute != RouteHelper.loginScreen) {
          Get.offAllNamed(RouteHelper.loginScreen);
        }
        return ResponseModel(false, LocalStrings.unAuthorized.tr, 401, '');
      }

      if (method == Method.postMethod) {
        if (passHeader) {
          initToken();
          if (isOnlyAcceptType) {
            response = await http.post(url, body: params, headers: {
              "Accept": "application/json",
            });
          } else {
            response =
                await http.post(url, body: params, headers: _authHeaders());
          }
        } else {
          response = await http.post(url, body: params);
        }
      } else if (method == Method.postMethod) {
        if (passHeader) {
          initToken();
          response =
              await http.post(url, body: params, headers: _authHeaders());
        } else {
          response = await http.post(url, body: params);
        }
      } else if (method == Method.putMethod) {
        if (passHeader) {
          initToken();
          response = await http.put(url, body: params, headers: _authHeaders());
        } else {
          response = await http.post(url, body: params);
        }
      } else if (method == Method.deleteMethod) {
        response = await http.delete(url);
      } else if (method == Method.updateMethod) {
        response = await http.patch(url);
      } else {
        if (passHeader) {
          initToken();
          response = await http.get(url, headers: _authHeaders());
        } else {
          response = await http.get(
            url,
          );
        }
      }

      if (kDebugMode) {
        print('url--------------${uri.toString()}');
        print('params-----------${params.toString()}');
        print('status-----------${response.statusCode}');
        print('body-------------${response.body.toString()}');
        print('token------------$token');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ResponseModel(
            true, 'Success', response.statusCode, response.body);
      } else {
        String message =
            response.reasonPhrase ?? LocalStrings.somethingWentWrong.tr;
        if (response.body.isNotEmpty) {
          try {
            Map<String, dynamic> responseData = jsonDecode(response.body);
            message = responseData['message'] ??
                responseData['error']?['message'] ??
                responseData['data']?['message'] ??
                message;
          } catch (_) {}
        }

        // Only authenticated requests should invalidate the stored session.
        // A 401 from the login endpoint simply means the submitted credentials
        // were rejected; clearing state or redirecting in that case can cause
        // an unnecessary navigation while the login controller handles it.
        if (passHeader &&
            (response.statusCode == 401 || response.statusCode == 403)) {
          await _clearAuthData();
          if (Get.currentRoute != RouteHelper.loginScreen) {
            Get.offAllNamed(RouteHelper.loginScreen);
          }
        }

        return ResponseModel(
            false, message, response.statusCode, response.body);
      }
    } on SocketException {
      return ResponseModel(false, LocalStrings.noInternet.tr, 503, '');
    } on FormatException {
      return ResponseModel(false, LocalStrings.badResponseMsg.tr, 400, '');
    } catch (e) {
      return ResponseModel(false, LocalStrings.somethingWentWrong.tr, 499, '');
    }
  }

  String token = '';
  String tokenType = '';

  Map<String, String> _authHeaders() {
    return {
      "Accept": "application/json",
      "Authorization": "$tokenType $token",
      "X-Auth-Token": token,
    };
  }

  bool _hasAuthToken() {
    initToken();
    final normalizedToken = token.trim().toLowerCase();
    return normalizedToken.isNotEmpty && normalizedToken != 'null';
  }

  Future<void> _clearAuthData() async {
    await sharedPreferences.setBool(
        SharedPreferenceHelper.rememberMeKey, false);
    await sharedPreferences.remove(SharedPreferenceHelper.token);
    await sharedPreferences.remove(SharedPreferenceHelper.accessTokenKey);
    await sharedPreferences.remove(SharedPreferenceHelper.accessTokenType);
  }

  initToken() {
    if (sharedPreferences.containsKey(SharedPreferenceHelper.accessTokenKey)) {
      String? t =
          sharedPreferences.getString(SharedPreferenceHelper.accessTokenKey);
      String? tType =
          sharedPreferences.getString(SharedPreferenceHelper.accessTokenType);
      token = t ?? '';
      tokenType = tType == null || tType.trim().isEmpty ? 'Bearer' : tType;
    } else {
      token = '';
      tokenType = 'Bearer';
    }
  }
}
