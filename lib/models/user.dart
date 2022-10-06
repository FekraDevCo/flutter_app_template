import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole {
  customer,
  restaurant,
}

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String phoneNumber,
    required String email,
    required UserRole role,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
