import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/nutrition.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Directory> get localDirectory async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'shizhi'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    final String databasePath;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      databasePath = 'nutri_diary.sqlite';
    } else {
      final dir = await localDirectory;
      databasePath = p.join(dir.path, 'nutri_diary.sqlite');
      final legacyPath = p.join(
        (await getApplicationDocumentsDirectory()).path,
        'nutri_diary.sqlite',
      );
      if (!await File(databasePath).exists() &&
          await File(legacyPath).exists()) {
        await File(legacyPath).copy(databasePath);
      }
    }
    _db = await openDatabase(
      databasePath,
      version: 3,
      onCreate: (db, version) async {
        await db.execute(
          '''CREATE TABLE food_entries (
          id TEXT PRIMARY KEY, loggedAt TEXT NOT NULL, name TEXT NOT NULL, meal TEXT NOT NULL,
          grams REAL NOT NULL, calories100g REAL NOT NULL, protein100g REAL NOT NULL,
          carbs100g REAL NOT NULL, fat100g REAL NOT NULL, fiber100g REAL NOT NULL,
          sugar100g REAL NOT NULL, source TEXT NOT NULL, photoPath TEXT, notes TEXT NOT NULL DEFAULT '',
          isPlanned INTEGER NOT NULL DEFAULT 0, mealId TEXT, referenceId TEXT)''',
        );
        await db.execute(
          '''CREATE INDEX food_entries_date_idx ON food_entries(loggedAt, isPlanned)''',
        );
        await db.execute(
          '''CREATE TABLE weight_logs (
          id TEXT PRIMARY KEY, loggedAt TEXT NOT NULL, kg REAL NOT NULL, notes TEXT NOT NULL DEFAULT '')''',
        );
        await db.execute(
          '''CREATE TABLE app_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE food_entries ADD COLUMN mealId TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE food_entries ADD COLUMN referenceId TEXT',
          );
        }
      },
    );
    return _db!;
  }

  Future<void> insertEntry(FoodEntry entry) async {
    final db = await database;
    await db.insert(
      'food_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertEntries(List<FoodEntry> entries) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final entry in entries) {
        await txn.insert(
          'food_entries',
          entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete('food_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPlanned(String id, bool planned) async {
    final db = await database;
    await db.update(
      'food_entries',
      {'isPlanned': planned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<FoodEntry>> entriesOn(DateTime date, {bool? planned}) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(date.year, date.month, date.day + 1).toIso8601String();
    final where = StringBuffer('loggedAt >= ? AND loggedAt < ?');
    final args = <Object?>[start, end];
    if (planned != null) {
      where.write(' AND isPlanned = ?');
      args.add(planned ? 1 : 0);
    }
    final rows = await db.query(
      'food_entries',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'loggedAt DESC',
    );
    return rows.map(FoodEntry.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> allEntryMaps() async =>
      (await (await database).query('food_entries')).toList();

  Future<void> insertWeight(WeightLog log) async {
    await (await database).insert(
      'weight_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WeightLog>> weights({int limit = 60}) async {
    final rows = await (await database).query(
      'weight_logs',
      orderBy: 'loggedAt DESC',
      limit: limit,
    );
    return rows.map(WeightLog.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> allWeightMaps() async =>
      (await (await database).query('weight_logs')).toList();

  Future<void> saveMeta(String key, Object value) async {
    await (await database).insert('app_meta', {
      'key': key,
      'value': jsonEncode(value),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> readMeta(String key) async {
    final rows = await (await database).query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final decoded = jsonDecode(rows.first['value']! as String);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<Map<String, dynamic>> allMeta() async {
    final rows = await (await database).query('app_meta');
    final result = <String, dynamic>{};
    for (final row in rows) {
      try {
        result['${row['key']}'] = jsonDecode('${row['value']}');
      } catch (_) {
        /* skip invalid metadata */
      }
    }
    return result;
  }

  Future<void> mergeImported({
    required List<Map<String, dynamic>> entries,
    required List<Map<String, dynamic>> weights,
    required Map<String, dynamic> meta,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final e in entries) {
        await txn.insert(
          'food_entries',
          e,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final w in weights) {
        await txn.insert(
          'weight_logs',
          w,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final entry in meta.entries) {
        final currentRows = await txn.query(
          'app_meta',
          columns: ['value'],
          where: 'key = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        dynamic value = entry.value;
        if (currentRows.isNotEmpty && value is Map<String, dynamic>) {
          try {
            final previous = jsonDecode('${currentRows.first['value']}');
            if (previous is Map<String, dynamic>) {
              value = {...previous, ...value};
            }
          } catch (_) {
            // Replace invalid existing metadata with the readable backup value.
          }
        }
        await txn.insert('app_meta', {
          'key': entry.key,
          'value': jsonEncode(value),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
