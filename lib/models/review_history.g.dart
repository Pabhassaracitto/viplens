// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReviewHistoryAdapter extends TypeAdapter<ReviewHistory> {
  @override
  final int typeId = 3;

  @override
  ReviewHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReviewHistory(
      id: fields[0] as String,
      nodeId: fields[1] as String,
      mindmapId: fields[2] as String,
      reviewedAt: fields[3] as DateTime,
      quality: fields[4] as int,
      previousInterval: fields[5] as int,
      newInterval: fields[6] as int,
      previousEaseFactor: fields[7] as double,
      newEaseFactor: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ReviewHistory obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nodeId)
      ..writeByte(2)
      ..write(obj.mindmapId)
      ..writeByte(3)
      ..write(obj.reviewedAt)
      ..writeByte(4)
      ..write(obj.quality)
      ..writeByte(5)
      ..write(obj.previousInterval)
      ..writeByte(6)
      ..write(obj.newInterval)
      ..writeByte(7)
      ..write(obj.previousEaseFactor)
      ..writeByte(8)
      ..write(obj.newEaseFactor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
