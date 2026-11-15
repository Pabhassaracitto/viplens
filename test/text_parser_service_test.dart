import 'package:flutter_test/flutter_test.dart';
import 'package:viplens/models/mindmap_model.dart';
import 'package:viplens/models/node_model.dart';
import 'package:viplens/services/text_parser_service.dart';

void main() {
  group('TextParserService.parseTextToMindMap', () {
    test('creates a root and preserves indented hierarchy', () {
      final mindmap = TextParserService.parseTextToMindMap(
        '- Khổ đế\n  - Sinh là khổ\n  - Già là khổ\n    - Vô thường',
        'Tứ diệu đế',
      );

      expect(mindmap.title, 'Tứ diệu đế');
      expect(mindmap.nodes, hasLength(5));
      final root = mindmap.getNodeById(mindmap.rootNodeId)!;
      expect(root.childIds, hasLength(1));
      final firstChild = mindmap.getNodeById(root.childIds.single)!;
      expect(firstChild.content, 'Khổ đế');
      expect(firstChild.childIds, hasLength(2));
      final nested = mindmap.getNodeById(firstChild.childIds.last)!;
      expect(nested.content, 'Già là khổ');
      expect(nested.childIds, hasLength(1));
      expect(mindmap.getNodeById(nested.childIds.single)!.content, 'Vô thường');
    });

    test('creates a root node when input is empty', () {
      final mindmap = TextParserService.parseTextToMindMap('  \n', 'Chánh niệm');

      expect(mindmap.nodes, hasLength(1));
      expect(mindmap.rootNode.content, 'Chánh niệm');
      expect(mindmap.rootNode.childIds, isEmpty);
    });

    test('extracts recognized Pali terms from parentheses', () {
      final mindmap = TextParserService.parseTextToMindMap(
        '- Khổ (Dukkha)',
        'Tứ diệu đế',
      );
      final child = mindmap.getNodeById(mindmap.rootNode.childIds.single)!;

      expect(child.content, 'Khổ');
      expect(child.paliText, 'Dukkha');
    });
  });

  group('TextParserService.updateMindMapFromText', () {
    test('updates outline and preserves metadata for edited nodes', () {
      final oldMindmap = _sampleMindmap();
      final oldReviewDate = oldMindmap.getNodeById('study')!.nextReviewDate;

      final updated = TextParserService.updateMindMapFromText(
        oldMindmap,
        '- Study updated\n  - Child updated\n- Keep this node',
        'New title',
      );

      final root = updated.getNodeById(updated.rootNodeId)!;
      final study = updated.getNodeById(root.childIds.first)!;
      final child = updated.getNodeById(study.childIds.single)!;
      final unchanged = updated.getNodeById(root.childIds.last)!;

      expect(updated.title, 'New title');
      expect(updated.rootNodeId, 'root');
      expect(root.content, 'New title');
      expect(study.id, 'study');
      expect(study.content, 'Study updated');
      expect(study.paliText, isNull);
      expect(study.isFlashcard, isTrue);
      expect(study.note, 'Remember this');
      expect(study.nextReviewDate, oldReviewDate);
      expect(study.repetitionCount, 3);
      expect(child.id, 'child');
      expect(child.content, 'Child updated');
      expect(unchanged.id, 'keep');
      expect(unchanged.content, 'Keep this node');
      expect(updated.nodes, hasLength(4));
    });

    test('does not transfer removed-node metadata to newly added lines', () {
      final oldMindmap = _sampleMindmap();

      final updated = TextParserService.updateMindMapFromText(
        oldMindmap,
        '- New topic\n- Keep this node\n- Added branch',
        'Study',
      );
      final root = updated.getNodeById(updated.rootNodeId)!;
      final added = updated.getNodeById(root.childIds.first)!;
      final retained = updated.getNodeById(root.childIds[1])!;
      final additional = updated.getNodeById(root.childIds.last)!;

      expect(added.content, 'New topic');
      expect(added.id, isNot('study'));
      expect(added.isFlashcard, isFalse);
      expect(retained.id, 'keep');
      expect(retained.isFlashcard, isFalse);
      expect(additional.content, 'Added branch');
      expect(additional.isFlashcard, isFalse);
      expect(updated.nodes, hasLength(4));
    });
  });
}

MindMapModel _sampleMindmap() {
  final now = DateTime.utc(2026, 1, 1);
  final root = NodeModel(
    id: 'root',
    content: 'Old title',
    childIds: ['study', 'keep'],
    level: 0,
  );
  final study = NodeModel(
    id: 'study',
    content: 'Study',
    paliText: 'Dukkha',
    note: 'Remember this',
    childIds: ['child'],
    parentId: 'root',
    level: 1,
    isFlashcard: true,
    nextReviewDate: now,
    repetitionCount: 3,
    easeFactor: 2.3,
    intervalDays: 4,
    imagePath: '/tmp/study.png',
    createdAt: now,
  );
  final child = NodeModel(
    id: 'child',
    content: 'Child',
    parentId: 'study',
    level: 2,
  );
  final keep = NodeModel(
    id: 'keep',
    content: 'Keep this node',
    parentId: 'root',
    level: 1,
  );

  return MindMapModel(
    id: 'mindmap',
    title: 'Old title',
    rootNodeId: root.id,
    nodes: [root, study, child, keep],
    createdAt: now,
    updatedAt: now,
  );
}
