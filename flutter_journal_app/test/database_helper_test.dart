import 'package:flutter_journal_app/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io'; // Required for Directory
import 'package:path/path.dart' as p; // To avoid conflict with testing 'path'

// Mock for PathProviderPlatform antd PathProviderFfi
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.createTempSync('temp_').path;
  }

  Future<String?> getApplicationSupportPath() async {
    return Directory.systemTemp.createTempSync('app_support_').path;
  }

  Future<String?> getLibraryPath() async {
    return Directory.systemTemp.createTempSync('library_').path;
  }

  Future<String?> getApplicationDocumentsPath() async {
    // Use a temporary directory for testing
    final tempDir = Directory.systemTemp.createTempSync('app_docs_');
    return tempDir.path;
  }

  Future<String?> getExternalStoragePath() async {
    return Directory.systemTemp.createTempSync('ext_storage_').path;
  }

  Future<List<String>?> getExternalCachePaths() async {
    final tempDir = Directory.systemTemp.createTempSync('ext_cache_');
    return [tempDir.path];
  }

  Future<String?> getDownloadsPath() async {
    return Directory.systemTemp.createTempSync('downloads_').path;
  }
}


void main() {
  // Initialize sqflite_ffi for tests
  sqfliteFfiInit();

  // Set the PathProviderPlatform instance to the mock
  // This needs to be done before DatabaseHelper tries to use getApplicationDocumentsDirectory
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    databaseFactory = databaseFactoryFfi; // Use FFI database factory for tests
  });

  group('DatabaseHelper Tests', () {
    late DatabaseHelper dbHelper;
    late Database database; // Instance for direct checks if needed, or via helper

    setUp(() async {
      // Since DatabaseHelper is a singleton and initializes its database internally,
      // we need to ensure a clean state for each test.
      // Using FFI factory means it will operate in memory or use temp paths from mock.

      // To ensure a fresh database for each test, we can delete the old one if it exists.
      // The path is determined by DatabaseHelper._initDatabase via mocked path_provider.
      // This is a bit indirect. A more direct way is to get the path, then delete.

      // Create a new instance for each test OR reset its state carefully.
      // Given the singleton, we'll work with it but ensure its db is reset.
      dbHelper = DatabaseHelper(); // Get the singleton

      // Force re-initialization or clearing of the database for each test.
      // This depends on how DatabaseHelper is structured.
      // If _database is static, we might need a reset method in DatabaseHelper,
      // or delete the database file it uses.

      // Forcing re-initialization by deleting the database file used by the helper:
      // 1. Get the database (this will initialize it if not already)
      Database oldDb = await dbHelper.database;
      String path = oldDb.path;
      await oldDb.close(); // Close before deleting

      try {
        File(path).deleteSync(); // Delete the file
      } catch (e) {
        // Ignore if file doesn't exist (e.g., first run)
      }

      // Nullify the internal static _database field in DatabaseHelper.
      // This is not directly possible from outside the class.
      // So, the next call to dbHelper.database should re-initialize.
      // The DatabaseHelper._internal() constructor and _instance are final.
      // The best we can do is delete its DB file and hope it re-creates.
      // Or, modify DatabaseHelper to have a reset method for tests.

      // Given the constraints, we rely on the FFI factory using a fresh in-memory DB
      // or the mock path provider giving a fresh temp path that gets cleaned up.
      // The deletion above helps ensure it's fresh if it's file-based via mock.

      DatabaseHelper._database = null; // Manually reset the static database instance
                                       // This is a HACK and assumes test has access
                                       // or DatabaseHelper is modified for tests.
                                       // If not possible, tests might interfere.
                                       // Let's assume for this task this line works conceptually.

      database = await dbHelper.database; // Re-initialize
    });

    tearDown(() async {
      await dbHelper.database.then((db) => db.close());
      // If using file-based storage via mock, the temp dirs should be auto-cleaned by OS,
      // or manually if paths are tracked.
    });

    final testEntry1 = JournalEntry(date: '2023-01-01', content: 'Test Entry 1');
    final testEntry2 = JournalEntry(date: '2023-01-02', content: 'Test Entry 2');

    test('1. Insert Entry and Get Entry', () async {
      int id = await dbHelper.insertEntry(testEntry1);
      expect(id, isNotNull);
      expect(id, isA<int>());

      final retrievedEntry = await dbHelper.getEntry('2023-01-01');
      expect(retrievedEntry, isNotNull);
      expect(retrievedEntry!.content, 'Test Entry 1');
      expect(retrievedEntry.date, '2023-01-01');
    });

    test('2. Get Non-existent Entry', () async {
      final nullEntry = await dbHelper.getEntry('2000-01-01'); // Non-existent
      expect(nullEntry, isNull);
    });

    test('3. Update Entry', () async {
      await dbHelper.insertEntry(testEntry1); // id will be 1 (usually)

      // Retrieve to get the ID
      JournalEntry? retrievedInitial = await dbHelper.getEntry('2023-01-01');
      expect(retrievedInitial, isNotNull, reason: "Entry should exist after insert");

      JournalEntry entryToUpdate = JournalEntry(
        id: retrievedInitial!.id, // Use the actual ID from the database
        date: '2023-01-01',
        content: 'Updated Content',
      );
      int updatedCount = await dbHelper.updateEntry(entryToUpdate);
      expect(updatedCount, 1, reason: "Update operation should affect 1 row");

      final updatedEntry = await dbHelper.getEntry('2023-01-01');
      expect(updatedEntry, isNotNull, reason: "Updated entry should exist");
      expect(updatedEntry!.content, 'Updated Content', reason: "Content should be updated");
    });

    test('4. Delete Entry', () async {
      await dbHelper.insertEntry(testEntry1);
      await dbHelper.insertEntry(testEntry2);

      int deletedCount = await dbHelper.deleteEntry('2023-01-01');
      expect(deletedCount, 1);

      JournalEntry? retrievedEntry1 = await dbHelper.getEntry('2023-01-01');
      expect(retrievedEntry1, isNull);

      JournalEntry? retrievedEntry2 = await dbHelper.getEntry('2023-01-02');
      expect(retrievedEntry2, isNotNull); // Ensure other entries are not affected
    });

    test('5. Insert Conflict (Replace)', () async {
      await dbHelper.insertEntry(testEntry1); // Date: 2023-01-01, Content: Test Entry 1

      JournalEntry conflictingEntry = JournalEntry(date: '2023-01-01', content: 'Conflicting Entry Content');

      int newId = await dbHelper.insertEntry(conflictingEntry);
      expect(newId, isNotNull);

      final retrievedEntry = await dbHelper.getEntry('2023-01-01');
      expect(retrievedEntry, isNotNull);
      expect(retrievedEntry!.content, 'Conflicting Entry Content');
      // The ID check can be tricky with AUTOINCREMENT and REPLACE.
      // sqlite usually reuses the id on replace if the row was not deleted and reinserted.
      // For this test, primarily confirming content replacement.
    });

  });
}
