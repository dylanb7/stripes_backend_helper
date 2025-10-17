import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
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
  Future<bool> addStamp(T stamp);
  Future<bool> removeStamp(T stamp);
  Future<bool> updateStamp(T stamp);
  Future<void> refresh();
  Future<bool> load();

  set earliestDate(DateTime time) => earliest = time;
}
