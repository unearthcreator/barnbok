// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardInfoAdapter extends TypeAdapter<CardInfo> {
  @override
  final int typeId = 0;

  @override
  CardInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardInfo(
      uniqueId: fields[0] as String,
      surname: fields[1] as String,
      lastName: fields[2] as String,
      imagePath: fields[3] as String,
      positionIndex: fields[4] as int,
      serverId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CardInfo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.uniqueId)
      ..writeByte(1)
      ..write(obj.surname)
      ..writeByte(2)
      ..write(obj.lastName)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.positionIndex)
      ..writeByte(5)
      ..write(obj.serverId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
