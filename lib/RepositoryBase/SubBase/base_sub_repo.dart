import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';

abstract class SubUserRepo {
  final AuthUser authUser;
  SubUserRepo({required this.authUser});
  Stream<List<SubUser>> get users;
  Future<void> addSubUser(SubUser user);
  Future<void> deleteSubUser(SubUser user);
  Future<void> updateSubUser(SubUser user);
}
