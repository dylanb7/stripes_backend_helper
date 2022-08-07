import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:stripes_backend_helper/db_keys.dart';

@immutable
class AuthUser extends Equatable {
  final String uid;
  final String? email;

  const AuthUser({
    required this.uid,
    this.email,
  });

  const AuthUser.empty()
      : uid = '',
        email = null;

  factory AuthUser.from({required Map<String, dynamic> json}) => AuthUser(
      uid: json[UID_FIELD],
      email: json.containsKey(EMAIL_FIELD) ? json[EMAIL_FIELD] : null);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {UID_FIELD: uid};
    if (email != null) {
      json[EMAIL_FIELD] = email;
    }
    return json;
  }

  static bool isEmpty(AuthUser user) => user.uid == '';

  @override
  String toString() {
    return 'AuthUser($uid)';
  }

  @override
  List<Object?> get props => [uid, email];
}
