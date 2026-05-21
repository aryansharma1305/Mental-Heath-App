import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mental_capacity_assessment/services/database_encryption_migration_service.dart';

void main() {
  group('DatabaseEncryptionMigrationService', () {
    late Directory tempDir;
    late String dbPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mca_db_migration_test_');
      dbPath = '${tempDir.path}/mental_capacity_assessments.db';
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'exports a plain database and atomically swaps the encrypted copy',
      () async {
        await File(dbPath).writeAsString('plain fixture row: patient=P001');
        await File('$dbPath-wal').writeAsString('stale wal');

        final executor = _FakeMigrationExecutor(isPlainDatabase: true);
        final service = DatabaseEncryptionMigrationService(executor: executor);

        final migrated = await service.migrateIfNeeded(dbPath, 'secret-key');

        expect(migrated, isTrue);
        expect(
          await File(dbPath).readAsString(),
          contains('encrypted:secret-key'),
        );
        expect(await File(dbPath).readAsString(), contains('patient=P001'));
        expect(await File('$dbPath.sqlcipher.tmp').exists(), isFalse);
        expect(await File('$dbPath.plain.bak').exists(), isFalse);
        expect(await File('$dbPath-wal').exists(), isFalse);
        expect(executor.exportCalls, 1);
      },
    );

    test('does nothing when the database is already encrypted', () async {
      await File(dbPath).writeAsString('encrypted database bytes');

      final executor = _FakeMigrationExecutor(isPlainDatabase: false);
      final service = DatabaseEncryptionMigrationService(executor: executor);

      final migrated = await service.migrateIfNeeded(dbPath, 'secret-key');

      expect(migrated, isFalse);
      expect(await File(dbPath).readAsString(), 'encrypted database bytes');
      expect(executor.exportCalls, 0);
    });

    test('keeps the original database if export fails', () async {
      await File(dbPath).writeAsString('plain fixture row: patient=P002');

      final executor = _FakeMigrationExecutor(
        isPlainDatabase: true,
        failExport: true,
      );
      final service = DatabaseEncryptionMigrationService(executor: executor);

      expect(
        () => service.migrateIfNeeded(dbPath, 'secret-key'),
        throwsA(isA<StateError>()),
      );
      expect(await File(dbPath).readAsString(), contains('patient=P002'));
      expect(await File('$dbPath.sqlcipher.tmp').exists(), isFalse);
    });
  });
}

class _FakeMigrationExecutor implements PlainDatabaseMigrationExecutor {
  final bool isPlainDatabase;
  final bool failExport;
  int exportCalls = 0;

  _FakeMigrationExecutor({
    required this.isPlainDatabase,
    this.failExport = false,
  });

  @override
  Future<bool> canOpenWithoutKey(String path) async => isPlainDatabase;

  @override
  Future<void> exportPlainToEncrypted({
    required String plainPath,
    required String encryptedPath,
    required String key,
  }) async {
    exportCalls++;
    if (failExport) {
      throw StateError('export failed');
    }
    final plainContent = await File(plainPath).readAsString();
    await File(encryptedPath).writeAsString('encrypted:$key:$plainContent');
  }
}
