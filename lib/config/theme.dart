import 'package:flutter/material.dart';

class AppTheme {
  final bool isDarkmode;
  final ColorScheme? darkColor;
  final ColorScheme? lightColor;

  AppTheme(
      {required this.isDarkmode,
      required this.darkColor,
      required this.lightColor});

  ThemeData getTheme() => ThemeData(
        colorScheme: isDarkmode ? darkColor : lightColor,
        brightness: isDarkmode ? Brightness.dark : Brightness.light,
      );
}
