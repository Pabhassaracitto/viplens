import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:viplens/models/folder_model.dart';
import 'package:viplens/models/mindmap_model.dart';
import 'package:viplens/models/node_model.dart';
import 'package:viplens/providers/review_provider.dart';
import 'package:viplens/services/backup_codec.dart';
import 'package:viplens/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory appDirectory;

  setUpAll(() async {
    appDirectory = await Directory.systemTemp.createTemp('viplens_hive_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => appDirectory.path,
    );
    await DatabaseService.initialize();
  });

  setUp(() async {
    await Hive.box<MindMapModel>('mindmaps').clear();
    await Hive.box<FolderModel>('folders').clear();
    await Hive.box<dynamic>('settings').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    await appDirectory.delete(recursive: true);
  });

  test('saves and retrieves a mindmap by ID', () async {
    final mindmap = _mindmap('map-1', 'Tứ diệu đế');

    await DatabaseService.saveMindMap(mindmap);

    expect(DatabaseService.getMindMapById('map-1')?.title, 'Tứ diệu đế');
    expect(DatabaseService.getAllMindMaps(), hasLength(1));
  });

  test('validates a full backup before merging it into Hive', () async {
    await DatabaseService.saveMindMap(_mindmap('local-map', 'Dữ liệu hiện có'));
    final backupMap = _mindmap('imported-map', 'Bản sao lưu');
    final backup = BackupCodec.encode(
      mindmaps: [backupMap],
      folders: [],
      settings: {'appSettings': {'isDarkMode': true}},
    );

    final importedCount = await DatabaseService.importData(backup);

    expect(importedCount, 1);
    expect(DatabaseService.getAllMindMaps(), hasLength(2));
    expect(DatabaseService.getMindMapById('local-map')?.title, 'Dữ liệu hiện có');
    expect(
      DatabaseService.getMindMapById('imported-map')?.title,
      'Bản sao lưu',
    );
    expect(DatabaseService.getSetting<Map>('appSettings')?['isDarkMode'], isTrue);
  });

  test('filters a review session to the selected mindmap', () async {
    await DatabaseService.saveMindMap(_mindmapWithDueCard('map-a'));
    await DatabaseService.saveMindMap(_mindmapWithDueCard('map-b'));

    final provider = ReviewProvider();
    await provider.loadDueFlashcards(mindmapId: 'map-b');

    expect(provider.totalCount, 1);
    expect(provider.currentMindMap?.id, 'map-b');
    provider.dispose();
  });

  test('selected mindmap with no due cards has an empty review session', () async {
    await DatabaseService.saveMindMap(_mindmap('map-no-cards', 'No cards'));

    final provider = ReviewProvider();
    await provider.loadDueFlashcards(mindmapId: 'map-no-cards');

    expect(provider.hasCards, isFalse);
    expect(provider.totalCount, 0);
    provider.dispose();
  });

  test('rejects an unsupported backup without changing saved data', () async {
    await DatabaseService.saveMindMap(_mindmap('local-map', 'Giữ nguyên'));

    await expectLater(
      DatabaseService.importData({
        'format': BackupCodec.formatName,
        'schemaVersion': BackupCodec.currentSchemaVersion + 1,
        'mindmaps': <dynamic>[],
        'folders': <dynamic>[],
        'settings': <String, dynamic>{},
      }),
      throwsA(isA<FormatException>()),
    );

    expect(DatabaseService.getAllMindMaps(), hasLength(1));
    expect(DatabaseService.getMindMapById('local-map')?.title, 'Giữ nguyên');
  });
}

MindMapModel _mindmapWithDueCard(String id) {
  final now = DateTime.now();
  final root = NodeModel(
    id: '$id-root',
    content: id,
    childIds: ['$id-card'],
  );
  final card = NodeModel(
    id: '$id-card',
    content: 'Due card for $id',
    parentId: root.id,
    level: 1,
    isFlashcard: true,
    nextReviewDate: now.subtract(const Duration(days: 1)),
  );
  return MindMapModel(
    id: id,
    title: id,
    rootNodeId: root.id,
    nodes: [root, card],
    createdAt: now,
    updatedAt: now,
  );
}

MindMapModel _mindmap(String id, String title) {
  final now = DateTime.utc(2026, 1, 1);
  final root = NodeModel(id: '$id-root', content: title);
  return MindMapModel(
    id: id,
    title: title,
    rootNodeId: root.id,
    nodes: [root],
    createdAt: now,
    updatedAt: now,
  );
}
