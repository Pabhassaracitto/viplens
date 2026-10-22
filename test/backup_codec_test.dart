import 'package:flutter_test/flutter_test.dart';
import 'package:viplens/models/mindmap_model.dart';
import 'package:viplens/models/node_model.dart';
import 'package:viplens/services/backup_codec.dart';

void main() {
  final root = NodeModel(id: 'root-1', content: 'Tứ diệu đế');
  final mindmap = MindMapModel(
    id: 'map-1',
    title: 'Tứ diệu đế',
    rootNodeId: root.id,
    nodes: [root],
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );

  group('BackupCodec', () {
    test('round-trips a versioned full backup', () {
      final encoded = BackupCodec.encode(
        mindmaps: [mindmap],
        folders: [],
        settings: {'appSettings': {'isDarkMode': true}},
        exportedAt: DateTime.utc(2026, 1, 3),
      );

      final decoded = BackupCodec.decode(encoded);

      expect(encoded['format'], BackupCodec.formatName);
      expect(encoded['schemaVersion'], BackupCodec.currentSchemaVersion);
      expect(decoded.mindmaps.single.title, 'Tứ diệu đế');
      expect(decoded.folders, isEmpty);
      expect(decoded.settings['appSettings']['isDarkMode'], isTrue);
    });

    test('accepts legacy backups without schema version', () {
      final decoded = BackupCodec.decode({
        'version': '1.0.0',
        'exportedAt': DateTime.utc(2026, 1, 3).toIso8601String(),
        'mindmaps': [mindmap.toJson()],
        'settings': <String, dynamic>{},
      });

      expect(decoded.mindmaps, hasLength(1));
    });

    test('rejects unknown schema versions before import', () {
      expect(
        () => BackupCodec.decode({
          'format': BackupCodec.formatName,
          'schemaVersion': BackupCodec.currentSchemaVersion + 1,
          'mindmaps': [],
          'folders': [],
          'settings': {},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed node graphs and duplicate mindmap IDs', () {
      final invalidGraph = mindmap.toJson()..['rootNodeId'] = 'missing-root';
      expect(
        () => BackupCodec.decode({
          'format': BackupCodec.formatName,
          'schemaVersion': BackupCodec.currentSchemaVersion,
          'mindmaps': [invalidGraph],
          'folders': [],
          'settings': {},
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => BackupCodec.decode({
          'format': BackupCodec.formatName,
          'schemaVersion': BackupCodec.currentSchemaVersion,
          'mindmaps': [mindmap.toJson(), mindmap.toJson()],
          'folders': [],
          'settings': {},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
