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

  /// Read persisted local entries for this profile, independent of the visible
  /// history window. Wait for local storage readiness, never for cloud sync.
  Future<List<Entry>> findByIds(Iterable<String> ids);

  /// Publish the current local history without waiting for cloud sync.
  Future<void> refreshLocal();
  Future<void> refresh();
  set earliestDate(DateTime time) => earliest = time;
}
