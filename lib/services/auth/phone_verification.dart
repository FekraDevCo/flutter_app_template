import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'credentials.dart';

enum VerificationError {
  unknown,
  autoRetrievalTimeout,
}

abstract class PhoneVerificationService {
  // when sms code is recieved this future completes with the phone credentials,
  // otherwise in case of timeout it will complete with a CodeRetrieval error
  Future<PhoneCredentials> whenCodeRecieved(String codeId);

  Future<String> sendVerificationCode(
    String phoneNumber, {
    bool force = false,
  });

  PhoneCredentials credentials(
      String phoneNumber, String? codeId, String? smsCode);
}

class FirebasePhoneVerificationService extends PhoneVerificationService {
  final _smsCodesRecievers = <String, Completer<PhoneCredentials>>{};
  // the verificationId provided by FirebaseAuth can be null in certain cases
  // thus we can't use it directly to identify the various sms codes, so this is
  // a map of a generated id to verificationId.
  final _verificationId = <String, String>{};
  final _forceResendingTokens = <String, int>{};

  @override
  PhoneCredentials credentials(phoneNumber, codeId, smsCode) {
    return FirebasePhoneCredentials.raw(
      phoneNumber,
      codeId != null ? _verificationId[codeId]! : '',
      smsCode ?? '',
    );
  }

  @override
  Future<PhoneCredentials> whenCodeRecieved(String codeId) {
    return _smsCodesRecievers[codeId]!.future;
  }

  @override
  Future<String> sendVerificationCode(
    String phoneNumber, {
    bool force = false,
  }) {
    final requestCompleter = Completer<String>();
    String? id;
    void completeRequest(String verificationId, [int? forceResendingToken]) {
      if (forceResendingToken != null) {
        _forceResendingTokens[phoneNumber] = forceResendingToken;
      }
      id = _nextId();
      _verificationId[id!] = verificationId;
      _smsCodesRecievers[id!] = Completer();
      requestCompleter.complete(id);
    }

    final forceToken = force ? null : _forceResendingToken(phoneNumber);
    FirebaseAuth.instance.verifyPhoneNumber(
      forceResendingToken: forceToken,
      phoneNumber: phoneNumber,
      verificationFailed: (exception) {
        requestCompleter.completeError(exception);
      },
      codeSent: (String verificationId, int? forceResendingToken) {
        completeRequest(verificationId, forceResendingToken);
      },
      verificationCompleted: (credential) {
        if (!requestCompleter.isCompleted) {
          completeRequest(credential.verificationId!);
        }
        _onVerified(phoneNumber, id!, credential);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!requestCompleter.isCompleted) {
          completeRequest(verificationId);
        }
        _onAutoRetrievalFailed(id!);
      },
    );
    return requestCompleter.future;
  }

  int? _forceResendingToken(String phoneNumber) {
    return _forceResendingTokens[phoneNumber];
  }

  void _onVerified(
      String phoneNumber, String codeId, PhoneAuthCredential credential) {
    _smsCodesRecievers[codeId]!
        .complete(FirebasePhoneCredentials(phoneNumber, credential));
  }

  void _onAutoRetrievalFailed(String codeId) {
    _smsCodesRecievers
        .remove(codeId)!
        .completeError(VerificationError.autoRetrievalTimeout);
  }

  static String _nextId() => (++_lastId).toString();
  static var _lastId = -1;
}

class MockPhoneVerificationService extends PhoneVerificationService {
  @override
  Future<PhoneCredentials> whenCodeRecieved(String codeId) {
    return Future.delayed(
        const Duration(seconds: 5),
        () =>
            MockPhoneCredentials('+249123456789', 'verificationId', 'smsCode'));
  }

  @override
  Future<String> sendVerificationCode(String phoneNumber,
      {bool force = false}) {
    return Future.delayed(const Duration(seconds: 3), () => 'codeId');
  }

  @override
  PhoneCredentials credentials(
      String phoneNumber, String? codeId, String? smsCode) {
    return MockPhoneCredentials('+249123456789', 'verificationId', 'smsCode');
  }
}

class MockPhoneCredentials implements PhoneCredentials {
  @override
  final String phoneNumber;
  final String verificationId;

  @override
  final String smsCode;

  MockPhoneCredentials(this.phoneNumber, this.verificationId, this.smsCode);
}
