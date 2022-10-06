import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart' as fire_auth show User;
import 'package:foodo_provider/models/user.dart';
import 'package:foodo_provider/services/auth/credentials.dart';
import 'package:foodo_provider/services/auth/phone_verification.dart';
import 'package:foodo_provider/utils/generator.dart';

enum AuthError {
  unknown,
  invalidRegistrationState,
  invalidSmsCode,
  accountAlreadyInUse,
  userNotFound,
  userDisabled,
  operationNotAllowed,
  wrongPassword,
  weakPassword,
  invalidEmail
}

extension AuthErrorFromFirebaseException on FirebaseAuthException {
  AuthError? get asAuthError {
    switch (code) {
      case "account-exists-with-different-credential":
      case "user-mismatch":
      case "credential-already-in-use":
      case 'email-already-in-use':
        return AuthError.accountAlreadyInUse;
      case "user-not-found":
        return AuthError.userNotFound;
      case "user-disabled":
        return AuthError.userDisabled;
      case "invalid-verification-code":
        return AuthError.invalidSmsCode;
      case "wrong-password":
        return AuthError.wrongPassword;
      case "weak-password":
        return AuthError.weakPassword;
      case "invalid-email":
        return AuthError.invalidEmail;
      case 'provider-already-linked':
      case "operation-not-allowed":
      case "invalid-credential":
      case "invalid-verification-id":
      default:
        return null;
    }
  }
}

enum SettingsError {
  errorSettingLanguage,
  errorSettingToken,
}

enum AuthState {
  authenticated,
  unauthenticated,
}

enum RegistrationState {
  /// The credentials aren't associated with a single user.
  cannotRegister,

  /// The credentials aren't associated with any user.
  canRegister,

  /// The credentials are associated with a single user.
  alreadyRegistered,
}

abstract class AuthRepository {
  User? get user;
  String? get displayImage;
  Stream<String?> get displayImageStream;

  Future<bool> isLoggedIn();
  Future<RegistrationState> getRegistrationState(Credentials credentials);
  Future<void> signOut();
  Future<User> signIn(Credentials credentials);
  Future<User> signUp(String name, Credentials credentials);
  Future<void> updateUserBasicInfo(String name);
  Future<void> updateUserDisplayImage(String imageUrl);
  Stream<AuthState> observeAuthState();
  Future<void> updatePhoneNumber(PhoneCredentials credentials);
  Future<void> setUserLanguage(String language);
  Future<void> setUserInformation(String language, String token);
}

class FirebaseAuthRepository implements AuthRepository {
  final UserRole role;

  final auth = FirebaseAuth.instance;
  final _ref = FirebaseFirestore.instance.collection('users');

  // although documentation warns of using currentUser directly according to
  // implementation it's mostly safe.
  // only time when this might give wrong result is if a server side change
  // occurred like email verification, but our use of the currentUser instance
  // is for basic info only.
  @override
  User? get user {
    return _toUser(auth.currentUser);
  }

  @override
  String? get displayImage {
    return auth.currentUser?.photoURL;
  }

  // get stream of user changes
  @override
  Stream<String?> get displayImageStream {
    return auth.userChanges().map((user) => user?.photoURL);
  }

  FirebaseAuthRepository({required this.role});

  User? _toUser(fire_auth.User? fireUser) {
    return fireUser == null
        ? null
        : User(
            id: fireUser.uid,
            name: fireUser.displayName ?? '',
            phoneNumber: fireUser.phoneNumber ?? '',
            email: fireUser.email ?? '',
            role: role,
          );
  }

  @override
  isLoggedIn() async {
    return auth.currentUser != null;
  }

  @override
  getRegistrationState(credentials) async {
    if (credentials is MultiProviderCredentials) {
      var firstUser = await _userByCredentials(credentials.credentials.first);
      for (final creds in credentials.credentials.skip(1)) {
        final user = await _userByCredentials(creds);
        if (user?.id != firstUser?.id) {
          return RegistrationState.cannotRegister;
        }
      }
      return firstUser != null
          ? RegistrationState.alreadyRegistered
          : RegistrationState.canRegister;
    } else {
      final userDoc = await _userByCredentials(credentials);
      return userDoc != null
          ? RegistrationState.alreadyRegistered
          : RegistrationState.canRegister;
    }
  }

  @override
  signOut() async {
    await auth.signOut();
  }

  @override
  signIn(Credentials credentials) async {
    final state = await getRegistrationState(credentials);
    if (state != RegistrationState.alreadyRegistered) {
      throw AuthError.invalidRegistrationState;
    }
    return await _performSignIn(credentials, null);
  }

  @override
  signUp(String name, Credentials credentials) async {
    final state = await getRegistrationState(credentials);
    if (state != RegistrationState.canRegister) {
      throw AuthError.invalidRegistrationState;
    }
    return await _performSignIn(
      credentials,
      () => _handleRegistration(name, credentials),
    );
  }

  Future<void> _handleRegistration(String name, Credentials credentials) async {
    await _updateAuthProfile(name);
    await _ref.doc(user!.id).set(user!.toJson());
  }

  Future<User> _performSignIn(
    Credentials credentials,
    Future<void> Function()? afterSignIn,
  ) async {
    try {
      if (credentials is MultiProviderCredentials) {
        await _multiProviderSignIn(credentials);
      } else {
        await _signIn(credentials as FirebaseCredentials);
      }
      await afterSignIn?.call();

      // when user sing with email it doens't have displayName and phoneNumber
      // because it got saved when user signed up for first time
      // and since driver app doesn't have signup, it will be null
      // so we need to update them manually when user sign in
      // and only if role is driver
      if (role == UserRole.customer) {
        await _updateUserBasicInfoFromCollection();
      }

      return _toUser(auth.currentUser)!;
    } catch (e) {
      await auth.signOut();
      if (e is FirebaseAuthException) {
        throw e.asAuthError ?? e;
      }
      rethrow;
    }
  }

  // update user info from collection
  // function name: updateUserInfoFromCollection
  Future<void> _updateUserBasicInfoFromCollection() async {
    if (user == null) {
      return;
    }

    final userDoc = await _ref.doc(user!.id).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      await auth.currentUser!.updateDisplayName(userData?['name'] ?? '');
    }
  }

  Future<void> _signIn(FirebaseCredentials creds) async {
    if (creds is FirebaseEmailAndPasswordCredentials) {
      await _emailSignIn(creds);
    } else {
      await auth.signInWithCredential(creds.internal);
    }
  }

  Future<void> _multiProviderSignIn(MultiProviderCredentials creds) async {
    await _signIn(creds.credentials.first as FirebaseCredentials);
    for (final credentials in creds.credentials.skip(1)) {
      try {
        await auth.currentUser!
            .linkWithCredential((credentials as FirebaseCredentials).internal);
      } on FirebaseAuthException catch (e) {
        if (e.code != "provider-already-linked") {
          rethrow;
        }

        auth.currentUser!.reauthenticateWithCredential(
            (credentials as FirebaseCredentials).internal);
      }
    }
  }

  Future<UserCredential> _emailSignIn(
      FirebaseEmailAndPasswordCredentials emailCreds) async {
    try {
      return await auth.signInWithCredential(emailCreds.internal);
    } on FirebaseAuthException catch (e) {
      if (e.code != "user-not-found") {
        rethrow;
      }
      return await auth.createUserWithEmailAndPassword(
          email: emailCreds.email, password: emailCreds.password);
    }
  }

  @override
  updateUserBasicInfo(name) async {
    await auth.currentUser!.updateDisplayName(name);
    await _ref.doc(user!.id).update(user!.toJson());
  }

  @override
  Future<void> updateUserDisplayImage(String imageUrl) async {
    await auth.currentUser!.updatePhotoURL(imageUrl);
  }

  Future<void> _updateAuthProfile(String? name) async {
    await auth.currentUser!.updateDisplayName(name);
  }

  @override
  updatePhoneNumber(PhoneCredentials credentials) async {
    final creds = (credentials as FirebasePhoneCredentials).internal;
    try {
      await auth.currentUser!.updatePhoneNumber(creds);
    } on FirebaseAuthException catch (e) {
      throw e.asAuthError ?? e;
    }
    await _ref.doc(user!.id).update({'phoneNumber': user!.phoneNumber});
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _userByCredentials(
      Credentials credentials) {
    if (credentials is FirebasePhoneCredentials) {
      return _userByPhoneNumber(credentials.phoneNumber);
    } else if (credentials is FirebaseEmailAndPasswordCredentials) {
      return _userByEmail(credentials.email);
    } else if (credentials is MultiProviderCredentials) {
      return _userByMultipleProviders(credentials);
    }
    throw 'not reachable';
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _userByMultipleProviders(
      MultiProviderCredentials credentials) async {
    var query = _ref.limit(1);
    for (final creds in credentials.credentials) {
      if (creds is FirebasePhoneCredentials) {
        query = query.where('phoneNumber', isEqualTo: creds.phoneNumber);
      } else if (creds is FirebaseEmailAndPasswordCredentials) {
        query = query.where('email', isEqualTo: creds.email);
      }
    }
    final result = await query.get();
    return result.size == 0 ? null : result.docs.first;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _userByPhoneNumber(
      String phoneNumber) async {
    final result =
        await _ref.where('phoneNumber', isEqualTo: phoneNumber).limit(1).get();
    return result.size == 0 ? null : result.docs.first;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _userByEmail(
      String email) async {
    final result = await _ref.where('email', isEqualTo: email).limit(1).get();
    return result.size == 0 ? null : result.docs.first;
  }

  @override
  Stream<AuthState> observeAuthState() {
    return auth.authStateChanges().map(
          (user) => user != null
              ? AuthState.authenticated
              : AuthState.unauthenticated,
        );
  }

  @override
  Future<void> setUserLanguage(String language) async {
    if (auth.currentUser != null) {
      await _ref
          .doc(auth.currentUser!.uid)
          .collection('private')
          .doc('settings')
          .set({
        'language': language,
      });
    } else {
      throw SettingsError.errorSettingLanguage;
    }
  }

  @override
  Future<void> setUserInformation(String language, String token) async {
    if (auth.currentUser != null) {
      await _ref
          .doc(auth.currentUser!.uid)
          .collection('private')
          .doc('settings')
          .set({
        'language': language,
      });

      await _ref
          .doc(auth.currentUser!.uid)
          .collection('private')
          .doc('notifications')
          .set(
        {
          'donorPnsTokens': FieldValue.arrayUnion(
            [token],
          ),
        },
        SetOptions(merge: true),
      );
    } else {
      throw SettingsError.errorSettingLanguage;
    }
  }
}

class MockAuthRepository implements AuthRepository {
  final UserRole role;

  MockAuthRepository(this.role);

  @override
  Future<bool> isLoggedIn() async {
    return user != null;
  }

  @override
  signIn(Credentials credentials) async {
    return _user = User(
      id: generator.id(),
      name: generator.userName(),
      phoneNumber: '+249123456789',
      email: 'user@mail.com',
      role: role,
    );
  }

  @override
  signUp(String name, Credentials credentials) async {
    return _user = User(
      id: generator.id(),
      name: name,
      phoneNumber: '+249123456789',
      email: 'user@mail.com',
      role: role,
    );
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }

  @override
  Future<void> updateUserBasicInfo(name) async {
    _user = _user!.copyWith(name: name);
  }

  @override
  getRegistrationState(credentials) {
    return Future.delayed(
      const Duration(seconds: 2),
      () => RegistrationState.canRegister,
    );
  }

  @override
  User? get user => _user;

  late User? _user = User(
      id: generator.id(),
      name: generator.userName(),
      role: role,
      phoneNumber: '+249123456789',
      email: 'user@mail.com');

  @override
  Future<void> updatePhoneNumber(Credentials creds) async {
    _user = User(
      id: _user!.id,
      name: _user!.name,
      phoneNumber: (creds as MockPhoneCredentials).phoneNumber,
      email: _user!.email,
      role: role,
    );
  }

  @override
  Stream<AuthState> observeAuthState() async* {
    yield AuthState.unauthenticated;
    await Future.delayed(const Duration(seconds: 2));
    yield AuthState.authenticated;
  }

  @override
  Future<void> setUserLanguage(String language) async {}

  @override
  Future<void> setUserInformation(String language, String token) async {}

  @override
  Future<void> updateUserDisplayImage(String imageUrl) {
    // TODO: implement updateUserDisplayImage
    throw UnimplementedError();
  }

  @override
  // TODO: implement displayImage
  String? get displayImage => throw UnimplementedError();

  @override
  // TODO: implement userStream
  Stream<String?> get displayImageStream => throw UnimplementedError();
}
