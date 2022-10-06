import 'package:foodo_provider/translation/translations.g.dart';

class ArabicPluralResolver {
  void setup() {
    LocaleSettings.setPluralResolver(
      language: 'ar',
      cardinalResolver: (num n,
          {String? zero,
          String? one,
          String? two,
          String? few,
          String? many,
          String? other}) {
        if (n == 0) {
          return zero ?? other!;
        }
        if (n == 1) {
          return one ?? other!;
        }
        if (n == 2) {
          return two ?? other!;
        }
        if (n > 2 && n < 11) {
          return few ?? other!;
        }
        return other!;
      },
    );
  }
}
