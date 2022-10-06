import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodo_provider/blocs/auth/phone_verification_bloc.dart';
import 'package:foodo_provider/translation/translations.g.dart';
import 'package:foodo_provider/ui/components/app_bar.dart';
import 'package:foodo_provider/ui/components/verification_code.dart';
import 'package:foodo_provider/ui/pages/auth/layout.dart';
import 'package:foodo_provider/ui/theme/theme.dart';

import 'otp_success_dialog.dart';

class VerifyPhonePage extends StatelessWidget {
  const VerifyPhonePage({Key? key}) : super(key: key);

  void _onPhoneVerificationStateChanged(
      BuildContext context, PhoneVerificationState state) {
    _handleErrors(context, state);
    _handleNavigation(context, state);
  }

  void _handleNavigation(BuildContext context, PhoneVerificationState state) {
    if (state.status == PhoneVerificationStatus.verified) {
      showDialog(
        context: context,
        builder: (context) => const OtpSuccessDialog(),
        useRootNavigator: false,
      );
    }
  }

  void _handleErrors(BuildContext context, PhoneVerificationState state) {
    final errors = Translations.of(context).auth.errors;
    late String errorMessage;
    switch (state.error) {
      case null:
        return;
      case PhoneVerificationError.codeNotSent:
        errorMessage = errors.smsCodeNotSent;
        break;
      case PhoneVerificationError.invalidCode:
        errorMessage = errors.invalidSmsCode;
        break;
      case PhoneVerificationError.unknown:
        errorMessage = errors.unknown;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errorMessage),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PhoneVerificationBloc, PhoneVerificationState>(
      listener: _onPhoneVerificationStateChanged,
      child: const _Page(),
    );
  }
}

class _Page extends StatefulWidget {
  const _Page({
    Key? key,
  }) : super(key: key);

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  String smsCode = '';

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: PageAppBar(title: t.auth.verifyPhonePage.title),
      body: AuthLayout(
        title: Text(t.auth.verifyPhonePage.enterCode),
        subtitle: Column(
          children: [
            Text(t.auth.verifyPhonePage.enterCodeSubtitle),
            Text(
              context.watch<PhoneVerificationBloc>().state.phoneNumber,
              style: TextStyle(color: context.theme.secondaryColor),
              textDirection: TextDirection.ltr,
            )
          ],
        ),
        header: const SizedBox(),
        form: [
          VerificationCode(
            onChanged: (code) {
              smsCode = code;
            },
          ),
        ],
        actionText: t.auth.verifyPhonePage.verifyButton,
        onAction: () {
          context.read<PhoneVerificationBloc>().add(VerifyPhoneNumber(smsCode));
        },
        isLoading: () {
          final status = context.watch<PhoneVerificationBloc>().state.status;
          return status == PhoneVerificationStatus.sendingCode ||
              status == PhoneVerificationStatus.verifying;
        }(),
        bottom: Row(
          children: [
            Text(t.auth.verifyPhonePage.noCodeMessage),
            TextButton(
              child: Text(t.auth.verifyPhonePage.resendCode),
              onPressed: () {
                final bloc = context.read<PhoneVerificationBloc>();
                bloc.add(SendSms(bloc.state.phoneNumber, resend: true));
              },
            )
          ],
        ),
      ),
    );
  }
}
