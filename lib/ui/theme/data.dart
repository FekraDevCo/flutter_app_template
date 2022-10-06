// ignore_for_file: annotate_overrides

part of 'theme.dart';

const String arabicFontFamily = "Baloo";
const String englishFontFamily = "Ubuntu";

abstract class AppThemeData {
  ThemeData material(BuildContext context) => ThemeData(
        primaryColor: primaryColor,
      );

  Color get backgroundColor;
  Color get primaryColor;
  Color get secondaryColor;
  Color get appBarColor;
  Color get hintColor;
  Color get inputBackgroundColor;
  Color get inputBorderColor;
  Color get inputErrorColor;
  Color get cardColor;
  Color get titleColor;
  Color get cardTextColor;
}

class LightThemeData extends AppThemeData {
  @override
  material(context) => super.material(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(
          color: backgroundColor,
          foregroundColor: const Color(0xFF242424),
          elevation: 0,
          centerTitle: true,
        ),
      );

  get backgroundColor => Colors.white;
  get primaryColor => const Color(0xFF01A0C6);
  get secondaryColor => Colors.orange;
  get appBarColor => Colors.blue;
  get hintColor => Colors.grey;
  get inputBackgroundColor => const Color(0x11000000);
  get inputBorderColor => Colors.grey;
  get inputErrorColor => Colors.red;
  get cardColor => Colors.white;
  get titleColor => Colors.black;
  get cardTextColor => Colors.black54;
}

class DarkThemeData extends LightThemeData {}
