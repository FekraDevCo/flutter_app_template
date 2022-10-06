import 'dart:async';

import 'package:foodo_provider/blocs/auth/phone_verification_bloc.dart';
import 'package:foodo_provider/models/user.dart';
import 'package:foodo_provider/repositories/auth.dart';
import 'package:foodo_provider/services/auth/credentials.dart';
import 'package:foodo_provider/services/auth/email_auth_provider.dart';
import 'package:foodo_provider/services/auth/phone_verification.dart';
import 'package:foodo_provider/utils/api_caller.dart';
import 'package:foodo_provider/utils/bloc.dart';
import 'package:foodo_provider/utils/service_locator.dart';
import 'package:foodo_provider/utils/validators.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_bloc.freezed.dart';

enum LoginStatus {
  phoneRequired,
  verificationRequired,
  loading,
  success,
  error,
}

@freezed
class LoginState with _$LoginState {
  factory LoginState(
    LoginStatus status, {
    required User? user,
    required String phoneNumber,
    LoginError? error,
  }) = _LoginState;
}

enum LoginError {
  invalidPhoneNumber,
  invalidSmsCode,
  userNotRegistered,
  unknown,
}

extension AuthToLoginError on AuthError? {
  LoginError get asLoginError {
    switch (this) {
      case null:
      case AuthError.unknown:
      case AuthError.accountAlreadyInUse:
      case AuthError.operationNotAllowed:
      case AuthError.weakPassword:
      case AuthError.invalidEmail:
      case AuthError.wrongPassword:
        return LoginError.unknown;
      case AuthError.invalidRegistrationState:
      case AuthError.userNotFound:
      case AuthError.userDisabled:
        return LoginError.userNotRegistered;
      case AuthError.invalidSmsCode:
        return LoginError.invalidSmsCode;
    }
  }
}

class InputForm extends BlocEvent<LoginState, LoginBloc> {
  final bool dryRun;
  final String phoneNumber;

  InputForm(
    this.phoneNumber, {
    this.dryRun = false,
  });

  @override
  toState(current, bloc) async* {
    yield current = current.copyWith(status: LoginStatus.phoneRequired);

    final error = PhoneNumber.validate(phoneNumber);
    if (error == PhoneNumberError.invalid) {
      yield current.copyWith(
          error: LoginError.invalidPhoneNumber, phoneNumber: phoneNumber);
    } else if (dryRun) {
      yield current.copyWith(phoneNumber: phoneNumber, error: null);
    } else {
      yield* _proceed(current, bloc);
    }
  }

  Stream<LoginState> _proceed(LoginState current, LoginBloc bloc) async* {
    yield current = current.copyWith(status: LoginStatus.loading);

    final credentials =
        bloc.phoneAuthProvider.credentials(phoneNumber, null, null);

    final res = await bloc.caller<RegistrationState, AuthError>(
      () => bloc.auth.getRegistrationState(credentials),
    );

    yield current = res.incase(
      value: (state) {
        return state == RegistrationState.alreadyRegistered
            ? current.copyWith(
                status: LoginStatus.verificationRequired,
                phoneNumber: phoneNumber,
              )
            : current.copyWith(
                status: LoginStatus.phoneRequired,
                error: LoginError.userNotRegistered,
              );
      },
      error: (e) => current.copyWith(
        status: LoginStatus.phoneRequired,
        error: e.asLoginError,
      ),
    );
  }
}

class _PerformLogin extends BlocEvent<LoginState, LoginBloc> {
  final PhoneCredentials phoneCredentials;

  _PerformLogin(this.phoneCredentials);

  @override
  toState(current, bloc) async* {
    final initialStatus = current.status;

    yield current = current.copyWith(
        status: LoginStatus.loading, phoneNumber: phoneCredentials.phoneNumber);

    final res = await bloc
        .caller<User, AuthError>(() => bloc.auth.signIn(phoneCredentials));

    yield res.incase(
      value: (user) =>
          current.copyWith(status: LoginStatus.success, user: user),
      error: (e) => current.copyWith(
        status: initialStatus,
        error: e.asLoginError,
      ),
    );
  }
}

class LoginBloc extends BaseBloc<LoginState> {
  LoginBloc(PhoneVerificationBloc verificationBloc)
      : super(LoginState(
          LoginStatus.phoneRequired,
          phoneNumber: '',
          user: null,
        )) {
    _sub = verificationBloc.stream.listen((state) {
      if (state.status == PhoneVerificationStatus.credentialsObtained) {
        add(_PerformLogin(state.credentials!));
      }
    });

    _selfSub = stream.listen((state) {
      if (state.error == LoginError.invalidSmsCode) {
        verificationBloc
            .add(CredentialsError(PhoneVerificationError.invalidCode));
      } else if (state.status == LoginStatus.loading) {
        verificationBloc.add(
          UpdateVerificationStatus(PhoneVerificationStatus.verifying),
        );
      } else if (state.status == LoginStatus.success) {
        verificationBloc.add(
          UpdateVerificationStatus(PhoneVerificationStatus.verified),
        );
      }
    });
  }

  final caller = serviceLocator<ApiCaller>();
  final auth = serviceLocator<AuthRepository>();
  final phoneAuthProvider = serviceLocator<PhoneVerificationService>();
  final emailAuthProvider = serviceLocator<EmailAuthProvider>();

  late final StreamSubscription<PhoneVerificationState> _sub;
  late final StreamSubscription<LoginState> _selfSub;

  @override
  Future<void> close() {
    _selfSub.cancel();
    _sub.cancel();
    return super.close();
  }
}
