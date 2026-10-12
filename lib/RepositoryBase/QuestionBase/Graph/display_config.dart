import 'package:flutter/foundation.dart' show immutable;


@immutable
class DisplayConfig {

  final String? displayKey;

  final Map<String, dynamic> params;

  const DisplayConfig({this.displayKey, this.params = const {}});
}


@immutable
class EntryConfig {

  final String? entryKey;

  final bool isSeparateScreen;

  final Map<String, dynamic> params;

  const EntryConfig({
    this.entryKey,
    this.isSeparateScreen = false,
    this.params = const {},
  });
}
