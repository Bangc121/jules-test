import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart'; // Required for getApplicationDocumentsDirectory
import 'dart:async';
import 'dart:io'; // Required for Directory

class JournalEntry {
  int? id;
  String date; // Store date as ISO8601 string: YYYY-MM-DD
  String content;

  JournalEntry({this.id, required this.date, required this.content});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'content': content,
    };
  }

  static JournalEntry fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      date: map['date'],
      content: map['content'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'journal.db';
  static const String _tableName = 'entries';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        content TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertEntry(JournalEntry entry) async {
    Database db = await database;
    return await db.insert(
      _tableName,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace if entry for date already exists
    );
  }

  Future<JournalEntry?> getEntry(String date) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isNotEmpty) {
      return JournalEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateEntry(JournalEntry entry) async {
    Database db = await database;
    return await db.update(
      _tableName,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(String date) async {
    Database db = await database;
    return await db.delete(
      _tableName,
      where: 'date = ?',
      whereArgs: [date],
    );
  }
}
