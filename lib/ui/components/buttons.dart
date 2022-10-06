import 'package:foodo_provider/ui/components/progress_indicator.dart';
import 'package:foodo_provider/ui/theme/theme.dart';

import 'package:flutter/material.dart';

const kAppButtonHeight = 48.0;

class MainButton extends StatelessWidget {
  final String title;
  final Widget? icon;
  final void Function()? onPressed;
  final double? height;
  final double? width;
  final bool showShadow;
  final bool removePadding;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? shadowColor;
  final Color? progressIndicatorColor;

  const MainButton({
    Key? key,
    required this.title,
    this.icon,
    this.onPressed,
    this.height,
    this.width,
    this.showShadow = true,
    this.removePadding = false,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.shadowColor,
    this.progressIndicatorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? kAppButtonHeight,
      width: width,
      padding: removePadding
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(onPressed != null
              ? backgroundColor ?? context.theme.primaryColor
              : context.theme.hintColor),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          shadowColor: MaterialStateProperty.all(
              shadowColor ?? context.theme.primaryColor),
        ),
        onPressed: isLoading ? null : onPressed,
        child: Center(
          child: isLoading
              ? AppProgressIndicator(
                  size: 30,
                  color: progressIndicatorColor ?? context.theme.primaryColor,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 16),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor ?? context.theme.cardColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class MainFlatButton extends StatelessWidget {
  final String title;
  final void Function()? onPressed;
  final Widget? icon;
  final double? height;
  final double? width;
  final bool removePadding;
  final bool isLoading;
  final Color? textColor;
  final Color? borderColor;

  const MainFlatButton({
    Key? key,
    required this.title,
    this.onPressed,
    this.icon,
    this.height,
    this.width,
    this.removePadding = false,
    this.isLoading = false,
    this.textColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? kAppButtonHeight,
      width: width,
      padding: removePadding
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(context.theme.cardColor),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              side: BorderSide(
                color: borderColor ?? context.theme.primaryColor,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        onPressed: onPressed,
        child: isLoading
            ? AppProgressIndicator(
                size: 30,
                color: context.theme.primaryColor,
              )
            : Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 10),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor ?? context.theme.cardColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class MainIconButton extends StatelessWidget {
  final String title;
  final Widget icon;
  final Function()? onPressed;
  final double? height;
  final double? width;
  final bool removePadding;
  final bool isLoading;

  const MainIconButton({
    Key? key,
    required this.title,
    required this.icon,
    this.onPressed,
    this.height,
    this.width,
    this.removePadding = false,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? kAppButtonHeight,
      width: width,
      padding: removePadding
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              side: BorderSide(color: context.theme.inputBorderColor),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        onPressed: onPressed,
        child: Center(
          child: isLoading
              ? AppProgressIndicator(
                  size: 30,
                  color: context.theme.primaryColor,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        color: context.theme.titleColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
