import 'package:shared_preferences/shared_preferences.dart';

late Preferences prefs;

class Preferences {
  late SharedPreferences _prefs;
  final _locale = 'Locale';
  final _nightMode = 'Night mode';

  init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  clearAll() async {
    await _prefs.clear();
  }

  setPreferredLanguage(String locale) async {
    await _prefs.setString(_locale, locale);
  }

  String? getPreferredLanguage() {
    return _prefs.getString(_locale);
  }

  setIsNightMode(bool isNightMode) async {
    await _prefs.setBool(_nightMode, isNightMode);
  }

  bool? isNightMode() {
    return _prefs.getBool(_nightMode);
  }
}
