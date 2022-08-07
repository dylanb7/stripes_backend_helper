import '../RepositoryBase/AccessBase/base_access_repo.dart';

class TestAccessRepo extends AccessCodeRepo {
  @override
  Future<String?> codeValid(String code) async {
    await Future.delayed(const Duration(seconds: 2));
    return 'valid';
  }

  @override
  Future<void> removeCode() async {
    print('$currentCode removed');
  }
}
