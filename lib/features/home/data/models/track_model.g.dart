// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrackModelAdapter extends TypeAdapter<TrackModel> {
  @override
  final int typeId = 0;

  @override
  TrackModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackModel(
      idField: fields[0] as String,
      titleField: fields[1] as String,
      artistField: fields[2] as String,
      albumArtUrlField: fields[3] as String,
      durationField: fields[4] as String,
      audioUrlField: fields[5] as String,
      localPathField: fields[6] as String?,
      isFavoriteField: fields[7] as bool,
      syncedLyricsField: fields[8] as String?,
      plainLyricsField: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TrackModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.idField)
      ..writeByte(1)
      ..write(obj.titleField)
      ..writeByte(2)
      ..write(obj.artistField)
      ..writeByte(3)
      ..write(obj.albumArtUrlField)
      ..writeByte(4)
      ..write(obj.durationField)
      ..writeByte(5)
      ..write(obj.audioUrlField)
      ..writeByte(6)
      ..write(obj.localPathField)
      ..writeByte(7)
      ..write(obj.isFavoriteField)
      ..writeByte(8)
      ..write(obj.syncedLyricsField)
      ..writeByte(9)
      ..write(obj.plainLyricsField);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
