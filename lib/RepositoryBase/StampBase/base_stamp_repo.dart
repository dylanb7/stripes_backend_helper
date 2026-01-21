import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';

import 'stamp.dart';

abstract class StampRepo<T extends Stamp> {
  final AuthUser authUser;
  final SubUser currentUser;
  final QuestionRepo questionRepo;
  DateTime? earliest;
  StampRepo(
      {required this.authUser,
      required this.currentUser,
      required this.questionRepo,
      this.earliest});
  Stream<List<T>> get stamps;
  Future<RepoResult<T?>> addStamp(T stamp);
  Future<RepoResult<void>> removeStamp(T stamp);
  Future<RepoResult<T?>> updateStamp(T stamp);
  Future<void> refresh();
  Future<void> refreshCheckins({Iterable<String>? types});

  set earliestDate(DateTime time) => earliest = time;
}

mixin BaselineMixin<T extends Stamp> on StampRepo<T> {
  Stream<List<T>> get baselines;
  Future<void> refreshBaselines({Iterable<String>? types});
}
