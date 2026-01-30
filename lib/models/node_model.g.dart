// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NodeModelAdapter extends TypeAdapter<NodeModel> {
  @override
  final int typeId = 0;

  @override
  NodeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NodeModel(
      id: fields[0] as String,
      content: fields[1] as String,
      paliText: fields[2] as String?,
      note: fields[3] as String?,
      childIds: (fields[4] as List?)?.cast<String>(),
      parentId: fields[5] as String?,
      level: fields[6] as int,
      colorIndex: fields[7] as int,
      isFlashcard: fields[8] as bool,
      nextReviewDate: fields[9] as DateTime?,
      repetitionCount: fields[10] as int,
      easeFactor: fields[11] as double,
      intervalDays: fields[12] as int,
      positionX: fields[13] as double?,
      positionY: fields[14] as double?,
      imagePath: fields[15] as String?,
      audioPath: fields[16] as String?,
      audioDuration: fields[17] as int?,
      imageUrl: fields[18] as String?,
      link: fields[19] as String?,
      createdAt: fields[20] as DateTime?,
      updatedAt: fields[21] as DateTime?,
      richNote: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NodeModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.paliText)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.childIds)
      ..writeByte(5)
      ..write(obj.parentId)
      ..writeByte(6)
      ..write(obj.level)
      ..writeByte(7)
      ..write(obj.colorIndex)
      ..writeByte(8)
      ..write(obj.isFlashcard)
      ..writeByte(9)
      ..write(obj.nextReviewDate)
      ..writeByte(10)
      ..write(obj.repetitionCount)
      ..writeByte(11)
      ..write(obj.easeFactor)
      ..writeByte(12)
      ..write(obj.intervalDays)
      ..writeByte(13)
      ..write(obj.positionX)
      ..writeByte(14)
      ..write(obj.positionY)
      ..writeByte(15)
      ..write(obj.imagePath)
      ..writeByte(16)
      ..write(obj.audioPath)
      ..writeByte(17)
      ..write(obj.audioDuration)
      ..writeByte(18)
      ..write(obj.imageUrl)
      ..writeByte(19)
      ..write(obj.link)
      ..writeByte(20)
      ..write(obj.createdAt)
      ..writeByte(21)
      ..write(obj.updatedAt)
      ..writeByte(22)
      ..write(obj.richNote);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
