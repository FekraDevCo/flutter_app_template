import 'package:flutter/material.dart';
import 'package:foodo_provider/repositories/auth.dart';
import 'package:foodo_provider/ui/components/progress_indicator.dart';
import 'package:foodo_provider/ui/pages/auth/login/login_page.dart';
import 'package:foodo_provider/ui/pages/home/home_page.dart';
import 'package:foodo_provider/ui/theme/theme.dart';
import 'package:foodo_provider/utils/api_caller.dart';
import 'package:foodo_provider/utils/service_locator.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ApiCaller caller = serviceLocator();
  final AuthRepository auth = serviceLocator();

  @override
  void initState() {
    super.initState();
    Future(() async {
      final result = await caller<bool, AuthError>(() => auth.isLoggedIn());
      // TODO(akram) improve with error handling
      final isLoggedIn = result.valueOrNull;

      if (isLoggedIn != true) {
        goToLogin();
      } else {
        goToHome();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppProgressIndicator(
        color: context.theme.primaryColor,
      ),
    );
  }

  void goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void goToHome() {
    // TODO: do save user token
    // saveUserInformation(context);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }
}
