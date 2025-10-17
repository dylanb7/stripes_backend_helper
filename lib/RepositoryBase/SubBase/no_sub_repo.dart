import 'package:stripes_backend_helper/RepositoryBase/SubBase/base_sub_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';

class NoSubRepo extends SubUserRepo {
  NoSubRepo({required super.authUser});

  @override
  Future<bool> addSubUser(SubUser user) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteSubUser(SubUser user) {
    throw UnimplementedError();
  }

  @override
  Future<bool> updateSubUser(SubUser user) {
    throw UnimplementedError();
  }

  @override
  Stream<List<SubUser>> get users => Stream.value([SubUser.marker()]);

  @override
  Future<void> refresh() {
    // TODO: implement refresh
    throw UnimplementedError();
  }

  @override
  Future<bool> load() async {
    return true;
  }
}
