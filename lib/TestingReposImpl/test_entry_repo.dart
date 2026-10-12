import 'dart:async';

import 'package:rxdart/subjects.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/EntryBase/base_entry_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/EntryBase/entry.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';

/// In-memory implementation of [EntryRepo] for testing.
class TestEntryRepo extends EntryRepo {
  final List<Entry> _inMemoryEntries = [];
  final BehaviorSubject<List<Entry>> _controller = BehaviorSubject.seeded([]);

  TestEntryRepo(AuthUser user, SubUser subUser)
      : super(authUser: user, currentUser: subUser);

  void _emit() {
    // Sort entries by stamp descending
    final list = List<Entry>.from(_inMemoryEntries);
    list.sort((a, b) => b.stamp.compareTo(a.stamp));
    _controller.add(list);
  }

  @override
  Stream<List<Entry>> get entries => _controller.stream;

  @override
  Stream<List<Entry>> entriesBySubtype(String subtype) {
    return entries.map(
      (list) => list.where((e) => e.subtype == subtype).toList(),
    );
  }

  @override
  Stream<List<Entry>> entriesByCategory(InputCategory category) {
    return entries.map(
      (list) => list.where((e) => e.category == category).toList(),
    );
  }

  @override
  Future<RepoResult<Entry>> addEntry(Entry entry) async {
    _inMemoryEntries.add(entry);
    _emit();
    return Success(entry);
  }

  @override
  Future<RepoResult<Entry>> updateEntry(Entry entry) async {
    final idx = _inMemoryEntries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      _inMemoryEntries[idx] = entry;
      _emit();
      return Success(entry);
    }
    return const Failure(message: 'Entry not found');
  }

  @override
  Future<RepoResult<void>> removeEntry(String entryId) async {
    _inMemoryEntries.removeWhere((e) => e.id == entryId);
    _emit();
    return const Success(null);
  }

  @override
  Future<Entry?> findOne({required String subtype}) async {
    final sorted = List<Entry>.from(_inMemoryEntries)
      ..sort((a, b) => b.stamp.compareTo(a.stamp));
    for (final e in sorted) {
      if (e.subtype == subtype) return e;
    }
    return null;
  }

  @override
  Future<List<Entry>> findBySession(String sessionId) async {
    return _inMemoryEntries
        .where((e) => e.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.stamp.compareTo(b.stamp));
  }

  @override
  Future<void> refresh() async {}

  @override
  set earliestDate(DateTime time) {
    earliest = time;
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
