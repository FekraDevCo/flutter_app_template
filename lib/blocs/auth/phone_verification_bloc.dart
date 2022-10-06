import 'package:foodo_provider/repositories/auth.dart';
import 'package:foodo_provider/services/auth/credentials.dart';
import 'package:foodo_provider/services/auth/phone_verification.dart';
import 'package:foodo_provider/utils/api_caller.dart';
import 'package:foodo_provider/utils/bloc.dart';
import 'package:foodo_provider/utils/result.dart';
import 'package:foodo_provider/utils/service_locator.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'phone_verification_bloc.freezed.dart';

enum PhoneVerificationStatus {
  initial,
  sendingCode,
  codeSent,
  credentialsObtained,
  verifying,
  verified,
}

enum PhoneVerificationError {
  codeNotSent,
  invalidCode,
  unknown,
}

@freezed
class PhoneVerificationState with _$PhoneVerificationState {
  factory PhoneVerificationState(
    PhoneVerificationStatus status, {
    required String phoneNumber,
    required String smsCode,
    required String verificationId,
    PhoneCredentials? credentials,
    PhoneVerificationError? error,
  }) = _PhoneVerificationState;
}

class SendSms extends BlocEvent<PhoneVerificationState, PhoneVerificationBloc> {
  final String phoneNumber;
  final bool resend;

  SendSms(this.phoneNumber, {this.resend = false});

  @override
  toState(current, bloc) async* {
    yield current = current.copyWith(
        status: PhoneVerificationStatus.sendingCode, phoneNumber: phoneNumber);

    final res = await bloc.caller<String, VerificationError>(
        () => bloc.verify.sendVerificationCode(phoneNumber, force: resend));

    yield current = res.incase(
      value: (verificationId) {
        bloc
            .caller<PhoneCredentials, VerificationError>(
                () => bloc.verify.whenCodeRecieved(current.verificationId))
            .then((res) {
          bloc.add(_AutoVerificationResult(res));
        });

        return current.copyWith(
            status: PhoneVerificationStatus.codeSent,
            verificationId: verificationId);
      },
      error: (e) => current.copyWith(
          status: PhoneVerificationStatus.initial,
          error: PhoneVerificationError.codeNotSent),
    );
  }
}

class VerifyPhoneNumber
    extends BlocEvent<PhoneVerificationState, PhoneVerificationBloc> {
  final String smsCode;

  VerifyPhoneNumber(this.smsCode);

  @override
  toState(current, bloc) async* {
    final credentials = bloc.verify
        .credentials(current.phoneNumber, current.verificationId, smsCode);

    yield current = current.copyWith(
        status: PhoneVerificationStatus.credentialsObtained,
        credentials: credentials);
  }
}

class _AutoVerificationResult
    extends BlocEvent<PhoneVerificationState, PhoneVerificationBloc> {
  _AutoVerificationResult(this.result);

  final Result<PhoneCredentials, VerificationError?> result;

  @override
  toState(current, bloc) async* {
    yield result.incase(
      value: (credentials) => current.copyWith(
        status: PhoneVerificationStatus.credentialsObtained,
        credentials: credentials,
      ),
      // silently ignore auto verification timeout error
      error: (e) => current,
    );
  }
}

/// use to update the phone verification status to:
/// - [PhoneVerificationStatus.verifying] when the operation of verifying is in
/// progress.
/// - [PhoneVerificationStatus.verified] when the operation has completed
class UpdateVerificationStatus
    extends BlocEvent<PhoneVerificationState, PhoneVerificationBloc> {
  final PhoneVerificationStatus status;

  UpdateVerificationStatus(this.status);

  @override
  toState(current, bloc) async* {
    yield current.copyWith(status: status);
  }
}

class CredentialsError
    extends BlocEvent<PhoneVerificationState, PhoneVerificationBloc> {
  CredentialsError(this.error);

  final PhoneVerificationError error;

  @override
  toState(current, bloc) async* {
    yield current.copyWith(
      status: PhoneVerificationStatus.codeSent,
      error: error,
    );
  }
}

class PhoneVerificationBloc extends BaseBloc<PhoneVerificationState> {
  PhoneVerificationBloc()
      : super(PhoneVerificationState(PhoneVerificationStatus.initial,
            phoneNumber: '', smsCode: '', verificationId: ''));

  final caller = serviceLocator<ApiCaller>();
  final auth = serviceLocator<AuthRepository>();
  final verify = serviceLocator<PhoneVerificationService>();
}
