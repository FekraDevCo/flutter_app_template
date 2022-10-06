import 'package:flutter/material.dart';
import 'package:foodo_provider/repositories/auth.dart';
import 'package:foodo_provider/ui/pages/landing/landing_page.dart';
import 'package:foodo_provider/utils/service_locator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: TextButton(
              onPressed: () async {
                await serviceLocator<AuthRepository>().signOut();
                goToLanding();
              },
              child: const Text('log out'))),
    );
  }

  void goToLanding() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (route) => false);
  }
}
