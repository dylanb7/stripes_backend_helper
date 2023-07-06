import 'package:flutter/foundation.dart';

const String localAccessKey = 'LocalAccessKey';

abstract class AccessCodeRepo {
  String? currentCode;

  bool _isValid = false;
  Future<String?> workingCode(String code) async {
    currentCode = code;
    String? res = await codeValid(code);
    _isValid = res != null;
    return res;
  }

  @protected
  Future<String?> codeValid(String code);
  bool validState() => _isValid;
  Future<void> removeCode();
}
