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

part 'register_bloc.freezed.dart';

enum RegisterStatus {
  fieldsInputRequired,
  verificationRequired,
  loading,
  success,
  error,
}

@freezed
class RegisterState with _$RegisterState {
  factory RegisterState(
    RegisterStatus status, {
    required User? user,
    required String phoneNumber,
    required String username,
    RegisterError? error,
  }) = _RegisterState;
}

enum RegisterError {
  invalidPhoneNumber,
  emptyUsername,
  invalidSmsCode,
  userRegistered,
  unknown,
}

extension AuthToRegisterError on AuthError? {
  RegisterError get asRegisterError {
    switch (this) {
      case null:
      case AuthError.unknown:
      case AuthError.accountAlreadyInUse:
      case AuthError.operationNotAllowed:
      case AuthError.wrongPassword:
      case AuthError.weakPassword:
      case AuthError.invalidEmail:
        return RegisterError.unknown;
      case AuthError.invalidRegistrationState:
      case AuthError.userNotFound:
      case AuthError.userDisabled:
        return RegisterError.userRegistered;
      case AuthError.invalidSmsCode:
        return RegisterError.invalidSmsCode;
    }
  }
}

class InputForm extends BlocEvent<RegisterState, RegisterBloc> {
  final bool dryRun;
  final String phoneNumber;
  final String username;

  InputForm(
    this.phoneNumber,
    this.username, {
    this.dryRun = false,
  });

  @override
  toState(current, bloc) async* {
    yield current =
        current.copyWith(status: RegisterStatus.fieldsInputRequired);

    final error = _verifyInput();
    if (dryRun) {
      yield current.copyWith(
          phoneNumber: phoneNumber, username: username, error: null);
    } else if (error != null) {
      yield current.copyWith(
          phoneNumber: phoneNumber, username: username, error: error);
    } else {
      yield* _proceed(current, bloc);
    }
  }

  RegisterError? _verifyInput() {
    if (PhoneNumber.validate(phoneNumber) == PhoneNumberError.invalid) {
      return RegisterError.invalidPhoneNumber;
    } else if (Username.validate(username) == UsernameError.empty) {
      return RegisterError.emptyUsername;
    }

    return null;
  }

  Stream<RegisterState> _proceed(
      RegisterState current, RegisterBloc bloc) async* {
    yield current = current.copyWith(status: RegisterStatus.loading);

    final credentials =
        bloc.phoneAuthProvider.credentials(phoneNumber, null, null);

    final res = await bloc.caller<RegistrationState, AuthError>(
      () => bloc.auth.getRegistrationState(credentials),
    );

    yield current = res.incase(
      value: (state) {
        return state == RegistrationState.canRegister
            ? current.copyWith(
                status: RegisterStatus.verificationRequired,
                phoneNumber: phoneNumber,
                username: username,
              )
            : current.copyWith(
                status: RegisterStatus.fieldsInputRequired,
                error: RegisterError.userRegistered,
              );
      },
      error: (e) => current.copyWith(
        status: RegisterStatus.fieldsInputRequired,
        error: e.asRegisterError,
      ),
    );
  }
}

class _PerformRegister extends BlocEvent<RegisterState, RegisterBloc> {
  final PhoneCredentials phoneCredentials;

  _PerformRegister(this.phoneCredentials);

  @override
  toState(current, bloc) async* {
    yield current = current.copyWith(
        status: RegisterStatus.loading,
        phoneNumber: phoneCredentials.phoneNumber);

    final res = await bloc.caller<User, AuthError>(
      () => bloc.auth.signUp(current.username, phoneCredentials),
    );

    yield res.incase(
      value: (user) =>
          current.copyWith(status: RegisterStatus.success, user: user),
      error: (e) => current.copyWith(
          status: RegisterStatus.error, error: e.asRegisterError),
    );
  }
}

class RegisterBloc extends BaseBloc<RegisterState> {
  RegisterBloc(PhoneVerificationBloc verificationBloc)
      : super(RegisterState(
          RegisterStatus.fieldsInputRequired,
          username: '',
          phoneNumber: '',
          user: null,
        )) {
    _sub = verificationBloc.stream.listen((state) {
      if (state.status == PhoneVerificationStatus.credentialsObtained) {
        add(_PerformRegister(state.credentials!));
      }
    });

    _selfSub = stream.listen((state) {
      if (state.error == RegisterError.invalidSmsCode) {
        verificationBloc
            .add(CredentialsError(PhoneVerificationError.invalidCode));
      } else if (state.status == RegisterStatus.loading) {
        verificationBloc.add(
          UpdateVerificationStatus(PhoneVerificationStatus.verifying),
        );
      } else if (state.status == RegisterStatus.success) {
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
  late final StreamSubscription<RegisterState> _selfSub;

  @override
  Future<void> close() {
    _selfSub.cancel();
    _sub.cancel();
    return super.close();
  }
}
