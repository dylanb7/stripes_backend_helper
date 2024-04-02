import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:stripes_backend_helper/db_keys.dart';

@immutable
class AuthUser extends Equatable {
  final String uid;

  final Map<String, dynamic> attributes;

  const AuthUser({
    required this.uid,
    required this.attributes,
  });

  const AuthUser.uid({required this.uid}) : attributes = const {};

  const AuthUser.empty()
      : uid = '',
        attributes = const {};

  AuthUser.localCode(String code)
      : uid = code,
        attributes = {"local": code};

  factory AuthUser.from({required Map<String, dynamic> json}) =>
      AuthUser(uid: json[UID_FIELD], attributes: {...json}..remove(UID_FIELD));

  Map<String, dynamic> toJson() {
    return {UID_FIELD: uid, ...attributes};
  }

  static bool isEmpty(AuthUser user) => user.uid == '';

  static bool isLocalCode(AuthUser user) =>
      user.attributes['local'] == 'LocalCode';

  @override
  String toString() {
    return 'AuthUser($uid)';
  }

  @override
  List<Object?> get props => [uid, attributes];
}
