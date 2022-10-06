import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodo_provider/blocs/auth/phone_verification_bloc.dart';
import 'package:foodo_provider/translation/translations.g.dart';
import 'package:foodo_provider/ui/components/app_bar.dart';
import 'package:foodo_provider/ui/pages/auth/verify_phone/verify_phone_page.dart';
import 'package:foodo_provider/ui/theme/theme.dart';

import '../layout.dart';

class ConfirmPhonePage extends StatelessWidget {
  final String phoneNumber;
  final String title;

  const ConfirmPhonePage({
    Key? key,
    required this.title,
    required this.phoneNumber,
  }) : super(key: key);

  void _onConfirmed(BuildContext context) {
    final phoneVerificationBloc = context.read<PhoneVerificationBloc>();

    phoneVerificationBloc.add(SendSms(phoneNumber));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: phoneVerificationBloc,
          child: const VerifyPhonePage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: PageAppBar(
        title: title,
      ),
      body: AuthLayout(
        header: const SizedBox(),
        title: Text(t.auth.confirmPhonePage.title),
        subtitle: Text(t.auth.confirmPhonePage.subtitle),
        form: [
          _PhoneText(phoneNumber: phoneNumber),
        ],
        actionText: t.auth.confirmPhonePage.confirmButton,
        onAction: () => _onConfirmed(context),
      ),
    );
  }
}

class _PhoneText extends StatelessWidget {
  const _PhoneText({Key? key, required this.phoneNumber}) : super(key: key);

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.theme.hintColor)),
      ),
      child: Text(
        phoneNumber,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          color: context.theme.hintColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
