import 'package:flutter/material.dart';
import 'package:ludicapp/core/constants/colors.dart';
import 'package:ludicapp/core/constants/styles.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.primary,
  textTheme: TextTheme(
    headlineSmall: AppTextStyles.headline, // Replace `headline6` with `headlineSmall`
    bodyMedium: AppTextStyles.body,       // Replace `bodyText2` with `bodyMedium`
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.buttonBackground, // Replace `primary` with `backgroundColor`
      foregroundColor: AppColors.primary,          // Replace `onPrimary` with `foregroundColor`
      textStyle: AppTextStyles.buttonText,
    ),
  ),
  cardTheme: const CardTheme(
    color: AppColors.cardBackground,
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  ),
);
