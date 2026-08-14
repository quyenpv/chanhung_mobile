import 'package:chanhung/core/utils/color_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chanhung/core/utils/app_design.dart';

ThemeData light = ThemeData(
  useMaterial3: true,
  primaryColor: ColorResources.primaryColor,
  secondaryHeaderColor: ColorResources.secondaryColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppDesign.canvas,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    actionsIconTheme: IconThemeData(color: AppDesign.ink),
    foregroundColor: AppDesign.ink,
    titleTextStyle: TextStyle(
      color: AppDesign.ink,
      fontWeight: FontWeight.bold,
      fontSize: 23,
    ),
    iconTheme: IconThemeData(color: Colors.black),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarColor: AppDesign.canvas,
      statusBarIconBrightness: Brightness.dark,
    ),
  ),
  fontFamily: 'Montserrat-Arabic',
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: AppDesign.canvas,
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
      foregroundColor: Colors.white,
      backgroundColor: ColorResources.primaryColor),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
      borderSide: const BorderSide(color: ColorResources.primaryColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(color: Colors.black),
    fillColor: ColorResources.inputColor,
  ),
  cardTheme: const CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDesign.radiusMedium)),
    ),
  ),
  cardColor: Colors.white,
  dataTableTheme: DataTableThemeData(
      headingRowColor:
          WidgetStateProperty.all<Color>(ColorResources.lightBlueGreyColor),
      dataRowColor: WidgetStateProperty.all<Color>(Colors.white)),
  drawerTheme: const DrawerThemeData(
      backgroundColor: ColorResources.colorWhite,
      surfaceTintColor: ColorResources.primaryColor),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
        color: AppDesign.ink, fontWeight: FontWeight.w700, fontSize: 36),
    headlineMedium: TextStyle(
        color: AppDesign.ink, fontWeight: FontWeight.w700, fontSize: 24),
    titleLarge: TextStyle(
        color: AppDesign.ink, fontWeight: FontWeight.w700, fontSize: 22),
    titleMedium: TextStyle(
        color: AppDesign.ink, fontWeight: FontWeight.w600, fontSize: 16),
    bodyLarge: TextStyle(
        color: AppDesign.ink, fontWeight: FontWeight.w400, fontSize: 16),
    bodyMedium: TextStyle(
        color: AppDesign.ink, fontWeight: FontWeight.w400, fontSize: 14),
    bodySmall: TextStyle(
        color: AppDesign.mutedInk, fontWeight: FontWeight.w400, fontSize: 12),
    labelLarge: TextStyle(
        color: AppDesign.ink, fontWeight: FontWeight.w600, fontSize: 12),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 5,
      type: BottomNavigationBarType.fixed),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: ColorResources.primaryColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: ColorResources.lightBlueGreyColor,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      minimumSize: const Size(48, 48),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ColorResources.primaryColor,
      side: const BorderSide(color: ColorResources.primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      minimumSize: const Size(48, 48),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ColorResources.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      elevation: 0,
      backgroundColor: ColorResources.primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      shape: const StadiumBorder(),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: ColorResources.primaryColor,
    disabledColor: ColorResources.lightBlueGreyColor,
    side: const BorderSide(color: ColorResources.primaryColor, width: .8),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
    labelStyle: const TextStyle(
      color: ColorResources.primaryColor,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    secondaryLabelStyle: const TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
    showCheckmark: false,
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 72,
    elevation: 0,
    backgroundColor: Colors.white,
    indicatorColor: ColorResources.primaryColor.withValues(alpha: .14),
    labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppDesign.ink
              : AppDesign.mutedInk,
        )),
  ),
  hintColor: ColorResources.hintColor,
);

ThemeData dark = ThemeData(
  useMaterial3: true,
  primaryColor: ColorResources.primaryColor,
  secondaryHeaderColor: ColorResources.secondaryColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: ColorResources.primaryColor,
    elevation: 0,
    actionsIconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 23,
    ),
    iconTheme: IconThemeData(color: Colors.white),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarColor: ColorResources.primaryColor,
      statusBarIconBrightness: Brightness.light,
    ),
  ),
  primarySwatch: Colors.red,
  scaffoldBackgroundColor: ColorResources.screenBgColorDark,
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    contentPadding: const EdgeInsetsDirectional.only(top: 5, start: 30),
    fillColor: ColorResources.inputColorDark,
    hintStyle: const TextStyle(color: Colors.white),
  ),
  cardTheme: const CardThemeData(color: Colors.black),
  cardColor: ColorResources.cardColorDark,
  drawerTheme: const DrawerThemeData(
      backgroundColor: ColorResources.screenBgColorDark,
      surfaceTintColor: ColorResources.screenBgColorDark),
  textTheme: const TextTheme(
      displaySmall: TextStyle(
          color: ColorResources.colorGrey,
          fontWeight: FontWeight.w400,
          fontSize: 16),
      bodyMedium: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w400, fontSize: 12),
      bodySmall: TextStyle(
          color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 12),
      bodyLarge: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14)),
  iconTheme: const IconThemeData(color: Colors.white),
  primaryIconTheme: const IconThemeData(color: Colors.white),
  hintColor: ColorResources.hintColorDark,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: ColorResources.primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      shape: const StadiumBorder(),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ColorResources.primaryColor,
      side: const BorderSide(color: ColorResources.primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: const StadiumBorder(),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(shape: const StadiumBorder()),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(shape: const StadiumBorder()),
  ),
  chipTheme: const ChipThemeData(
    backgroundColor: ColorResources.cardColorDark,
    selectedColor: ColorResources.primaryColor,
    side: BorderSide(color: ColorResources.primaryColor, width: .8),
    shape: StadiumBorder(),
    showCheckmark: false,
  ),
);
