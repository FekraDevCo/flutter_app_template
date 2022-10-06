import 'package:flutter/material.dart';
import 'package:foodo_provider/ui/pages/auth/login/login_page.dart';
import 'package:foodo_provider/ui/pages/auth/register/register_page.dart';
import 'package:foodo_provider/ui/pages/landing/landing_page.dart';

class AuthFlow {
  static MaterialPageRoute get loginFlowRoute => MaterialPageRoute(
        builder: (context) => const LoginPage(),
        settings: settings,
      );

  static MaterialPageRoute get registerFlowRoute => MaterialPageRoute(
        builder: (context) => const RegisterPage(),
        settings: settings,
      );

  static void exitFlow(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (_) => false,
    );
    //Navigator.pop(context);
  }

  static const settings = RouteSettings(name: 'NavigatorStackMarker.authFlow');
}
