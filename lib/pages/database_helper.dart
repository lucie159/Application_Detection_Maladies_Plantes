import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart'; // Ajout pour debugPrint
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      Directory dir = await getApplicationDocumentsDirectory();
      String path = join(dir.path, "diagnostics.db");

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e, stack) {
      // Gestion robuste des erreurs
      debugPrint("⚠️ ERREUR INITIALISATION BASE DE DONNÉES: $e");
      debugPrint("Stack trace: $stack");

      // Solution de repli : base de données en mémoire
      return await openDatabase(
        ':memory:',
        version: 1,
        onCreate: _onCreate,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE history (
          id TEXT PRIMARY KEY,
          plantName TEXT,
          date TEXT,
          confidence REAL,
          status TEXT,
          imagePath TEXT
        )
      ''');
    } catch (e, stack) {
      debugPrint("⚠️ ERREUR CRÉATION TABLE: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  Future<void> insertHistory(HistoryItem item) async {
    try {
      final db = await database;
      await db.insert(
        'history',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stack) {
      debugPrint("⚠️ ERREUR INSERTION HISTORIQUE: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  Future<List<HistoryItem>> getAllHistory() async {
    try {
      final db = await database;
      final result = await db.query('history', orderBy: "date DESC");
      return result.map((e) => HistoryItem.fromMap(e)).toList();
    } catch (e, stack) {
      debugPrint("⚠️ ERREUR LECTURE HISTORIQUE: $e");
      debugPrint("Stack trace: $stack");
      return []; // Retourne une liste vide en cas d'erreur
    }
  }

  Future<void> clearHistory() async {
    try {
      final db = await database;
      await db.delete('history');
    } catch (e, stack) {
      debugPrint("⚠️ ERREUR SUPPRESSION HISTORIQUE: $e");
      debugPrint("Stack trace: $stack");
    }
  }
}