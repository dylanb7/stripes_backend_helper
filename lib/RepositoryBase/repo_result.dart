enum FailureType { network, storage, authentication, validation, sync, unknown }

sealed class RepoResult<T> {
  const RepoResult();
}

class Success<T> extends RepoResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends RepoResult<T> {
  final String message;
  final FailureType type;
  final dynamic error;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.type = FailureType.unknown,
    this.error,
    this.stackTrace,
  });
}
