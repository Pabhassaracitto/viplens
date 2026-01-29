import 'package:uuid/uuid.dart';
import '../models/node_model.dart';
import '../models/mindmap_model.dart';

class TextParserService {
  static const _uuid = Uuid();

  /// Parse text thành MindMap
  ///
  /// Hỗ trợ các định dạng:
  /// - Indent bằng tab hoặc spaces
  /// - Dấu -, +, *, • cho bullet
  /// - Số thứ tự (1., 2., ...)
  /// - Pali text trong ngoặc đơn: (Pali text)
  static MindMapModel parseTextToMindMap(String text, String title) {
    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      // Tạo mindmap trống với một node gốc
      final rootNode = NodeModel(
        id: _uuid.v4(),
        content: title,
        level: 0,
        colorIndex: 0,
      );

      return MindMapModel(
        id: _uuid.v4(),
        title: title,
        rootNodeId: rootNode.id,
        nodes: [rootNode],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final nodes = <NodeModel>[];
    final nodeStack = <NodeModel>[]; // Stack để theo dõi parent nodes

    // Tạo node gốc từ title
    final rootNode = NodeModel(
      id: _uuid.v4(),
      content: title,
      level: 0,
      colorIndex: 0,
    );
    nodes.add(rootNode);
    nodeStack.add(rootNode);

    for (final line in lines) {
      final parsed = _parseLine(line);
      if (parsed == null) continue;

      final level = parsed.level + 1; // +1 vì root là level 0
      final content = parsed.content;
      final paliText = parsed.paliText;

      // Tìm parent node
      while (nodeStack.length > level) {
        nodeStack.removeLast();
      }

      final parent = nodeStack.isNotEmpty ? nodeStack.last : rootNode;

      // Tạo node mới
      final newNode = NodeModel(
        id: _uuid.v4(),
        content: content,
        paliText: paliText,
        parentId: parent.id,
        level: level,
        colorIndex: level % 6, // Xoay vòng 6 màu
      );

      // Thêm child ID vào parent
      parent.childIds.add(newNode.id);

      nodes.add(newNode);
      nodeStack.add(newNode);
    }

    return MindMapModel(
      id: _uuid.v4(),
      title: title,
      rootNodeId: rootNode.id,
      nodes: nodes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Parse một dòng text
  static _ParsedLine? _parseLine(String line) {
    if (line.trim().isEmpty) return null;

    // Đếm indent level
    int indentCount = 0;
    int index = 0;

    while (index < line.length) {
      if (line[index] == '\t') {
        indentCount += 1;
        index++;
      } else if (line[index] == ' ') {
        // Đếm 2-4 spaces = 1 level
        int spaceCount = 0;
        while (index < line.length && line[index] == ' ') {
          spaceCount++;
          index++;
        }
        indentCount += (spaceCount / 2).floor();
      } else {
        break;
      }
    }

    String content = line.substring(index).trim();

    // Loại bỏ bullet markers
    content = _removeBulletMarker(content);

    if (content.isEmpty) return null;

    // Extract Pali text từ ngoặc đơn
    String? paliText;
    final paliMatch = RegExp(r'\(([^)]+)\)').firstMatch(content);
    if (paliMatch != null) {
      final matched = paliMatch.group(1)!;
      // Kiểm tra xem có phải Pali không (có dấu hoặc chữ đặc biệt)
      if (_looksLikePali(matched)) {
        paliText = matched;
        content = content.replaceFirst(paliMatch.group(0)!, '').trim();
      }
    }

    return _ParsedLine(
      level: indentCount,
      content: content,
      paliText: paliText,
    );
  }

  /// Loại bỏ các bullet markers
  static String _removeBulletMarker(String text) {
    // Patterns: -, +, *, •, 1., 2., a., b., etc.
    final patterns = [
      RegExp(r'^[-+*•]\s*'), // -, +, *, •
      RegExp(r'^\d+\.\s*'), // 1., 2., 3.
      RegExp(r'^[a-zA-Z]\.\s*'), // a., b., A., B.
      RegExp(r'^\[\s*\]\s*'), // [ ]
      RegExp(r'^\[x\]\s*', caseSensitive: false), // [x]
    ];

    String result = text;
    for (final pattern in patterns) {
      result = result.replaceFirst(pattern, '');
    }
    return result.trim();
  }

  /// Kiểm tra xem text có giống Pali không
  static bool _looksLikePali(String text) {
    // Các từ Pali thường có:
    // - Dấu macron: ā, ī, ū
    // - Các chữ đặc trưng: ṃ, ṇ, ṭ, ḍ, ñ, ṅ
    // - Hoặc là từ Pali phổ biến

    final paliChars = RegExp(r'[āīūṃṇṭḍñṅḷ]', caseSensitive: false);
    if (paliChars.hasMatch(text)) return true;

    // Một số từ Pali phổ biến
    final commonPali = [
      'dukkha',
      'sukha',
      'nibbana',
      'nibbāna',
      'dhamma',
      'dharma',
      'buddha',
      'sangha',
      'sutta',
      'vinaya',
      'abhidhamma',
      'sila',
      'samadhi',
      'panna',
      'pañña',
      'sati',
      'samatha',
      'vipassana',
      'magga',
      'phala',
      'sacca',
      'ariya',
      'bhikkhu',
      'bhikkhuni',
      'kamma',
      'vipaka',
      'cetana',
      'vedana',
      'sanna',
      'sankhara',
      'vinnana',
      'rupa',
      'nama',
      'citta',
      'cetasika',
      'jhana',
      'samapatti',
    ];

    final lowerText = text.toLowerCase();
    return commonPali.any((word) => lowerText.contains(word));
  }

  /// Thêm node mới vào mindmap
  static MindMapModel addNode(
    MindMapModel mindmap,
    String parentId,
    String content, {
    String? paliText,
  }) {
    final parent = mindmap.getNodeById(parentId);
    if (parent == null) return mindmap;

    final newNode = NodeModel(
      id: _uuid.v4(),
      content: content,
      paliText: paliText,
      parentId: parentId,
      level: parent.level + 1,
      colorIndex: (parent.level + 1) % 6,
    );

    parent.childIds.add(newNode.id);

    final updatedNodes = List<NodeModel>.from(mindmap.nodes)..add(newNode);

    return mindmap.copyWith(nodes: updatedNodes, updatedAt: DateTime.now());
  }

  /// Xóa node khỏi mindmap (và tất cả con của nó)
  static MindMapModel deleteNode(MindMapModel mindmap, String nodeId) {
    if (nodeId == mindmap.rootNodeId) return mindmap; // Không xóa root

    // Tìm tất cả node cần xóa (node này và con cháu)
    final nodesToDelete = <String>{nodeId};
    _collectDescendants(mindmap, nodeId, nodesToDelete);

    // Tìm parent và xóa reference
    final nodeToDelete = mindmap.getNodeById(nodeId);
    if (nodeToDelete?.parentId != null) {
      final parent = mindmap.getNodeById(nodeToDelete!.parentId!);
      parent?.childIds.remove(nodeId);
    }

    // Lọc bỏ các nodes đã xóa
    final updatedNodes = mindmap.nodes
        .where((node) => !nodesToDelete.contains(node.id))
        .toList();

    return mindmap.copyWith(nodes: updatedNodes, updatedAt: DateTime.now());
  }

  /// Thu thập tất cả node con cháu
  static void _collectDescendants(
    MindMapModel mindmap,
    String nodeId,
    Set<String> result,
  ) {
    final node = mindmap.getNodeById(nodeId);
    if (node == null) return;

    for (final childId in node.childIds) {
      result.add(childId);
      _collectDescendants(mindmap, childId, result);
    }
  }

  /// Cập nhật nội dung node
  static MindMapModel updateNodeContent(
    MindMapModel mindmap,
    String nodeId,
    String newContent, {
    String? newPaliText,
  }) {
    final nodeIndex = mindmap.nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex < 0) return mindmap;

    final updatedNode = mindmap.nodes[nodeIndex].copyWith(
      content: newContent,
      paliText: newPaliText,
    );

    final updatedNodes = List<NodeModel>.from(mindmap.nodes);
    updatedNodes[nodeIndex] = updatedNode;

    return mindmap.copyWith(nodes: updatedNodes, updatedAt: DateTime.now());
  }

  /// Chuyển đổi node thành flashcard
  static MindMapModel toggleFlashcard(MindMapModel mindmap, String nodeId) {
    final nodeIndex = mindmap.nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex < 0) return mindmap;

    final node = mindmap.nodes[nodeIndex];
    final updatedNode = node.copyWith(
      isFlashcard: !node.isFlashcard,
      nextReviewDate: !node.isFlashcard ? DateTime.now() : null,
      repetitionCount: 0,
      easeFactor: 2.5,
      intervalDays: 1,
    );

    final updatedNodes = List<NodeModel>.from(mindmap.nodes);
    updatedNodes[nodeIndex] = updatedNode;

    return mindmap.copyWith(nodes: updatedNodes, updatedAt: DateTime.now());
  }
}

class _ParsedLine {
  final int level;
  final String content;
  final String? paliText;

  _ParsedLine({required this.level, required this.content, this.paliText});
}
