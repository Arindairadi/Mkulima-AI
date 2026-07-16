import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Lightweight offline persistence: reads/writes JSON files to the app's
/// local documents directory.
///
/// This replaces the originally-planned Isar integration. Isar's Android
/// packaging (`isar_flutter_libs`) has an unresolved `namespace` issue with
/// modern Android Gradle Plugin versions (see the backend/root README's
/// "Known build fixes" table) and the project appears unmaintained, so it
/// was dropped entirely rather than fought with.
///
/// This is intentionally simple — no query engine, no indexes — just
/// "save this list of JSON-serializable records under this key, load it
/// back later." That's enough for farm records, and it has zero native
/// plugin surface, so it can't reintroduce a Gradle build failure.
///
/// If the app's storage needs grow (large datasets, complex queries),
/// swap this for `sqflite` or `drift` — both are mainstream, well
/// maintained, and don't have Isar's packaging problems.
class LocalCacheService {
  Future<File> _fileFor(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$key.json');
  }

  /// Saves a JSON-encodable value (e.g. a `List<Map<String, dynamic>>`)
  /// under [key]. Overwrites any existing value.
  Future<void> save(String key, dynamic value) async {
    final file = await _fileFor(key);
    await file.writeAsString(jsonEncode(value));
  }

  /// Loads and decodes the JSON previously saved under [key].
  /// Returns null if nothing has been saved yet, or if the file is corrupt.
  Future<dynamic> load(String key) async {
    try {
      final file = await _fileFor(key);
      if (!await file.exists()) return null;
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String key) async {
    final file = await _fileFor(key);
    if (await file.exists()) await file.delete();
  }
}
