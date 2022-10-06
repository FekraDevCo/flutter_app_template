import 'package:flutter/material.dart';
import 'package:foodo_provider/translation/translations.dart';
import 'package:foodo_provider/ui/pages/auth/route.dart';

class OtpSuccessDialog extends StatefulWidget {
  const OtpSuccessDialog({Key? key}) : super(key: key);

  @override
  State<OtpSuccessDialog> createState() => _OtpSuccessDialogState();
}

class _OtpSuccessDialogState extends State<OtpSuccessDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        AuthFlow.exitFlow(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 64.0,
              horizontal: 64.0,
            ),
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(38.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 64.0),
                Text(
                  t.otpSuccessDialog.message,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
