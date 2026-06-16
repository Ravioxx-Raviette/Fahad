import 'dart:math';
import 'dart:convert';
import 'package:path/path.dart';
// CHANGE: Import SQLCipher instead of standard sqflite
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/verification_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Secure Storage to hold the database encryption key
  final _secureStorage = const FlutterSecureStorage();
  static const _dbKeyName = 'db_encryption_key';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('secure_history.db'); // New name for new DB
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // 1. Get or Generate the Encryption Key
    String password = await _getEncryptionKey();

    // 2. Open the Database with the Password
    return await openDatabase(
      path,
      version: 1,
      password: password, // <--- THE SECURITY FEATURE
      onCreate: _createDB,
    );
  }

  // Helper to manage the key securely
  Future<String> _getEncryptionKey() async {
    // Try to read existing key
    String? encryptionKey = await _secureStorage.read(key: _dbKeyName);

    if (encryptionKey == null) {
      // If no key exists, generate a new strong one
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(255));
      encryptionKey = base64UrlEncode(values);

      // Save it to the secure vault
      await _secureStorage.write(key: _dbKeyName, value: encryptionKey);
    }
    return encryptionKey;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY,
        imageFilename TEXT,
        verificationDate TEXT,
        credibilityScore REAL,
        classificationResult TEXT,
        metadata TEXT,
        imageBytes BLOB
      )
    ''');
  }

  Future<int> create(VerificationResult result) async {
    final db = await instance.database;
    return await db.insert('history', result.toMap());
  }

  Future<List<VerificationResult>> readAllResults() async {
    final db = await instance.database;
    final orderBy = 'verificationDate DESC';
    final result = await db.query('history', orderBy: orderBy);
    return result.map((json) => VerificationResult.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }
}
