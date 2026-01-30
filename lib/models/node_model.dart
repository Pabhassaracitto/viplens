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

  @HiveField(13)
  double? positionX;

  @HiveField(14)
  double? positionY;

  // --- CÁC TRƯỜNG MỚI (GIAI ĐOẠN 3) ---

  @HiveField(15)
  String? imagePath;

  @HiveField(16)
  String? audioPath;

  @HiveField(17)
  int? audioDuration;

  @HiveField(18)
  String? imageUrl;

  @HiveField(19)
  String? link;

  @HiveField(20)
  DateTime? createdAt;

  @HiveField(21)
  DateTime? updatedAt;

  @HiveField(22)
  String? richNote;

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
    // Tham số mới
    this.imagePath,
    this.audioPath,
    this.audioDuration,
    this.imageUrl,
    this.link,
    this.createdAt,
    this.updatedAt,
    this.richNote,
  }) : childIds = childIds ?? [];

  // Getters tiện ích
  bool get hasImage => imagePath != null || imageUrl != null;
  bool get hasAudio => audioPath != null;
  bool get hasNote =>
      (note != null && note!.isNotEmpty) ||
      (richNote != null && richNote!.isNotEmpty);

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
    // Tham số mới
    String? imagePath,
    String? audioPath,
    int? audioDuration,
    String? imageUrl,
    String? link,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? richNote,
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
      // Gán giá trị mới
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      audioDuration: audioDuration ?? this.audioDuration,
      imageUrl: imageUrl ?? this.imageUrl,
      link: link ?? this.link,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      richNote: richNote ?? this.richNote,
    );
  }

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
      // Serialize mới
      'imagePath': imagePath,
      'audioPath': audioPath,
      'audioDuration': audioDuration,
      'imageUrl': imageUrl,
      'link': link,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'richNote': richNote,
    };
  }

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
      // Deserialize mới
      imagePath: json['imagePath'] as String?,
      audioPath: json['audioPath'] as String?,
      audioDuration: json['audioDuration'] as int?,
      imageUrl: json['imageUrl'] as String?,
      link: json['link'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      richNote: json['richNote'] as String?,
    );
  }
}
