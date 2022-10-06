import 'package:flutter/material.dart';
import 'package:foodo_provider/ui/components/buttons.dart';
import 'package:foodo_provider/ui/components/progress_indicator.dart';
import 'package:foodo_provider/ui/theme/theme.dart';

const kSpaceAroundInputForm = 32.0;

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    Key? key,
    required this.header,
    required this.title,
    this.subtitle,
    required this.form,
    required this.actionText,
    this.isLoading = false,
    required this.onAction,
    this.bottom,
  }) : super(key: key);

  final Widget header;
  final Widget title;
  final Widget? subtitle;
  final List<Widget> form;
  final String actionText;
  final bool isLoading;
  final void Function() onAction;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            header,
            const SizedBox(height: 8.0),
            DefaultTextStyle.merge(
              child: title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8.0),
              SizedBox(
                width: 300.0,
                child: DefaultTextStyle.merge(
                    child: subtitle!,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.0,
                      color: context.theme.cardTextColor,
                    ),
                    textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: kSpaceAroundInputForm),
            Column(
                children: form
                    .map(
                      (inp) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: inp,
                      ),
                    )
                    .toList()),
            const SizedBox(height: kSpaceAroundInputForm),
            isLoading
                ? AppProgressIndicator(
                    color: context.theme.primaryColor,
                  )
                : MainButton(
                    title: actionText,
                    onPressed: onAction,
                  ),
            if (bottom != null) ...[
              const SizedBox(height: 12),
              bottom!,
            ]
          ],
        ),
      ),
    );
  }
}
