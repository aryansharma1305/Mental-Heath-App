import 'dart:io';

import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseEncryptionMigrationService {
  final PlainDatabaseMigrationExecutor executor;

  const DatabaseEncryptionMigrationService({
    this.executor = const SqlCipherPlainDatabaseMigrationExecutor(),
  });

  Future<bool> migrateIfNeeded(String dbPath, String key) async {
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) return false;

    final isPlainDatabase = await executor.canOpenWithoutKey(dbPath);
    if (!isPlainDatabase) return false;

    final tempPath = '$dbPath.sqlcipher.tmp';
    final backupPath = '$dbPath.plain.bak';
    await _deleteIfExists(tempPath);
    await _deleteIfExists(backupPath);

    try {
      await executor.exportPlainToEncrypted(
        plainPath: dbPath,
        encryptedPath: tempPath,
        key: key,
      );

      await dbFile.rename(backupPath);
      await _deleteSidecarFiles(dbPath);
      await File(tempPath).rename(dbPath);
      await _deleteSidecarFiles(tempPath);
      await _deleteIfExists(backupPath);
      return true;
    } catch (_) {
      await _deleteIfExists(tempPath);
      await _deleteSidecarFiles(tempPath);
      if (!await File(dbPath).exists() && await File(backupPath).exists()) {
        await File(backupPath).rename(dbPath);
      }
      rethrow;
    }
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _deleteSidecarFiles(String path) async {
    for (final suffix in ['-wal', '-shm', '-journal']) {
      await _deleteIfExists('$path$suffix');
    }
  }
}

abstract class PlainDatabaseMigrationExecutor {
  Future<bool> canOpenWithoutKey(String path);

  Future<void> exportPlainToEncrypted({
    required String plainPath,
    required String encryptedPath,
    required String key,
  });
}

class SqlCipherPlainDatabaseMigrationExecutor
    implements PlainDatabaseMigrationExecutor {
  const SqlCipherPlainDatabaseMigrationExecutor();

  @override
  Future<bool> canOpenWithoutKey(String path) async {
    Database? db;
    try {
      final opened = await openDatabase(
        path,
        readOnly: true,
        singleInstance: false,
      );
      db = opened;
      await opened.rawQuery('SELECT count(*) FROM sqlite_master');
      return true;
    } catch (_) {
      return false;
    } finally {
      await db?.close();
    }
  }

  @override
  Future<void> exportPlainToEncrypted({
    required String plainPath,
    required String encryptedPath,
    required String key,
  }) async {
    Database? plainDb;
    var encryptedAttached = false;
    try {
      plainDb = await openDatabase(plainPath, singleInstance: false);
      await plainDb.rawQuery('PRAGMA wal_checkpoint(FULL)');
      final versionRows = await plainDb.rawQuery('PRAGMA user_version');
      final userVersion =
          (versionRows.firstOrNull?['user_version'] as int?) ?? 0;

      await plainDb.execute(
        'ATTACH DATABASE ${_sqlLiteral(encryptedPath)} AS encrypted KEY ${_sqlLiteral(key)}',
      );
      encryptedAttached = true;
      await plainDb.execute("SELECT sqlcipher_export('encrypted')");
      await plainDb.execute('PRAGMA encrypted.user_version = $userVersion');
    } finally {
      if (plainDb != null && encryptedAttached) {
        try {
          await plainDb.execute('DETACH DATABASE encrypted');
        } catch (_) {
          // Closing the database will release the attachment if detach fails.
        }
      }
      await plainDb?.close();
    }
  }

  String _sqlLiteral(String value) => "'${value.replaceAll("'", "''")}'";
}
