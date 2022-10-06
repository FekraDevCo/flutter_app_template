import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:foodo_provider/models/user.dart';
import 'package:foodo_provider/repositories/auth.dart';
import 'package:foodo_provider/services/auth/email_auth_provider.dart';
import 'package:foodo_provider/services/auth/phone_verification.dart';
import 'package:foodo_provider/utils/api_caller.dart';
import 'package:foodo_provider/utils/preferences.dart';
import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

Future<void> initCoreServices() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  prefs = Preferences();
  await prefs.init();
  serviceLocator.registerSingleton<ApiCaller>(ApiCaller());
  serviceLocator.registerSingleton<PhoneVerificationService>(
    FirebasePhoneVerificationService(),
  );
  serviceLocator.registerSingleton<EmailAuthProvider>(
    FirebaseEmailAuthProvider(),
  );
  serviceLocator.registerSingleton<AuthRepository>(
    FirebaseAuthRepository(role: UserRole.restaurant),
  );
}
