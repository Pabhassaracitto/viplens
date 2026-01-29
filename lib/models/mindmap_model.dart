import 'package:hive/hive.dart';
import 'node_model.dart';

part 'mindmap_model.g.dart';

@HiveType(typeId: 1)
class MindMapModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String rootNodeId;

  @HiveField(4)
  List<NodeModel> nodes;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  String? folderId;

  @HiveField(9)
  bool isZenMode;

  MindMapModel({
    required this.id,
    required this.title,
    this.description,
    required this.rootNodeId,
    required this.nodes,
    required this.createdAt,
    required this.updatedAt,
    List<String>? tags,
    this.folderId,
    this.isZenMode = false,
  }) : tags = tags ?? [];

  // Lấy node gốc
  NodeModel get rootNode {
    return nodes.firstWhere(
      (node) => node.id == rootNodeId,
      orElse: () => nodes.first,
    );
  }

  // Lấy node theo ID
  NodeModel? getNodeById(String nodeId) {
    try {
      return nodes.firstWhere((node) => node.id == nodeId);
    } catch (e) {
      return null;
    }
  }

  // Lấy các node con của một node
  List<NodeModel> getChildren(String parentId) {
    final parent = getNodeById(parentId);
    if (parent == null) return [];

    return parent.childIds
        .map((childId) => getNodeById(childId))
        .where((node) => node != null)
        .cast<NodeModel>()
        .toList();
  }

  // Đếm số flashcard
  int get flashcardCount {
    return nodes.where((node) => node.isFlashcard).length;
  }

  // Đếm số flashcard cần ôn tập hôm nay
  int get dueFlashcardCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return nodes.where((node) {
      if (!node.isFlashcard || node.nextReviewDate == null) return false;
      final reviewDate = DateTime(
        node.nextReviewDate!.year,
        node.nextReviewDate!.month,
        node.nextReviewDate!.day,
      );
      return reviewDate.compareTo(today) <= 0;
    }).length;
  }

  // Lấy tất cả flashcard cần ôn tập
  List<NodeModel> getDueFlashcards() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return nodes.where((node) {
      if (!node.isFlashcard || node.nextReviewDate == null) return false;
      final reviewDate = DateTime(
        node.nextReviewDate!.year,
        node.nextReviewDate!.month,
        node.nextReviewDate!.day,
      );
      return reviewDate.compareTo(today) <= 0;
    }).toList();
  }

  // Copy with
  MindMapModel copyWith({
    String? id,
    String? title,
    String? description,
    String? rootNodeId,
    List<NodeModel>? nodes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? folderId,
    bool? isZenMode,
  }) {
    return MindMapModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rootNodeId: rootNodeId ?? this.rootNodeId,
      nodes: nodes ?? List.from(this.nodes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? List.from(this.tags),
      folderId: folderId ?? this.folderId,
      isZenMode: isZenMode ?? this.isZenMode,
    );
  }

  // To JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rootNodeId': rootNodeId,
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'folderId': folderId,
      'isZenMode': isZenMode,
    };
  }

  // From JSON for import
  factory MindMapModel.fromJson(Map<String, dynamic> json) {
    return MindMapModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      rootNodeId: json['rootNodeId'] as String,
      nodes: (json['nodes'] as List)
          .map(
            (nodeJson) => NodeModel.fromJson(nodeJson as Map<String, dynamic>),
          )
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: List<String>.from(json['tags'] ?? []),
      folderId: json['folderId'] as String?,
      isZenMode: json['isZenMode'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'MindMapModel(id: $id, title: $title, nodes: ${nodes.length})';
  }
}
