// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurrenceRuleAdapter extends TypeAdapter<RecurrenceRule> {
  @override
  final int typeId = 8;

  @override
  RecurrenceRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurrenceRule(
      pattern: fields[0] as RecurrencePattern,
      interval: fields[1] as int?,
      endDate: fields[2] as DateTime?,
      maxOccurrences: fields[3] as int?,
      selectedWeekdays: (fields[4] as List?)?.cast<int>(),
      monthlyType: fields[5] as MonthlyRecurrenceType?,
      weekOfMonth: fields[6] as int?,
      dayOfMonth: fields[7] as int?,
      excludedDates: (fields[8] as List?)?.cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, RecurrenceRule obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.pattern)
      ..writeByte(1)
      ..write(obj.interval)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.maxOccurrences)
      ..writeByte(4)
      ..write(obj.selectedWeekdays)
      ..writeByte(5)
      ..write(obj.monthlyType)
      ..writeByte(6)
      ..write(obj.weekOfMonth)
      ..writeByte(7)
      ..write(obj.dayOfMonth)
      ..writeByte(8)
      ..write(obj.excludedDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MonthlyRecurrenceTypeAdapter extends TypeAdapter<MonthlyRecurrenceType> {
  @override
  final int typeId = 9;

  @override
  MonthlyRecurrenceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MonthlyRecurrenceType.byDate;
      case 1:
        return MonthlyRecurrenceType.byWeekday;
      default:
        return MonthlyRecurrenceType.byDate;
    }
  }

  @override
  void write(BinaryWriter writer, MonthlyRecurrenceType obj) {
    switch (obj) {
      case MonthlyRecurrenceType.byDate:
        writer.writeByte(0);
        break;
      case MonthlyRecurrenceType.byWeekday:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyRecurrenceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
