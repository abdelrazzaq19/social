import 'package:shared_preferences/shared_preferences.dart';

/// Local key/value storage for everything the app remembers between launches.
///
/// Keys are namespaced and versioned (`qs.v1.*`). When a future change makes
/// stored values unreadable, bump [_version] — [create] then drops every key
/// from an older namespace instead of handing the app data it cannot parse.
class PrefsService {
  PrefsService._(this._prefs);

  static const String _prefix = 'qs';
  static const int _version = 1;
  static const String _namespace = '$_prefix.v$_version.';

  final SharedPreferences _prefs;

  /// Opens storage and discards any keys left behind by an older version.
  static Future<PrefsService> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _discardStaleVersions(prefs);
    return PrefsService._(prefs);
  }

  /// Builds a service over an already-open [SharedPreferences], for tests.
  static PrefsService fromPreferences(SharedPreferences prefs) {
    return PrefsService._(prefs);
  }

  static Future<void> _discardStaleVersions(SharedPreferences prefs) async {
    final Iterable<String> stale = prefs.getKeys().where(
          (key) => key.startsWith('$_prefix.') && !key.startsWith(_namespace),
        );

    for (final String key in stale) {
      await prefs.remove(key);
    }
  }

  String _key(String name) => '$_namespace$name';

  String? getString(String name) => _prefs.getString(_key(name));

  Future<void> setString(String name, String value) {
    return _prefs.setString(_key(name), value);
  }

  bool? getBool(String name) => _prefs.getBool(_key(name));

  Future<void> setBool(String name, {required bool value}) {
    return _prefs.setBool(_key(name), value);
  }

  List<String> getStringList(String name) {
    return _prefs.getStringList(_key(name)) ?? const <String>[];
  }

  Future<void> setStringList(String name, List<String> value) {
    return _prefs.setStringList(_key(name), value);
  }

  Future<void> remove(String name) => _prefs.remove(_key(name));
}
