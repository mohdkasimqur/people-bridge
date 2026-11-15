// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkerDataAdapter extends TypeAdapter<WorkerData> {
  @override
  final int typeId = 1;

  @override
  WorkerData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkerData(
      name: fields[0] as String,
      phone: fields[1] as String,
      job: (fields[2] as List).cast<String>(),
      experience: fields[3] as String,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      availableToday: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WorkerData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.job)
      ..writeByte(3)
      ..write(obj.experience)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.availableToday);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
