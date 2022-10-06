import 'dart:async';

import 'package:foodo_provider/services/auth/credentials.dart';
import 'package:foodo_provider/blocs/auth/phone_verification_bloc.dart';
import 'package:foodo_provider/repositories/auth.dart';
import 'package:foodo_provider/utils/api_caller.dart';
import 'package:foodo_provider/utils/bloc.dart';
import 'package:foodo_provider/utils/service_locator.dart';

enum ChangePhoneNumberError {
  invalidSmsCode,
  unknown,
}

extension AuthToChangePhoneNumberError on AuthError? {
  ChangePhoneNumberError get asLoginError {
    switch (this) {
      case null:
      case AuthError.unknown:
      case AuthError.accountAlreadyInUse:
      case AuthError.operationNotAllowed:
      case AuthError.invalidRegistrationState:
      case AuthError.userNotFound:
      case AuthError.userDisabled:
      case AuthError.wrongPassword:
      case AuthError.weakPassword:
      case AuthError.invalidEmail:
        return ChangePhoneNumberError.unknown;
      case AuthError.invalidSmsCode:
        return ChangePhoneNumberError.invalidSmsCode;
    }
  }
}

enum ChangePhoneNumberStatus {
  success,
  loading,
  error,
}

class ChangePhoneNumberState {
  final ChangePhoneNumberError? error;
  final ChangePhoneNumberStatus status;

  ChangePhoneNumberState({required this.status, this.error});
}

class _PerformChangePhoneNumber
    extends BlocEvent<ChangePhoneNumberState, ChangePhoneNumberBloc> {
  _PerformChangePhoneNumber(this.credentials);

  final PhoneCredentials credentials;

  @override
  toState(current, bloc) async* {
    yield current =
        ChangePhoneNumberState(status: ChangePhoneNumberStatus.loading);

    final res = await bloc._caller<void, AuthError>(
        () => bloc._auth.updatePhoneNumber(credentials));

    yield current = res.incase(
      value: (_) =>
          ChangePhoneNumberState(status: ChangePhoneNumberStatus.success),
      error: (e) {
        return ChangePhoneNumberState(
            status: ChangePhoneNumberStatus.error, error: e.asLoginError);
      },
    );
  }
}

class ChangePhoneNumberBloc extends BaseBloc<ChangePhoneNumberState> {
  final _caller = serviceLocator<ApiCaller>();
  final _auth = serviceLocator<AuthRepository>();

  late final StreamSubscription<PhoneVerificationState> _sub;
  late final StreamSubscription<ChangePhoneNumberState> _selfSub;

  final PhoneVerificationBloc verificationBloc;

  ChangePhoneNumberBloc(this.verificationBloc)
      : super(ChangePhoneNumberState(status: ChangePhoneNumberStatus.success)) {
    _sub = verificationBloc.stream.listen(_handleVerification);
    _selfSub = stream.listen(_syncVerificationState);
  }

  void _syncVerificationState(state) {
    if (state.error == ChangePhoneNumberError.invalidSmsCode) {
      verificationBloc
          .add(CredentialsError(PhoneVerificationError.invalidCode));
    } else if (state.error == ChangePhoneNumberError.unknown) {
      verificationBloc.add(CredentialsError(PhoneVerificationError.unknown));
    } else if (state.status == ChangePhoneNumberStatus.loading) {
      verificationBloc.add(
        UpdateVerificationStatus(PhoneVerificationStatus.verifying),
      );
    } else if (state.status == ChangePhoneNumberStatus.success) {
      verificationBloc.add(
        UpdateVerificationStatus(PhoneVerificationStatus.verified),
      );
    }
  }

  _handleVerification(PhoneVerificationState state) {
    if (state.status == PhoneVerificationStatus.credentialsObtained) {
      add(_PerformChangePhoneNumber(state.credentials!));
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    _selfSub.cancel();
    return super.close();
  }
}
