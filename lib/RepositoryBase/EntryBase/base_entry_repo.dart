import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/EntryBase/entry.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';

abstract class EntryRepo {
  final AuthUser authUser;
  final SubUser currentUser;

  EntryRepo({required this.authUser, required this.currentUser});
  Stream<List<Entry>> get entries;
  Stream<List<Entry>> entriesBySubtype(String subtype);
  Stream<List<Entry>> entriesByCategory(InputCategory category);

  DateTime? earliest;

  Future<RepoResult<Entry>> addEntry(Entry entry);
  Future<RepoResult<Entry>> updateEntry(Entry entry);
  Future<RepoResult<void>> removeEntry(String entryId);
  Future<Entry?> findOne({required String subtype});
  Future<List<Entry>> findBySession(String sessionId);
  Future<void> refresh();
  set earliestDate(DateTime time) => earliest = time;
}
