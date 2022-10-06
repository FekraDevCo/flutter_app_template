import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodo_provider/blocs/auth/phone_verification_bloc.dart';
import 'package:foodo_provider/blocs/auth/register_bloc.dart';
import 'package:foodo_provider/translation/translations.g.dart';
import 'package:foodo_provider/ui/components/app_bar.dart';
import 'package:foodo_provider/ui/components/input.dart';
import 'package:foodo_provider/ui/pages/auth/confirm_phone/confirm_phone_page.dart';
import 'package:foodo_provider/ui/pages/auth/layout.dart';
import 'package:foodo_provider/ui/pages/auth/login/login_page.dart';
import 'package:foodo_provider/ui/theme/theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  void _onRegisterStateChanged(context, state) {
    _handleErrors(context, state);

    if (state.status == RegisterStatus.verificationRequired) {
      _navigateToConfirmPhonePage(context, state);
    }
  }

  _handleErrors(BuildContext context, RegisterState state) {
    final errors = Translations.of(context).auth.errors;
    late String errorMessage;
    switch (state.error) {
      case null:
        return;
      case RegisterError.invalidPhoneNumber:
      case RegisterError.emptyUsername:
        // handled by _Page
        return;
      case RegisterError.invalidSmsCode:
        // handled by PhoneVerificationPage
        return;
      case RegisterError.unknown:
        errorMessage = errors.unknown;
        break;
      case RegisterError.userRegistered:
        errorMessage = errors.userRegistered;
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
        create: (context) =>
            RegisterBloc(context.read<PhoneVerificationBloc>()),
        child: BlocListener<RegisterBloc, RegisterState>(
          listener: _onRegisterStateChanged,
          child: const _Page(),
        ),
      ),
    );
  }

  void _navigateToConfirmPhonePage(BuildContext context, RegisterState state) {
    final phoneVerificationBloc = context.read<PhoneVerificationBloc>();
    final t = Translations.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: phoneVerificationBloc,
          child: ConfirmPhonePage(
            title: t.auth.registerPage.title,
            phoneNumber: state.phoneNumber,
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

  void _onInputChanged(BuildContext context,
      {String? username, String? phoneNumber}) {
    final bloc = context.read<RegisterBloc>();
    bloc.add(InputForm(
      phoneNumber ?? bloc.state.phoneNumber,
      username ?? bloc.state.username,
      dryRun: true,
    ));
  }

  void _onRegister(BuildContext context) {
    final bloc = context.read<RegisterBloc>();
    bloc.add(InputForm(
      bloc.state.phoneNumber,
      bloc.state.username,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: PageAppBar(
        title: t.auth.registerPage.title,
      ),
      backgroundColor: context.theme.backgroundColor,
      body: AuthLayout(
        title: Text(t.auth.registerPage.createNewAccount),
        subtitle: Text(t.auth.registerPage.createNewAccountSubtitle),
        header: const SizedBox(),
        form: [
          AppTextField(
            hint: t.auth.signup.username,
            icon: const Icon(Icons.person_outline),
            error: context.watch<RegisterBloc>().state.error ==
                    RegisterError.emptyUsername
                ? t.auth.errors.emptyUsername
                : null,
            onChanged: (username) =>
                _onInputChanged(context, username: username),
            textInputAction: TextInputAction.next,
          ),
          AppPhoneNumberField(
            error: context.watch<RegisterBloc>().state.error ==
                    RegisterError.invalidPhoneNumber
                ? t.auth.errors.invalidPhoneNumber
                : null,
            onChanged: (phoneNumber) =>
                _onInputChanged(context, phoneNumber: phoneNumber),
          ),
        ],
        actionText: t.auth.registerPage.registerButton,
        onAction: () => _onRegister(context),
        isLoading: context.watch<RegisterBloc>().state.status ==
            RegisterStatus.loading,
        bottom: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.auth.registerPage.alreadyHaveAccount),
            TextButton(
              child: Text(t.auth.registerPage.login),
              onPressed: () => _replaceWithLoginPage(context),
            ),
          ],
        ),
      ),
    );
  }

  void _replaceWithLoginPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }
}
