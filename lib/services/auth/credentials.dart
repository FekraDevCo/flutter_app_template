import 'package:firebase_auth/firebase_auth.dart';

abstract class Credentials {
  Credentials();
}

abstract class FirebaseCredentials implements Credentials {
  AuthCredential get internal;
}

abstract class PhoneCredentials implements Credentials {
  String get phoneNumber;
  String get smsCode;
}

abstract class EmailAndPasswordCredentials implements Credentials {
  String get email;
  String get password;
}

class FirebasePhoneCredentials
    implements PhoneCredentials, FirebaseCredentials {
  @override
  final String phoneNumber;

  @override
  final String smsCode;

  @override
  final PhoneAuthCredential internal;

  final String verificationId;

  FirebasePhoneCredentials(this.phoneNumber, this.internal)
      : verificationId = internal.verificationId!,
        smsCode = internal.smsCode!;

  FirebasePhoneCredentials.raw(
      this.phoneNumber, this.verificationId, this.smsCode)
      : internal = PhoneAuthProvider.credential(
            verificationId: verificationId, smsCode: smsCode);
}

class FirebaseEmailAndPasswordCredentials
    implements EmailAndPasswordCredentials, FirebaseCredentials {
  @override
  final String email;

  @override
  final String password;

  @override
  final EmailAuthCredential internal;

  FirebaseEmailAndPasswordCredentials(this.internal)
      : email = internal.email,
        password = internal.password!;

  FirebaseEmailAndPasswordCredentials.raw(this.email, this.password)
      : internal =
            EmailAuthProvider.credential(email: email, password: password)
                as EmailAuthCredential;
}

class MultiProviderCredentials extends Credentials {
  final List<Credentials> credentials;

  MultiProviderCredentials(this.credentials);
}
