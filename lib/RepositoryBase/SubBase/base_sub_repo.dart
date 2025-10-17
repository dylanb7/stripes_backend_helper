import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';

abstract class SubUserRepo {
  final AuthUser authUser;
  SubUserRepo({required this.authUser});
  Stream<List<SubUser>> get users;
  Future<bool> addSubUser(SubUser user);
  Future<bool> deleteSubUser(SubUser user);
  Future<bool> updateSubUser(SubUser user);
  Future<void> refresh();
  Future<bool> load();
}
