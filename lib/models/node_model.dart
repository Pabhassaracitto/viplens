import 'package:hive/hive.dart';

part 'node_model.g.dart';

@HiveType(typeId: 0)
class NodeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String content;

  @HiveField(2)
  String? paliText;

  @HiveField(3)
  String? note;

  @HiveField(4)
  List<String> childIds;

  @HiveField(5)
  String? parentId;

  @HiveField(6)
  int level;

  @HiveField(7)
  int colorIndex;

  // Flashcard data
  @HiveField(8)
  bool isFlashcard;

  @HiveField(9)
  DateTime? nextReviewDate;

  @HiveField(10)
  int repetitionCount;

  @HiveField(11)
  double easeFactor;

  @HiveField(12)
  int intervalDays;

  // Position for mindmap canvas
  @HiveField(13)
  double? positionX;

  @HiveField(14)
  double? positionY;

  NodeModel({
    required this.id,
    required this.content,
    this.paliText,
    this.note,
    List<String>? childIds,
    this.parentId,
    this.level = 0,
    this.colorIndex = 0,
    this.isFlashcard = false,
    this.nextReviewDate,
    this.repetitionCount = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.positionX,
    this.positionY,
  }) : childIds = childIds ?? [];

  // Copy with method
  NodeModel copyWith({
    String? id,
    String? content,
    String? paliText,
    String? note,
    List<String>? childIds,
    String? parentId,
    int? level,
    int? colorIndex,
    bool? isFlashcard,
    DateTime? nextReviewDate,
    int? repetitionCount,
    double? easeFactor,
    int? intervalDays,
    double? positionX,
    double? positionY,
  }) {
    return NodeModel(
      id: id ?? this.id,
      content: content ?? this.content,
      paliText: paliText ?? this.paliText,
      note: note ?? this.note,
      childIds: childIds ?? List.from(this.childIds),
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      colorIndex: colorIndex ?? this.colorIndex,
      isFlashcard: isFlashcard ?? this.isFlashcard,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
    );
  }

  // To JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'paliText': paliText,
      'note': note,
      'childIds': childIds,
      'parentId': parentId,
      'level': level,
      'colorIndex': colorIndex,
      'isFlashcard': isFlashcard,
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'repetitionCount': repetitionCount,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'positionX': positionX,
      'positionY': positionY,
    };
  }

  // From JSON for import
  factory NodeModel.fromJson(Map<String, dynamic> json) {
    return NodeModel(
      id: json['id'] as String,
      content: json['content'] as String,
      paliText: json['paliText'] as String?,
      note: json['note'] as String?,
      childIds: List<String>.from(json['childIds'] ?? []),
      parentId: json['parentId'] as String?,
      level: json['level'] as int? ?? 0,
      colorIndex: json['colorIndex'] as int? ?? 0,
      isFlashcard: json['isFlashcard'] as bool? ?? false,
      nextReviewDate: json['nextReviewDate'] != null
          ? DateTime.parse(json['nextReviewDate'] as String)
          : null,
      repetitionCount: json['repetitionCount'] as int? ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: json['intervalDays'] as int? ?? 1,
      positionX: (json['positionX'] as num?)?.toDouble(),
      positionY: (json['positionY'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'NodeModel(id: $id, content: $content, level: $level, children: ${childIds.length})';
  }
}
