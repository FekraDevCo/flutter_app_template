import 'package:flutter/material.dart';
import 'package:foodo_provider/ui/theme/theme.dart';

class PageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PageAppBar({
    required this.title,
    Key? key,
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return AppBar(
      title: Text(title),
      primary: true,
      leadingWidth: 80.0,
      leading: canPop
          ? IconButton(
              icon: Center(
                child: Container(
                  constraints: BoxConstraints.tight(const Size.square(32.0)),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.theme.appBarColor,
                    ),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsetsDirectional.only(start: 6.0),
                  child: const Icon(Icons.arrow_back_ios, size: 14),
                ),
              ),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () {
                Navigator.maybePop(context);
              },
            )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
