import 'package:stripes_backend_helper/RepositoryBase/SubBase/base_sub_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';

class NoSubRepo extends SubUserRepo {
  NoSubRepo({required super.authUser});

  @override
  Future<void> addSubUser(SubUser user) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSubUser(SubUser user) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateSubUser(SubUser user) {
    throw UnimplementedError();
  }

  @override
  Stream<List<SubUser>> get users => Stream.value([SubUser.marker()]);
}
