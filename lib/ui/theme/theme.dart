import 'package:flutter/material.dart';

part 'data.dart';

extension ThemeContext on BuildContext {
  AppThemeData get theme => AppTheme.of(this).theme;
}

class AppTheme extends StatefulWidget {
  const AppTheme({Key? key, required this.child}) : super(key: key);

  final Widget child;

  static AppThemeState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppThemeProvider>()!.state;

  @override
  State<AppTheme> createState() => AppThemeState();

  static final light = LightThemeData();
  static final dark = DarkThemeData();
}

class AppThemeState extends State<AppTheme> {
  late AppThemeData theme;
  ThemeMode themeMode = ThemeMode.system;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onPlatformBrightnessUpdated(MediaQuery.of(context).platformBrightness);
  }

  void onPlatformBrightnessUpdated(Brightness brightness) {
    if (themeMode != ThemeMode.system) return;

    switch (brightness) {
      case Brightness.light:
        theme = AppTheme.light;
        break;
      case Brightness.dark:
        theme = AppTheme.dark;
        break;
    }
  }

  void changeThemeMode(ThemeMode mode) {
    themeMode = mode;
    switch (mode) {
      case ThemeMode.system:
        onPlatformBrightnessUpdated(MediaQuery.of(context).platformBrightness);
        break;
      case ThemeMode.light:
        theme = AppTheme.light;
        break;
      case ThemeMode.dark:
        theme = AppTheme.dark;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AppThemeProvider(state: this, child: widget.child);
  }
}

class _AppThemeProvider extends InheritedWidget {
  const _AppThemeProvider({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  final AppThemeState state;

  @override
  bool updateShouldNotify(_AppThemeProvider oldWidget) =>
      oldWidget.state.theme != state.theme ||
      oldWidget.state.themeMode != state.themeMode;
}
