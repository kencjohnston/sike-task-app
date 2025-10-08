// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskTypeAdapter extends TypeAdapter<TaskType> {
  @override
  final int typeId = 1;

  @override
  TaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskType.creative;
      case 1:
        return TaskType.administrative;
      case 2:
        return TaskType.technical;
      case 3:
        return TaskType.communication;
      case 4:
        return TaskType.physical;
      default:
        return TaskType.creative;
    }
  }

  @override
  void write(BinaryWriter writer, TaskType obj) {
    switch (obj) {
      case TaskType.creative:
        writer.writeByte(0);
        break;
      case TaskType.administrative:
        writer.writeByte(1);
        break;
      case TaskType.technical:
        writer.writeByte(2);
        break;
      case TaskType.communication:
        writer.writeByte(3);
        break;
      case TaskType.physical:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RequiredResourceAdapter extends TypeAdapter<RequiredResource> {
  @override
  final int typeId = 2;

  @override
  RequiredResource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RequiredResource.computer;
      case 1:
        return RequiredResource.phone;
      case 2:
        return RequiredResource.internet;
      case 3:
        return RequiredResource.materials;
      case 4:
        return RequiredResource.tools;
      case 5:
        return RequiredResource.transportation;
      case 6:
        return RequiredResource.people;
      case 7:
        return RequiredResource.documents;
      default:
        return RequiredResource.computer;
    }
  }

  @override
  void write(BinaryWriter writer, RequiredResource obj) {
    switch (obj) {
      case RequiredResource.computer:
        writer.writeByte(0);
        break;
      case RequiredResource.phone:
        writer.writeByte(1);
        break;
      case RequiredResource.internet:
        writer.writeByte(2);
        break;
      case RequiredResource.materials:
        writer.writeByte(3);
        break;
      case RequiredResource.tools:
        writer.writeByte(4);
        break;
      case RequiredResource.transportation:
        writer.writeByte(5);
        break;
      case RequiredResource.people:
        writer.writeByte(6);
        break;
      case RequiredResource.documents:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequiredResourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskContextAdapter extends TypeAdapter<TaskContext> {
  @override
  final int typeId = 3;

  @override
  TaskContext read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskContext.home;
      case 1:
        return TaskContext.office;
      case 2:
        return TaskContext.outdoor;
      case 3:
        return TaskContext.anywhere;
      case 4:
        return TaskContext.specificRoom;
      default:
        return TaskContext.home;
    }
  }

  @override
  void write(BinaryWriter writer, TaskContext obj) {
    switch (obj) {
      case TaskContext.home:
        writer.writeByte(0);
        break;
      case TaskContext.office:
        writer.writeByte(1);
        break;
      case TaskContext.outdoor:
        writer.writeByte(2);
        break;
      case TaskContext.anywhere:
        writer.writeByte(3);
        break;
      case TaskContext.specificRoom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskContextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EnergyLevelAdapter extends TypeAdapter<EnergyLevel> {
  @override
  final int typeId = 4;

  @override
  EnergyLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EnergyLevel.high;
      case 1:
        return EnergyLevel.medium;
      case 2:
        return EnergyLevel.low;
      default:
        return EnergyLevel.high;
    }
  }

  @override
  void write(BinaryWriter writer, EnergyLevel obj) {
    switch (obj) {
      case EnergyLevel.high:
        writer.writeByte(0);
        break;
      case EnergyLevel.medium:
        writer.writeByte(1);
        break;
      case EnergyLevel.low:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnergyLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimeEstimateAdapter extends TypeAdapter<TimeEstimate> {
  @override
  final int typeId = 5;

  @override
  TimeEstimate read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TimeEstimate.veryShort;
      case 1:
        return TimeEstimate.short;
      case 2:
        return TimeEstimate.medium;
      case 3:
        return TimeEstimate.long;
      case 4:
        return TimeEstimate.veryLong;
      default:
        return TimeEstimate.veryShort;
    }
  }

  @override
  void write(BinaryWriter writer, TimeEstimate obj) {
    switch (obj) {
      case TimeEstimate.veryShort:
        writer.writeByte(0);
        break;
      case TimeEstimate.short:
        writer.writeByte(1);
        break;
      case TimeEstimate.medium:
        writer.writeByte(2);
        break;
      case TimeEstimate.long:
        writer.writeByte(3);
        break;
      case TimeEstimate.veryLong:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeEstimateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DueDateStatusAdapter extends TypeAdapter<DueDateStatus> {
  @override
  final int typeId = 6;

  @override
  DueDateStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DueDateStatus.none;
      case 1:
        return DueDateStatus.overdue;
      case 2:
        return DueDateStatus.dueToday;
      case 3:
        return DueDateStatus.upcoming;
      case 4:
        return DueDateStatus.future;
      default:
        return DueDateStatus.none;
    }
  }

  @override
  void write(BinaryWriter writer, DueDateStatus obj) {
    switch (obj) {
      case DueDateStatus.none:
        writer.writeByte(0);
        break;
      case DueDateStatus.overdue:
        writer.writeByte(1);
        break;
      case DueDateStatus.dueToday:
        writer.writeByte(2);
        break;
      case DueDateStatus.upcoming:
        writer.writeByte(3);
        break;
      case DueDateStatus.future:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DueDateStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrencePatternAdapter extends TypeAdapter<RecurrencePattern> {
  @override
  final int typeId = 7;

  @override
  RecurrencePattern read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrencePattern.none;
      case 1:
        return RecurrencePattern.daily;
      case 2:
        return RecurrencePattern.weekly;
      case 3:
        return RecurrencePattern.biweekly;
      case 4:
        return RecurrencePattern.monthly;
      case 5:
        return RecurrencePattern.yearly;
      case 6:
        return RecurrencePattern.custom;
      default:
        return RecurrencePattern.none;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrencePattern obj) {
    switch (obj) {
      case RecurrencePattern.none:
        writer.writeByte(0);
        break;
      case RecurrencePattern.daily:
        writer.writeByte(1);
        break;
      case RecurrencePattern.weekly:
        writer.writeByte(2);
        break;
      case RecurrencePattern.biweekly:
        writer.writeByte(3);
        break;
      case RecurrencePattern.monthly:
        writer.writeByte(4);
        break;
      case RecurrencePattern.yearly:
        writer.writeByte(5);
        break;
      case RecurrencePattern.custom:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrencePatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
