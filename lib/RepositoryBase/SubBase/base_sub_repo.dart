import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';

abstract class SubUserRepo {
  final AuthUser authUser;
  SubUserRepo({required this.authUser});
  Stream<List<SubUser>> get users;
  Future<RepoResult<SubUser?>> addSubUser(SubUser user);
  Future<RepoResult<void>> deleteSubUser(SubUser user);
  Future<RepoResult<SubUser?>> updateSubUser(SubUser user);
  Future<void> refresh();
}
