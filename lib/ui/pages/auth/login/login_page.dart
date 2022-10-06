import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodo_provider/blocs/auth/phone_verification_bloc.dart';
import 'package:foodo_provider/blocs/auth/login_bloc.dart';
import 'package:foodo_provider/translation/translations.g.dart';
import 'package:foodo_provider/ui/components/app_bar.dart';
import 'package:foodo_provider/ui/components/input.dart';
import 'package:foodo_provider/ui/pages/auth/confirm_phone/confirm_phone_page.dart';
import 'package:foodo_provider/ui/pages/auth/route.dart';

import '../layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  void _onLoginStateChanged(BuildContext context, LoginState state) {
    _handleErrors(context, state);

    if (state.status == LoginStatus.verificationRequired) {
      _navigateToConfirmPhonePage(context, state.phoneNumber);
    }
  }

  void _handleErrors(BuildContext context, LoginState state) {
    final errors = Translations.of(context).auth.errors;
    late String errorMessage;
    switch (state.error) {
      case null:
        return;
      case LoginError.invalidPhoneNumber:
        // handled by _Page
        return;
      case LoginError.invalidSmsCode:
        // handled by PhoneVerificationPage
        return;
      case LoginError.userNotRegistered:
        errorMessage = errors.userNotRegistered;
        break;
      case LoginError.unknown:
        errorMessage = errors.unknown;
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errorMessage),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PhoneVerificationBloc(),
      child: BlocProvider(
        create: (context) => LoginBloc(context.read<PhoneVerificationBloc>()),
        child: BlocListener<LoginBloc, LoginState>(
          listener: _onLoginStateChanged,
          child: const _Page(),
        ),
      ),
    );
  }

  void _navigateToConfirmPhonePage(BuildContext context, String phoneNumber) {
    final phoneVerificationBloc = context.read<PhoneVerificationBloc>();
    final t = Translations.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: phoneVerificationBloc,
          child: ConfirmPhonePage(
            title: t.auth.loginPage.title,
            phoneNumber: phoneNumber,
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    Key? key,
  }) : super(key: key);

  void _onInputChanged(
    BuildContext context, {
    String? phoneNumber,
  }) {
    final bloc = context.read<LoginBloc>();
    bloc.add(InputForm(
      phoneNumber ?? bloc.state.phoneNumber,
      dryRun: true,
    ));
  }

  void _onLogin(BuildContext context) {
    final bloc = context.read<LoginBloc>();
    bloc.add(InputForm(bloc.state.phoneNumber));
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: PageAppBar(title: t.auth.loginPage.title),
      body: AuthLayout(
        header: const SizedBox(),
        title: Text(t.auth.loginPage.enterPhoneNumber),
        subtitle: Text(t.auth.loginPage.enterPhoneNumberSubtitle),
        form: [
          AppPhoneNumberField(
            error: context.watch<LoginBloc>().state.error ==
                    LoginError.invalidPhoneNumber
                ? t.auth.errors.invalidPhoneNumber
                : null,
            onChanged: (phoneNumber) =>
                _onInputChanged(context, phoneNumber: phoneNumber),
            textInputAction: TextInputAction.next,
          ),
        ],
        actionText: t.auth.loginPage.loginButton,
        isLoading:
            context.watch<LoginBloc>().state.status == LoginStatus.loading,
        onAction: () => _onLogin(context),
        bottom: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.auth.loginPage.noAccount),
            TextButton(
              child: Text(t.auth.loginPage.createAccount),
              onPressed: () => _replaceWithRegisterPage(context),
            ),
          ],
        ),
      ),
    );
  }

  void _replaceWithRegisterPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      AuthFlow.registerFlowRoute,
    );
  }
}
