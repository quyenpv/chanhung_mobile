import 'dart:convert';

import 'package:chanhung/data/repo/dashboard/dashboard_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/messages.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/localization/localization_controller.dart';
import 'package:chanhung/data/model/language/language_model.dart';

class LanguageBody extends StatefulWidget {
  final List<LanguageModel> langList;

  const LanguageBody({super.key, required this.langList});

  @override
  State<LanguageBody> createState() => _LanguageBodyState();
}

class _LanguageBodyState extends State<LanguageBody> {
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.langList.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  setState(() {
                    selectedIndex = index;
                  });
                  String languageCode = widget.langList[index].languageCode;
                  String countryCode = widget.langList[index].countryCode;
                  final repo = Get.put(DashboardRepo(apiClient: Get.find()));
                  final localizationController = Get.put(
                      LocalizationController(sharedPreferences: Get.find()));
                  Map<String, Map<String, String>> language = {};
                  final String response = await rootBundle
                      .loadString('assets/lang/$languageCode.json');
                  var resJson = jsonDecode(response);
                  await repo.apiClient.sharedPreferences.setString(
                      SharedPreferenceHelper.languageListKey, languageCode);

                  var value = resJson as Map<String, dynamic>;
                  Map<String, String> json = {};
                  value.forEach((key, value) {
                    json[key] = value.toString();
                  });

                  language['${languageCode}_$countryCode'] = json;

                  Get.clearTranslations();
                  Get.addTranslations(Messages(languages: language).keys);

                  Locale local = Locale(languageCode, countryCode);
                  localizationController.setLanguage(local);

                  Get.back();
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.space15,
                      horizontal: Dimensions.space15),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          BorderRadius.circular(Dimensions.defaultRadius)),
                  child: Text(
                    (widget.langList[index].languageName).tr,
                    style: regularDefault.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium!.color),
                  ),
                ),
              );
            }));
  }
}
