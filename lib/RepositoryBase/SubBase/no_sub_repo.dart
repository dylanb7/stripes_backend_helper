import 'package:stripes_backend_helper/RepositoryBase/SubBase/base_sub_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';

class NoSubRepo extends SubUserRepo {
  NoSubRepo({required super.authUser});

  @override
  Future<RepoResult<SubUser?>> addSubUser(SubUser user) {
    throw UnimplementedError();
  }

  @override
  Future<RepoResult<void>> deleteSubUser(SubUser user) {
    throw UnimplementedError();
  }

  @override
  Future<RepoResult<SubUser?>> updateSubUser(SubUser user) {
    throw UnimplementedError();
  }

  @override
  Stream<List<SubUser>> get users => Stream.value([SubUser.marker()]);

  @override
  Future<void> refresh() {
    // TODO: implement refresh
    throw UnimplementedError();
  }
}
