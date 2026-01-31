import 'package:hive/hive.dart';

part 'folder_model.g.dart';

@HiveType(typeId: 2)
class FolderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? icon;

  @HiveField(3)
  int colorIndex;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int order;

  FolderModel({
    required this.id,
    required this.name,
    this.icon,
    this.colorIndex = 0,
    required this.createdAt,
    this.order = 0,
  });

  FolderModel copyWith({
    String? id,
    String? name,
    String? icon,
    int? colorIndex,
    DateTime? createdAt,
    int? order,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorIndex': colorIndex,
      'createdAt': createdAt.toIso8601String(),
      'order': order,
    };
  }

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      colorIndex: json['colorIndex'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      order: json['order'] as int? ?? 0,
    );
  }
}
