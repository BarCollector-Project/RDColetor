import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart'; // Só para usar ConflictAlgorithm enum
import 'app_database.dart';

class WebAppDatabase extends AppDatabase {
  late SharedPreferences _prefs;

  @override
  Future<bool> init() async {
    _prefs = await SharedPreferences.getInstance();
    return true;
  }

  @override
  Future<bool> close() async {
    // Nada a fechar no Web
    return true;
  }

  String _key(String table, String id) => '$table:$id';

  Future<List<String>> _getIndex(String table) async {
    final indexRaw = _prefs.getString('_index:$table');
    if (indexRaw == null) return [];
    return List<String>.from(jsonDecode(indexRaw));
  }

  Future<void> _setIndex(String table, List<String> ids) async {
    await _prefs.setString('_index:$table', jsonEncode(ids));
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values, {ConflictAlgorithm? conflictAlgorithm}) async {
    final id = values['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    final key = _key(table, id);

    final exists = _prefs.containsKey(key);
    if (exists && conflictAlgorithm == ConflictAlgorithm.ignore) {
      return 0;
    }

    await _prefs.setString(key, jsonEncode(values));

    final index = await _getIndex(table);
    if (!index.contains(id)) {
      index.add(id);
      await _setIndex(table, index);
    }

    return 1;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy, int? limit}) async {
    final index = await _getIndex(table);
    final result = <Map<String, dynamic>>[];

    for (final id in index) {
      final data = _prefs.getString(_key(table, id));
      if (data != null) {
        final map = jsonDecode(data) as Map<String, dynamic>;
        result.add(map);
      }
    }

    return result.take(limit ?? result.length).toList();
  }

  @override
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    final id = values['id']?.toString();
    if (id == null || !_prefs.containsKey(_key(table, id))) return 0;

    await _prefs.setString(_key(table, id), jsonEncode(values));
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final index = await _getIndex(table);
    int count = 0;
    for (final id in index) {
      await _prefs.remove(_key(table, id));
      count++;
    }
    await _prefs.remove('_index:$table');
    return count;
  }
}
