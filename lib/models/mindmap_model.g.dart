// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mindmap_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MindMapModelAdapter extends TypeAdapter<MindMapModel> {
  @override
  final int typeId = 1;

  @override
  MindMapModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MindMapModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      rootNodeId: fields[3] as String,
      nodes: (fields[4] as List).cast<NodeModel>(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      tags: (fields[7] as List?)?.cast<String>(),
      folderId: fields[8] as String?,
      isZenMode: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MindMapModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.rootNodeId)
      ..writeByte(4)
      ..write(obj.nodes)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.folderId)
      ..writeByte(9)
      ..write(obj.isZenMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMapModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
