# Flutter app template

A flutter app project that's used as a template for future projects.
It contains several features configures:
- State management using bloc
- Dependency injection using get_it
- Arabic/English localization
- User authentication with phone number using firebase authentication
- App structure is ready

flutter version : 3.3.0

## How to run

- flutter pub get
- flutter pub run build_runner build
- flutter run
- To use authentication :
    - cd android
    - ./gradlew signingReport
    - copy the SHA256 token from the debug
    - paste it in the fingerprint section in the firebase project general settings
    
## Test user :

name: Alzobair
phone: +249100640514
otp key: 000000

## Packages used:

- [flutter_bloc](https://pub.dev/packages/flutter_bloc) used for state managements.
- [get_it](https://pub.dev/packages/get_it) used for dependency injection.
- [fast_i18n](https://pub.dev/packages/fast_i18n) used for localization of the app.
- [firebase auth](https://pub.dev/packages/firebase_auth) used to authenticate users.
- [cloud_firestore](https://pub.dev/packages/cloud_firestore) used as a database.
- [freezed](https://pub.dev/packages/freezed) used with build_runner to generate models.
- [build_runner](https://pub.dev/packages/build_runner) used with freezed to generate models.
