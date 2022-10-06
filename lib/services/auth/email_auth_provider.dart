import 'package:foodo_provider/services/auth/credentials.dart';

abstract class EmailAuthProvider {
  EmailAndPasswordCredentials credentials(String email, String password);
}

class FirebaseEmailAuthProvider implements EmailAuthProvider {
  @override
  EmailAndPasswordCredentials credentials(String email, String password) {
    return FirebaseEmailAndPasswordCredentials.raw(email, password);
  }
}
